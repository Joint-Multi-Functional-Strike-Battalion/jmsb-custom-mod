# jmsb_voice

The Arma 3 extension that carries radio voice over LiveKit
(docs/DESIGN_VOICE_LIVEKIT.md). Rust. Not part of any PBO: the builds ship in
the mod root (`.hemtt/project.toml` includes them) and are tracked in git.
Called only by `addons/adapter_livekit`.

| Mod root | Built | For |
|---|---|---|
| `jmsb_voice_x64.dll` | Windows, default features | players (and a Windows server) |
| `jmsb_voice_x64.so` | Linux, `--no-default-features` | the Linux Arma server: `version` and `token` only |

The `client` feature (default) is the audio side: rooms, microphone, mixer.

## Build

**Windows** (the DLL). Needs Rust (rustup, stable) and the Visual Studio 2022
Build Tools (C++).

```
cargo build --release
copy target\release\jmsb_voice.dll ..\..\jmsb_voice_x64.dll
```

`target/release/voicetest.exe` is the phase 1 test, no Arma.

`build.rs` gives the DLL its file properties (description, publisher,
version from Cargo.toml). Then sign it: docs/SIGNING.md. Every rebuild is a
new hash, so a new BattlEye submission: batch changes.

**Linux** (the server's .so), in Docker (WSL Ubuntu); bullseye's older glibc
runs on newer systems:

```
docker run --rm -v /mnt/d/Git/jmsb-custom-mod/extensions/jmsb_voice:/src:ro -v /tmp/jvout:/out -w /src \
  -e CARGO_TARGET_DIR=/tmp/t rust:1-bullseye \
  sh -c "cargo build --release --locked --no-default-features --lib && cp /tmp/t/release/libjmsb_voice.so /out/jmsb_voice_x64.so"
cp /tmp/jvout/jmsb_voice_x64.so /mnt/d/Git/jmsb-custom-mod/
```

The C runtime is linked in (`.cargo/config.toml`): libwebrtc's prebuilt
library needs it, and players need no VC++ redistributable. The DLL depends
only on Windows' own DLLs.

**The LiveKit crates are pinned** to the 2026-10-12 release set in
`Cargo.lock` (`livekit` 0.9.5 and its sub-crates). The sub-crates are released
on their own, and a newer one broke 0.9.5, so update them together or not at all.

## License

MIT (`LICENSE` in this folder), since 2026-11-01. Only this extension: the
rest of the mod is APL-SA. It is MIT so that SignPath Foundation, which signs
open-source builds for free, can sign the DLL.

## Code signing policy

Free code signing provided by [SignPath.io](https://about.signpath.io/),
certificate by [SignPath Foundation](https://signpath.org/).

- **What is signed:** `jmsb_voice_x64.dll` only, built by GitHub Actions from
  this folder of the public repository (`.github/workflows/jmsb_voice.yml`).
  A DLL built on someone's own PC is never signed.
- **Who:** committers and reviewers - YonV (GitHub YonVclaw); approver of each
  signing request - YonV. Changes from anyone else are reviewed before they
  are merged.
- **Privacy:** the DLL connects only to the voice server the playing unit sets
  in its own settings (its LiveKit server), and sends microphone audio there
  only while the player talks. It sends nothing to anyone else and collects
  no data. It writes one log on the player's PC
  (`%LOCALAPPDATA%\Arma 3\jmsb_voice.log`).

## Files

| File | What |
|---|---|
| `src/lib.rs` | the Arma commands and callbacks (arma-rs) |
| `src/session.rs` | one player in one LiveKit room: mic published, the speakers asked for subscribed, push-to-talk |
| `src/audio.rs` | microphone capture, and the mixer: each speaker his own gain and ear, silent until set |
| `src/token.rs` | join tokens, microphone only |
| `src/bin/voicetest.rs` | the test exe |
| `build.rs` | the Windows DLL's file properties |
| `rust-toolchain.toml` | the compiler version, the same here and on GitHub Actions |
| `LICENSE` | MIT |

## Arma commands

`"jmsb_voice" callExtension [command, [args]]`:

| Command | Args | Where | Returns |
|---|---|---|---|
| `version` | | any | the version |
| `token` | key, secret, room, identity, name | server | a join token. The key and secret are adapter_livekit's CBA settings as SQF passes them; **each one passed empty is read from the server's environment, `JMSB_LIVEKIT_KEY` / `JMSB_LIVEKIT_SECRET`** (per call) - where they belong, since CBA copies every server setting to every client (review S9 / R4). Neither: fails with "API key or secret not set (CBA setting or JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET)" |
| `connect` | url, token | client | "ok"; then callbacks |
| `talk` | on | client | true when connected |
| `subscribe` | identity, on | client | true when connected: receive that speaker or not. **Auto-subscribe is off**: nobody's audio is downloaded until asked (kept per identity, so a microphone published later is subscribed when it appears) |
| `speaker` | identity, gain 0..1, pan -1..1 | client | true when connected. **A speaker not set yet is silent**; his gain and ear are kept while his audio restarts (a new track, a re-subscription) and forgotten only when he leaves |
| `disconnect` | | client | "ok" |
| `devices` | | client | `[[microphones], [speakers]]` by name, as Windows lists them |
| `device` | input, output | client | "kept" / "reopening": use the devices whose names hold these (case does not matter; "" = the Windows default) at every connect, and when a session is live open them now, off Arma's thread (a failure comes back as `error`, no microphone as `nomic`) |

Callbacks (ExtensionCallback, name `jmsb_voice`): `connected`, `disconnected`
[reason], `joined` [identity] (also for everyone already in the room on
joining), `left` [identity], `speaking` [identities], `nomic` [text] (no
microphone, or Windows' microphone privacy: the session runs on and he
listens), `error` [text].
Nothing is called back after `disconnect` (or after a `connect` replaces the
session): the task that hands events to the engine is stopped first, because
a callback into an engine that is shutting down crashed the game on exit
(2026-10-31). The mission's end disconnects.

**One connect at a time** (2026-10-31): every `connect` and `disconnect`
counts up a generation. A connect waits for the one before it, closes the
old session, joins, and keeps the new one only if nothing came after it;
otherwise it closes it unused and calls nothing back. So one identity never
has two sessions (the server would kick one, the rejoin kick the other), and
a `disconnect` during a connect is never missed.

**No microphone** fails nothing: the speakers open, the session joins, and
`nomic` says why. No speakers still fails the join (`error`).

**Which devices open** with no name given: Windows' default COMMUNICATIONS
device of each kind (what Windows gives chat and calls - the headset, where
the default device is the monitor's speakers; asked of WASAPI directly,
`communications_default` in audio.rs), else the default device. A name in
the mod's settings (addons/adapter_livekit README) overrides either.

**The log:** `%LOCALAPPDATA%\Arma 3\jmsb_voice.log`, started afresh each game
start: the devices opened, each connect and disconnect.

**The process's end:** once a room was joined, the DLL ends the process
itself when Windows detaches it at exit (`DllMain`, `TerminateProcess`):
libwebrtc's C++ statics would otherwise be unwound after their threads were
killed, which is where the game crashed on exit (2026-10-31, twice, no
dump). The engine is done by then - profile saved, RPT written. A game that
never joined a room detaches as it always did. Nothing else runs there - no
log line since 2026-10-31: it is under the loader lock after the other
threads were killed, and a lock one of them held would hang the exit.
**A stopgap:** it also skips the other DLLs' detach. The clean way, still
to build: shut the runtime and libwebrtc down at the mission's end (or a
`shutdown` command), while their threads live, so the detach has nothing
left to unwind and the guard can go.

Returns are callExtension's `[result, returnCode, errorCode]`: code 0 ran, 9
the command failed (the result says why).

## Test (phase 1)

On two machines (or two windows on one), against a LiveKit server:

```
voicetest --url ws://HOST:7880 --key KEY --secret SECRET --name alpha
voicetest --url ws://HOST:7880 --key KEY --secret SECRET --name bravo
```

Everyone who joins is subscribed and set to full volume by the test exe
itself (the extension starts every speaker unsubscribed and silent).
Enter toggles your microphone; `pan NAME -1` puts that speaker in your left
ear, `gain NAME 0.3` turns him down; `q` quits. Without talking:
`--tone --open` on one sends a 440 Hz tone, `--stats --quiet` on the other
prints, per speaker, the samples received and the audible ones. LiveKit
streams silence while nobody talks, so the first count grows 48000 a second
always; the second grows only while someone is heard.

**Echo test, one machine:** the voice server's egg runs an echo bot
(pelican-eggs `livekit-voice/echobot`) that answers any room named `echo-...`.
`voicetest ... --room echo-me`, talk, let go: it plays back what you said. In
game it is the ECHO TEST call (addons/adapter_livekit).

**Run 2026-10-28 on one machine** (LiveKit v1.13.9 for Windows, localhost):
both joined; bravo received alpha's tone at 48000 samples a second; joined,
left and speaking events all fired. **Not heard yet**: real microphones and
speakers, two machines, the server under Pelican.
