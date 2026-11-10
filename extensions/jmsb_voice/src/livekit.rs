//! One player in one LiveKit room over pure Rust WebRTC (webrtc-rs), no
//! libwebrtc (2026-11-01: antivirus flagged Google's library). LiveKit's
//! signalling is done here, the way its SDKs do it:
//!
//! - THE SIGNAL is a WebSocket to `<url>/rtc` carrying LiveKit's protobuf
//!   `SignalRequest` / `SignalResponse` (the `livekit-protocol` crate), one
//!   per binary frame. TLS is rustls over ring, the certificate checked by
//!   Windows' own verifier (the system's roots).
//! - TWO PEER CONNECTIONS, as LiveKit's dual-PC mode has them: the PUBLISHER
//!   (we offer: our one microphone track) and the SUBSCRIBER (the server
//!   offers whatever we subscribed to, we answer). ICE candidates trickle
//!   both ways over the signal, each marked with the connection it is for.
//! - THE MICROPHONE is announced first (AddTrackRequest, muted), and offered
//!   once the server has given it a track sid. Push-to-talk mutes and
//!   unmutes it on the server (MuteTrackRequest); the session sends packets
//!   only while the key is held anyway. Each Opus packet is one RTP packet,
//!   timed by the clock so a pause between transmissions is a pause to the
//!   receivers too. It carries a fixed audio level (`SPEAKING_LEVEL`), which
//!   is what LiveKit's speaker detection reads.
//! - NOBODY IS RECEIVED until `subscribe` asks for him (auto-subscribe off):
//!   his audio tracks are subscribed by sid, now and whenever he publishes
//!   one later; turned off, they are unsubscribed.
//! - WHO SENT A PACKET: each remote track is LiveKit's track sid (the msid,
//!   whose stream id is "participantSid|trackSid"), and the participant
//!   infos say whose track that is.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use futures_util::stream::{SplitSink, SplitStream};
use futures_util::{SinkExt, StreamExt};
use livekit_protocol as proto;
use prost::Message as _;
use proto::{signal_request, signal_response, SignalTarget};
use rtc::media_stream::MediaStreamTrack;
use rtc::rtp::extension::audio_level_extension::AudioLevelExtension;
use rtc::rtp::extension::HeaderExtension;
use rtc::rtp_transceiver::rtp_sender::{
    RTCRtpCodec, RTCRtpCodecParameters, RTCRtpCodingParameters, RTCRtpEncodingParameters,
    RTCRtpHeaderExtensionCapability, RtpCodecKind,
};
use rtc::rtp_transceiver::{RTCRtpTransceiverDirection, RTCRtpTransceiverInit};
use rtc::sdp::extmap::AUDIO_LEVEL_URI;
use tokio::io::{AsyncRead, AsyncWrite};
use tokio::net::TcpStream;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tokio::sync::oneshot;
use tokio::task::JoinHandle;
use tokio_rustls::rustls;
use tokio_rustls::TlsConnector;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::{self, Message as WsMessage};
use tokio_tungstenite::WebSocketStream;
use webrtc::media_stream::track_local::static_rtp::TrackLocalStaticRTP;
use webrtc::media_stream::track_remote::{TrackRemote, TrackRemoteEvent};
use webrtc::media_stream::Track;
use webrtc::peer_connection::{
    register_default_interceptors, MediaEngine, PeerConnection, PeerConnectionBuilder,
    PeerConnectionEventHandler, RTCBundlePolicy, RTCConfigurationBuilder, RTCIceCandidateInit,
    RTCIceServer, RTCPeerConnectionIceEvent, RTCPeerConnectionState, RTCSessionDescription, Registry,
};
use webrtc::rtp_transceiver::RtpTransceiver;

use crate::session::{Event, Inbound};

/// The signal protocol version we speak. 16 has everything used here (the
/// packed "participantSid|trackSid" stream id, speakers-changed, PingReq)
/// and comes before 18, where the data channels become pre-negotiated ones
/// this client would have to open itself.
const PROTOCOL: u32 = 16;
/// Who we say we are to the server.
const SDK: &str = "rust";
const SDK_VERSION: &str = env!("CARGO_PKG_VERSION");
/// The ports a ws:// / wss:// address means when it names none.
const WS_PORT: u16 = 80;
const WSS_PORT: u16 = 443;
/// How long the connect, the TLS, and the server's JoinResponse may take (s).
const CONNECT_TIMEOUT_S: u64 = 15;
/// Ping interval and timeout (s) when the JoinResponse gives none.
const DEFAULT_PING_INTERVAL_S: u64 = 5;
const DEFAULT_PING_TIMEOUT_S: u64 = 15;
/// Where the peer connections gather their host candidates: every local
/// IPv4 interface (webrtc-rs binds one socket per interface for a wildcard),
/// each on a port of the system's choosing.
const UDP_BIND: &str = "0.0.0.0:0";

