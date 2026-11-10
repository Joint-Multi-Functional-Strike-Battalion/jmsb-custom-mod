//! One player in one LiveKit room: his microphone published, everyone he is
//! subscribed to played through the mixer, push-to-talk, and what happens
//! reported as events.

use std::borrow::Cow;
use std::collections::{HashMap, HashSet};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use futures_util::StreamExt;
use livekit::options::TrackPublishOptions;
use livekit::prelude::*;
use livekit::webrtc::audio_source::native::NativeAudioSource;
use livekit::webrtc::audio_source::{AudioSourceOptions, RtcAudioSource};
use livekit::webrtc::audio_stream::native::NativeAudioStream;
use livekit::webrtc::prelude::AudioFrame;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tokio::task::JoinHandle;

use crate::audio::{Devices, Mixer, FRAME, RATE};

/// How much audio LiveKit's source may queue (ms).
const SOURCE_QUEUE_MS: u32 = 100;

/// A test tone in place of the microphone (Hz, and its level 0..1).
const TONE_HZ: f32 = 440.0;
const TONE_LEVEL: f32 = 0.2;

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
    /// Everyone talking now, by identity, as the server sees it.
    Speaking(Vec<String>),
    /// The microphone could not be opened; the session runs on, listening
    /// only. Sent once per opening of the devices.
    NoMic(String),
    Error(String),
}

pub struct Session {
    room: Arc<Room>,
    track: LocalAudioTrack,
    talking: Arc<AtomicBool>,
    mixer: Mixer,
    devices: Devices,
    /// Where the microphone's frames go; none under the test tone.
    mic_tx: Option<UnboundedSender<Vec<i16>>>,
    /// The speakers SQF wants received (`subscribe`), by identity: kept so a
    /// track published later is subscribed when it appears.
    wanted: Arc<Mutex<HashSet<String>>>,
    events: UnboundedSender<Event>,
}

