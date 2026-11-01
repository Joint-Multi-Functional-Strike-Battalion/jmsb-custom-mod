# LiveKit Adapter

`jmfsb_adapter_livekit`

**THE VOICE** (user, 2026-10-31: "livekit was to be the VON", "no in-game
VON"): every net, call, RTO net and local voice over our own LiveKit server
(docs/DESIGN_VOICE_LIVEKIT.md), through the `jmsb_voice` extension. The only
addon that calls it. The voice adapter `"livekit"` of `jmfsb_voice`, the
system by default wherever the extension loads (the adapter announces
itself in `jmfsb_voice_loaded` from its preInit; `jmfsb_adapter_von` is the
fallback where it does not). NOT RUN IN GAME.

## The voice

- **One room per mission**, named by the server at start
  (`mission-<mission>-<n>`, published). Each client asks the server for a
  token (`roomJoin` > `srvRoomToken` > `roomAnswer`; the identity is the
  player's UID) and connects; the room is live on the extension's
  `connected`. A drop is rejoined after 10 s; a join that fails is tried
  again after 10 s, doubling to 60 s, and said once until it works; a server
  that cannot sign you in (address, key or secret not set) says so once and
  is asked again every 60 s; no answer in 15 s is asked again. Each ask is
  numbered and the server sends the number back: an answer to an older ask
  is dropped, so one join makes one connect (the extension also runs one
  connect at a time). The server gives a machine one token per 2 s.
- **Only where the server chose it** (jmfsb_voice: the server picks the
  voice system for everyone). This machine starts on
  `jmfsb_voice_systemReady`, once it has taken the server's choice.
- **Game VON is off** on every game channel (0-15, chat left alone) while
  LiveKit carries the voice - at start, every second and on respawn
  (`vonOff`) - so Caps Lock reaching Arma's own Push To Talk sends nothing.
  Also on a machine left with no voice ("none": the server runs LiveKit and
  this machine's extension did not load).
- **No microphone** (none, or Windows' microphone privacy): the room is
  joined all the same and he hears the nets; told once (`nomic`).
- **The mic** opens from the talk keys (`initKeybinds.inc.sqf`, the same
  Caps Lock + modifier keys as the game VON's): a PTT key on its net
  (`jmfsb_voice_fnc_pttNet`), when the player is on that net and the voice
  core's cut-off level allows it; TALK LOCAL to the people round him. `hold`
  keeps what is held, `mic` sends `talk` on a change. The voice core reads
  the key through the `ptt` hook and sends the key edge to the net itself.
- **The mix** (`tick` every 0.2 s, `speaker`, `gainOf`): everyone is in the
  room, and each client tells the extension how loud and in which ear every
  speaker is - the net's quality from the core (`quality` hook: RF link,
  grace, mute) while he is keyed on a net you are on NOW (the core's
  `jmfsb_voice_myNets`; a net you left, or a CALL slot another call reuses,
  is not heard - and the core sends quality 0 for a net you leave), in the
  ear the net is set to; local by distance always - full in the same
  vehicle, else fading to nothing at the local voice range (CBA setting) -
  in the ear he stands to. The louder wins. Sent when the gain moves 0.02 or
  the ear 0.1. The extension starts every speaker silent and keeps his gain
  when his audio restarts. **Your own cut-offs** (radio silence,
  unconscious, out of air) close only your mic, as under the game VON; you
  still hear. Dead, you hear nothing.
- **Who is received** (`canHear`): the extension's auto-subscribe is off.
  A speaker is subscribed while he could be heard - on a net you are on by
  the server's roster (`jmfsb_voice_fnc_rosterNets`), in your vehicle, or
  within 1.5 times the local voice range - and dropped otherwise, so nobody
  downloads the other side's voices or nets he is not on.
- **Hooks** registered with `jmfsb_voice`: `quality`, `talking` (the keyed
  speakers), `setActive` / `current`, `block`, `ptt`, `keyed`; `reserve`
  always true (no channel count), `global` false (no Global channel). No
  `audience`: the core's default sends a key event to everyone the server
  has on that net. The extension's `speaking` callback is not used.
- **The echo test** takes the extension's one session: the room is left for
  it and rejoined after.
- **Microphone and speakers** (user, 2026-10-31: the echo came out of the
  monitor, not the headset the game plays on): two settings of the player's
  own, JMSB - Voice (Built-in) > Voice server (LiveKit) > Microphone /
  Speakers - part of the device's name as Windows lists it, empty for
  Windows' communications device (the headset, when Windows has one set as
  such), else its default device. The names this machine has are in the RPT at mission
  start after `voice devices`. Applied at settings init and on change
  (`applyDevices`, the extension's `device`), live when a session is up -
  opened off the game's thread.

## The extension

| File (mod root) | Where | What |
|---|---|---|
| `jmsb_voice_x64.dll` | players (and a Windows server) | joins rooms, the microphone, the mix; signs tokens |
| `jmsb_voice_x64.so` | a Linux server | signs tokens only |

Built from `extensions/jmsb_voice` (its README). A player without the DLL
(Linux, or a BattlEye server that has not whitelisted it) is offered no echo
test, and where the server chose LiveKit he has no voice: VOICE UNAVAILABLE,
told once (jmfsb_voice "none"), his game VON off too.

## The echo test

- **ECHO TEST** is the first row of the call list: the phone's RADIO app,
  CALLS tab (F2 calls, F4 hangs up), and the tablet's RADIO page, CONTACTS.
- Calling it asks the server for a token to the player's own room,
  `echo-<UID>`. The server signs it with the key and secret from its CBA
  settings and sends it to him alone, so nobody hears another's echo.
- The voice server's echo bot (pelican-eggs `livekit-voice/echobot`) answers.
  It is subscribed and set to full volume (the extension receives nobody
  until told), and the microphone opens: talk, pause, and the bot plays it
  back. No microphone ends the test, saying so.
- Hanging up leaves the room and closes the microphone. The test also ends by
  itself when the bot does not answer in 15 s, after 3 minutes, and when the
  mission ends.
- The microphone is open for the whole test (no key): the bot cuts a clip at
  0.7 s of quiet.

## Server setup

CBA settings, JMSB - Voice (Built-in) > Voice server (LiveKit), set on the
server:

- **Voice server address:** `ws://VOICE-SERVER:7880`, as the players reach it.
  With the egg's Encryption (TLS) on: `wss://game9001.ghostsofbattle.com:7880`
  (the node's name, which the certificate is for; pelican-eggs
  `livekit-voice/README.md`).
- **API key** and **API secret: leave them EMPTY** (review S9 / R4,
  2026-10-31). CBA copies server values to every client, so a secret set
  there is in every player's game and anyone could sign himself in. Set
  them in the Arma server's environment instead - `JMSB_LIVEKIT_KEY` and
  `JMSB_LIVEKIT_SECRET`, variables of the Arma server's egg - to the LiveKit
  egg's `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET`. The extension reads them
  there whenever the settings are empty (a setting that is set still wins).

No address, or no key and secret either way: the join and the echo test
answer "not set".

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_voice`
- `jmfsb_notify`
- `cba_main` _(external)_
- `cba_xeh` _(external)_

## Ships

25 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_adapter_livekit_url` | EDITBOX | Voice server address |
| `jmfsb_adapter_livekit_key` | EDITBOX | API key |
| `jmfsb_adapter_livekit_inputDevice` | EDITBOX | Microphone |
| `jmfsb_adapter_livekit_outputDevice` | EDITBOX | Speakers |
| `jmfsb_adapter_livekit_localRange` | SLIDER | Local voice range (m) |
| `jmfsb_adapter_livekit_secret` | EDITBOX | API secret |

## Functions

<details><summary>25</summary>

- `jmfsb_adapter_livekit_fnc_applyDevices`
- `jmfsb_adapter_livekit_fnc_block`
- `jmfsb_adapter_livekit_fnc_callback`
- `jmfsb_adapter_livekit_fnc_canHear`
- `jmfsb_adapter_livekit_fnc_echo`
- `jmfsb_adapter_livekit_fnc_echoAnswer`
- `jmfsb_adapter_livekit_fnc_echoState`
- `jmfsb_adapter_livekit_fnc_echoTick`
- `jmfsb_adapter_livekit_fnc_ext`
- `jmfsb_adapter_livekit_fnc_gainOf`
- `jmfsb_adapter_livekit_fnc_hold`
- `jmfsb_adapter_livekit_fnc_keyed`
- `jmfsb_adapter_livekit_fnc_mic`
- `jmfsb_adapter_livekit_fnc_ptt`
- `jmfsb_adapter_livekit_fnc_quality`
- `jmfsb_adapter_livekit_fnc_roomAnswer`
- `jmfsb_adapter_livekit_fnc_roomJoin`
- `jmfsb_adapter_livekit_fnc_roomLeave`
- `jmfsb_adapter_livekit_fnc_setActive`
- `jmfsb_adapter_livekit_fnc_speaker`
- `jmfsb_adapter_livekit_fnc_srvEchoToken`
- `jmfsb_adapter_livekit_fnc_srvRoomToken`
- `jmfsb_adapter_livekit_fnc_talking`
- `jmfsb_adapter_livekit_fnc_tick`
- `jmfsb_adapter_livekit_fnc_vonOff`

</details>