/// Opus as WebRTC names it: 48 kHz, "2" channels in the SDP whatever is sent
/// (RFC 7587 - we send mono), and the parameters every browser offers.
const OPUS_MIME: &str = "audio/opus";
const OPUS_RATE: u32 = 48_000;
const OPUS_SDP_CHANNELS: u16 = 2;
const OPUS_FMTP: &str = "minptime=10;useinbandfec=1";
const OPUS_PAYLOAD_TYPE: u8 = 111;
/// One packet from the session is 20 ms: this many samples at 48 kHz.
const FRAME_SAMPLES: u32 = OPUS_RATE / 50;
/// The RTP version.
const RTP_VERSION: u8 = 2;
/// The audio level on every packet we send, in -dBov (0 loudest, 127
/// silence). Packets go out only while the key is held, so this says "talking";
/// LiveKit counts a level under its active level (35 by default) as speech.
/// The session hands over Opus, not samples, so there is no measured level.
const SPEAKING_LEVEL: u8 = 30;
/// Our microphone track's name on the server.
const TRACK_NAME: &str = "microphone";

/// What the session asks of the connection's task.
enum Ask {
    Audio(Vec<u8>, bool),
    Talking(bool),
    Subscribe(String, bool),
    Close(oneshot::Sender<()>),
}

/// What the peer connections tell the connection's task. Their callbacks run
/// on the connections' own drivers, so they only pass things on.
enum PcEvent {
    Candidate(SignalTarget, RTCIceCandidateInit),
    State(SignalTarget, RTCPeerConnectionState),
    Track(Arc<dyn TrackRemote>),
}

/// The handle to one LiveKit connection.
#[derive(Clone)]
pub struct Conn {
    tx: UnboundedSender<Ask>,
}

impl Conn {
    /// Opens the signal and joins the room, then hands the rest to the
    /// connection's task. Its first events are `Connected`, then `Joined`
    /// for everyone already in the room.
    pub async fn connect(
        url: &str,
        token: &str,
        inbound: UnboundedSender<Inbound>,
        events: UnboundedSender<Event>,
    ) -> Result<Self, String> {
        let timeout = Duration::from_secs(CONNECT_TIMEOUT_S);
        let (ws, join) = tokio::time::timeout(timeout, join(url, token))
            .await
            .map_err(|_| format!("livekit: no answer from {url} in {CONNECT_TIMEOUT_S} s"))??;

        let ice_servers: Vec<RTCIceServer> = join
            .ice_servers
            .iter()
            .map(|s| RTCIceServer { urls: s.urls.clone(), username: s.username.clone(), credential: s.credential.clone() })
            .collect();
        let (pc_tx, pc_rx) = unbounded_channel::<PcEvent>();
        let publisher = peer(SignalTarget::Publisher, ice_servers.clone(), pc_tx.clone()).await?;
        let subscriber = peer(SignalTarget::Subscriber, ice_servers, pc_tx).await?;

        let (tx, rx) = unbounded_channel::<Ask>();
        tokio::spawn(run(ws, join, publisher, subscriber, rx, pc_rx, inbound, events));
        Ok(Self { tx })
    }

    pub fn send(&self, opus: Vec<u8>, last: bool) {
        let _ = self.tx.send(Ask::Audio(opus, last));
    }

    /// Mutes or unmutes the microphone track on the server.
    pub fn set_talking(&self, on: bool) {
        let _ = self.tx.send(Ask::Talking(on));
    }

    /// Subscribes to his audio tracks, or unsubscribes them.
    pub fn subscribe(&self, identity: &str, on: bool) {
        let _ = self.tx.send(Ask::Subscribe(identity.to_owned(), on));
    }

    /// Leaves the room; no event follows.
    pub async fn close(&self) {
        let (done_tx, done_rx) = oneshot::channel();
        if self.tx.send(Ask::Close(done_tx)).is_ok() {
            let _ = done_rx.await;
        }
    }
}

/// The signal's stream: plain TCP for ws://, TLS for wss://.
trait Io: AsyncRead + AsyncWrite + Unpin + Send {}
impl<T: AsyncRead + AsyncWrite + Unpin + Send> Io for T {}

type Ws = WebSocketStream<Box<dyn Io>>;
type WsWriter = SplitSink<Ws, WsMessage>;
type WsReader = SplitStream<Ws>;

/// The signal's address: the server's, with LiveKit's `/rtc` and our join
/// parameters. An http(s) address is taken as its ws(s) twin.
fn signal_url(url: &str, token: &str) -> Result<String, String> {
    let url = url.trim().trim_end_matches('/');
    let base = if let Some(rest) = url.strip_prefix("https://") {
        format!("wss://{rest}")
    } else if let Some(rest) = url.strip_prefix("http://") {
        format!("ws://{rest}")
    } else if url.starts_with("ws://") || url.starts_with("wss://") {
        url.to_owned()
    } else {
        return Err(format!("livekit: '{url}' is not a ws:// or wss:// address"));
    };
    // A JWT is base64url and dots: nothing in it needs escaping.
    Ok(format!(
        "{base}/rtc?access_token={token}&auto_subscribe=0&adaptive_stream=0&sdk={SDK}&version={SDK_VERSION}&protocol={PROTOCOL}"
    ))
}

