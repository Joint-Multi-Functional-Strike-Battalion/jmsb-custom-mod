# Voice messages (15 s) - design

Status: design, for code. Date 2026-10-20. Nothing here is built.
Replaces: DICTATE in TAC//MSG ([PLAN_MESSAGING_UI.md](PLAN_MESSAGING_UI.md) phase 5).
Roadmap: [TODO_DEVICES.md](TODO_DEVICES.md) section 6, row 10 ("DLL trim: RECORD/NOTE voice notes").
Upstream code read: `d:\Git\task-force-radio-standalone` at `8d023da` (origin
`github.com/ltsammy/task-force-radio-standalone`). Line refs below are to that tree.

## What it is

In TAC//MSG the player presses VOICE MSG, speaks for up to 15 s, and the clip is sent into the thread
as a reply. Anyone who can read the thread sees a VOICE row with its length and a PLAY cell, and
hears the clip in their own ear when they press it.

## Verdict

**Feasible, but only inside TFAR standalone. Nothing on the mod side can be built until that work
exists.**

| Question | Answer | Evidence |
|---|---|---|
| Can the voice-server capture audio? | No. It is a UDP relay. It never sees a microphone or a speaker, and never decodes, mixes or stores audio | `voice-server/README.md` 3-8; `RelayServer.cs` 217-246 (`HandleVoiceUp` forwards each Opus frame to every other session and keeps nothing) |
| Where is the mic captured? | In the client extension DLL `task_force_radio_pipe[_x64].dll`. WASAPI shared-mode capture, noise suppression, AGC, then Opus encode of 20 ms frames | `WasapiCaptureEngine.cpp` 32, 173; `TransmitController.cpp` 76-184 (encode at 167); `OpusCodec.h` 15-21 (48 kHz mono, 24 kbps, 960-sample frames) |
| Where is audio played? | Also in the client DLL. `PlaybackMixer` already mixes a local, centred PCM clip over the voice mix (the radio beep) | `PlaybackMixer.cpp` 103-110 (`triggerLocalBeep`), 129-138 (overlay); `VoiceSession.h` 83-89 |
| Does the voice-server already relay audio outside TeamSpeak? | Yes, live voice only: `VoiceUp` in, `VoiceDown` out to every session, fire-and-forget, with no buffer, no storage and no addressing | `docs/protocol-network.md` 126-151, 211-218 |
| Can SQF reach the DLL? | Yes. It already has non-legacy verbs (`UID`, `MICPTT`, `MUTE_STATE`), and an unknown sync verb answers `UNKNOWN COMMAND`. That answer is what makes a runtime capability probe possible | `CommandProcessor.cpp` 101-107, 121, 163, 200-211 |
| Can the server announce a new capability without breaking old clients? | Yes. The client reads `ConnectAccept` defensively and ignores trailing bytes, so a caps byte after the version string is safe. A `VersionMajor` bump is not safe, because the server rejects a mismatch | `VoiceNetworkClient.cpp` 249-266; `RelayServer.cs` 108-113 |

**Capture**: in the existing DLL, as a tap on `TransmitController::onFrameCaptured` after
denoise and AGC. A new jmfsb DLL would open the same mic a second time. It would also need its own
Opus build and transport, and a second BattlEye whitelist. Rejected.

**Storage and relay**: on the voice-server, which gains a small clip store. Not on the Arma network:
- 15 s is 750 frames, about 45 KB at 24 kbps (VBR, frames up to 500 B each, so the cap is 64 KB).
  As an SQF string that is about 60 KB per clip. It would sit in the server's messaging store and be
  pushed again on every thread request and every JIP index.
- The DLL exports only `RVExtension` and answers in one string truncated to `outputSize`, with no
  callback (`Extension.cpp` 1-5, 229-247; extension `README.md` 100). Getting 45 KB out of the DLL
  would need a polling loop of chunk calls. Putting it back into another client's DLL would need the
  same in the other direction.
- `publicVariable` and CBA events are reliable and ordered, and share the game channel with
  simulation traffic. Sending a clip to a whole platoon net this way would cause lag.

**Playback**: in the recipient's DLL. The DLL fetches the clip from the voice-server, decodes it with a
fresh Opus decoder and mixes it as a local overlay, the same path the radio beep uses. The
voice-server cannot "inject" a clip into one player's audio by itself:
- `VoiceDown` goes to every session (`RelayServer.cs` 241-245).
- A recipient's DLL plays a session only at the gain its own audibility solver gives that unit
  (extension `README.md` 74-78). A replayed clip would be inaudible, or audible to everyone.
