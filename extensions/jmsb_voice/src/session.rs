//! One player in one voice room, on either voice server: his microphone sent
//! while he talks, everyone he is subscribed to played through the mixer,
//! and what happens reported as events.
//!
//! THE TWO VOICE SERVERS (2026-11-01, no libwebrtc): the address picks one.
//! - `ws://` / `wss://`: LiveKit, over pure Rust WebRTC (`livekit.rs`).
//! - `mumble://identity@host:port/room`: a Mumble server (`mumble.rs`).
//!
//! Both carry 20 ms Opus packets; the encoding, the noise suppression and the
//! decoding are this side's (`codec.rs`), the same for both.

use std::collections::HashSet;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};

use crate::audio::{Devices, Mixer, FRAME, RATE};
use crate::codec::{Mic, Speakers};
use crate::{livekit, mumble};

/// A test tone in place of the microphone (Hz, and its level 0..1).
const TONE_HZ: f32 = 440.0;
const TONE_LEVEL: f32 = 0.2;
/// The address that picks the Mumble server.
const MUMBLE_SCHEME: &str = "mumble://";

/// How a session is made.
#[derive(Debug, Clone, Default)]
pub struct Options {
    /// Send a steady tone instead of the microphone, which is not opened:
    /// the test exe's way to show audio flows without anyone talking.
    pub tone: bool,
    /// Part of the microphone's and the speakers' names to use (case does
    /// not matter); empty = the Windows default device. Arma's own output
    /// may not be the Windows default (user, 2026-10-31: the echo came out
    /// of the speakers, not the headset), so SQF names them.
    pub input: String,
    pub output: String,
}

/// What the session tells its owner.
#[derive(Debug, Clone)]
pub enum Event {
    Connected,
    Disconnected(String),
    Joined(String),
    Left(String),
    /// Everyone talking now, by identity.
    Speaking(Vec<String>),
    /// The microphone could not be opened; the session runs on, listening
    /// only. Sent once per opening of the devices.
    NoMic(String),
    Error(String),
}

/// What a voice server hands the session.
#[derive(Debug)]
pub enum Inbound {
    /// One Opus packet from one speaker, by identity.
    Audio { identity: String, opus: Vec<u8> },
    /// A speaker is gone: forget his decoder and his place in the mixer.
    Gone(String),
}

/// THE VOICE SERVER, either one. Each is a cheap handle (Clone) to its own
/// task, so the microphone's task holds one too.
#[derive(Clone)]
pub enum Transport {
    LiveKit(livekit::Conn),
    Mumble(mumble::Conn),
}

impl Transport {
    /// Connects to the server the address names. Its first events are
    /// `Connected`, then `Joined` for everyone already there.
    async fn connect(
        url: &str,
        token: &str,
        inbound: UnboundedSender<Inbound>,
        events: UnboundedSender<Event>,
    ) -> Result<Self, String> {
        if url.starts_with(MUMBLE_SCHEME) {
            mumble::Conn::connect(url, token, inbound, events).await.map(Self::Mumble)
        } else {
            livekit::Conn::connect(url, token, inbound, events).await.map(Self::LiveKit)
        }
    }

    /// One 20 ms Opus packet of the microphone; `last` ends a transmission.
    fn send(&self, opus: Vec<u8>, last: bool) {
        match self {
            Self::LiveKit(c) => c.send(opus, last),
            Self::Mumble(c) => c.send(opus, last),
        }
    }

    fn set_talking(&self, on: bool) {
        match self {
            Self::LiveKit(c) => c.set_talking(on),
            Self::Mumble(c) => c.set_talking(on),
        }
    }

    fn subscribe(&self, identity: &str, on: bool) {
        match self {
            Self::LiveKit(c) => c.subscribe(identity, on),
            Self::Mumble(c) => c.subscribe(identity, on),
        }
    }

    async fn close(&self) {
        match self {
            Self::LiveKit(c) => c.close().await,
            Self::Mumble(c) => c.close().await,
        }
    }
}

pub struct Session {
    transport: Transport,
    talking: Arc<AtomicBool>,
    mixer: Mixer,
    devices: Devices,
    /// Where the microphone's frames go; none under the test tone.
    mic_tx: Option<UnboundedSender<Vec<i16>>>,
    /// The speakers SQF wants received (`subscribe`), by identity: only they
    /// are decoded and played.
    wanted: Arc<Mutex<HashSet<String>>>,
    events: UnboundedSender<Event>,
}

