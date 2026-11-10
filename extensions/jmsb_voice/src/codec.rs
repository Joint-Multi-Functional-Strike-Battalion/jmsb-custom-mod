//! Opus out and in, the same for every voice server (LiveKit and Mumble).
//!
//! Out: the microphone's 10 ms chunks are cleaned of noise (RNNoise, the
//! pure Rust nnnoiseless) and encoded as 20 ms Opus packets. In: each
//! speaker's packets are decoded on their own, so the mixer still sets one
//! man's gain and ear.

use std::collections::HashMap;

use opus::{Application, Bitrate, Channels, Decoder, Encoder};

use crate::audio::{FRAME, RATE};

/// One Opus packet: 20 ms, two microphone chunks.
pub const OPUS_FRAME: usize = (RATE / 50) as usize;
/// Voice bitrate (bit/s): clear speech, small on the wire.
const BITRATE: i32 = 32_000;
/// The largest Opus packet there is (bytes).
const MAX_PACKET: usize = 1276;
/// The longest Opus packet there is: 120 ms of samples.
const MAX_DECODED: usize = RATE as usize * 120 / 1000;
/// Expected loss (%) the encoder plans for with in-band FEC.
const LOSS_PERC: i32 = 5;

/// The microphone side: noise suppression, then Opus.
pub struct Mic {
    encoder: Encoder,
    denoise: Box<nnnoiseless::DenoiseState<'static>>,
    pending: Vec<i16>,
    noisy: Vec<f32>,
    clean: Vec<f32>,
}

impl Mic {
    pub fn new() -> Result<Self, String> {
        let mut encoder = Encoder::new(RATE, Channels::Mono, Application::Voip).map_err(|e| e.to_string())?;
        encoder.set_bitrate(Bitrate::Bits(BITRATE)).map_err(|e| e.to_string())?;
        encoder.set_inband_fec(true).map_err(|e| e.to_string())?;
        encoder.set_packet_loss_perc(LOSS_PERC).map_err(|e| e.to_string())?;
        Ok(Self {
            encoder,
            denoise: nnnoiseless::DenoiseState::new(),
            pending: Vec::with_capacity(OPUS_FRAME),
            noisy: vec![0.0; nnnoiseless::DenoiseState::FRAME_SIZE],
            clean: vec![0.0; nnnoiseless::DenoiseState::FRAME_SIZE],
        })
    }

    /// One microphone chunk (`FRAME` samples) in; an Opus packet out every
    /// second chunk.
    pub fn push(&mut self, chunk: &[i16]) -> Option<Vec<u8>> {
        if chunk.len() == FRAME && FRAME == nnnoiseless::DenoiseState::FRAME_SIZE {
            for (n, &v) in self.noisy.iter_mut().zip(chunk) {
                *n = f32::from(v);
            }
            self.denoise.process_frame(&mut self.clean, &self.noisy);
            let max = f32::from(i16::MAX);
            self.pending.extend(self.clean.iter().map(|&v| v.clamp(-max, max) as i16));
        } else {
            self.pending.extend_from_slice(chunk);
        }
        if self.pending.len() < OPUS_FRAME {
            return None;
        }
        let rest = self.pending.split_off(OPUS_FRAME);
        let frame = std::mem::replace(&mut self.pending, rest);
        self.encode(&frame)
    }

    /// The end of a transmission: what is left, filled out with silence, as
    /// the last packet (Mumble marks it the end).
    pub fn finish(&mut self) -> Option<Vec<u8>> {
        let mut frame = std::mem::take(&mut self.pending);
        frame.resize(OPUS_FRAME, 0);
        self.encode(&frame)
    }

    fn encode(&mut self, frame: &[i16]) -> Option<Vec<u8>> {
        let mut out = vec![0u8; MAX_PACKET];
        match self.encoder.encode(frame, &mut out) {
            Ok(n) => {
                out.truncate(n);
                Some(out)
            }
            Err(e) => {
                log::warn!("opus encode: {e}");
                None
            }
        }
    }
}

/// The speakers' side: one decoder per speaker, by identity.
#[derive(Default)]
pub struct Speakers {
    decoders: HashMap<String, Decoder>,
}

impl Speakers {
    /// One speaker's packet to samples, mono at `RATE`.
    pub fn decode(&mut self, id: &str, packet: &[u8]) -> Option<Vec<i16>> {
        if !self.decoders.contains_key(id) {
            let decoder = Decoder::new(RATE, Channels::Mono).map_err(|e| log::warn!("opus decoder: {e}")).ok()?;
            self.decoders.insert(id.to_owned(), decoder);
        }
        let decoder = self.decoders.get_mut(id)?;
        let mut out = vec![0i16; MAX_DECODED];
        match decoder.decode(packet, &mut out, false) {
            Ok(n) => {
                out.truncate(n);
                Some(out)
            }
            Err(e) => {
                log::warn!("opus decode from {id}: {e}");
                None
            }
        }
    }

    /// Forgets a speaker's decoder: he left, or is no longer received.
    pub fn forget(&mut self, id: &str) {
        self.decoders.remove(id);
    }
}