/// TLS for wss://, the server's certificate checked against the system's
/// trusted roots (Windows' own verifier).
async fn tls(host: &str, tcp: TcpStream) -> Result<tokio_rustls::client::TlsStream<TcpStream>, String> {
    use rustls_platform_verifier::BuilderVerifierExt;
    let provider = Arc::new(rustls::crypto::ring::default_provider());
    let config = rustls::ClientConfig::builder_with_provider(provider)
        .with_safe_default_protocol_versions()
        .map_err(|e| e.to_string())?
        .with_platform_verifier()
        .map_err(|e| e.to_string())?
        .with_no_client_auth();
    let name = rustls::pki_types::ServerName::try_from(host.to_owned()).map_err(|e| e.to_string())?;
    TlsConnector::from(Arc::new(config))
        .connect(name, tcp)
        .await
        .map_err(|e| format!("livekit: TLS: {e}"))
}

/// Opens the signal and waits for the server's JoinResponse.
async fn join(url: &str, token: &str) -> Result<(Ws, proto::JoinResponse), String> {
    let request = signal_url(url, token)?.into_client_request().map_err(|e| format!("livekit: {e}"))?;
    let uri = request.uri().clone();
    let secure = uri.scheme_str() == Some("wss");
    let host = uri.host().ok_or("livekit: the address has no host")?;
    let host = host.trim_start_matches('[').trim_end_matches(']').to_owned();
    let port = uri.port_u16().unwrap_or(if secure { WSS_PORT } else { WS_PORT });

    let tcp = TcpStream::connect((host.as_str(), port))
        .await
        .map_err(|e| format!("livekit: {host}:{port}: {e}"))?;
    let _ = tcp.set_nodelay(true);
    let io: Box<dyn Io> = if secure { Box::new(tls(&host, tcp).await?) } else { Box::new(tcp) };
    let (mut ws, _) = tokio_tungstenite::client_async(request, io).await.map_err(|e| match e {
        // The server says why it refused (a bad token, no such room) in the body.
        tungstenite::Error::Http(response) => {
            let body = response.body().as_deref().map(String::from_utf8_lossy).unwrap_or_default();
            format!("livekit: refused ({}): {}", response.status(), body.trim())
        }
        e => format!("livekit: {e}"),
    })?;

    loop {
        let frame = ws.next().await.ok_or("livekit: the server closed the signal before joining")?;
        let Some(message) = decode(frame.map_err(|e| format!("livekit: {e}"))?)? else { continue };
        match message {
            signal_response::Message::Join(join) => return Ok((ws, join)),
            signal_response::Message::Leave(leave) => {
                return Err(format!("livekit: refused: {}", leave.reason().as_str_name()));
            }
            _ => {}
        }
    }
}

/// One signal frame read; `None` for frames that are no message (pings,
/// text). A close is an error: the server has dropped us.
fn decode(frame: WsMessage) -> Result<Option<signal_response::Message>, String> {
    match frame {
        WsMessage::Binary(data) => proto::SignalResponse::decode(data)
            .map(|r| r.message)
            .map_err(|e| format!("livekit: bad signal message: {e}")),
        WsMessage::Close(frame) => Err(match frame {
            Some(f) if !f.reason.is_empty() => format!("livekit: the server closed the signal: {}", f.reason),
            _ => "livekit: the server closed the signal".to_owned(),
        }),
        _ => Ok(None),
    }
}

/// One message to the server.
async fn signal(writer: &mut WsWriter, message: signal_request::Message) -> Result<(), String> {
    let bytes = proto::SignalRequest { message: Some(message) }.encode_to_vec();
    writer.send(WsMessage::Binary(bytes.into())).await.map_err(|e| format!("livekit: signal: {e}"))
}

/// Passes one peer connection's events to the connection's task, marked
/// with which connection they come from.
struct Handler {
    target: SignalTarget,
    tx: UnboundedSender<PcEvent>,
}

#[async_trait::async_trait]
impl PeerConnectionEventHandler for Handler {
    async fn on_ice_candidate(&self, event: RTCPeerConnectionIceEvent) {
        match event.candidate.to_json() {
            Ok(init) => {
                let _ = self.tx.send(PcEvent::Candidate(self.target, init));
            }
            Err(e) => log::warn!("livekit: {:?} candidate: {e}", self.target),
        }
    }

    async fn on_connection_state_change(&self, state: RTCPeerConnectionState) {
        let _ = self.tx.send(PcEvent::State(self.target, state));
    }

    async fn on_track(&self, track: Arc<dyn TrackRemote>) {
        let _ = self.tx.send(PcEvent::Track(track));
    }
}

/// Opus, as both connections offer and accept it.
fn opus() -> RTCRtpCodec {
    RTCRtpCodec {
        mime_type: OPUS_MIME.to_owned(),
        clock_rate: OPUS_RATE,
        channels: OPUS_SDP_CHANNELS,
        sdp_fmtp_line: OPUS_FMTP.to_owned(),
        rtcp_feedback: vec![],
    }
}

