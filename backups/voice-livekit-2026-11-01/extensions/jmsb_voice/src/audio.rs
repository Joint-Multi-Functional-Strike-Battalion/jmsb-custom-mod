//! Microphone capture and speaker playback (cpal, WASAPI on Windows).
//!
//! Capture turns the default input device into 10 ms mono frames at
//! `RATE`, the rate LiveKit's native source is fed at. Playback mixes every
//! speaker on its own: each has a buffer, a gain and a pan, set from Arma
//! (docs/DESIGN_VOICE_LIVEKIT.md "How it works"), so RF quality and the ear
//! act on one man's voice, not on the mix.

use std::collections::{HashMap, VecDeque};
use std::f32::consts::FRAC_PI_4;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{mpsc, Arc, Mutex};
use std::thread;

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::{SampleFormat, StreamConfig};

/// The rate everything inside the extension runs at (Hz): LiveKit's Opus rate.
pub const RATE: u32 = 48_000;
/// One frame pushed to LiveKit: 10 ms.
pub const FRAME: usize = (RATE / 100) as usize;
/// A speaker's buffer is held this deep before he is played (ms), so network
/// jitter does not break his first words.
const PRIME_MS: usize = 40;
/// ... and never grows past this (ms): older audio is dropped, so a stall does
/// not turn into a delay that never goes away.
const MAX_MS: usize = 500;
/// A sample louder than this (16-bit) counts as heard in the test exe's
/// stats: LiveKit streams silence while nobody talks, so `got` alone does
/// not show speech.
const AUDIBLE: i16 = 300;

/// One speaker as the mixer hears him.
struct Speaker {
    buf: VecDeque<f32>,
    /// 0 silent .. 1 as sent.
    gain: f32,
    /// -1 left ear only, 0 both, 1 right ear only.
    pan: f32,
    primed: bool,
    /// Where between two buffered samples the output is, for a device that
    /// does not run at `RATE`.
    pos: f64,
    /// Samples received in all, for the test exe's stats.
    got: u64,
    /// ... and of those, the ones above `AUDIBLE`.
    heard: u64,
}

impl Speaker {
    /// A new speaker is SILENT until SQF gives him a gain: who hears whom is
    /// SQF's to say, and a speaker nobody has decided on is not heard.
    fn new() -> Self {
        Self { buf: VecDeque::new(), gain: 0.0, pan: 0.0, primed: false, pos: 0.0, got: 0, heard: 0 }
    }
}

/// Every speaker heard, by LiveKit identity (the player's UID).
#[derive(Clone)]
pub struct Mixer {
    speakers: Arc<Mutex<HashMap<String, Speaker>>>,
    /// Every radio speaker at once, 0..1, as f32 bits: the player's own
    /// radio voice volume.
    master: Arc<AtomicU32>,
}

impl Default for Mixer {
    fn default() -> Self {
        Self { speakers: Arc::default(), master: Arc::new(AtomicU32::new(1.0f32.to_bits())) }
    }
}

impl Mixer {
    /// Audio for one speaker, mono at `RATE`, as it comes off the network.
    pub fn push(&self, id: &str, samples: &[i16]) {
        let mut map = self.speakers.lock().unwrap();
        let s = map.entry(id.to_owned()).or_insert_with(Speaker::new);
        s.buf.extend(samples.iter().map(|&v| f32::from(v) / f32::from(i16::MAX)));
        s.got += samples.len() as u64;
        s.heard += samples.iter().filter(|v| v.unsigned_abs() > AUDIBLE as u16).count() as u64;
        let max = RATE as usize * MAX_MS / 1000;
        while s.buf.len() > max {
            s.buf.pop_front();
        }
    }

    /// How loud one speaker is and which ear he is in. A speaker not heard
    /// yet is made, so the setting is there when his voice arrives.
    pub fn set(&self, id: &str, gain: f32, pan: f32) {
        let mut map = self.speakers.lock().unwrap();
        let s = map.entry(id.to_owned()).or_insert_with(Speaker::new);
        s.gain = gain.clamp(0.0, 1.0);
        s.pan = pan.clamp(-1.0, 1.0);
    }

    pub fn set_master(&self, gain: f32) {
        self.master.store(gain.clamp(0.0, 1.0).to_bits(), Ordering::Relaxed);
    }

