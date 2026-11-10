# VON Adapter

`jmfsb_adapter_von`

The default voice adapter of `jmfsb_voice`: Arma 3's own VON
(docs/DESIGN_VOICE.md). The only addon that uses the VON commands for voice.
Registers itself as `"von"` in preInit; another VON-mode adapter registered
replaces it. NOT RUN IN GAME.

**The fallback only:** the voice is LiveKit (`jmfsb_adapter_livekit`); this
adapter runs only while the game's VON is the system chosen
(`jmfsb_voice_system` "von": the setting JMSB - Voice > Voice system, or
Automatic on a server without the voice extension;
`jmfsb_voice_fnc_selectSystem`, read at `CBA_settingsInitialized`). Under
LiveKit, and under "none" (the server's system cannot run here), the postInit
sets nothing up - no channels, no enableChannel, no handlers. The server's
system is everyone's: a client starts on `jmfsb_voice_systemReady`, once it
has taken it. TFAR and ACRE were removed on 2026-10-31 (DEC1). Its settings
are the page JMSB - Voice (Built-in) > VON.

## Channels

| ID | VON channel | Use | Here |
|---|---|---|---|
| 0 | Global | admin broadcast | talk: logged-in admins and the host only |
| 1 | Side | not used | voice off (text chat left as the mission set it) |
| 2 | Command | not used (C2 replaces it) | voice off |
| 3 | Group | TEAM net | voice on; off under radio silence and the cut-offs |
| 4 | Vehicle | crew intercom | the mission's; passengers muted by volume; voice off while unconscious, dead or out of air, then put back |
| 5 | Direct | local 3D voice | the mission's, never muted; voice off while dead or out of air, then put back |
| 6+ | custom | C2, A2G, CALL 1-8, the RTO nets | made with `radioChannelCreate`; voice off under radio silence and the cut-offs |

- **Custom channels** are made on the server, C2 and A2G at mission start (so
  they take the lowest free ids), a CALL channel on its slot's first call. VON
  cannot delete one: an ended call's channel is emptied and reused. Channels a
  mission made itself are left alone; when all ten are taken a net has none
  (and logs a warning). The map `[[key, id], ...]` is published as
  `jmfsb_adapter_von_channelMap`.
- **Eight calls at once, here only.** The `channelUse` count is what keeps
  the voice core at CALL 1-8 (`jmfsb_voice_fnc_srvSlot`): on the voice
  server, which counts no channels, calls have no limit (user, 2026-11-01).
- **An RTO net** (voice kind `custom`, addons/voice/README.md "RTO nets") is
  keyed by its id like a CALL and gets its own channel when the voice core
  asks through the `reserve` hook (`fnc_reserve`: `ensureChannel`, false
  when the ten are taken) - at creation, so a net with no channel is refused
  rather than silent. Removed, its channel stays made under its name and is
  handed back if the name is made again.
- **Membership** (hooks `join` / `leave`, server): `radioChannelAdd` /
  `radioChannelRemove` on the net's custom channel. Every C2-kind net shares
  the C2 channel, every A2G-kind net (the PAC plan's air-to-ground nets too)
  the A2G channel; on those channels `netOf` gives the speaker's own C2- or
  A2G-kind net. TEAM needs nothing: Group follows the Arma group.
- **Who may talk** is checked every second on each client with
  `enableChannel` (voice only), so an admin who logs in gets Global, and at
  once when the voice core's cut-off level changes (hook `block`: 1 radio
  silence, 2 unconscious, 3 dead / no air). Vehicle and Direct are only
  closed by a cut-off; their voice state before it is kept and put back.

## Push-to-talk

- **Every PTT input** (hook `ptt`, every frame): inputAction of
  `PushToTalkAll`, `PushToTalkSide`, `PushToTalkCommand`, `PushToTalkGroup`,
  `PushToTalkVehicle`, `PushToTalkDirect` (each sends on its own channel),
  `pushToTalk` and `voiceOverNet` (the current channel). The channel's net is
  the transmission's (`netOf`). With no key held his own `getPlayerChannel` is
  the fallback.
- **Who hears a key** (hook `audience`, for the speaker's pushed key event):
  Group = the players of his Arma group, set or not; Vehicle = the players
  aboard, passengers too; a custom channel = every player on a net that rides
  it (all C2-kind nets share one, all A2G-kind nets another), by the nets
  the server has him on (`jmfsb_voice_fnc_rosterNets`), not the speaker's
  own reading of them. Direct: nobody - it is never touched.
- **The VON toggle is blocked:** a KeyDown handler on the mission display
  (46) swallows `actionKeys "VoiceOverNet"` and says once: bind Push To Talk
  (Configure > Controls > Multiplayer). At mission start he is told when Push
  To Talk has no key, or his VON volume (`getAudioOptionVolumes` index 3) is
  below 0.1.

## Talk keys, open channel, volume (2026-10-24)

The engine owns the microphone - no script starts a transmission - so the
keys move the **current channel**, which is what Arma's Push To Talk sends on
and what Arma's own voice activation (Options > Audio) transmits on.

- **Voice: PTT 1-4 (hold)** (2026-10-30) - every talk key is Caps Lock with
  a modifier, because Caps Lock is Arma's own Push To Talk and the engine
  sees it whatever else is held: PTT 1 is Caps Lock and the mic on the active
  net while held; PTT 2-4 are Ctrl, Alt and Shift + Ctrl with Caps Lock, the
  mic on the net the tablet's RADIO app gave each (`jmfsb_voice_fnc_pttNet`:
  net 2, 3, 4 of his list until set). Two held: the last pressed talks. The
  bind is not consumed, so Arma's Push To Talk on Caps Lock still opens the
  mic. **Voice: talk local (hold)** - Shift + Caps Lock - the mic on Direct;
  the modifier released before the key still ends the hold (`fnc_hold`: the
  key's release arrives as PTT 1's). Under voice activation a held key alone
  is the whole radio: hold and speak. Under push to talk they pick the
  channel the Push To Talk key sends on. **A PTT 2-4 key VON will not give
  its net** (no net set, the net has no channel, or `setCurrentChannel` is
  refused - not yet a member; PLAN_VOICE_EW_PLAY V4) sends nothing: the
  channel he is on has its voice held off while the key is down
  (`fnc_holdOff`; `fnc_channels` leaves it alone meanwhile), the `ptt` hook
  reports no key, and the key says why once per press. Before, the engine
  sent on PTT 1's net.
- **Voice activation** (setting, off by default): the player says his VON is
  on voice activation. His mic then sits on the **open channel** when no key
  is held - LOCAL (Direct) by default, or his active net; **Voice: open
  channel NET / LOCAL** (numpad /) flips it, and the RADIO app shows the
  word. **Voice activation on calls** (on): a live call is the open channel
  for as long as it lasts. The missing-Push-To-Talk warning is not given.
- **Radio voice volume** (setting, 0-100%, on the RADIO app and numpad - / +):
  scales every radio speaker on top of the mesh; Direct is untouched.

## Volume (the mesh)

VON's volume is per speaker, for this listener (`setPlayerVoNVolume`), not per
channel, so it follows the channel the speaker is on now:

- not talking, Direct, Global: full - his 3D voice is never touched;
- Vehicle: full between crew of the same vehicle, else muted;
- Group and custom channels: from the quality the voice core gave for his net
  (hook `quality`, grace and mute applied) - muted at 0, **Volume at the
  weakest link** (setting, 0.3) just above 0, rising to full at 1;
- Side, Command: muted.

**A pushed key sets it at once** (hook `keyed`): the speaker's own key-down
event carries his net, so this listener's volume for him is set from the
current quality before the engine reports anything, and he counts as talking
on that channel until his key-up (or he dies, respawns or leaves). The
`talking` hook runs every frame: pushed speakers first, then `getPlayerChannel`
of every other player as the FALLBACK for a key-down that did not arrive (no
VON event exists). When a speaker's channel changes his volume is set for the
new channel in the same pass, so his first words come at the mesh volume. Link
quality as volume fade plus the voice core's static is all VON allows: no ear
split for voice, no real distortion.

## Active net

`setActive` is `setCurrentChannel` to the net's channel: the game's
push-to-talk sends on the current channel. VON refuses a custom channel the
player is not yet a member of; the voice core retries. `current` maps the
current channel back to a net, so the game's own channel keys move the active
net.

## Self test

`[] call jmfsb_voice_fnc_selfTest` runs the five "Tests to run first", every
line to the RPT tagged `VON T1`-`T5`. T1 and T5 at once, T2-T4 over 15 s:

1. `setPlayerVoNVolume` per listener per speaker: set 0.5 on every other
   player, read back, restore. Per channel by ear.
2. `enableChannel` with voice off still hears: Group voice off for the window;
   group members seen talking on Group are listed - did you hear them? The
   cut-offs and radio silence rely on it. Expected to pass: a script-only VON
   radio we reviewed keeps channel voice off except while the key is held,
   and its listeners hear.
3. `getPlayerChannel` speed: ms and frames from a push-to-talk press (any PTT
   input) to his own channel change; the count of remote channel changes (0
   while others talk means it does not report remote players) and of pushed
   key events received. `getPlayerChannel` is now only the fallback.
4. Custom channel add / remove delay: the server takes him off C2 and back on
   3 s later; the server's times and the membership changes seen on this
   client (`radioChannelInfo`) are logged.
5. Vehicle channel crew only: in a vehicle, crew or not, `channelEnabled 4`,
   whether `setCurrentChannel 4` takes (his current channel is put back). No
   command sets Vehicle membership. `enableChannel` on GetInMan / GetOutMan is
   a workable gate, but it opens the channel for everyone aboard, passengers
   too, so passengers stay muted by volume.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_voice`
- `jmfsb_notify`
- `cba_main` _(external)_
- `cba_xeh` _(external)_
- `cba_settings` _(external)_
- `A3_Ui_F` _(external)_

## Ships

35 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_adapter_von_volumeFloor` | SLIDER | Volume at the weakest link |
| `jmfsb_adapter_von_masterVolume` | SLIDER | Radio voice volume |
| `jmfsb_adapter_von_vad` | CHECKBOX | Voice activation |
| `jmfsb_adapter_von_vaCalls` | CHECKBOX | Voice activation on calls |

## Functions

<details><summary>35</summary>

- `jmfsb_adapter_von_fnc_applyOpen`
- `jmfsb_adapter_von_fnc_applyVolume`
- `jmfsb_adapter_von_fnc_audience`
- `jmfsb_adapter_von_fnc_block`
- `jmfsb_adapter_von_fnc_channel`
- `jmfsb_adapter_von_fnc_channelKey`
- `jmfsb_adapter_von_fnc_channelUse`
- `jmfsb_adapter_von_fnc_channels`
- `jmfsb_adapter_von_fnc_countChannels`
- `jmfsb_adapter_von_fnc_current`
- `jmfsb_adapter_von_fnc_ensureChannel`
- `jmfsb_adapter_von_fnc_global`
- `jmfsb_adapter_von_fnc_hold`
- `jmfsb_adapter_von_fnc_holdOff`
- `jmfsb_adapter_von_fnc_join`
- `jmfsb_adapter_von_fnc_keyDown`
- `jmfsb_adapter_von_fnc_keyed`
- `jmfsb_adapter_von_fnc_leave`
- `jmfsb_adapter_von_fnc_liveCallChannel`
- `jmfsb_adapter_von_fnc_netOf`
- `jmfsb_adapter_von_fnc_openChannel`
- `jmfsb_adapter_von_fnc_openState`
- `jmfsb_adapter_von_fnc_openToggle`
- `jmfsb_adapter_von_fnc_ptt`
- `jmfsb_adapter_von_fnc_quality`
- `jmfsb_adapter_von_fnc_reserve`
- `jmfsb_adapter_von_fnc_selfTest`
- `jmfsb_adapter_von_fnc_selfTestFrame`
- `jmfsb_adapter_von_fnc_setActive`
- `jmfsb_adapter_von_fnc_talking`
- `jmfsb_adapter_von_fnc_testChannel`
- `jmfsb_adapter_von_fnc_testResult`
- `jmfsb_adapter_von_fnc_voiceChatLoad`
- `jmfsb_adapter_von_fnc_volumeStep`
- `jmfsb_adapter_von_fnc_warn`

</details>