/// One peer connection: Opus only (audio is all this carries; anything else
/// the server offers is declined), the audio level extension, and the usual
/// RTCP (reports, NACK). Max-bundle, as LiveKit expects: one transport.
async fn peer(target: SignalTarget, ice_servers: Vec<RTCIceServer>, tx: UnboundedSender<PcEvent>) -> Result<Arc<dyn PeerConnection>, String> {
    let fail = |e: webrtc::error::Error| format!("livekit: {target:?} connection: {e}");
    let mut media = MediaEngine::default();
    media
        .register_codec(RTCRtpCodecParameters { rtp_codec: opus(), payload_type: OPUS_PAYLOAD_TYPE }, RtpCodecKind::Audio)
        .map_err(fail)?;
    media
        .register_header_extension(RTCRtpHeaderExtensionCapability { uri: AUDIO_LEVEL_URI.to_owned() }, RtpCodecKind::Audio, None)
        .map_err(fail)?;
    let registry = register_default_interceptors(Registry::new(), &mut media).map_err(fail)?;
    let config = RTCConfigurationBuilder::new()
        .with_ice_servers(ice_servers)
        .with_bundle_policy(RTCBundlePolicy::MaxBundle)
        .build();
    let pc = PeerConnectionBuilder::new()
        .with_configuration(config)
        .with_media_engine(media)
        .with_interceptor_registry(registry)
        .with_handler(Arc::new(Handler { target, tx }))
        .with_udp_addrs(vec![UDP_BIND.to_owned()])
        .build()
        .await
        .map_err(fail)?;
    Ok(Arc::new(pc))
}

/// Random bytes from the system (ring's), for ids, the SSRC and the RTP
/// sequence and timestamp starts.
fn random<const N: usize>() -> [u8; N] {
    let rng = ring::rand::SystemRandom::new();
    ring::rand::generate::<[u8; N]>(&rng).map(|r| r.expose()).unwrap_or([0; N])
}

fn random_hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

/// Milliseconds since 1970, for the ping.
fn now_ms() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_millis() as i64).unwrap_or(0)
}

/// The first `a=mid:` of an SDP: with max-bundle every candidate belongs to
/// it. webrtc-rs leaves a gathered candidate's mid empty.
fn first_mid(sdp: &str) -> Option<String> {
    sdp.lines().find_map(|l| l.trim().strip_prefix("a=mid:")).map(str::to_owned)
}

/// Our microphone: the track, its state on the server, and the RTP stream.
struct Mic {
    track: Arc<TrackLocalStaticRTP>,
    /// Our id for the track until the server names it (AddTrackRequest.cid,
    /// also the msid track id it is matched by).
    cid: String,
    /// The server's track sid, from TrackPublishedResponse.
    sid: Option<String>,
    transceiver: Option<Arc<dyn RtpTransceiver>>,
    /// The SSRC and payload type to send with, once the offer is answered.
    sending: Option<(u32, u8)>,
    /// Push-to-talk as the session last set it.
    talking: bool,
    /// The RTP stream: the next sequence number and timestamp, the clock
    /// the timestamps follow, and whether a transmission is under way.
    sequence: u16,
    timestamp: u32,
    timestamp_base: u32,
    clock: Instant,
    in_transmission: bool,
}

impl Mic {
    fn new() -> Self {
        let cid = format!("TR_jmsb_{}", random_hex(&random::<8>()));
        let ssrc = u32::from_be_bytes(random::<4>());
        let track = MediaStreamTrack::new(
            format!("jmsb_{}", random_hex(&random::<8>())),
            cid.clone(),
            TRACK_NAME.to_owned(),
            RtpCodecKind::Audio,
            vec![RTCRtpEncodingParameters {
                rtp_coding_parameters: RTCRtpCodingParameters { ssrc: Some(ssrc), ..Default::default() },
                codec: opus(),
                ..Default::default()
            }],
        );
        let timestamp_base = u32::from_be_bytes(random::<4>());
        Self {
            track: Arc::new(TrackLocalStaticRTP::new(track)),
            cid,
            sid: None,
            transceiver: None,
            sending: None,
            talking: false,
            sequence: u16::from_be_bytes(random::<2>()),
            timestamp: timestamp_base,
            timestamp_base,
            clock: Instant::now(),
            in_transmission: false,
        }
    }

    /// The RTP packet for one Opus packet. A transmission's first packet is
    /// stamped with the clock (so the silence before it lasts as long for
    /// the receivers) and marked as a talk spurt's start; the rest follow
    /// 20 ms apart.
    fn packet(&mut self, ssrc: u32, payload_type: u8, opus: Vec<u8>, last: bool) -> rtc::rtp::Packet {
        let marker = !self.in_transmission;
        if marker {
            let elapsed = (self.clock.elapsed().as_micros() * u128::from(OPUS_RATE) / 1_000_000) as u32;
            let now = self.timestamp_base.wrapping_add(elapsed);
            // never backwards: a clock behind the last packet sent waits
            if now.wrapping_sub(self.timestamp) as i32 > 0 {
                self.timestamp = now;
            }
        }
        let header = rtc::rtp::Header {
            version: RTP_VERSION,
            marker,
            payload_type,
            sequence_number: self.sequence,
            timestamp: self.timestamp,
            ssrc,
            ..Default::default()
        };
        self.sequence = self.sequence.wrapping_add(1);
        self.timestamp = self.timestamp.wrapping_add(FRAME_SAMPLES);
        self.in_transmission = !last;
        rtc::rtp::Packet { header, payload: opus.into() }
    }
}

/// The room as we know it.
#[derive(Default)]
struct Room {
    own_sid: String,
    own_identity: String,
    /// Everyone else, by participant sid.
    participants: HashMap<String, proto::ParticipantInfo>,
    /// Whose audio the session wants, by identity.
    wanted: HashSet<String>,
    /// The audio tracks we are subscribed to, by track sid.
    subscribed: HashSet<String>,
    /// Who is talking, by participant sid (ours included).
    speaking: HashSet<String>,
    /// Track sid -> its owner's identity, for the track readers.
    owners: Arc<Mutex<HashMap<String, String>>>,
}