    /// Samples received from each speaker so far: [id, all, audible].
    pub fn received(&self) -> Vec<(String, u64, u64)> {
        self.speakers.lock().unwrap().iter().map(|(id, s)| (id.clone(), s.got, s.heard)).collect()
    }

    /// Forgets a speaker, his gain and ear too: he left the room.
    pub fn remove(&self, id: &str) {
        self.speakers.lock().unwrap().remove(id);
    }

    /// Empties a speaker's buffer and keeps his gain and ear: his reader
    /// restarts (a new track, or a re-subscription), and the setting SQF sent
    /// still holds - SQF sends it again only when it moves.
    pub fn reset(&self, id: &str) {
        if let Some(s) = self.speakers.lock().unwrap().get_mut(id) {
            s.buf.clear();
            s.primed = false;
            s.pos = 0.0;
        }
    }

    /// Fills an interleaved output buffer of `channels` at `rate`.
    fn mix(&self, out: &mut [f32], channels: usize, rate: u32) {
        out.fill(0.0);
        let step = f64::from(RATE) / f64::from(rate);
        let prime = RATE as usize * PRIME_MS / 1000;
        let master = f32::from_bits(self.master.load(Ordering::Relaxed));
        let mut map = self.speakers.lock().unwrap();
        for s in map.values_mut() {
            if !s.primed {
                if s.buf.len() < prime {
                    continue;
                }
                s.primed = true;
            }
            // Equal-power pan: both ears at 0.707 when centred.
            let angle = (s.pan + 1.0) * FRAC_PI_4;
            let gain = s.gain * master;
            let (left, right) = (gain * angle.cos(), gain * angle.sin());
            for frame in out.chunks_mut(channels) {
                if s.buf.len() < 2 {
                    s.primed = false;
                    break;
                }
                let frac = s.pos as f32;
                let v = s.buf[0] * (1.0 - frac) + s.buf[1] * frac;
                s.pos += step;
                while s.pos >= 1.0 {
                    s.pos -= 1.0;
                    s.buf.pop_front();
                }
                if channels == 1 {
                    frame[0] += v * gain;
                } else {
                    frame[0] += v * left;
                    frame[1] += v * right;
                }
            }
        }
        for v in out.iter_mut() {
            *v = v.clamp(-1.0, 1.0);
        }
    }
}

/// Turns any device rate and channel count into mono `FRAME` chunks at `RATE`.
struct Chunker {
    step: f64,
    pos: f64,
    last: f32,
    chunk: Vec<i16>,
    tx: tokio::sync::mpsc::UnboundedSender<Vec<i16>>,
}

impl Chunker {
    fn feed(&mut self, mono: f32) {
        // Linear resampling from the device rate to RATE.
        while self.pos < 1.0 {
            let v = self.last + (mono - self.last) * self.pos as f32;
            self.chunk.push((v.clamp(-1.0, 1.0) * f32::from(i16::MAX)) as i16);
            if self.chunk.len() == FRAME {
                let _ = self.tx.send(std::mem::replace(&mut self.chunk, Vec::with_capacity(FRAME)));
            }
            self.pos += self.step;
        }
        self.pos -= 1.0;
        self.last = mono;
    }
}

/// The two device streams. cpal's streams stay on the thread that made them,
/// so they live on one of their own until `stop`.
pub struct Devices {
    stop: Option<mpsc::Sender<()>>,
    thread: Option<thread::JoinHandle<()>>,
}

/// Every microphone and every speaker set Windows lists, by name.
pub fn list() -> (Vec<String>, Vec<String>) {
    let host = cpal::default_host();
    let names = |devices: Option<Vec<cpal::Device>>| -> Vec<String> {
        devices.unwrap_or_default().iter().filter_map(|d| name_of(d)).collect()
    };
    (
        names(host.input_devices().ok().map(|d| d.collect())),
        names(host.output_devices().ok().map(|d| d.collect())),
    )
}

/// A device's name as Windows shows it (cpal 0.18: in its description).
fn name_of(device: &cpal::Device) -> Option<String> {
    device.description().ok().map(|d| d.name().to_string())
}

