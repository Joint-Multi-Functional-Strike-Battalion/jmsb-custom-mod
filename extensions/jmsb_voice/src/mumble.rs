//! One player on a Mumble server (2026-11-01), inside the DLL: no Mumble
//! app to install. The address is `mumble://identity@host:port/room`
//! (`?echo` for the echo test), the token the server's password.
//!
//! - THE CONNECTION is Mumble's TCP control channel over TLS. Voice goes
//!   through it too (Mumble's "UDP tunnel"): one connection, no UDP and no
//!   voice encryption of our own to get wrong. The server tunnels its voice
//!   back the same way to a client that never sent UDP.
//! - VERSION 1.4.0 is announced, so every server (1.4 and 1.5 alike) speaks
//!   the classic voice packet to us: one header byte, the session, the
//!   sequence, the Opus size and the data.
//! - THE ROOM is a channel of that name under the root: entered when it is
//!   there, else made (temporary: the server deletes it when empty). Mumble
//!   makes one only for a client with a certificate (we make our own, see
//!   `sign_in`) and, stock, only for registered users: the server must allow
//!   it to all (pelican-eggs mumble-voice does). A server that will not
//!   leaves us in the root, which still works - SQF decides who is heard, by
//!   identity - but every voice there goes to everyone.
//! - WHO IS THERE is everyone in our channel, by user name (the identity,
//!   the player's UID).
//! - THE ECHO TEST talks to target 31, the server's loopback: our voice comes
//!   back to us alone, as "echo" - no bot needed.
//! - WHO IS TALKING is worked out here, from whose packets arrive.
//! - THE CERTIFICATE: Mumble servers mostly run on a self-signed one, so any
//!   is accepted; its SHA-256 goes in the log. The password is the gate.

use std::collections::{HashMap, HashSet};
use std::sync::Arc;
use std::time::{Duration, Instant};

use prost::Message;
use tokio::io::{AsyncReadExt, AsyncWriteExt, ReadHalf, WriteHalf};
use tokio::net::TcpStream;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tokio::sync::oneshot;
use tokio_rustls::client::TlsStream;
use tokio_rustls::rustls;
use tokio_rustls::TlsConnector;

use crate::session::{Event, Inbound};

/// Mumble's own port when the address gives none.
const DEFAULT_PORT: u16 = 64738;
/// The version we say we are: 1.4.0, which gets the classic voice packet.
const VERSION_V1: u32 = (1 << 16) | (4 << 8);
const RELEASE: &str = concat!("jmsb_voice ", env!("CARGO_PKG_VERSION"));
/// How long the connect and the server's welcome may take (s).
const CONNECT_TIMEOUT_S: u64 = 15;
/// A ping this often keeps the server from dropping us (it waits 30 s).
const PING_S: u64 = 15;
/// Who is talking is re-worked this often (ms), and a speaker counts as
/// talking until this long after his last packet (ms).
const SPEAKING_TICK_MS: u64 = 100;
const SPEAKING_HOLD_MS: u64 = 300;
/// The largest control message we read (bytes): more is a broken stream.
const MAX_MESSAGE: usize = 8 * 1024 * 1024;
/// The root channel.
const ROOT: u32 = 0;
/// The identity the server's loopback plays under (adapter_livekit ECHO_BOT).
const ECHO_ID: &str = "echo";
/// The name in our own client certificate.
const CERT_NAME: &str = "jmsb-voice";

/// Control message types (Mumble.proto's order).
mod kind {
    pub const VERSION: u16 = 0;
    pub const UDP_TUNNEL: u16 = 1;
    pub const AUTHENTICATE: u16 = 2;
    pub const PING: u16 = 3;
    pub const REJECT: u16 = 4;
    pub const SERVER_SYNC: u16 = 5;
    pub const CHANNEL_REMOVE: u16 = 6;
    pub const CHANNEL_STATE: u16 = 7;
    pub const USER_REMOVE: u16 = 8;
    pub const USER_STATE: u16 = 9;
    pub const PERMISSION_DENIED: u16 = 12;
}

