# Voice on LiveKit - design

Our own voice server and client DLL, so radio voice gets real per-speaker effects, ear split and RF degradation, with no app for the player to install.
Related: [DESIGN_VOICE.md](DESIGN_VOICE.md) (the voice core and its adapters), [DESIGN_VOICE_MESSAGES.md](DESIGN_VOICE_MESSAGES.md), [DESIGN_RF.md](DESIGN_RF.md).
Status: phase 1 built (extensions/jmsb_voice, the egg in ghosts-of-battle/pelican-eggs livekit-voice/). The echo test built in the mod (addons/adapter_livekit), 2026-10-29. **Phase 2 built 2026-10-31: the voice adapter "livekit" - every net, call and local voice over the server; the system by default wherever the extension loads.** The echo test ran in game 2026-10-31 (heard; it played on the Windows default output, the monitor, not the headset). **The DLL was rebuilt 2026-10-31 (0.1.0)**: `devices` and `device [input, output]` (the player names his microphone and speakers in two CBA settings; `fnc_applyDevices`), the engine now sees the real version, and the callback task is stopped before a session closes. The second run that day (the rebuilt DLL, the speakers setting left empty) still played on the monitor and still crashed on exit, so: with no name set the DLL now opens Windows' default *communications* device (the headset) rather than its default device; it keeps a log (`%LOCALAPPDATA%\Arma 3\jmsb_voice.log`); and once a room was joined it ends the process itself when detached at exit (`DllMain`, `TerminateProcess`) so libwebrtc's statics are never unwound after their threads were killed - the reading of a crash that leaves no dump. New hash in `tools/dlls.sha256`; **not yet signed nor sent to BattlEye** (docs/SIGNING.md). The radio effect (phase 3) is not built; the DLL carries the phase 1 commands plus the two above, not the whole API 1 below. **Review fixes 2026-10-31 (REVIEW_CODE B14, B15, V1-V8; R13), DLL rebuilt again (new hash), NOT RUN IN GAME:** the mixer starts every speaker silent and keeps his gain and ear when his audio restarts; auto-subscribe off, with a `subscribe` command (SQF subscribes whoever could be heard: a shared net by the server's roster, the same vehicle, or 1.5 times the local range); one connect at a time (a generation counter: an overtaken connect closes its session and calls nothing back); no microphone no longer fails the join (`nomic` callback: he listens); `device` reopens off Arma's thread; no log line in `DllMain`; the `token` command reads an empty key or secret from the server's environment (`JMSB_LIVEKIT_KEY` / `JMSB_LIVEKIT_SECRET`, review S9 / R4: CBA copies the secret to every client) - **so the Linux .so needs rebuilding** (not done). SQF: the server picks the voice system for everyone ("none" = VOICE UNAVAILABLE where the extension did not load); hearing follows the nets the listener is on now (and the core sends quality 0 for a net he leaves); his own cut-offs close only his mic, dead hears nothing; game VON voice off on every channel under LiveKit (again every second and on respawn); token asks numbered (a stale answer is dropped) and rate-limited on the server; join failures back off and are said once.

## Decision

- **LIVEKIT IS THE VOICE** (user, 2026-10-28, said again 2026-10-31: "livekit was to be the VON", "no in-game VON, use what was supposed to be built"). The mod's voice system is this server and this DLL. Arma's own VON carries nothing - every game channel's voice is off in the missions - except on a machine where the extension does not load (Linux, BattlEye without the whitelist), which falls back to the game VON adapter. It is NOT a fourth adapter beside VON; the earlier line here saying so was wrong.
- **LiveKit** (user, 2026-10-28), picked over our own relay, Janus + libdatachannel, TFAR standalone's server and Steam Voice: the most is already built, and what is left is the glue and our radio effects. This replaces DESIGN_VOICE.md's "Not used: LiveKit".
- **Mumble is out** (user).
- **The player downloads nothing** beyond the mod (user). The DLL ships in the mod. No second app, no installer, no VC++ redistributable (the runtime is linked in).
- **Video stays off.** Tokens allow the microphone only. The call picture stays a game camera (DESIGN_VOICE.md "Call picture").
- **The server is a Pelican egg** (user, 2026-10-28).
- **The voice API does not change**, so the devices, the RADIO apps, BFT and the HUD keep working: `jmfsb_voice` runs its full logic (nets, calls, callbacks, RTO nets, cut-offs) under `"livekit"` as it did under VON.

## Parts

| Part | What | Licence |
|---|---|---|
| `livekit-server` | the media server, in a Docker container under Pelican | Apache 2.0 |
| `jmsb_voice_x64.dll` | our Arma extension, written in Rust, shipped in the mod root | ours |
| `jmsb_voice_x64.so` | the same, built without its audio side: tokens only, for a Linux Arma server | ours |
| `livekit` Rust crate | the client: WebRTC, Opus, jitter buffer, echo / noise / gain processing | Apache 2.0 / MIT |
| `arma-rs` | the Rust side of `callExtension` and the extension callback | MIT |
| `cpal` | microphone capture and speaker playback (WASAPI) | Apache 2.0 |
| `addons/adapter_livekit` | the voice adapter `"livekit"`: SQF only, talks to the DLL | APL-SA |

No GPL code in the DLL. ACRE's filters are not copied; our radio effect is written fresh.

## How it works

```
Arma (SQF)  --callExtension-->  jmsb_voice_x64.dll  --WebRTC (UDP)-->  livekit-server
   ^                                  |
   +------ extension callback --------+   (talking, connection state)
```

- **One room per mission.** The identity is the player's UID (`getPlayerUID`).
- **Join:** the client asks the Arma server for a token; the server's copy of the DLL signs it (a JWT, HMAC SHA-256) with the LiveKit key and secret, then sends it back to that client only. The token grants: join this room, publish the microphone only, subscribe.
- **Talk:** each player publishes one microphone track, muted while no key is held. A net key (our keybinds, not Arma's Push To Talk) unmutes it. The key edge still goes out as `jmfsb_voice_keyed` [speaker, net, on], so every listener knows which net he is on.
- **Hear:** auto-subscribe is off. Each client subscribes only to the tracks of speakers the voice core says it can hear on one of its nets, and drops them when it can't.
  (Built 2026-10-31: `subscribe [identity, on]`; SQF's `canHear` - a shared net by the server's roster, the same vehicle, or 1.5 times the local range - so his first words are not lost to the subscription.)
- **Mix:** the SDK hands us each speaker's audio separately. A speaker starts silent until SQF sets him, and keeps his gain and ear while his audio restarts. The DLL applies, per speaker: gain from RF quality and the net's volume, the ear (left / both / right), and the radio effect for that quality. It then mixes and plays the result on the default output device, beside Arma's own sound.
- **SQF sends the DLL what to do; the DLL does the audio.** Per speaker, about every 0.1 s: `[uid, gain, pan, quality]`. Per key edge: open or close the mic. The DLL calls back with who started and stopped talking, and with connection drops.

## Radio effect

Written fresh, applied after decoding, per speaker:

- band-pass filter, about 300-3000 Hz (biquads);
- soft clipping that grows as quality falls;
- noise and dropouts that grow as quality falls; cut-out at 0;
- a squelch tail and key-up click from the existing cue sounds.

Jamming and range lower the quality the voice core already computes, so they degrade voice with no new rules.

## Direct (local) voice

- **Over the server too** (user, 2026-10-31: "no in-game VON"). TALK LOCAL opens the mic and keys no net; every listener hears every open mic by distance - full in the same vehicle, else falling to nothing at the local voice range (CBA setting, 50 m by default) by the square - in the ear the speaker stands to (`fnc_gainOf`). A man on the radio beside you is heard beside you too: the louder of radio and local wins.
- **Later, maybe: occlusion** (Steam Audio, Apache 2.0).

## What changes in the mod

Built 2026-10-31 (addons/adapter_livekit): one room per mission, named by the server (`mission-<mission>-<n>`, published); each client asks the server for a token (`srvRoomToken`, its own UID the identity) and connects; the talk keys (Caps Lock with a modifier, as before) open the extension's mic on the key's net (`hold`, `mic`, the core's `ptt` hook); every speaker's gain and ear is sent to the extension when it moves (`tick` every 0.2 s, `speaker`, `gainOf`): the net's quality from the core while he is keyed on a net you are on, local by distance always; a new speaker's track is set silent on `joined`. The echo test takes the extension's one session and the room is rejoined after. A drop is rejoined after 10 s; a server that cannot sign you in is asked again every 60 s.

- `jmfsb_voice_system` is `"livekit"` wherever the extension answers `version` (the adapter announces itself in `jmfsb_voice_loaded` from its preInit). TFAR and ACRE were removed on 2026-10-31 (DEC1) and are no choice any more (a stored `"tfar"` / `"acre"` reads as Automatic); `"von"` is the fallback without the extension, or by choice. **The server's choice is everyone's** (2026-10-31, R13): a client follows it, and one that cannot run LiveKit while the server chose it is `"none"` - VOICE UNAVAILABLE, told once - not alone on the game VON.
- **Game VON is off** under LiveKit: every game channel's voice (0-15), at start, every second and on respawn (`fnc_vonOff`), so Arma's own Push To Talk on Caps Lock sends nothing.
- **Hearing follows the listener's nets now** (`fnc_gainOf`): a net he left, or a CALL slot another call reuses, is not heard. His own cut-offs (radio silence, unconscious, no air) close only his mic, as under VON; dead, he hears nothing.
- The voice core runs its full logic under `"livekit"`, as under VON: nets, calls, callbacks, RTO nets, cut-offs. There is no 10-channel limit, so calls and RTO nets stop competing for slots.
- `adapter_livekit` hooks: `join` / `leave` (subscription lists), `quality` (gain and effect), `talking` (from the DLL's callback), `ptt` (our net keys), `block` (cut-offs close the mic), `setEar`, `setMute`, `audience`.
- **Talk on any net:** a key per net becomes possible, because the DLL opens the mic and the engine does not.
- **Voice messages** (DESIGN_VOICE_MESSAGES.md) become possible: the DLL can record.

## Server (Pelican egg)

- Image: `yonvclaw/jmsb-livekit:latest` (the egg names `latest`, so a push and a restart update it; version tags kept for rollback), the pinned `livekit-server` binary on the Pelican Debian yolk, plus the echo bot and Caddy.
- **Encryption, optional** (egg variable TLS, default false; user, 2026-10-30): Caddy serves `wss://` on the primary port with the node's own certbot certificate (`game9001.ghostsofbattle.com`), copied by a host deploy hook into a read-only Pelican mount at `/mnt/voice-cert`. LiveKit moves to the container's loopback. Caddy gets no certificate itself, so no port 80/443; it reloads the copy hourly when it changes. Steps: pelican-eggs `livekit-voice/README.md`. Voice audio is DTLS-SRTP either way; TLS protects the sign-in token.
- Ports: TCP 7880 (signalling), UDP 7882 (all media on one port), TCP 7881 (fallback). One primary allocation plus two additional.
- Variables: the API key and secret, the ports, the public IP for ICE, a log level, the echo test, encryption.
- Startup is `jmsb-voice-start` in the image, which builds the LiveKit config from the variables. Not inline in the egg: the yolk entrypoint turns `}}` into `}` (broke the first start, 2026-10-29) and prints the startup line, secret included.
- **Echo test:** a bot (`echobot`, LiveKit Rust SDK) beside the server, on while `ECHO_TEST` is true. See "Echo test" below.

## Echo test

Called from in game (user, 2026-10-29: "the test is designed to be called from in game", "not random users").

- **ECHO TEST** is the first row of the call list: the phone's RADIO app, CALLS (F2 calls, F4 hangs up), and the tablet's RADIO page, CONTACTS. Offered only where the extension loaded.
- **One room per caller,** `echo-<UID>`. The client asks the Arma server; the server signs a token for that room with the key and secret from its CBA settings and sends it to that client only. So nobody hears another's echo.
- **The bot answers on demand:** it reads the voice server's room list every second, joins each `echo-` room with a caller in it (checked by its participants: the room's count lags by seconds and still counts the bot after it leaves), and leaves when he does. Answers in under half a second.
- **The microphone is open for the whole test,** no key. The bot cuts a clip at 0.7 s of quiet (15 s at most), plays it back, and does not record while it plays.
- **It ends** on HANG UP, when the bot has not answered in 15 s, after 3 minutes, and when the mission ends (the mission display's Unload; scripts stop with it).
- **The Arma server is Linux** (the arma3 egg runs `arma3server_x64`), so it signs tokens with `jmsb_voice_x64.so`: the extension built without its "client" feature, no audio libraries, 1 MB.
- The LiveKit URL, key and secret are CBA settings (adapter_livekit), set on the server (user, 2026-10-30: "jmsb_voice_server.json pull from cba"). CBA copies server values to every client, so every player's game would hold the secret and could sign its own tokens. **Since 2026-10-31 (review S9 / R4):** leave the key and secret settings empty and set `JMSB_LIVEKIT_KEY` / `JMSB_LIVEKIT_SECRET` in the Arma server's environment (its egg's variables); the `token` command reads them when passed empty. The URL stays a setting.
- **The egg's exact format:** match a PLCN_v3 export from our own Pelican panel (the user to send one).

## BattlEye

- The DLL needs BattlEye whitelisting before it runs on a server with BattlEye. Each build is a new file to whitelist.
- Our servers run without BattlEye, so development needs none. Submit release builds only, and keep DLL changes rare: most changes are SQF.

## Frozen DLL (user, 2026-10-30: "make sure the dll is not going to change")

The client DLL is built once more, with the full command set below, then signed, whitelisted and frozen. Everything after that is SQF, the server's `.so`, the egg and its bots.

**The rule: the DLL has mechanisms, not policy.** Every number SQF could want to tune is an argument; the DLL keeps only safety clamps and buffer sizes. Who hears whom, how well, which effect, which key, which room: all decided in SQF or on the server.

**What stays changeable without touching the DLL:**

- The token grants (signed by the server's `.so`).
- Rooms, nets, calls, quality, the effect amounts per quality, ears, volumes, keys: SQF.
- The radio effect's sound: SQF picks every parameter of the fixed chain below.
- Voice messages and net recording: a recorder bot on the voice server records a player's microphone track and plays clips back as its own track, which the client hears like any speaker. The DLL needs no record command. (DESIGN_VOICE_MESSAGES.md still describes the TFAR route; to be rewritten.)
- Control messages between players and the bots: the `send` command and `data` callback carry any text on any topic.
- The LiveKit server version, kept pinned in the image (`LIVEKIT_VERSION`). A new version is tried against the frozen DLL before `latest` moves.

**Command set, API 1** (`slot` names a session, so the echo test or a recorder room can run beside the radio room):

| Command | Args | Does |
|---|---|---|
| `version` | | the API level and build |
| `connect` | slot, url, token | join a room in that slot |
| `disconnect` | slot | leave it |
| `talk` | slot, on | microphone open / closed in that room |
| `subscribe` | slot, identity, on | receive that speaker or not (auto-subscribe off) |
| `speaker` | slot, identity, gain, pan, fx | loudness 0..1, ear -1..1, and the effect: [low cut Hz, high cut Hz, drive, noise, dropout, crush], each 0 = off; missing values are off, extra ones ignored |
| `volume` | gain | every speaker at once |
| `mic` | gain | microphone level |
| `processing` | echo, noise, autogain | WebRTC's echo cancel, noise suppression, gain control |
| `devices` | | [[inputs], [outputs]] by name |
| `device` | input, output | pick them ("" = Windows default) |
| `send` | slot, topic, text, identities | a reliable data message ([] = everyone) |
| `stats` | slot | per speaker: level, buffered ms, packets lost; and the ping |
| `log` | level | the extension log's level |

Callbacks: `connected` [slot], `disconnected` [slot, reason], `joined` / `left` [slot, identity], `speaking` [slot, identities], `data` [slot, from, topic, text], `devices` (the device list changed), `error` [slot, text].

**Forward compatibility:** `version` tells SQF the API level, and SQF uses only what that level has. An unknown command fails with code 1 and changes nothing.

**The lock:** `tools/dlls.sha256` holds every mod-root DLL's SHA-256, and `check_all` fails when a DLL differs (`tools/check_dll_lock.py`). A new hash goes in only with a signed build sent to BattlEye.

## Phases

1. **Spike:** a test exe on the DLL's code. Two machines join a room and hear each other with push-to-talk. No effects, no Arma. **Built 2026-10-28** (`voicetest`): on one machine against a local LiveKit, audio flows at 48000 samples a second with the right events. Real microphones and two machines not tried yet.
2. **In Arma:** the DLL loaded, `adapter_livekit` registered, radio nets and calls over LiveKit, Direct still on VON. Gain and ear per speaker.
3. **The radio effect,** jamming and range in the sound, keys per net.
4. **Release:** the egg, server config, Workshop build, BattlEye submission.
5. **Later, maybe:** our own 3D Direct voice, voice messages, net recording (LiveKit Egress) for after-action review.

## To check before building

- ~~The Rust SDK gives raw frames~~: yes, `NativeAudioSource` in, `NativeAudioStream` out per track (checked in the 0.9.5 source and the smoke test).
- ~~Single UDP port~~: `rtc.udp_port` works (smoke test, and the egg's flow-style `--config-body` start line).
- ~~DLL size~~: 27 MB, static C runtime, only Windows DLLs.

- Echo cancellation needs the far-end signal; with our own playout it may not get it. Most players wear headsets; if it fails, leave it off.
- Linux / Proton players: the DLL is Windows-native.
- The token's microphone-only grant (`canPublishSources`).

## Open

- Which box hosts the egg: the Lightsail server or another Pelican node.
- Whether Direct voice ever leaves VON (phase 5).