/// Windows' default COMMUNICATIONS device of a kind, by name: what Windows
/// gives chat and calls - the headset, where the default device is the
/// monitor's speakers (user, 2026-10-31: the echo came out of the monitor).
/// cpal asks only for the default (console) device, so this asks WASAPI
/// itself, the way cpal reads a name.
#[cfg(windows)]
fn communications_default(capture: bool) -> Option<String> {
    use windows::Win32::Devices::Properties::DEVPKEY_Device_FriendlyName;
    use windows::Win32::Foundation::PROPERTYKEY;
    use windows::Win32::Media::Audio::{eCapture, eCommunications, eRender, IMMDeviceEnumerator, MMDeviceEnumerator};
    use windows::Win32::System::Com::StructuredStorage::PropVariantClear;
    use windows::Win32::System::Com::{CoCreateInstance, CoInitializeEx, CLSCTX_ALL, COINIT_MULTITHREADED, STGM_READ};
    use windows::Win32::System::Variant::VT_LPWSTR;

    unsafe {
        // Already initialised on this thread in another mode is fine: COM is up either way.
        let _ = CoInitializeEx(None, COINIT_MULTITHREADED);
        let enumerator: IMMDeviceEnumerator = CoCreateInstance(&MMDeviceEnumerator, None, CLSCTX_ALL).ok()?;
        let flow = if capture { eCapture } else { eRender };
        let device = enumerator.GetDefaultAudioEndpoint(flow, eCommunications).ok()?;
        let store = device.OpenPropertyStore(STGM_READ).ok()?;
        let key = &DEVPKEY_Device_FriendlyName as *const _ as *const PROPERTYKEY;
        let mut value = store.GetValue(key).ok()?;
        let variant = &value.Anonymous.Anonymous;
        if variant.vt != VT_LPWSTR {
            return None;
        }
        let ptr = *(&variant.Anonymous as *const _ as *const *const u16);
        let mut len = 0;
        while len < 4096 && *ptr.add(len) != 0 {
            len += 1;
        }
        let name = String::from_utf16_lossy(std::slice::from_raw_parts(ptr, len));
        let _ = PropVariantClear(&mut value);
        Some(name)
    }
}

#[cfg(not(windows))]
fn communications_default(_capture: bool) -> Option<String> {
    None
}

/// The device whose name holds `wanted` (case does not matter), else the
/// default. An empty `wanted` is Windows' communications device of that
/// kind when it is one of the devices listed, else the default device.
fn pick(wanted: &str, devices: Option<Vec<cpal::Device>>, default: Option<cpal::Device>, capture: bool) -> Option<cpal::Device> {
    let wanted = wanted.trim().to_lowercase();
    let mut devices = devices.unwrap_or_default();
    if wanted.is_empty() {
        if let Some(comm) = communications_default(capture) {
            if let Some(at) = devices.iter().position(|d| name_of(d).as_deref() == Some(comm.as_str())) {
                log::info!("{}: Windows' communications device '{comm}'", if capture { "microphone" } else { "speakers" });
                return Some(devices.swap_remove(at));
            }
            log::info!("communications device '{comm}' not among the devices listed - the default device instead");
        }
        return default;
    }
    let found = devices
        .into_iter()
        .find(|d| name_of(d).map(|n| n.to_lowercase().contains(&wanted)).unwrap_or(false));
    match found {
        Some(d) => Some(d),
        None => {
            log::warn!("no audio device named '{wanted}' - using the default");
            default
        }
    }
}

/// The microphone named by `input` (or the default), capturing into `tx`.
fn open_mic(host: &cpal::Host, input: &str, tx: tokio::sync::mpsc::UnboundedSender<Vec<i16>>) -> Result<cpal::Stream, String> {
    let input = pick(input, host.input_devices().ok().map(|d| d.collect()), host.default_input_device(), true)
        .ok_or("no microphone")?;
    log::info!("microphone: {}", name_of(&input).unwrap_or_default());
    let stream = open_input(&input, tx)?;
    stream.play().map_err(|e| e.to_string())?;
    Ok(stream)
}