/// The voice packet: type Opus, and the targets used.
const AUDIO_OPUS: u8 = 4;
const AUDIO_TYPE_SHIFT: u8 = 5;
const TARGET_MASK: u8 = 0x1F;
const TARGET_NORMAL: u8 = 0;
const TARGET_LOOPBACK: u8 = 31;
/// The Opus size field: the size, and the bit that ends a transmission.
const OPUS_SIZE_MASK: u64 = 0x1FFF;
const OPUS_TERMINATOR: u64 = 0x2000;
/// One 20 ms packet is two of Mumble's 10 ms sequence steps.
const SEQUENCE_STEP: u64 = 2;

/// The control messages used, as Mumble.proto has them (proto2: every field
/// optional). Fields not listed are skipped when read.
mod proto {
    #[derive(Clone, PartialEq, prost::Message)]
    pub struct Version {
        #[prost(uint32, optional, tag = "1")]
        pub version_v1: Option<u32>,
        #[prost(string, optional, tag = "2")]
        pub release: Option<String>,
        #[prost(string, optional, tag = "3")]
        pub os: Option<String>,
        #[prost(string, optional, tag = "4")]
        pub os_version: Option<String>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct Authenticate {
        #[prost(string, optional, tag = "1")]
        pub username: Option<String>,
        #[prost(string, optional, tag = "2")]
        pub password: Option<String>,
        #[prost(bool, optional, tag = "5")]
        pub opus: Option<bool>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct Ping {
        #[prost(uint64, optional, tag = "1")]
        pub timestamp: Option<u64>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct Reject {
        #[prost(int32, optional, tag = "1")]
        pub kind: Option<i32>,
        #[prost(string, optional, tag = "2")]
        pub reason: Option<String>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct ServerSync {
        #[prost(uint32, optional, tag = "1")]
        pub session: Option<u32>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct ChannelRemove {
        #[prost(uint32, optional, tag = "1")]
        pub channel_id: Option<u32>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct ChannelState {
        #[prost(uint32, optional, tag = "1")]
        pub channel_id: Option<u32>,
        #[prost(uint32, optional, tag = "2")]
        pub parent: Option<u32>,
        #[prost(string, optional, tag = "3")]
        pub name: Option<String>,
        #[prost(bool, optional, tag = "8")]
        pub temporary: Option<bool>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct UserRemove {
        #[prost(uint32, optional, tag = "1")]
        pub session: Option<u32>,
        #[prost(string, optional, tag = "3")]
        pub reason: Option<String>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct UserState {
        #[prost(uint32, optional, tag = "1")]
        pub session: Option<u32>,
        #[prost(string, optional, tag = "3")]
        pub name: Option<String>,
        #[prost(uint32, optional, tag = "5")]
        pub channel_id: Option<u32>,
    }

    #[derive(Clone, PartialEq, prost::Message)]
    pub struct PermissionDenied {
        #[prost(string, optional, tag = "4")]
        pub reason: Option<String>,
        #[prost(int32, optional, tag = "5")]
        pub kind: Option<i32>,
    }
}

/// Mumble's own variable-length integer (not protobuf's), non-negative.
mod varint {
    pub fn put(out: &mut Vec<u8>, v: u64) {
        if v < 0x80 {
            out.push(v as u8);
        } else if v < 0x4000 {
            out.extend_from_slice(&[(v >> 8) as u8 | 0x80, v as u8]);
        } else if v < 0x20_0000 {
            out.extend_from_slice(&[(v >> 16) as u8 | 0xC0, (v >> 8) as u8, v as u8]);
        } else if v < 0x1000_0000 {
            out.extend_from_slice(&[(v >> 24) as u8 | 0xE0, (v >> 16) as u8, (v >> 8) as u8, v as u8]);
        } else if v <= u64::from(u32::MAX) {
            out.push(0xF0);
            out.extend_from_slice(&(v as u32).to_be_bytes());
        } else {
            out.push(0xF4);
            out.extend_from_slice(&v.to_be_bytes());
        }
    }

    /// Reads one from the front of `data`; `None` for a short or negative one.
    pub fn take(data: &mut &[u8]) -> Option<u64> {
        let (&first, rest) = data.split_first()?;
        let v = u64::from(first);
        let (value, used) = if v & 0x80 == 0 {
            (v & 0x7F, 0)
        } else if v & 0xC0 == 0x80 {
            ((v & 0x3F) << 8 | u64::from(*rest.first()?), 1)
        } else if v & 0xE0 == 0xC0 {
            ((v & 0x1F) << 16 | be(rest, 2)?, 2)
        } else if v & 0xF0 == 0xE0 {
            ((v & 0x0F) << 24 | be(rest, 3)?, 3)
        } else if v & 0xFC == 0xF0 {
            (be(rest, 4)?, 4)
        } else if v & 0xFC == 0xF4 {
            (be(rest, 8)?, 8)
        } else {
            return None;
        };
        *data = rest.get(used..)?;
        Some(value)
    }

    fn be(data: &[u8], n: usize) -> Option<u64> {
        Some(data.get(..n)?.iter().fold(0u64, |acc, &b| acc << 8 | u64::from(b)))
    }
}

/// Where to connect, from `mumble://identity@host:port/room[?echo]`.
#[derive(Debug, Clone)]
struct Address {
    host: String,
    port: u16,
    identity: String,
    room: String,
    echo: bool,
}

fn parse(url: &str) -> Result<Address, String> {
    let rest = url.strip_prefix("mumble://").ok_or("not a mumble:// address")?;
    let (rest, echo) = match rest.split_once('?') {
        Some((r, query)) => (r, query.split('&').any(|q| q == "echo")),
        None => (rest, false),
    };
    let (identity, rest) = rest.split_once('@').ok_or("the address has no identity (identity@host)")?;
    let (hostport, room) = rest.split_once('/').unwrap_or((rest, ""));
    let (host, port) = match hostport.rsplit_once(':') {
        Some((h, p)) if !h.ends_with(']') || h.starts_with('[') => {
            (h, p.parse::<u16>().map_err(|_| format!("bad port '{p}'"))?)
        }
        _ => (hostport, DEFAULT_PORT),
    };
    let host = host.trim_start_matches('[').trim_end_matches(']');
    if identity.is_empty() || host.is_empty() {
        return Err("the address needs identity@host".to_owned());
    }
    Ok(Address { host: host.to_owned(), port, identity: identity.to_owned(), room: room.to_owned(), echo })
}

/// Accepts the server's certificate whatever it is (see the top); the
/// handshake's signatures are still checked, so the TLS is real.
#[derive(Debug)]
struct AnyCertificate(Arc<rustls::crypto::CryptoProvider>);

impl rustls::client::danger::ServerCertVerifier for AnyCertificate {
    fn verify_server_cert(
        &self,
        end_entity: &rustls::pki_types::CertificateDer<'_>,
        _intermediates: &[rustls::pki_types::CertificateDer<'_>],
        _server_name: &rustls::pki_types::ServerName<'_>,
        _ocsp: &[u8],
        _now: rustls::pki_types::UnixTime,
    ) -> Result<rustls::client::danger::ServerCertVerified, rustls::Error> {
        let digest = ring::digest::digest(&ring::digest::SHA256, end_entity.as_ref());
        let hex: String = digest.as_ref().iter().map(|b| format!("{b:02x}")).collect();
        log::info!("mumble: server certificate sha256 {hex}");
        Ok(rustls::client::danger::ServerCertVerified::assertion())
    }

    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls12_signature(message, cert, dss, &self.0.signature_verification_algorithms)
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls13_signature(message, cert, dss, &self.0.signature_verification_algorithms)
    }

    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        self.0.signature_verification_algorithms.supported_schemes()
    }
}

type Reader = ReadHalf<TlsStream<TcpStream>>;
type Writer = WriteHalf<TlsStream<TcpStream>>;

/// One control message off the stream.
async fn read_message(reader: &mut Reader) -> Result<(u16, Vec<u8>), String> {
    let mut head = [0u8; 6];
    reader.read_exact(&mut head).await.map_err(|e| e.to_string())?;
    let kind = u16::from_be_bytes([head[0], head[1]]);
    let len = u32::from_be_bytes([head[2], head[3], head[4], head[5]]) as usize;
    if len > MAX_MESSAGE {
        return Err(format!("message of {len} bytes"));
    }
    let mut body = vec![0u8; len];
    reader.read_exact(&mut body).await.map_err(|e| e.to_string())?;
    Ok((kind, body))
}

async fn write_raw(writer: &mut Writer, kind: u16, body: &[u8]) -> Result<(), String> {
    let mut frame = Vec::with_capacity(6 + body.len());
    frame.extend_from_slice(&kind.to_be_bytes());
    frame.extend_from_slice(&(body.len() as u32).to_be_bytes());
    frame.extend_from_slice(body);
    writer.write_all(&frame).await.map_err(|e| e.to_string())
}

async fn write_message(writer: &mut Writer, kind: u16, msg: &impl Message) -> Result<(), String> {
    write_raw(writer, kind, &msg.encode_to_vec()).await
}

/// What the session asks of the connection's task.
enum Ask {
    Audio(Vec<u8>, bool),
    Close(oneshot::Sender<()>),
}

/// The handle to one Mumble connection.
#[derive(Clone)]
pub struct Conn {
    tx: UnboundedSender<Ask>,
}

impl Conn {
    /// Connects, signs in, and enters the room. Its first events are
    /// `Connected`, then `Joined` for everyone already in the room.
    pub async fn connect(
        url: &str,
        password: &str,
        inbound: UnboundedSender<Inbound>,
        events: UnboundedSender<Event>,
    ) -> Result<Self, String> {
        let address = parse(url)?;
        let timeout = Duration::from_secs(CONNECT_TIMEOUT_S);
        let (reader, writer, state) = tokio::time::timeout(timeout, sign_in(&address, password))
            .await
            .map_err(|_| format!("mumble: no answer from {}:{} in {CONNECT_TIMEOUT_S} s", address.host, address.port))??;
        let (tx, rx) = unbounded_channel::<Ask>();
        tokio::spawn(run(address, reader, writer, state, rx, inbound, events));
        Ok(Self { tx })
    }

    pub fn send(&self, opus: Vec<u8>, last: bool) {
        let _ = self.tx.send(Ask::Audio(opus, last));
    }

    /// Nothing to tell the server: Mumble carries voice only while it is sent.
    pub fn set_talking(&self, _on: bool) {}

    /// Nothing to tell the server: Mumble sends everyone in the channel, and
    /// the session plays only who is wanted.
    pub fn subscribe(&self, _identity: &str, _on: bool) {}

    pub async fn close(&self) {
        let (done_tx, done_rx) = oneshot::channel();
        if self.tx.send(Ask::Close(done_tx)).is_ok() {
            let _ = done_rx.await;
        }
    }
}

/// The server as we know it.
#[derive(Default)]
struct State {
    own: u32,
    /// channel id -> (parent, name)
    channels: HashMap<u32, (u32, String)>,
    /// session -> (name, channel)
    users: HashMap<u32, (String, u32)>,
}

impl State {
    fn own_channel(&self) -> u32 {
        self.users.get(&self.own).map(|u| u.1).unwrap_or(ROOT)
    }

    fn room_channel(&self, room: &str) -> Option<u32> {
        self.channels.iter().find(|(_, (parent, name))| *parent == ROOT && name == room).map(|(&id, _)| id)
    }

    /// Everyone else in our channel, by name.
    fn present(&self) -> HashSet<String> {
        let ours = self.own_channel();
        self.users
            .iter()
            .filter(|(&s, (_, ch))| s != self.own && *ch == ours)
            .map(|(_, (name, _))| name.clone())
            .collect()
    }

    fn user_state(&mut self, m: proto::UserState) {
        let Some(session) = m.session else { return };
        let entry = self.users.entry(session).or_insert_with(|| (String::new(), ROOT));
        if let Some(name) = m.name {
            entry.0 = name;
        }
        if let Some(channel) = m.channel_id {
            entry.1 = channel;
        }
    }

    fn channel_state(&mut self, m: proto::ChannelState) {
        let Some(id) = m.channel_id else { return };
        let entry = self.channels.entry(id).or_insert_with(|| (ROOT, String::new()));
        if let Some(parent) = m.parent {
            entry.0 = parent;
        }
        if let Some(name) = m.name {
            entry.1 = name;
        }
    }
}

/// TLS, version, password; then the server's whole state up to its
/// ServerSync, which names our session.
async fn sign_in(address: &Address, password: &str) -> Result<(Reader, Writer, State), String> {
    let provider = Arc::new(rustls::crypto::ring::default_provider());
    // OUR OWN CERTIFICATE, new at each connect: Mumble refuses a channel to
    // a client without one ("missing certificate"), even a temporary one.
    let own = rcgen::generate_simple_self_signed(vec![CERT_NAME.to_owned()]).map_err(|e| format!("mumble: certificate: {e}"))?;
    let own_key = rustls::pki_types::PrivateKeyDer::Pkcs8(own.signing_key.serialize_der().into());
    let config = rustls::ClientConfig::builder_with_provider(provider.clone())
        .with_safe_default_protocol_versions()
        .map_err(|e| e.to_string())?
        .dangerous()
        .with_custom_certificate_verifier(Arc::new(AnyCertificate(provider)))
        .with_client_auth_cert(vec![own.cert.der().clone()], own_key)
        .map_err(|e| format!("mumble: certificate: {e}"))?;
    let tcp = TcpStream::connect((address.host.as_str(), address.port))
        .await
        .map_err(|e| format!("mumble: {}:{}: {e}", address.host, address.port))?;
    let _ = tcp.set_nodelay(true);
    let name = rustls::pki_types::ServerName::try_from(address.host.clone()).map_err(|e| e.to_string())?;
    let tls = TlsConnector::from(Arc::new(config))
        .connect(name, tcp)
        .await
        .map_err(|e| format!("mumble: TLS: {e}"))?;
    let (mut reader, mut writer) = tokio::io::split(tls);

    let version = proto::Version {
        version_v1: Some(VERSION_V1),
        release: Some(RELEASE.to_owned()),
        os: Some(std::env::consts::OS.to_owned()),
        os_version: None,
    };
    write_message(&mut writer, kind::VERSION, &version).await?;
    let auth = proto::Authenticate {
        username: Some(address.identity.clone()),
        password: Some(password.to_owned()),
        opus: Some(true),
    };
    write_message(&mut writer, kind::AUTHENTICATE, &auth).await?;

    let mut state = State::default();
    loop {
        let (kind, body) = read_message(&mut reader).await?;
        match kind {
            kind::REJECT => {
                let m = proto::Reject::decode(body.as_slice()).unwrap_or_default();
                return Err(format!("mumble: refused: {}", m.reason.unwrap_or_else(|| "no reason given".to_owned())));
            }
            kind::CHANNEL_STATE => {
                if let Ok(m) = proto::ChannelState::decode(body.as_slice()) {
                    state.channel_state(m);
                }
            }
            kind::USER_STATE => {
                if let Ok(m) = proto::UserState::decode(body.as_slice()) {
                    state.user_state(m);
                }
            }
            kind::SERVER_SYNC => {
                let m = proto::ServerSync::decode(body.as_slice()).map_err(|e| e.to_string())?;
                state.own = m.session.ok_or("mumble: the server named no session")?;
                log::info!("mumble: signed in to {}:{} as {}", address.host, address.port, address.identity);
                return Ok((reader, writer, state));
            }
            _ => {}
        }
    }
}

/// Enter the room's channel, or make it (temporary) when it is not there.
async fn enter_room(writer: &mut Writer, state: &State, room: &str) -> Result<(), String> {
    if room.is_empty() {
        return Ok(());
    }
    match state.room_channel(room) {
        Some(id) if id == state.own_channel() => Ok(()),
        Some(id) => {
            let m = proto::UserState { session: Some(state.own), name: None, channel_id: Some(id) };
            write_message(writer, kind::USER_STATE, &m).await
        }
        None => {
            let m = proto::ChannelState {
                channel_id: None,
                parent: Some(ROOT),
                name: Some(room.to_owned()),
                temporary: Some(true),
            };
            write_message(writer, kind::CHANNEL_STATE, &m).await
        }
    }
}

/// One voice packet, as the client sends it.
fn voice_packet(target: u8, sequence: u64, opus: &[u8], last: bool) -> Vec<u8> {
    let mut out = Vec::with_capacity(opus.len() + 8);
    out.push(AUDIO_OPUS << AUDIO_TYPE_SHIFT | (target & TARGET_MASK));
    varint::put(&mut out, sequence);
    let mut size = opus.len() as u64 & OPUS_SIZE_MASK;
    if last {
        size |= OPUS_TERMINATOR;
    }
    varint::put(&mut out, size);
    out.extend_from_slice(opus);
    out
}

/// One voice packet from the server: (session, the Opus data, last).
fn read_voice(packet: &[u8]) -> Option<(u32, Vec<u8>, bool)> {
    let (&head, mut rest) = packet.split_first()?;
    if head >> AUDIO_TYPE_SHIFT != AUDIO_OPUS {
        return None;
    }
    let session = varint::take(&mut rest)?;
    let _sequence = varint::take(&mut rest)?;
    let size = varint::take(&mut rest)?;
    let len = (size & OPUS_SIZE_MASK) as usize;
    let data = rest.get(..len)?.to_vec();
    Some((u32::try_from(session).ok()?, data, size & OPUS_TERMINATOR != 0))
}

/// Sends `Joined` / `Left` for the change from `before` to who is there now.
fn report_change(before: &HashSet<String>, now: &HashSet<String>, events: &UnboundedSender<Event>, inbound: &UnboundedSender<Inbound>) {
    for gone in before.difference(now) {
        let _ = inbound.send(Inbound::Gone(gone.clone()));
        let _ = events.send(Event::Left(gone.clone()));
    }
    for came in now.difference(before) {
        let _ = events.send(Event::Joined(came.clone()));
    }
}

/// The connection's task: the server's messages, the session's asks, the
/// ping and who is talking - until the server drops us or we close.
async fn run(
    address: Address,
    mut reader: Reader,
    mut writer: Writer,
    mut state: State,
    mut asks: UnboundedReceiver<Ask>,
    inbound: UnboundedSender<Inbound>,
    events: UnboundedSender<Event>,
) {
    // Reading has its own task, so a half-read message is never dropped.
    let (msg_tx, mut msgs) = unbounded_channel::<Result<(u16, Vec<u8>), String>>();
    let read_task = tokio::spawn(async move {
        loop {
            let m = read_message(&mut reader).await;
            let failed = m.is_err();
            if msg_tx.send(m).is_err() || failed {
                break;
            }
        }
    });

    let _ = events.send(Event::Connected);
    let target = if address.echo { TARGET_LOOPBACK } else { TARGET_NORMAL };
    let mut present = if address.echo { HashSet::from([ECHO_ID.to_owned()]) } else { state.present() };
    for id in &present {
        let _ = events.send(Event::Joined(id.clone()));
    }
    if !address.echo {
        if let Err(e) = enter_room(&mut writer, &state, &address.room).await {
            log::warn!("mumble: entering {}: {e}", address.room);
        }
    }

    let mut sequence: u64 = 0;
    let mut ping = tokio::time::interval(Duration::from_secs(PING_S));
    let mut tick = tokio::time::interval(Duration::from_millis(SPEAKING_TICK_MS));
    let started = Instant::now();
    let mut talking: HashMap<String, Instant> = HashMap::new();
    let mut speaking: Vec<String> = Vec::new();
    let mut closed: Option<oneshot::Sender<()>> = None;

    let why = loop {
        tokio::select! {
            ask = asks.recv() => match ask {
                Some(Ask::Audio(opus, last)) => {
                    let packet = voice_packet(target, sequence, &opus, last);
                    sequence = if last { 0 } else { sequence + SEQUENCE_STEP };
                    if let Err(e) = write_raw(&mut writer, kind::UDP_TUNNEL, &packet).await {
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
                let (kind, body) = match msg {
                    Some(Ok(m)) => m,
                    Some(Err(e)) => break Some(e),
                    None => break Some("the connection closed".to_owned()),
                };
                match kind {
                    kind::UDP_TUNNEL => {
                        let Some((session, opus, last)) = read_voice(&body) else { continue };
                        let identity = if address.echo && session == state.own {
                            ECHO_ID.to_owned()
                        } else {
                            match state.users.get(&session) {
                                Some((name, _)) if present.contains(name) => name.clone(),
                                _ => continue,
                            }
                        };
                        if last {
                            talking.remove(&identity);
                        } else {
                            talking.insert(identity.clone(), Instant::now());
                        }
                        let _ = inbound.send(Inbound::Audio { identity, opus });
                    }
                    kind::USER_STATE => {
                        if let Ok(m) = proto::UserState::decode(body.as_slice()) {
                            state.user_state(m);
                        }
                    }
                    kind::USER_REMOVE => {
                        if let Ok(m) = proto::UserRemove::decode(body.as_slice()) {
                            if m.session == Some(state.own) {
                                break Some(m.reason.unwrap_or_else(|| "removed by the server".to_owned()));
                            }
                            if let Some(s) = m.session {
                                state.users.remove(&s);
                            }
                        }
                    }
                    kind::CHANNEL_STATE => {
                        if let Ok(m) = proto::ChannelState::decode(body.as_slice()) {
                            let named_room = m.name.as_deref() == Some(address.room.as_str());
                            state.channel_state(m);
                            // made by someone else first: go in
                            if named_room && !address.echo {
                                if let Err(e) = enter_room(&mut writer, &state, &address.room).await {
                                    break Some(e);
                                }
                            }
                        }
                    }
                    kind::CHANNEL_REMOVE => {
                        if let Ok(m) = proto::ChannelRemove::decode(body.as_slice()) {
                            if let Some(id) = m.channel_id {
                                state.channels.remove(&id);
                            }
                        }
                    }
                    kind::PERMISSION_DENIED => {
                        let m = proto::PermissionDenied::decode(body.as_slice()).unwrap_or_default();
                        log::warn!("mumble: permission denied ({:?}): {} - staying in the channel we are in", m.kind, m.reason.unwrap_or_default());
                    }
                    kind::REJECT => {
                        let m = proto::Reject::decode(body.as_slice()).unwrap_or_default();
                        break Some(m.reason.unwrap_or_else(|| "refused".to_owned()));
                    }
                    _ => {}
                }
                if !address.echo {
                    let now = state.present();
                    if now != present {
                        report_change(&present, &now, &events, &inbound);
                        present = now;
                    }
                }
            },
            _ = ping.tick() => {
                let m = proto::Ping { timestamp: Some(started.elapsed().as_millis() as u64) };
                if let Err(e) = write_message(&mut writer, kind::PING, &m).await {
                    break Some(e);
                }
            },
            _ = tick.tick() => {
                let hold = Duration::from_millis(SPEAKING_HOLD_MS);
                talking.retain(|_, at| at.elapsed() < hold);
                let mut now: Vec<String> = talking.keys().cloned().collect();
                now.sort();
                if now != speaking {
                    speaking = now;
                    let _ = events.send(Event::Speaking(speaking.clone()));
                }
            },
        }
    };

    read_task.abort();
    let _ = writer.shutdown().await;
    match why {
        Some(why) => {
            log::info!("mumble: dropped: {why}");
            let _ = events.send(Event::Disconnected(why));
        }
        None => log::info!("mumble: closed"),
    }
    if let Some(done) = closed {
        let _ = done.send(());
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn varint_round_trip() {
        for v in [0u64, 1, 0x7F, 0x80, 0x3FFF, 0x4000, 0x1F_FFFF, 0x20_0000, 0xFFF_FFFF, 0x1000_0000, 0xFFFF_FFFF, 0x1_0000_0000] {
            let mut buf = Vec::new();
            varint::put(&mut buf, v);
            let mut slice = buf.as_slice();
            assert_eq!(varint::take(&mut slice), Some(v), "value {v:#x}");
            assert!(slice.is_empty());
        }
    }

    #[test]
    fn voice_packet_reads_back() {
        // the server's form has the session after the header
        let opus = vec![1u8, 2, 3, 4];
        let mut packet = vec![AUDIO_OPUS << AUDIO_TYPE_SHIFT];
        varint::put(&mut packet, 42);
        varint::put(&mut packet, 6);
        varint::put(&mut packet, opus.len() as u64 | OPUS_TERMINATOR);
        packet.extend_from_slice(&opus);
        assert_eq!(read_voice(&packet), Some((42, opus.clone(), true)));
        let sent = voice_packet(TARGET_LOOPBACK, 4, &opus, false);
        assert_eq!(sent[0] & TARGET_MASK, TARGET_LOOPBACK);
    }

    #[test]
    fn addresses() {
        let a = parse("mumble://7656@voice.example:1234/mission-5").unwrap();
        assert_eq!((a.host.as_str(), a.port, a.identity.as_str(), a.room.as_str(), a.echo), ("voice.example", 1234, "7656", "mission-5", false));
        let b = parse("mumble://7656@10.0.0.2?echo").unwrap();
        assert_eq!((b.port, b.room.as_str(), b.echo), (DEFAULT_PORT, "", true));
        assert!(parse("mumble://host:1").is_err());
    }
}
