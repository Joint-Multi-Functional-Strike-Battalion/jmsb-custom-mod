//! Echo test for the JMSB voice server. Called from in game: the Arma server
//! signs the caller a token for his own room, `echo-<his UID>`. This bot
//! watches the server's rooms, joins each echo room someone is in, records
//! him until he stops talking (or for MAX_CLIP_S), plays it back, and leaves
//! when he does. One room per caller: nobody hears anyone else's echo, and
//! only a player the Arma server let in can call it.
//!
//! Environment (the egg's variables; Pelican sets SERVER_PORT):
//!   LIVEKIT_API_KEY, LIVEKIT_API_SECRET   the server's key pair
//!   ECHO_URL                              default ws://127.0.0.1:$SERVER_PORT

use std::borrow::Cow;
use std::collections::{HashMap, HashSet};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use futures_util::StreamExt;
use livekit::options::TrackPublishOptions;
use livekit::prelude::*;
use livekit::webrtc::audio_source::native::NativeAudioSource;
use livekit::webrtc::audio_source::{AudioSourceOptions, RtcAudioSource};
use livekit::webrtc::audio_stream::native::NativeAudioStream;
use livekit::webrtc::prelude::AudioFrame;
use livekit_api::access_token::{AccessToken, VideoGrants};
use livekit_api::services::room::RoomClient;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tokio::task::JoinHandle;

/// The echo rooms' names: this, then the caller's UID. The mod's
/// adapter_livekit names them the same (ECHO_ROOM_PREFIX).
const ROOM_PREFIX: &str = "echo-";
const IDENTITY: &str = "echo";
const NAME: &str = "ECHO";
const DEFAULT_PORT: &str = "7880";

/// How often the server's room list is read (ms).
const POLL_MS: u64 = 1000;

/// 48 kHz mono, 10 ms frames: what LiveKit's native audio works in.
const RATE: u32 = 48_000;
const FRAME: usize = 480;

/// A frame louder than this (RMS, 16-bit) is speech.
const SPEECH_RMS: f32 = 300.0;
/// This long without speech ends a clip (ms).
const END_QUIET_MS: u64 = 700;
/// The longest clip (s): a held key or an open mic still gets an answer.
const MAX_CLIP_S: usize = 15;
/// Pause before the playback starts, and after it ends before recording
/// again (ms).
const GAP_MS: u64 = 400;
/// How much audio LiveKit's source may queue (ms).
const SOURCE_QUEUE_MS: u32 = 100;
/// How long a join token is good for (s).
const TOKEN_TTL_S: u64 = 600;

#[tokio::main]
async fn main() {
    let env = |k: &str| std::env::var(k).unwrap_or_default();
    let (key, secret) = (env("LIVEKIT_API_KEY"), env("LIVEKIT_API_SECRET"));
    let url = match env("ECHO_URL") {
        u if !u.is_empty() => u,
        _ => {
            let port = env("SERVER_PORT");
            format!("ws://127.0.0.1:{}", if port.is_empty() { DEFAULT_PORT } else { &port })
        }
    };
    let rooms = RoomClient::with_api_key(&url.replacen("ws", "http", 1), &key, &secret);
    let inside: Arc<Mutex<HashSet<String>>> = Arc::default();
    println!("echo: answering rooms {ROOM_PREFIX}* at {url}");

    let mut poll = tokio::time::interval(Duration::from_millis(POLL_MS));
    let mut failing = false;
    loop {
        tokio::select! {
            _ = poll.tick() => {}
            _ = tokio::signal::ctrl_c() => return,
        }
        let list = match rooms.list_rooms(Vec::new()).await {
            Ok(list) => {
                failing = false;
                list
            }
            Err(e) => {
                // Said once, not every second, while the server is not up.
                if !failing {
                    println!("echo: room list: {e}");
                    failing = true;
                }
                continue;
            }
        };
        for room in list {
            if !room.name.starts_with(ROOM_PREFIX) || inside.lock().unwrap().contains(&room.name) {
                continue;
            }
            // Not the room's participant count: it lags by seconds, and still
            // holds us for a while after we leave. Answer only a room with a
            // caller in it now.
            let callers = rooms.list_participants(&room.name).await.unwrap_or_default();
            if !callers.iter().any(|p| p.identity != IDENTITY) {
                continue;
            }
            inside.lock().unwrap().insert(room.name.clone());
            let (url, key, secret, inside) = (url.clone(), key.clone(), secret.clone(), inside.clone());
            tokio::spawn(async move {
                if let Err(e) = answer(&url, &key, &secret, &room.name).await {
                    println!("echo: {}: {e}", room.name);
                }
                inside.lock().unwrap().remove(&room.name);
            });
        }
    }
}

fn token(key: &str, secret: &str, room: &str) -> Result<String, String> {
    let grants = VideoGrants {
        room_join: true,
        room: room.to_owned(),
        can_publish: Some(true),
        can_subscribe: Some(true),
        can_publish_data: Some(false),
        can_publish_sources: vec!["microphone".to_owned()],
        ..Default::default()
    };
    AccessToken::with_api_key(key, secret)
        .with_identity(IDENTITY)
        .with_name(NAME)
        .with_ttl(Duration::from_secs(TOKEN_TTL_S))
        .with_grants(grants)
        .to_jwt()
        .map_err(|e| format!("token: {e}"))
}