impl Session {
    /// Joins the room and starts the devices. The microphone starts closed.
    /// AUTO-SUBSCRIBE IS OFF (docs/DESIGN_VOICE_LIVEKIT.md "Hear"): nobody's
    /// audio is downloaded until `subscribe` asks for him.
    pub async fn connect(url: &str, token: &str, events: UnboundedSender<Event>, opts: Options) -> Result<Self, String> {
        let mut options = RoomOptions::default();
        options.auto_subscribe = false;
        let (room, room_events) = Room::connect(url, token, options).await.map_err(|e| e.to_string())?;
        let room = Arc::new(room);

        // The microphone: our own frames pushed into a native source. The
        // WebRTC noise suppression and gain run on them; echo cancellation
        // has no far end to work from (we play the audio ourselves), so it
        // stays off - most players wear headsets.
        let source = NativeAudioSource::new(
            AudioSourceOptions { echo_cancellation: false, noise_suppression: true, auto_gain_control: true },
            RATE,
            1,
            SOURCE_QUEUE_MS,
        );
        let track = LocalAudioTrack::create_audio_track("mic", RtcAudioSource::Native(source.clone()));
        track.mute();
        room.local_participant()
            .publish_track(
                LocalTrack::Audio(track.clone()),
                TrackPublishOptions { source: TrackSource::Microphone, dtx: true, ..Default::default() },
            )
            .await
            .map_err(|e| e.to_string())?;

        let mixer = Mixer::default();
        let (mic_tx, mic_rx) = unbounded_channel::<Vec<i16>>();
        let (devices, mic_tx) = if opts.tone {
            tokio::spawn(tone(mic_tx));
            (Devices::open(mixer.clone(), None, &opts.input, &opts.output), None)
        } else {
            (Devices::open(mixer.clone(), Some(mic_tx.clone()), &opts.input, &opts.output), Some(mic_tx))
        };
        // No speakers fails the session; no microphone does not (Windows'
        // microphone privacy settings answer "Access is denied"): he listens.
        let (devices, mic_error) = devices.map_err(|e| format!("speakers: {e}"))?;
        let talking = Arc::new(AtomicBool::new(false));
        let wanted: Arc<Mutex<HashSet<String>>> = Arc::default();

        tokio::spawn(pump_mic(source, mic_rx, talking.clone()));
        tokio::spawn(pump_room(room_events, mixer.clone(), events.clone(), wanted.clone()));
        let _ = events.send(Event::Connected);
        // Who was there first: the room reports only those who join later.
        for id in room.remote_participants().keys() {
            let _ = events.send(Event::Joined(id.to_string()));
        }
        if let Some(e) = mic_error {
            let _ = events.send(Event::NoMic(e));
        }

        Ok(Self { room, track, talking, mixer, devices, mic_tx, wanted, events })
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

    /// Receive one speaker or not. Off drops his audio from the network, not
    /// his gain and ear in the mixer: turned on again he plays as set.
    pub fn subscribe(&self, identity: &str, on: bool) {
        {
            let mut wanted = self.wanted.lock().unwrap();
            if on {
                wanted.insert(identity.to_owned());
            } else {
                wanted.remove(identity);
            }
        }
        for p in self.room.remote_participants().values() {
            if p.identity().as_str() != identity {
                continue;
            }
            for publication in p.track_publications().values() {
                if publication.kind() == TrackKind::Audio && publication.is_desired() != on {
                    publication.set_subscribed(on);
                }
            }
        }
    }

    /// Push-to-talk: open or close the microphone.
    pub fn set_talking(&self, on: bool) {
        self.talking.store(on, Ordering::Relaxed);
        if on {
            self.track.unmute();
        } else {
            self.track.mute();
        }
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
        let _ = self.room.close().await;
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

/// Microphone chunks to LiveKit while the key is held; dropped otherwise.
async fn pump_mic(source: NativeAudioSource, mut rx: UnboundedReceiver<Vec<i16>>, talking: Arc<AtomicBool>) {
    while let Some(chunk) = rx.recv().await {
        if !talking.load(Ordering::Relaxed) {
            continue;
        }
        let frame = AudioFrame {
            data: Cow::Owned(chunk),
            sample_rate: RATE,
            num_channels: 1,
            samples_per_channel: FRAME as u32,
        };
        if let Err(e) = source.capture_frame(&frame).await {
            log::warn!("capture: {e}");
        }
    }
}

/// The room's events: a new audio track gets a reader into the mixer, and
/// loses it when the track goes. LiveKit reuses the receiver for the next
/// speaker, so a reader left running would play the newcomer under the old
/// name (and twice). A reader's restart (a new track, a re-subscription)
/// empties the speaker's buffer but KEEPS HIS GAIN AND EAR: SQF sends them
/// only when they move, so dropping them here would play him at the
/// default until the next change. Only his leaving forgets them.
async fn pump_room(
    mut rx: UnboundedReceiver<RoomEvent>,
    mixer: Mixer,
    events: UnboundedSender<Event>,
    wanted: Arc<Mutex<HashSet<String>>>,
) {
    let mut readers: HashMap<String, JoinHandle<()>> = HashMap::new();
    let stop = |id: &str, readers: &mut HashMap<String, JoinHandle<()>>| {
        if let Some(reader) = readers.remove(id) {
            reader.abort();
        }
        mixer.reset(id);
    };
    while let Some(event) = rx.recv().await {
        match event {
            RoomEvent::ParticipantConnected(p) => {
                let _ = events.send(Event::Joined(p.identity().to_string()));
            }
            RoomEvent::ParticipantDisconnected(p) => {
                let id = p.identity().to_string();
                stop(&id, &mut readers);
                mixer.remove(&id);
                let _ = events.send(Event::Left(id));
            }
            // Auto-subscribe is off: a speaker SQF asked for before his
            // microphone was published is subscribed when it is.
            RoomEvent::TrackPublished { publication, participant } => {
                let id = participant.identity().to_string();
                if publication.kind() == TrackKind::Audio && wanted.lock().unwrap().contains(&id) {
                    publication.set_subscribed(true);
                }
            }
            RoomEvent::TrackSubscribed { track: RemoteTrack::Audio(track), participant, .. } => {
                let id = participant.identity().to_string();
                stop(&id, &mut readers);
                let into = mixer.clone();
                let key = id.clone();
                let reader = tokio::spawn(async move {
                    let mut stream = NativeAudioStream::new(track.rtc_track(), RATE as i32, 1);
                    while let Some(frame) = stream.next().await {
                        into.push(&key, &frame.data);
                    }
                });
                readers.insert(id, reader);
            }
            RoomEvent::TrackUnsubscribed { participant, .. } => {
                stop(participant.identity().as_str(), &mut readers);
            }
            RoomEvent::ActiveSpeakersChanged { speakers } => {
                let ids = speakers.iter().map(|p| p.identity().to_string()).collect();
                let _ = events.send(Event::Speaking(ids));
            }
            RoomEvent::Disconnected { reason } => {
                let _ = events.send(Event::Disconnected(format!("{reason:?}")));
                break;
            }
            _ => {}
        }
    }
    readers.into_values().for_each(|r| r.abort());
}