- Either way the DLL has to change.

**BattlEye: the voice-server path does not avoid it.**
- The voice-server runs outside Arma. BattlEye never sees it, and changing it needs no whitelist.
- Capture and playback can only live in the client DLL, and that DLL has to change. That means a
  new binary with a new hash.
- TFAR standalone already depends on a client-side extension DLL, so a BattlEye-enabled server
  already needs `task_force_radio_pipe` whitelisted before voice messages come into it. The repo says
  nothing about BattlEye anywhere (grep), so whether ltsammy's published build is whitelisted is
  **unverified**.
- That leaves three routes:
  1. Upstream: the verbs land in ltsammy's repo, and his release goes through whatever whitelisting
     his DLL already gets.
  2. Our own build: the unit ships a fork build and submits it to BattlEye itself, again for every
     rebuild.
  3. BattlEye off on the unit's servers.
- Route 1 is the only one that does not leave the unit owning a DLL.

**Mod side now: not built.** Today the record tile, the clip message type and the PLAY cell would sit
behind a probe that always answers "no", because no DLL has the verbs (`CommandProcessor.cpp` 121).
That is code that never runs and cannot be tested. Its verb names and reply shapes are a proposal
that upstream may change. The VOICE MSG tile stays drawn and disabled ("COMING",
`addons/tacpad/functions/fnc_readerQuick.sqf` 126-133) until the DLL and server work is released.

## Message flow

```
 reader (tacpad)            adapter_tfar            TFRS DLL                 voice-server
 ---------------            ------------            --------                 ------------
 VOICE MSG press  ------>  voiceMsg "rec" ------>  VMSG_REC START~
                                                    tap encoded frames
 tile: REC 0:07 (poll VMSG_STATE each 0.25 s)       (auto stop at 15 s)
 press again / 15 s ---->  voiceMsg "stop" ----->  VMSG_REC STOP~ ------->  ClipUpBegin/Chunk...
                                                                      <---  ClipChunkAck (per chunk)
                                                                      <---  ClipStored(clipId)
 VMSG_STATE = READY <clipId> <ms>
 VMSG_TAKE -> clipId
 submit "voicemsg" [Clip.A=clipId, Length.A=s] -> jmfsb messaging server -> srvDeliver -> mailboxes
                                                     (a normal reply - routing, unread, notify)
 recipient thread view: VOICE 0:12  [PLAY]
 PLAY press ------------>  voiceMsg "play" ----->  VMSG_PLAY <clipId>~ --->  ClipFetch(clipId)
                                                                      <---  ClipDownChunk x n
                                                    decode, local overlay mix
 cell: PLAYING 0:04 (poll VMSG_STATE)               done -> IDLE
```

- **Record control**: the sixth quick-reply tile in `fnc_readerQuick.sqf`, and the same control in
  the composer's action row (`fnc_composePane.sqf`), so a voice message can also open a thread.
  - Press to start and press again to stop and send. A 15 s auto-stop sends it too. A small CANCEL
    cell replaces the + GRID / + MARKER row while recording. This is a toggle, not hold: the
    reader's hits are click handlers (`FUNC(drawHit)`), and a release lost to a dialog closing
    would leave the mic open.
  - While recording the tile is accent-filled, shows a countdown, and the record square blinks.
- **15 s cap**: enforced in the DLL (frame count) and again on the server (frame count and bytes).
  The mod reads the cap from `VMSG_CAPS`, so it is not a CBA setting.
- **Upload**: the DLL does it, not SQF. SQF polls `VMSG_STATE` until `READY` or `FAIL`.
- **Message record**: a normal jmfsb messaging reply, template `voicemsg`, payload `Clip.A` (clip
  id) and `Length.A` (seconds). It goes through `submit` -> `srvSubmit` -> `srvDeliver` like any other
  reply. The thread's mailboxes are the access control: the clip id only reaches people the thread
  reaches.
- **Playback**: the reply spine (`fnc_readerReplies.sqf`) draws a `voicemsg` reply as `VOICE 0:12`
  with a PLAY cell. Playback is fetch-on-press, so a JIP player or someone who opens the thread
  later can still play it while the clip lives on the server.

## Voice-server changes (spec for `task-force-radio-standalone`, not edited here)