/// One caller's echo room: join, echo, and leave when nobody else is there.
async fn answer(url: &str, key: &str, secret: &str, room_name: &str) -> Result<(), String> {
    let jwt = token(key, secret, room_name)?;
    let (room, mut events) = Room::connect(url, &jwt, RoomOptions::default())
        .await
        .map_err(|e| format!("join: {e}"))?;

    let source = NativeAudioSource::new(
        AudioSourceOptions { echo_cancellation: false, noise_suppression: false, auto_gain_control: false },
        RATE,
        1,
        SOURCE_QUEUE_MS,
    );
    let track = LocalAudioTrack::create_audio_track("echo", RtcAudioSource::Native(source.clone()));
    room.local_participant()
        .publish_track(
            LocalTrack::Audio(track),
            TrackPublishOptions { source: TrackSource::Microphone, dtx: true, ..Default::default() },
        )
        .await
        .map_err(|e| format!("publish: {e}"))?;
    println!("echo: answered {room_name}");

    let playing = Arc::new(AtomicBool::new(false));
    let (clips_tx, clips_rx) = unbounded_channel::<(String, Vec<i16>)>();
    let player = tokio::spawn(play(source, clips_rx, playing.clone()));
    // One recorder per speaker, stopped when his track goes: LiveKit reuses
    // the receiver for the next speaker, so a recorder left running would
    // hear the newcomer under the old name.
    let mut recorders: HashMap<String, JoinHandle<()>> = HashMap::new();

    // He may have left while we joined.
    if room.remote_participants().is_empty() {
        player.abort();
        let _ = room.close().await;
        return Ok(());
    }
    while let Some(event) = events.recv().await {
        match event {
            RoomEvent::TrackSubscribed { track: RemoteTrack::Audio(track), participant, .. } => {
                let id = participant.identity().to_string();
                let recorder = tokio::spawn(record(track, id.clone(), clips_tx.clone(), playing.clone()));
                if let Some(old) = recorders.insert(id, recorder) {
                    old.abort();
                }
            }
            RoomEvent::TrackUnsubscribed { participant, .. } => {
                if let Some(old) = recorders.remove(participant.identity().as_str()) {
                    old.abort();
                }
            }
            RoomEvent::ParticipantDisconnected(participant) => {
                if let Some(old) = recorders.remove(participant.identity().as_str()) {
                    old.abort();
                }
                if room.remote_participants().is_empty() {
                    break;
                }
            }
            RoomEvent::Disconnected { reason } => {
                println!("echo: {room_name}: disconnected ({reason:?})");
                break;
            }
            _ => {}
        }
    }
    player.abort();
    recorders.into_values().for_each(|r| r.abort());
    let _ = room.close().await;
    println!("echo: left {room_name}");
    Ok(())
}

fn rms(samples: &[i16]) -> f32 {
    if samples.is_empty() {
        return 0.0;
    }
    let sum: f32 = samples.iter().map(|&s| f32::from(s) * f32::from(s)).sum();
    (sum / samples.len() as f32).sqrt()
}

/// One speaker's track: clips cut at the end of speech, sent to the player.
async fn record(track: RemoteAudioTrack, id: String, clips: UnboundedSender<(String, Vec<i16>)>, playing: Arc<AtomicBool>) {
    let mut stream = NativeAudioStream::new(track.rtc_track(), RATE as i32, 1);
    let mut clip: Vec<i16> = Vec::new();
    let mut quiet_ms = 0u64;
    let end_quiet = Duration::from_millis(END_QUIET_MS);
    loop {
        // No frames at all (the speaker let go of his key) counts as quiet.
        match tokio::time::timeout(end_quiet, stream.next()).await {
            Ok(None) => break,
            Ok(Some(frame)) => {
                if playing.load(Ordering::Relaxed) {
                    clip.clear();
                    continue;
                }
                let speech = rms(&frame.data) > SPEECH_RMS;
                if speech && clip.is_empty() {
                    println!("echo: recording {id}");
                }
                if speech || !clip.is_empty() {
                    clip.extend_from_slice(&frame.data);
                }
                quiet_ms = if speech { 0 } else { quiet_ms + u64::from(frame.samples_per_channel) * 1000 / u64::from(RATE) };
            }
            Err(_) => quiet_ms = END_QUIET_MS,
        }
        if !clip.is_empty() && (quiet_ms >= END_QUIET_MS || clip.len() >= MAX_CLIP_S * RATE as usize) {
            if clips.send((id.clone(), std::mem::take(&mut clip))).is_err() {
                break;
            }
            quiet_ms = 0;
        }
    }
}

/// Plays each clip into the room, one at a time, in real time.
async fn play(source: NativeAudioSource, mut clips: UnboundedReceiver<(String, Vec<i16>)>, playing: Arc<AtomicBool>) {
    let gap = Duration::from_millis(GAP_MS);
    while let Some((id, clip)) = clips.recv().await {
        playing.store(true, Ordering::Relaxed);
        println!("echo: playing {:.1} s back to {id}", clip.len() as f32 / RATE as f32);
        tokio::time::sleep(gap).await;
        for chunk in clip.chunks(FRAME) {
            let mut data = chunk.to_vec();
            data.resize(FRAME, 0);
            let frame = AudioFrame { data: Cow::Owned(data), sample_rate: RATE, num_channels: 1, samples_per_channel: FRAME as u32 };
            if let Err(e) = source.capture_frame(&frame).await {
                println!("echo: playback: {e}");
                break;
            }
        }
        // Let the source's queue drain before listening again.
        tokio::time::sleep(Duration::from_millis(u64::from(SOURCE_QUEUE_MS)) + gap).await;
        playing.store(false, Ordering::Relaxed);
    }
}