impl Room {
    /// Takes in one participant's info; older versions of it than we have
    /// are ignored (updates may cross), and a disconnected one is dropped.
    fn update(&mut self, p: proto::ParticipantInfo) {
        if p.sid == self.own_sid {
            return;
        }
        if self.participants.get(&p.sid).is_some_and(|old| p.version < old.version) {
            return;
        }
        if p.state == proto::participant_info::State::Disconnected as i32 {
            self.participants.remove(&p.sid);
        } else {
            self.participants.insert(p.sid.clone(), p);
        }
        let owners = self
            .participants
            .values()
            .flat_map(|p| p.tracks.iter().map(|t| (t.sid.clone(), p.identity.clone())))
            .collect();
        *self.owners.lock().unwrap() = owners;
    }

    /// Everyone else in the room, by identity.
    fn present(&self) -> HashSet<String> {
        self.participants.values().map(|p| p.identity.clone()).collect()
    }

    /// The audio tracks of everyone wanted: participant sid -> track sids.
    fn wanted_tracks(&self) -> HashMap<String, Vec<String>> {
        self.participants
            .values()
            .filter(|p| self.wanted.contains(&p.identity))
            .map(|p| {
                let audio = p.tracks.iter().filter(|t| t.r#type == proto::TrackType::Audio as i32).map(|t| t.sid.clone());
                (p.sid.clone(), audio.collect())
            })
            .collect()
    }

    /// The track's owner, by participant sid, while he is here.
    fn owner_sid(&self, track_sid: &str) -> Option<String> {
        self.participants.values().find(|p| p.tracks.iter().any(|t| t.sid == track_sid)).map(|p| p.sid.clone())
    }

    /// Whoever is talking now, by identity, sorted.
    fn speakers(&self) -> Vec<String> {
        let mut ids: Vec<String> = self
            .speaking
            .iter()
            .filter_map(|sid| {
                if *sid == self.own_sid {
                    Some(self.own_identity.clone())
                } else {
                    self.participants.get(sid).map(|p| p.identity.clone())
                }
            })
            .collect();
        ids.sort();
        ids.dedup();
        ids
    }
}

/// Brings the server's subscriptions in line with who is wanted: their audio
/// tracks subscribed (a track published later included), every other
/// subscribed track that still exists unsubscribed.
async fn sync_subscriptions(room: &mut Room, writer: &mut WsWriter) -> Result<(), String> {
    let wanted = room.wanted_tracks();
    let want: HashSet<&String> = wanted.values().flatten().collect();

    let add: Vec<proto::ParticipantTracks> = wanted
        .iter()
        .map(|(p, tracks)| proto::ParticipantTracks {
            participant_sid: p.clone(),
            track_sids: tracks.iter().filter(|t| !room.subscribed.contains(*t)).cloned().collect(),
        })
        .filter(|pt| !pt.track_sids.is_empty())
        .collect();

    let mut unwanted: HashMap<String, Vec<String>> = HashMap::new();
    for t in room.subscribed.iter().filter(|t| !want.contains(t)) {
        // a track gone with its owner needs no unsubscribing
        if let Some(p) = room.owner_sid(t) {
            unwanted.entry(p).or_default().push(t.clone());
        }
    }
    room.subscribed = want.into_iter().cloned().collect();
    let remove = unwanted.into_iter().map(|(p, t)| proto::ParticipantTracks { participant_sid: p, track_sids: t }).collect();

    for (pts, on) in [(add, true), (remove, false)] {
        if pts.is_empty() {
            continue;
        }
        let track_sids = pts.iter().flat_map(|pt| pt.track_sids.iter().cloned()).collect();
        log::info!("livekit: {} {:?}", if on { "subscribe" } else { "unsubscribe" }, track_sids);
        let m = proto::UpdateSubscription { track_sids, subscribe: on, participant_tracks: pts };
        signal(writer, signal_request::Message::Subscription(m)).await?;
    }
    Ok(())
}

/// Tells the session who came and went since `before`.
fn report_change(before: &HashSet<String>, now: &HashSet<String>, events: &UnboundedSender<Event>, inbound: &UnboundedSender<Inbound>) {
    for id in now.difference(before) {
        let _ = events.send(Event::Joined(id.clone()));
    }
    for id in before.difference(now) {
        let _ = inbound.send(Inbound::Gone(id.clone()));
        let _ = events.send(Event::Left(id.clone()));
    }
}

/// One remote track's packets to the session, under its owner's identity
/// (looked up per packet: the owner is known from the participant infos,
/// which may arrive after the track's first packet). The reader lives as
/// long as the connection: webrtc-rs keeps one track per track sid, which
/// carries the packets again when the track is subscribed again.
async fn read_track(track: Arc<dyn TrackRemote>, track_sid: String, owners: Arc<Mutex<HashMap<String, String>>>, inbound: UnboundedSender<Inbound>) {
    while let Some(event) = track.poll().await {
        let TrackRemoteEvent::OnRtpPacket(packet) = event else { continue };
        if packet.payload.is_empty() {
            continue; // padding
        }
        let Some(identity) = owners.lock().unwrap().get(&track_sid).cloned() else { continue };
        if inbound.send(Inbound::Audio { identity, opus: packet.payload.to_vec() }).is_err() {
            break;
        }
    }
}

/// The connection's two peer connections, and what each needs while it
/// waits for its remote description.
struct Peers {
    publisher: Arc<dyn PeerConnection>,
    subscriber: Arc<dyn PeerConnection>,
    /// Candidates that came before their connection's remote description.
    pending: HashMap<SignalTarget, Vec<RTCIceCandidateInit>>,
}

impl Peers {
    fn get(&self, target: SignalTarget) -> &Arc<dyn PeerConnection> {
        match target {
            SignalTarget::Publisher => &self.publisher,
            SignalTarget::Subscriber => &self.subscriber,
        }
    }