impl Devices {
    /// Opens the speakers, playing `mixer`, and the microphone when `mic` is
    /// given: its chunks go there. Each is the device named by `input` /
    /// `output` (part of the name), or the Windows default when the name is
    /// empty or matches nothing.
    ///
    /// The speakers failing fails it all. THE MICROPHONE FAILING DOES NOT
    /// (no microphone, or Windows' microphone privacy answering "Access is
    /// denied"): the speakers play on, so he still hears, and the error comes
    /// back as the second value for the caller to report.
    pub fn open(
        mixer: Mixer,
        mic: Option<tokio::sync::mpsc::UnboundedSender<Vec<i16>>>,
        input: &str,
        output: &str,
    ) -> Result<(Self, Option<String>), String> {
        let (stop_tx, stop_rx) = mpsc::channel::<()>();
        let (ready_tx, ready_rx) = mpsc::channel::<Result<Option<String>, String>>();
        let (input, output) = (input.to_string(), output.to_string());
        let thread = thread::spawn(move || {
            let streams = (|| -> Result<_, String> {
                let host = cpal::default_host();
                let output = pick(&output, host.output_devices().ok().map(|d| d.collect()), host.default_output_device(), false)
                    .ok_or("no speakers")?;
                log::info!("speakers: {}", name_of(&output).unwrap_or_default());
                let out_stream = open_output(&output, mixer)?;
                out_stream.play().map_err(|e| e.to_string())?;
                let (in_stream, mic_error) = match mic {
                    Some(mic) => match open_mic(&host, &input, mic) {
                        Ok(stream) => (Some(stream), None),
                        Err(e) => {
                            log::warn!("microphone: {e} - listening only");
                            (None, Some(e))
                        }
                    },
                    None => (None, None),
                };
                Ok(((in_stream, out_stream), mic_error))
            })();
            match streams {
                Ok((streams, mic_error)) => {
                    let _ = ready_tx.send(Ok(mic_error));
                    let _ = stop_rx.recv();
                    drop(streams);
                }
                Err(e) => {
                    let _ = ready_tx.send(Err(e));
                }
            }
        });
        let mic_error = ready_rx.recv().map_err(|e| e.to_string())??;
        Ok((Self { stop: Some(stop_tx), thread: Some(thread) }, mic_error))
    }
}

impl Drop for Devices {
    fn drop(&mut self) {
        if let Some(stop) = self.stop.take() {
            let _ = stop.send(());
        }
        if let Some(thread) = self.thread.take() {
            let _ = thread.join();
        }
    }
}

fn open_input(device: &cpal::Device, tx: tokio::sync::mpsc::UnboundedSender<Vec<i16>>) -> Result<cpal::Stream, String> {
    let supported = device.default_input_config().map_err(|e| e.to_string())?;
    let format = supported.sample_format();
    let config: StreamConfig = supported.into();
    let channels = usize::from(config.channels);
    let mut chunker = Chunker {
        step: f64::from(config.sample_rate) / f64::from(RATE),
        pos: 0.0,
        last: 0.0,
        chunk: Vec::with_capacity(FRAME),
        tx,
    };
    let err = |e| log::warn!("microphone: {e}");
    let stream = match format {
        SampleFormat::F32 => device.build_input_stream(
            config,
            move |data: &[f32], _: &_| {
                for frame in data.chunks(channels) {
                    chunker.feed(frame.iter().sum::<f32>() / frame.len() as f32);
                }
            },
            err,
            None,
        ),
        SampleFormat::I16 => device.build_input_stream(
            config,
            move |data: &[i16], _: &_| {
                for frame in data.chunks(channels) {
                    let sum: f32 = frame.iter().map(|&v| f32::from(v) / f32::from(i16::MAX)).sum();
                    chunker.feed(sum / frame.len() as f32);
                }
            },
            err,
            None,
        ),
        other => return Err(format!("microphone sample format {other:?} not handled")),
    };
    stream.map_err(|e| e.to_string())
}

fn open_output(device: &cpal::Device, mixer: Mixer) -> Result<cpal::Stream, String> {
    let supported = device.default_output_config().map_err(|e| e.to_string())?;
    let format = supported.sample_format();
    let config: StreamConfig = supported.into();
    let channels = usize::from(config.channels);
    let rate = config.sample_rate;
    let err = |e| log::warn!("speakers: {e}");
    let stream = match format {
        SampleFormat::F32 => device.build_output_stream(
            config,
            move |data: &mut [f32], _: &_| mixer.mix(data, channels, rate),
            err,
            None,
        ),
        SampleFormat::I16 => {
            let mut scratch = Vec::new();
            device.build_output_stream(
                config,
                move |data: &mut [i16], _: &_| {
                    scratch.resize(data.len(), 0.0);
                    mixer.mix(&mut scratch, channels, rate);
                    for (o, v) in data.iter_mut().zip(&scratch) {
                        *o = (v * f32::from(i16::MAX)) as i16;
                    }
                },
                err,
                None,
            )
        }
        other => return Err(format!("speaker sample format {other:?} not handled")),
    };
    stream.map_err(|e| e.to_string())
}