Additive to protocol v1. `Protocol.VersionMajor` stays 1.

### Capability
- `ConnectAccept` gains a trailing `byte caps` after the version string. Bit 0 = ClipStore.
- Old clients stop reading after the version (`VoiceNetworkClient.cpp` 255-266). Old servers do not
  send it, so new clients treat that as "no clips".

### New packet types
Update `Protocol.cs` / `Protocol.h` and `docs/protocol-network.md` together.

| Value | Name | Dir | Body |
|---|---|---|---|
| 14 | ClipUpBegin | C->S | `uint32 nonce, uint16 frameCount, uint16 durationMs, uint16 chunkCount` |
| 15 | ClipUpChunk | C->S | `uint32 nonce, uint16 chunkIndex, byte frames, {uint16 len, bytes}*` (fits `MaxUdpPayload` 1200) |
| 16 | ClipChunkAck | S->C | `uint32 nonce, uint16 chunkIndex` |
| 17 | ClipStored | S->C | `uint32 nonce, byte idLen, id` (22-char base64url of 128 random bits) |
| 18 | ClipFetch | C->S | `byte idLen, id, uint16 chunkIndex` (client pulls chunk by chunk, so retransmit is its timer) |
| 19 | ClipDownChunk | S->C | `byte idLen, id, uint16 chunkIndex, uint16 chunkCount, uint16 durationMs, byte frames, {uint16 len, bytes}*` |
| 20 | ClipError | S->C | `uint32 nonce or 0, byte idLen, id, byte reason` (1 NotFound, 2 TooLarge, 3 Quota, 4 Disabled, 5 Incomplete) |

- **Reliability**: UDP with no reliable layer today (`protocol-network.md` 211-216). Upload is
  ack-per-chunk with client resend (250 ms, 5 tries). Download is pull-per-chunk. A 45 KB clip is
  about 40 chunks.
- **Rate**: per-session cap on clip packets per second, so a clip upload cannot starve live voice.

### Store
- In memory: `clipId -> {ownerUid, createdUtc, durationMs, frames[]}`.
- Assembled only after every chunk arrives. Incomplete uploads are dropped after 30 s.
- Limits: 775 frames, 64 KB per clip, 20 clips per uid (oldest evicted), global byte cap with
  oldest-first eviction, TTL sweep alongside `TimeoutSweepLoopAsync` (`RelayServer.cs` 299-325).
- A clip outlives its uploader's session (a recipient may play it after the sender logs off).
- A server restart loses every clip. Messages then read "clip expired". Disk persistence is a later
  option, not v1.

### Settings
Same pattern as `ServerOptions.cs` 20-28:
- `TFRS_CLIPS_ENABLED`: default on. Off means caps bit 0 is clear and the mod hides the feature.
- `TFRS_CLIP_TTL_MINUTES`: default 240.
- `TFRS_CLIP_MAX_TOTAL_MB`: default 64.

### Extension DLL changes (same repo)
- **Record tap**:
  - `TransmitController` gets `m_recording`. While it is set, every captured frame is encoded with a
    second `OpusVoiceEncoder` and appended to a 750-frame buffer, independent of `shouldTransmit`.
    Recording is its own gate.
  - Normal transmit gating is untouched: a VAD player recording a message is still heard nearby,
    as a real one would be.
  - A full buffer stops itself.
- **Verbs** (`CommandProcessor`, additive like `MUTE_STATE`):
  - `VMSG_CAPS` (sync) -> `VMSG\t1\t15000` when the connected server has bit 0, `VMSG\t0` when it
    does not. An old DLL answers `UNKNOWN COMMAND`, and no DLL answers `""`.
  - `VMSG_REC\tSTART|STOP|CANCEL~` (async).
  - `VMSG_STATE` (sync) -> `IDLE` | `REC\t<ms>` | `UP\t<pct>` | `READY\t<id>\t<ms>` |
    `PLAY\t<id>\t<ms>` | `FAIL\t<reason>`.
  - `VMSG_TAKE` (sync) -> the ready id, once, then `IDLE`.
  - `VMSG_PLAY\t<id>~`, `VMSG_STOP~` (async).
- **Playback**:
  - Fetch the clip unless it is in an 8-clip LRU, decode with a fresh `OpusVoiceDecoder`, and mix
    centred through a clip slot beside the local beep overlay (`PlaybackMixer.cpp` 129-138).
  - Master volume, speaker mute and the soft limiter apply.
  - No radio effect in v1.
