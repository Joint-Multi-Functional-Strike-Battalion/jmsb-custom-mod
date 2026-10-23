#!/usr/bin/env python3
"""Make the voice addon's tones: our own simple sounds, no third-party audio.

    python tools/voice_sounds.py

Writes addons/voice/sounds/<cue>.wav (16-bit mono PCM) for the cues whose
file is FILE_OWN in CUES (addons/voice/script_component.hpp): the net switch
click, the blocked tone and the call tones. The radio's squelch open / tail,
its static and the TX / roger / cut clicks are the game's own radio sounds
(A3/Dubbing_Radio_F/sfx, shipped with Arma 3) and are not made here.
jmfsb_voice_fnc_playCue plays every cue by file path. Pitch per net and ear
panning are applied when the cue is played, so each cue is one file at a mid
pitch.

Deterministic: the noise uses a fixed seed, so a re-run writes the same bytes.
Not named gen_*.py on purpose: tools/check_art.py runs every gen_*.py in a
temporary folder, and this one writes into addons/.
"""

import math
import os
import random
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "addons", "voice", "sounds")

RATE = 22050
PEAK = 0.6          # headroom: the cues are mixed over voice
FADE_S = 0.004      # ramp at each tone's edges, so tones do not click


def tone(freqs, seconds, level=1.0):
    """A tone (one frequency or a chord), with ramped edges."""
    n = int(RATE * seconds)
    out = []
    fade = max(1, int(RATE * FADE_S))
    phase = [0.0] * len(freqs)
    for i in range(n):
        v = 0.0
        for k, f in enumerate(freqs):
            phase[k] += 2 * math.pi * f / RATE
            v += math.sin(phase[k])
        v /= len(freqs)
        env = min(1.0, i / fade, (n - 1 - i) / fade)
        out.append(v * env * level)
    return out


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def noise(seconds, level=1.0, seed=1, smooth=0.5):
    """Band-limited noise (a one-pole low-pass)."""
    rnd = random.Random(seed)
    n = int(RATE * seconds)
    out = []
    last = 0.0
    fade = max(1, int(RATE * FADE_S))
    for i in range(n):
        last = last * smooth + rnd.uniform(-1, 1) * (1 - smooth)
        env = min(1.0, i / fade, (n - 1 - i) / fade)
        out.append(last * 2.0 * env * level)
    return out


def trill(f1, f2, seconds, step_s):
    out = []
    flip = False
    while len(out) < RATE * seconds:
        out += tone([f2 if flip else f1], step_s)
        flip = not flip
    return out


def cat(*parts):
    out = []
    for p in parts:
        out += p
    return out


CUES = {
    # radio (the squelch, static and TX / roger / cut are the game's own)
    "netSwitch": lambda: cat(tone([3000], 0.008), noise(0.012, 0.5, seed=5, smooth=0.1)),
    "blocked": lambda: cat(tone([400, 410], 0.14), silence(0.06), tone([400, 410], 0.14)),
    # call
    "dialTone": lambda: tone([350, 440], 1.0),
    "ringback": lambda: tone([440, 480], 1.0),
    "ring": lambda: trill(1000, 1250, 0.8, 0.025),
    "busy": lambda: cat(tone([480, 620], 0.25), silence(0.25), tone([480, 620], 0.25), silence(0.25)),
    "connect": lambda: cat(tone([800], 0.08), tone([1200], 0.1)),
    "hangUp": lambda: cat(tone([1200], 0.08), tone([800], 0.12)),
    "joinChime": lambda: cat(tone([800], 0.07), tone([1000], 0.07), tone([1300], 0.1)),
    "priorityWarning": lambda: cat(*[tone([1600], 0.06) + silence(0.05) for _ in range(4)]),
}


def write(name, samples):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * PEAK)) * 32767)) for s in samples)
        w.writeframes(frames)
    return path


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, make in CUES.items():
        path = write(name, make())
        print(os.path.relpath(path, ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