    /// A server candidate: added now, or kept until the description is in.
    async fn add_candidate(&mut self, target: SignalTarget, init: RTCIceCandidateInit) {
        let pc = self.get(target).clone();
        if pc.remote_description().await.is_none() {
            self.pending.entry(target).or_default().push(init);
        } else if let Err(e) = pc.add_ice_candidate(init).await {
            log::warn!("livekit: {target:?} remote candidate: {e}");
        }
    }

    /// Sets the remote description, then adds the candidates kept for it.
    async fn set_remote(&mut self, target: SignalTarget, desc: RTCSessionDescription) -> Result<(), String> {
        let pc = self.get(target).clone();
        pc.set_remote_description(desc).await.map_err(|e| format!("livekit: {target:?} remote description: {e}"))?;
        for init in self.pending.remove(&target).unwrap_or_default() {
            if let Err(e) = pc.add_ice_candidate(init).await {
                log::warn!("livekit: {target:?} remote candidate: {e}");
            }
        }
        Ok(())
    }
}

/// The microphone, published: its transceiver, and our offer to the server.
async fn offer_mic(mic: &mut Mic, peers: &Peers, writer: &mut WsWriter) -> Result<(), String> {
    let fail = |e: webrtc::error::Error| format!("livekit: publishing: {e}");
    let stream = mic.track.stream_id().await;
    let init = RTCRtpTransceiverInit { direction: RTCRtpTransceiverDirection::Sendonly, streams: vec![stream], send_encodings: vec![] };
    let transceiver = peers.publisher.add_transceiver_from_track(mic.track.clone(), Some(init)).await.map_err(fail)?;
    let offer = peers.publisher.create_offer(None).await.map_err(fail)?;
    peers.publisher.set_local_description(offer).await.map_err(fail)?;
    let sdp = peers.publisher.local_description().await.ok_or("livekit: publishing: no offer")?.sdp;
    let mut mid_to_track_id = HashMap::new();
    if let Ok(Some(mid)) = transceiver.mid().await {
        mid_to_track_id.insert(mid, mic.cid.clone());
    }
    mic.transceiver = Some(transceiver);
    let desc = proto::SessionDescription { r#type: "offer".to_owned(), sdp, id: 0, mid_to_track_id };
    signal(writer, signal_request::Message::Offer(desc)).await
}

/// The SSRC and payload type the answered offer sends with.
async fn mic_sending(mic: &Mic) -> Option<(u32, u8)> {
    let sender = mic.transceiver.as_ref()?.sender().await.ok()??;
    let params = sender.get_parameters().await.ok()?;
    let payload_type = params.rtp_parameters.codecs.first()?.payload_type;
    let ssrc = params.encodings.first()?.rtp_coding_parameters.ssrc?;
    Some((ssrc, payload_type))
}

/// Tells the server the microphone is muted or not, once it has a sid.
async fn send_mute(mic: &Mic, writer: &mut WsWriter) -> Result<(), String> {
    let Some(sid) = mic.sid.clone() else { return Ok(()) };
    signal(writer, signal_request::Message::Mute(proto::MuteTrackRequest { sid, muted: !mic.talking })).await
}

/// The connection's task: the server's messages, the session's asks, the
/// peer connections' events and the ping - until the server drops us or we
/// close.
#[allow(clippy::too_many_arguments)]
async fn run(
    ws: Ws,
    join: proto::JoinResponse,
    publisher: Arc<dyn PeerConnection>,
    subscriber: Arc<dyn PeerConnection>,
    mut asks: UnboundedReceiver<Ask>,
    mut pc_events: UnboundedReceiver<PcEvent>,
    inbound: UnboundedSender<Inbound>,
    events: UnboundedSender<Event>,
) {
    let (mut writer, mut reader): (WsWriter, WsReader) = ws.split();
    // Reading has its own task, so a half-read frame is never dropped.
    let (msg_tx, mut msgs) = unbounded_channel::<Result<signal_response::Message, String>>();
    let read_task = tokio::spawn(async move {
        while let Some(frame) = reader.next().await {
            let m = match frame {
                Ok(frame) => match decode(frame) {
                    Ok(Some(m)) => Ok(m),
                    Ok(None) => continue,
                    Err(e) => Err(e),
                },
                Err(e) => Err(format!("livekit: {e}")),
            };
            let failed = m.is_err();
            if msg_tx.send(m).is_err() || failed {
                return;
            }
        }
        let _ = msg_tx.send(Err("livekit: the signal closed".to_owned()));
    });

    let mut room = Room::default();
    if let Some(me) = &join.participant {
        room.own_sid = me.sid.clone();
        room.own_identity = me.identity.clone();
    }
    log::info!(
        "livekit: joined {} as {} ({}), server {}",
        join.room.as_ref().map(|r| r.name.as_str()).unwrap_or("?"),
        room.own_identity,
        room.own_sid,
        join.server_version
    );
    for p in join.other_participants {
        room.update(p);
    }
    let _ = events.send(Event::Connected);
    let mut present = room.present();
    for id in &present {
        let _ = events.send(Event::Joined(id.clone()));
    }

    let mut peers = Peers { publisher, subscriber, pending: HashMap::new() };
    let mut mic = Mic::new();
    let mut readers: HashMap<String, JoinHandle<()>> = HashMap::new();
    let ping_every = Duration::from_secs(u64::try_from(join.ping_interval).ok().filter(|&s| s > 0).unwrap_or(DEFAULT_PING_INTERVAL_S));
    let ping_timeout = Duration::from_secs(u64::try_from(join.ping_timeout).ok().filter(|&s| s > 0).unwrap_or(DEFAULT_PING_TIMEOUT_S));
    let mut ping = tokio::time::interval(ping_every);
    let mut last_pong = Instant::now();
    let mut rtt: i64 = 0;
    let mut closed: Option<oneshot::Sender<()>> = None;

    // The microphone is announced first; it is offered once it has a sid.
    let add = proto::AddTrackRequest {
        cid: mic.cid.clone(),
        name: TRACK_NAME.to_owned(),
        r#type: proto::TrackType::Audio as i32,
        source: proto::TrackSource::Microphone as i32,
        muted: true,
        disable_red: true,
        ..Default::default()
    };
    let started = signal(&mut writer, signal_request::Message::AddTrack(add)).await;

    let why: Option<String> = if let Err(e) = started {
        Some(e)
    } else {
        loop {
            tokio::select! {
                ask = asks.recv() => match ask {
                    Some(Ask::Audio(opus, last)) => {
                        let Some((ssrc, payload_type)) = mic.sending else { continue };
                        let packet = mic.packet(ssrc, payload_type, opus, last);
                        let level = HeaderExtension::AudioLevel(AudioLevelExtension { level: SPEAKING_LEVEL, voice: true });
                        if let Err(e) = mic.track.write_rtp_with_extensions(packet, &[level]).await {
                            log::warn!("livekit: sending: {e}");
                        }
                    }
                    Some(Ask::Talking(on)) => {
                        if mic.talking != on {
                            mic.talking = on;
                            if let Err(e) = send_mute(&mic, &mut writer).await {
                                break Some(e);
                            }
                        }
                    }
                    Some(Ask::Subscribe(identity, on)) => {
                        if on {
                            room.wanted.insert(identity);
                        } else {
                            room.wanted.remove(&identity);
                        }
                        if let Err(e) = sync_subscriptions(&mut room, &mut writer).await {
                            break Some(e);
                        }
                    }
                    Some(Ask::Close(done)) => {
                        closed = Some(done);
                        break None;
                    }
                    None => break None,
                },
                msg = msgs.recv() => {
                    let message = match msg {
                        Some(Ok(m)) => m,
                        Some(Err(e)) => break Some(e),
                        None => break Some("livekit: the signal closed".to_owned()),
                    };
                    if let Err(e) = handle(message, &mut room, &mut peers, &mut mic, &mut writer, &mut last_pong, &mut rtt, &events).await {
                        break Some(e);
                    }
                    let now = room.present();
                    if now != present {
                        report_change(&present, &now, &events, &inbound);
                        present = now;
                    }
                },
                pc = pc_events.recv() => match pc {
                    Some(PcEvent::Candidate(target, mut init)) => {
                        if let Some(desc) = peers.get(target).local_description().await {
                            if let Some(mid) = first_mid(&desc.sdp) {
                                init.sdp_mid = Some(mid);
                                init.sdp_mline_index = Some(0);
                            }
                        }
                        let candidate_init = match serde_json::to_string(&init) {
                            Ok(json) => json,
                            Err(e) => {
                                log::warn!("livekit: candidate: {e}");
                                continue;
                            }
                        };
                        let m = proto::TrickleRequest { candidate_init, target: target as i32, r#final: false };
                        if let Err(e) = signal(&mut writer, signal_request::Message::Trickle(m)).await {
                            break Some(e);
                        }
                    }
                    Some(PcEvent::State(target, state)) => {
                        log::info!("livekit: {target:?} connection {state}");
                        if state == RTCPeerConnectionState::Failed {
                            break Some(format!("livekit: the {target:?} connection failed (ICE)"));
                        }
                    }
                    Some(PcEvent::Track(track)) => {
                        if track.kind().await != RtpCodecKind::Audio {
                            continue;
                        }
                        // The stream id is "participantSid|trackSid"; the
                        // track id is the track sid too.
                        let stream = track.stream_id().await;
                        let track_sid = match stream.split_once('|') {
                            Some((_, sid)) if !sid.is_empty() => sid.to_owned(),
                            _ => track.track_id().await,
                        };
                        log::info!("livekit: receiving track {track_sid} (stream {stream})");
                        let reader = tokio::spawn(read_track(track, track_sid.clone(), room.owners.clone(), inbound.clone()));
                        if let Some(old) = readers.insert(track_sid, reader) {
                            old.abort();
                        }
                    }
                    // the connections own the senders: they are gone only if closed
                    None => break Some("livekit: the peer connections closed".to_owned()),
                },
                _ = ping.tick() => {
                    if last_pong.elapsed() > ping_timeout {
                        break Some(format!("livekit: no answer from the server in {} s", ping_timeout.as_secs()));
                    }
                    let m = proto::Ping { timestamp: now_ms(), rtt };
                    if let Err(e) = signal(&mut writer, signal_request::Message::PingReq(m)).await {
                        break Some(e);
                    }
                },
            }
        }
    };

    // Our own leaving: the server is told, so the others see us go at once.
    if why.is_none() {
        let leave = proto::LeaveRequest {
            can_reconnect: false,
            reason: proto::DisconnectReason::ClientInitiated as i32,
            action: proto::leave_request::Action::Disconnect as i32,
            regions: None,
        };
        let _ = signal(&mut writer, signal_request::Message::Leave(leave)).await;
    }
    let _ = writer.close().await;
    read_task.abort();
    for reader in readers.into_values() {
        reader.abort();
    }
    let _ = peers.publisher.close().await;
    let _ = peers.subscriber.close().await;
    match why {
        Some(why) => {
            log::info!("livekit: dropped: {why}");
            let _ = events.send(Event::Disconnected(why));
        }
        None => log::info!("livekit: closed"),
    }
    if let Some(done) = closed {
        let _ = done.send(());
    }
}

/// One message from the server.
#[allow(clippy::too_many_arguments)]
async fn handle(
    message: signal_response::Message,
    room: &mut Room,
    peers: &mut Peers,
    mic: &mut Mic,
    writer: &mut WsWriter,
    last_pong: &mut Instant,
    rtt: &mut i64,
    events: &UnboundedSender<Event>,
) -> Result<(), String> {
    use signal_response::Message as M;
    match message {
        // The microphone has its sid: offer it, and unmute it if the key
        // went down meanwhile.
        M::TrackPublished(published) if published.cid == mic.cid => {
            mic.sid = published.track.map(|t| t.sid);
            offer_mic(mic, peers, writer).await?;
            if mic.talking {
                send_mute(mic, writer).await?;
            }
        }
        M::Answer(answer) => {
            let desc = RTCSessionDescription::answer(answer.sdp).map_err(|e| format!("livekit: publisher answer: {e}"))?;
            peers.set_remote(SignalTarget::Publisher, desc).await?;
            mic.sending = mic_sending(mic).await;
            if mic.sending.is_none() {
                log::warn!("livekit: the publisher answer left the microphone with no codec");
            }
        }
        M::Offer(offer) => {
            let fail = |e: webrtc::error::Error| format!("livekit: subscriber: {e}");
            let desc = RTCSessionDescription::offer(offer.sdp).map_err(fail)?;
            peers.set_remote(SignalTarget::Subscriber, desc).await?;
            let answer = peers.subscriber.create_answer(None).await.map_err(fail)?;
            peers.subscriber.set_local_description(answer).await.map_err(fail)?;
            let sdp = peers.subscriber.local_description().await.ok_or("livekit: subscriber: no answer")?.sdp;
            let desc = proto::SessionDescription { r#type: "answer".to_owned(), sdp, id: offer.id, mid_to_track_id: HashMap::new() };
            signal(writer, signal_request::Message::Answer(desc)).await?;
        }
        M::Trickle(trickle) => match serde_json::from_str::<RTCIceCandidateInit>(&trickle.candidate_init) {
            Ok(init) => peers.add_candidate(trickle.target(), init).await,
            Err(e) => log::warn!("livekit: bad candidate from the server: {e}"),
        },
        M::Update(update) => {
            let before = room.speakers();
            for p in update.participants {
                room.update(p);
            }
            // someone who left while talking is talking no longer
            let Room { speaking, participants, own_sid, .. } = &mut *room;
            speaking.retain(|sid| sid == own_sid || participants.contains_key(sid));
            let now = room.speakers();
            if now != before {
                let _ = events.send(Event::Speaking(now));
            }
            sync_subscriptions(room, writer).await?;
        }
        M::SpeakersChanged(changed) => {
            let before = room.speakers();
            for s in changed.speakers {
                if s.active {
                    room.speaking.insert(s.sid);
                } else {
                    room.speaking.remove(&s.sid);
                }
            }
            let now = room.speakers();
            if now != before {
                let _ = events.send(Event::Speaking(now));
            }
        }
        M::Mute(mute) => log::info!("livekit: the server {} our track {}", if mute.muted { "muted" } else { "unmuted" }, mute.sid),
        M::SubscriptionResponse(r) => log::warn!("livekit: subscribing {}: {}", r.track_sid, r.err().as_str_name()),
        M::PongResp(pong) => {
            *last_pong = Instant::now();
            *rtt = now_ms() - pong.last_ping_timestamp;
        }
        M::Pong(_) => *last_pong = Instant::now(),
        M::Leave(leave) => return Err(format!("livekit: the server ended the session: {}", leave.reason().as_str_name())),
        _ => {}
    }
    Ok(())
}