impl Session {
    /// Opens the devices, then joins. The microphone starts closed.
    /// NOBODY IS RECEIVED until `subscribe` asks for him
    /// (docs/DESIGN_VOICE_LIVEKIT.md "Hear").
    pub async fn connect(url: &str, token: &str, events: UnboundedSender<Event>, opts: Options) -> Result<Self, String> {
        let mixer = Mixer::default();
        let (mic_tx, mic_rx) = unbounded_channel::<Vec<i16>>();
        let (devices, mic_tx) = if opts.tone {
            (Devices::open(mixer.clone(), None, &opts.input, &opts.output), None)
        } else {
            (Devices::open(mixer.clone(), Some(mic_tx.clone()), &opts.input, &opts.output), Some(mic_tx))
        };
        // No speakers fails the session; no microphone does not (Windows'
        // microphone privacy settings answer "Access is denied"): he listens.
        let (devices, mic_error) = devices.map_err(|e| format!("speakers: {e}"))?;
        let mic = Mic::new()?;

        let (in_tx, in_rx) = unbounded_channel::<Inbound>();
        let transport = Transport::connect(url, token, in_tx, events.clone()).await?;

        let talking = Arc::new(AtomicBool::new(false));
        let wanted: Arc<Mutex<HashSet<String>>> = Arc::default();
        if opts.tone {
            let (tone_tx, tone_rx) = unbounded_channel::<Vec<i16>>();
            tokio::spawn(tone(tone_tx));
            tokio::spawn(pump_mic(mic, tone_rx, talking.clone(), transport.clone()));
        } else {
            tokio::spawn(pump_mic(mic, mic_rx, talking.clone(), transport.clone()));
        }
        tokio::spawn(pump_inbound(in_rx, mixer.clone(), wanted.clone()));
        if let Some(e) = mic_error {
            let _ = events.send(Event::NoMic(e));
        }

        Ok(Self { transport, talking, mixer, devices, mic_tx, wanted, events })
    }

    /// What opening other devices needs (`Devices::open`), so it can run off
    /// the caller's thread: the mixer, the microphone's channel, the events.
    pub fn device_parts(&self) -> (Mixer, Option<UnboundedSender<Vec<i16>>>, UnboundedSender<Event>) {
        (self.mixer.clone(), self.mic_tx.clone(), self.events.clone())
    }

    /// Puts newly opened devices in place of the playing ones, which are
    /// handed back for the caller to drop (dropping waits for their thread).
    pub fn swap_devices(&mut self, devices: Devices) -> Devices {
        std::mem::replace(&mut self.devices, devices)
    }

    /// Receive one speaker or not. Off stops his audio (from the network
    /// where the server allows it: LiveKit), not his gain and ear in the
    /// mixer: turned on again he plays as set.
    pub fn subscribe(&self, identity: &str, on: bool) {
        {
            let mut wanted = self.wanted.lock().unwrap();
            if on {
                wanted.insert(identity.to_owned());
            } else {
                wanted.remove(identity);
            }
        }
        if !on {
            self.mixer.reset(identity);
        }
        self.transport.subscribe(identity, on);
    }

    /// Push-to-talk: open or close the microphone.
    pub fn set_talking(&self, on: bool) {
        self.talking.store(on, Ordering::Relaxed);
        self.transport.set_talking(on);
    }

    /// One speaker's loudness and ear, from Arma.
    pub fn set_speaker(&self, identity: &str, gain: f32, pan: f32) {
        self.mixer.set(identity, gain, pan);
    }

    /// Every radio speaker at once, 0..1.
    pub fn set_master(&self, gain: f32) {
        self.mixer.set_master(gain);
    }

    /// Samples received from each speaker so far: [id, all, audible].
    pub fn received(&self) -> Vec<(String, u64, u64)> {
        self.mixer.received()
    }

    pub async fn close(self) {
        self.set_talking(false);
        self.transport.close().await;
    }
}

/// The test tone, one `FRAME` every 10 ms, into the microphone's channel.
async fn tone(tx: UnboundedSender<Vec<i16>>) {
    let mut ticker = tokio::time::interval(std::time::Duration::from_millis(10));
    let mut phase = 0.0f32;
    let step = TONE_HZ * std::f32::consts::TAU / RATE as f32;
    loop {
        ticker.tick().await;
        let chunk = (0..FRAME)
            .map(|_| {
                phase = (phase + step) % std::f32::consts::TAU;
                (phase.sin() * TONE_LEVEL * f32::from(i16::MAX)) as i16
            })
            .collect();
        if tx.send(chunk).is_err() {
            break;
        }
    }
}

/// Microphone chunks, encoded, to the server while the key is held; dropped
/// otherwise. Letting go sends what is left as the transmission's last packet.
async fn pump_mic(mut mic: Mic, mut rx: UnboundedReceiver<Vec<i16>>, talking: Arc<AtomicBool>, transport: Transport) {
    let mut was_on = false;
    while let Some(chunk) = rx.recv().await {
        let on = talking.load(Ordering::Relaxed);
        if on {
            if let Some(packet) = mic.push(&chunk) {
                transport.send(packet, false);
            }
        } else if was_on {
            if let Some(packet) = mic.finish() {
                transport.send(packet, true);
            }
        }
        was_on = on;
    }
}

/// The server's audio: each wanted speaker's packets decoded into the mixer.
/// A speaker no longer wanted, or gone, loses his decoder; his gain and ear
/// stay until he leaves (SQF sends them only when they move).
async fn pump_inbound(mut rx: UnboundedReceiver<Inbound>, mixer: Mixer, wanted: Arc<Mutex<HashSet<String>>>) {
    let mut speakers = Speakers::default();
    while let Some(inbound) = rx.recv().await {
        match inbound {
            Inbound::Audio { identity, opus } => {
                if !wanted.lock().unwrap().contains(&identity) {
                    speakers.forget(&identity);
                    continue;
                }
                if let Some(samples) = speakers.decode(&identity, &opus) {
                    mixer.push(&identity, &samples);
                }
            }
            Inbound::Gone(identity) => {
                speakers.forget(&identity);
                mixer.remove(&identity);
            }
        }
    }
}