- **Lifecycle**: `MISSIONEND` and `KILLED` cancel any recording. `MISSIONEND` clears the cache.
- **Log**: one `extension.log` line per record, upload, fetch and play edge.

## Mod changes (jmfsb), when the DLL and server above are released

- **`addons/adapter_tfar`**: the only file that names the `task_force_radio_pipe` extension.
  - New `fnc_voiceMsg` (`["caps"|"rec"|"stop"|"cancel"|"state"|"take"|"play"|"halt", args]`) wraps
    the verbs.
  - It caches `VMSG_CAPS` per voice connection, and re-probes when `TS_INFO PING` drops and comes
    back.
  - The adapter already loads only with TFAR standalone (its README), so with vanilla TFAR or no
    TFAR the function does not exist and the feature stays hidden.
  - (Other agents own this addon now; coordinate before adding the file.)
- **`addons/messaging`**: one built-in template `voicemsg`, registered in preInit by code rather than
  from the mission deck.
  - Fields `Clip.A` (text, required, `^[A-Za-z0-9_-]{22}$`) and `Length.A` (number 1-15).
  - Kind `both`, subject `VOICE {Length.A} S`, flag `system`.
  - Legal wherever `freetext` is legal, so no deck's `replyableWith` has to change.
  - `system` keeps it out of `composeTiles`, the picker and the quick-reply tiles.
  - The notification line reads `VOICE MSG 0:12`.
  - It is registered only when the capability exists anywhere: the server registers it on first
    sight of a client reporting caps. That rules out a template no machine can fill.
- **`addons/tacpad`**:
  - `fnc_readerQuick.sqf`: the VOICE MSG tile becomes live when the adapter function exists and caps
    is 1. It gets the countdown, CANCEL and the send-on-ready poll (a per-frame handler, removed on
    reader close).
  - `fnc_composePane.sqf`: the same control for a root voice message.
  - `fnc_readerReplies.sqf`: a `voicemsg` reply draws as VOICE m:ss + PLAY / PLAYING / EXPIRED.
    Without caps on this client it draws `VOICE 0:12 - NO PLAYER`, dim.
- **RF / EW**: the clip travels out of band, on the voice-server, not the RF graph.
  - PLAY is gated on the same `EFUNC(messaging,linkState)` that gates delivery.
  - The record tile is gated on the sender's link.
  - Without those gates a jammed player could still hear voice traffic.
- **No new CBA settings.** The cap comes from the DLL and the TTL from the voice-server. Nothing to
  plumb, nothing dead.

## Fallback with no DLL

If upstream declines and the unit will not own a DLL, the tile can send a CALL ME reply instead (a
`freetext` with the sender's net and grid). It is weaker, but it needs no new binary and nothing
from BattlEye.

## Open risks

1. **Upstream acceptance.** ltsammy owns the DLL and server. Without a merge the unit ships and
   maintains a fork build: two binaries, a Workshop item, and every upstream fix merged by hand.
2. **BattlEye.** The current DLL's whitelist status is unverified. Any modified DLL is a new hash.
   Check whether the unit's servers run BattlEye at all before anything else.
3. **UDP.** No reliable layer exists. Chunk acks and pulls are new protocol surface, and a lossy link
   can show FAIL after the 5 retries.
4. **Clip lifetime.** The voice-server is in memory. A restart or the TTL expires clips while the
   message lives on in the thread (and in PAC if threads are ever persisted), so EXPIRED must render
   cleanly.
5. **Abuse.** The store is a write endpoint on a password-only server. The quotas above are
   mandatory, not tuning.
6. **Privacy.** The DLL must never record without an explicit `VMSG_REC START`, must stop itself at
   15 s, and must cancel on `KILLED` / `MISSIONEND` / reader close. The record light shows it.
7. **Interception.** The clip is plain Opus over UDP, like live voice, and a held clip id fetches it.
   The id only travels in the message record, so the mailbox routing is the boundary. TFAR radio
   codes do not apply.
8. **Testing.** It needs two Steam identities: the voice-server drops the first voice session when the
   same UID connects again (`docs/server-hosting.md` 82-89). Upload and fetch can be tested headless
   with the DLL-host harness in the extension README 104-117.
9. **TS3 / vanilla TFAR players.** No DLL with the verbs, so no record and no playback. The row says
   so instead of failing quietly.
