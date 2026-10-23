# Voice

`jmfsb_voice`

Voice on Arma 3's own VON (docs/DESIGN_VOICE.md, SPEC_TACNET D14 / D16 /
`voice_adapter`). RF decides who hears whom; a voice adapter carries the
audio - `jmfsb_adapter_von` (VON) by default. This addon knows nets, calls,
callbacks and sounds; it never names a VON command. NOT RUN IN GAME.

**VON only without TFAR or ACRE; then external-radio mode** (user,
2026-10-20: "our in game VoIP setup should only run if there is no TFAR or
ACRE", then "keep the ACRE and TFAR"). Set once in preInit, on every machine,
from its own CfgPatches (one RPT line says which):

- `jmfsb_voice_system` - `"von"`, `"tfar"` (`task_force_radio` or `tfar_core`
  loaded) or `"acre"` (`acre_main`); TFAR wins if both are loaded (a warning).
- `jmfsb_voice_active` - true only for `"von"`: VON is running.

Under TFAR or ACRE nothing of VON is set up, exactly as before: `jmfsb_adapter_von`
does not register, no channels, no enableChannel, no PTT / KeyDown / frame
handlers, no VON toggle block, no volume ticks, no server call logic, no
sounds. The core runs in **external-radio mode** instead: only that radio's
adapter is taken (`jmfsb_adapter_tfar` registers `"tfar"`, `jmfsb_adapter_acre`
`"acre"`), and a client tick (`fnc_externalTick`, every 0.1 s; the nets every
second) mirrors it: `nets`, `netState`, `activeNet`, `setActive` /
`stepActive`, `setEar` / `setMute` (where the radio has them), `quality`,
`talking` and the `jmfsb_voice_talk` event are served from it, so the RADIO
app, the HUD widget, the net rows, the talking box, BFT rings, reaction, the
scanner and the RADIO tile keep working. **Calls are VON only**: `call`,
`calls`, `callSlots`, `callbacks`, `contacts` and the rest answer empty and
do nothing, and the screens say so in words. `members` and `playCue` are VON
only too.

## API

The contract agents and devices code against. All functions are
`jmfsb_voice_fnc_<name>`; client calls act for the local player.

`jmfsb_voice_system` - `"von"`, `"tfar"` or `"acre"`. `jmfsb_voice_active` -
VON is running (system `"von"`). Under TFAR / ACRE the net functions answer
for that radio (nets for the local player only; voiceChannel -1) and the call
functions answer empty (`[]`, `""`, `false`, 0 or -1) and do nothing.

**External radio adapters** (`"tfar"`, `"acre"`; `registerAdapter` takes only
the one whose id is `jmfsb_voice_system`, and refuses them under VON).
Required hooks: `"nets"` `[] -> [[net, name, kind, -1], ...]` (the local
player's), `"netState"` `[] -> [[net, name, kind, active, muted, ear,
reachable], ...]` (the core adds the talkers), `"talking"` `[] -> [[unit,
net], ...]` (others). Optional: `"current"` `[] -> net`, `"setActive"` `[net]
-> bool`, `"ptt"` `[] -> [down, net]` (his own key), `"setEar"` `[net, ear] ->
bool`, `"setMute"` `[net, muted] -> bool`, `"linkQuality"` `[speaker, net] ->
0..1`, `"selfTest"`.

| Function | Arguments | Returns |
|---|---|---|
| `registerAdapter` | `[id, hooks]`; hooks is a hashmap of code. Required: `"join"` `[unit, net]`, `"leave"` `[unit, net]` (server), `"quality"` `[unit, net, q 0..1]`, `"talking"` `[] -> [[unit, net], ...]` (client, every frame: other speakers). Optional: `"channel"` `[net] -> number`, `"setActive"` `[net] -> bool`, `"current"` `[] -> net`, `"block"` `[level 0..3]` (0 none, 1 radio silence, 2 unconscious, 3 dead / no air), `"ptt"` `[] -> [down, net]` (his own key, every frame), `"keyed"` `[unit, net, on]` (a speaker's pushed key event), `"audience"` `[unit, net] -> units` (who hears him there; default `members`), `"selfTest"` `[]` | bool |
| `nets` | `[unit]` | `[[netId, name, kind, voiceChannel], ...]`; kind `"team"`, `"c2"`, `"a2g"`, `"veh"`, `"call"`, `"direct"`; voiceChannel -1 when none yet |
| `netState` | `[]` | per net of the local player `[netId, name, kind, active, muted, ear "L"/"B"/"R", reachable, talkers [[unit, quality], ...]]` |
| `activeNet` | `[]` | netId (`""` none) |
| `setActive` | `[netId]` | bool |
| `stepActive` | `[+1 or -1]` | the active netId after the step |
| `setEar` | `[netId, ear]` | nothing |
| `setMute` | `[netId, bool]` | nothing |
| `quality` | `[speaker, netId]` | 0..1 for the local listener (grace applied, mute not) |
| `talking` | `[]` | `[[unit, netId], ...]` heard by the local player now, himself included |
| `members` | `[netId, unit (optional: whose vehicle VEH means)]` | the players on that net, by the voice layer |
| `call` | `[[units], priority "ROUTINE"/"FLASH"]` | callId, or `""` with a reason notified |
| `callAdd` | `[callId, [units]]` | nothing - only the call's owner may add; anyone else gets `"notOwner"` |
| `callAccept` / `callDecline` / `hangUp` | `[callId]` | nothing |
| `callBack` | `[unit]` | nothing |
| `calls` | `[]` | `[[callId, state "ringing"/"live"/"outgoing", members, priority, startedAt, owner], ...]` - owner is who started the call (or who it passed to) |
| `callSlots` | `[]` | `[[slot 1..8, callId or "", membersCount], ...]` (server-wide) |
| `callbacks` | `[]` | `[[fromUnit, toUnit, requestedAt, state "waiting"/"held"], ...]` for the local player |
| `contacts` | `[]` | `[[unit, name, callsign, roleTags, reachable, inCall], ...]`; tags from `"SL"`, `"RTO"` (by `isRto`), `"MEDIC"`, `"HQ"` |
| `isRto` | `[unit]` | bool: he holds the RTO job - the one RTO test (see The RTO job); answers whether or not voice is active |
| `playCue` | `[cue, netId, volumeFactor (optional, 1)]` | sound id (for `stopSound`), -1 when nothing played |
| `selfTest` | `[]` | nothing (logs to the RPT; first line: `jmfsb_voice_system`, `jmfsb_voice_active` and the TFAR / ACRE patches found; under TFAR / ACRE the radio's nets, then its adapter's `selfTest`) |
| `customList` | `[]` | the RTO nets, `[[id, name, squads, uids, owner uid, owner name], ...]` |
| `customNets` | `[unit]` | the RTO net ids he is on (his squad's callsign or his UID named) |
| `canManageNets` | `[unit]` | bool: the RTO job, or a logged-in admin - what a client may draw; the server re-checks with `canFlash` |
| `netAdd` | `[name, squads, uids]` | bool sent; the server answers with the net published or `jmfsb_voice_netFailed` |
| `netMembers` | `[id, squads, uids]` | bool sent; both lists replaced |
| `netRemove` | `[id]` | bool sent |

CBA local events: `jmfsb_voice_talk` `[unit, netId, on]`, `jmfsb_voice_netsChanged`
`[]`, `jmfsb_voice_callRing` `[callId, fromUnit]`, `jmfsb_voice_callState`
`[callId, state]` - state is `"ringing"`, `"outgoing"`, `"live"`, `"warning"`
(a FLASH call is about to take the slot), `"ended"`, or a failure reason
`"noRoute"`, `"busy"`, `"noAnswer"`, `"declined"`, `"bumped"`, `"dropped"`,
`"refused"`, `"notOwner"` (an add by someone other than the call's owner) (callId `""` when the dial was refused on the client).

**The owner invites** (user, 2026-10-20): who starts a call owns it, and only the owner adds people. If he leaves a call that goes on, the longest-standing member becomes owner. There is no RTO pull-in.

Targeted CBA event `jmfsb_voice_keyed` `[speaker, netId, on]`: sent by the
speaker himself, once per key edge, to the clients of everyone who can hear
him on that net (see What the push-to-talk sends).

Times (`startedAt`, `requestedAt`) are `CBA_missionTime`.

## Nets

| Net id | Kind | VON channel | RF net | Who is on it |
|---|---|---|---|---|
| his squad's plan TEAM net (`sr`), else `TEAM <side> <callsign>` | team | 3 Group | same id | his group, if he carries a set |
| his squad's plan long range net (`lr`: a VON c2 net or `LR n`), else `C2` | c2 | the C2 custom channel | same id | everyone with a set |
| pilots: his squad's plan air-to-ground net (`a2g`), else the plan's first a2g net, else `A2G`; ground: his squad's plan a2g net, else `A2G` only when the plan has no a2g net at all | a2g | the A2G custom channel | same id | pilots and copilots by seat, the ground squads the plan lists (see A2G is pilots) |
| `CALL 1`-`CALL 8` | call | one custom channel per call | DATA | the call's members and ringing |
| an RTO net, named by its maker | custom | its own custom channel, kept for the mission | same id | the squads and players the RTO put on it (see RTO nets) |
| `VEH` | veh | 4 Vehicle | none | crew (not cargo) of a land vehicle, aircraft or boat |
| `DIRECT` | direct | 5 Direct | none | everyone |

- **The PAC plan is the one plan** (`jmfsb_pac_fnc_netPlan`, plan nets
  `[id, band, "sr" | "lr" | "a2g", slot]`). A player's TEAM, C2-kind and
  A2G-kind nets are his squad's (the squad named by his group's callsign)
  from `jmfsb_pac_fnc_netPlanSquad [squad, "sr" | "lr" | "a2g"]`, which
  answers for the VON plan (`vonTeamNets`, `vonNets`; nets with no slot) and
  for the old tfarNets slots alike; an answer the plan does not list is not
  used. Answers are cached per squad and kind and the cache is emptied on
  every plan refresh (each second). Without that function: the tfarNets row
  named after his callsign gives the slot, else the plan's fallback slot
  (that plan has no air-to-ground nets). Plan kind `sr` is a TEAM net, `lr`
  a C2-kind net, `a2g` an A2G-kind net. pac makes the plan's nets in RF
  (`netPlanSync`); this addon makes only `C2`, `A2G` and the TEAM nets of
  groups the plan does not name. Without pac every group gets its own TEAM
  net and everyone `C2` and `A2G`.
- **One VON channel, several nets.** Every C2-kind net rides the C2 custom
  channel and every A2G-kind net the A2G custom channel: a listener's volume
  for a speaker is worked out on the speaker's own net, so someone on `LR 2`
  hears nothing of `LR 1`. A plan short range
  net shared by two groups is still two Group channels in VON.
- **Sets** are RF's to recognise (`jmfsb_rf_fnc_carriedSets`: radio slot and
  radio bag) plus the vehicle set of a crew seat. Each becomes an RF node
  `voice_<uid>_<sr|lr|veh>` holding the fill: his TEAM net, his C2-kind net,
  his A2G-kind net when he is on one, and DATA. No set, no radio nets: only VEH and DIRECT.
- **Membership changes only for keys, fills, calls and pilot seats.** The server reads each
  player's fill back from RF every second (the roster) and calls the
  adapter's join / leave when a net comes or goes. A flickering link changes
  volume, never membership.

## A2G is pilots

User, 2026-10-20 ("who counts as air: pilots"). `a2gNet [unit]` answers his
A2G-kind net, `""` for none:

- **Air** (`jmfsb_voice_air` true on him): the driver of an Air vehicle (a
  parachute is not one) or a man in one of its copilot turrets (turret config
  `isCopilot`). He is on his squad's plan a2g net, else the plan's first a2g
  net, else `A2G`. Drone operators and door gunners are not air.
- **Ground:** his squad's plan a2g net. With no a2g net in the plan at all
  (no pac, the tfarNets plan, a VON plan without an a2g row) the default plan
  puts everyone on `A2G`; a plan with a2g nets that does not name his squad
  puts him on none.
- `airSeat` (client) sets `jmfsb_voice_air` on his own unit, public and only
  when it changes, on `GetInMan`, `GetOutMan` and `SeatSwitchedMan` (CBA class
  events on CAManBase, read the next frame), on his Killed and Respawn and once
  at start - never per frame. The fill holds the A2G net only while he is on
  one, so the server's roster joins and leaves him on the next tick.

## The RTO job

User, 2026-10-20: the RTO console (MANAGE and the permission table's RTO
column) is a player job, not admins only. `isRto [unit]` is the one test, used
by the RTO contact tag, the FLASH right (`canFlash`: the RTO or a logged-in
admin) and the tablet's radio role (`jmfsb_tacpad_apps_fnc_radioRole`, which
the tablet and small-device MANAGE tabs and the CALLS FLASH toggle read). He
is the RTO when any of these holds:

- `isRTO` true on him: a PAC skill effect (`trait:isRTO` / `var:isRTO=true`,
  his own or his role's granted skills) or the mission's own setVariable;
- `RTO` among his PAC skill tags (`jmfsb_pac_skillTags`);
- his role description (the part before any `@`) has one of the whole words
  `RTO`, `RADIO`, `JTAC`, `FAC`.

**The manpack is not the job** (user, 2026-10-20: "can we lose the LR"):
wearing a long range set no longer makes a man the RTO. The RTO is whoever
PAC (the flag or the tag) or his slot says. Nothing needs a manpack for C2
either: `fill` gives every set he carries (radio-slot handheld, bag, vehicle
seat) the same fill, his C2-kind net included, and the staging zones' and
patrol bases' base stations relay C2 round each site and link the sites by
satellite (`jmfsb_pac_fnc_baseStation`, docs/DESIGN_RF.md "Base stations").
A manpack is optional kit that extends range away from the bases.

## Mesh drives the voice

- Every second each client works out, for every other player and each of his
  radio nets, the RF link quality from his slice: the best path between any
  of his nodes and any of the speaker's, on the net (a CALL on DATA).
- **Grace time** (setting, 3 s): when a route drops the last quality is kept
  that long before the speaker goes to 0.
- A muted net counts as 0. The result goes to the adapter's `quality` hook,
  which for VON becomes the speaker's volume for this listener.
- **Cut-offs** (`blockLevel`, checked every frame and on his Killed /
  Respawn, given to the adapter's `block` hook):
  - radio silence, EMCON 3 on any of his nodes (from the roster): the radio
    nets closed (TEAM, C2-kind, A2G, CALL);
  - unconscious (lifeState `INCAPACITATED`, which ACE unconsciousness sets):
    every radio closed, the VEH intercom too; DIRECT stays open;
  - dead, or unable to breathe (`isAbleToBreathe` false: underwater without
    a rebreather): DIRECT closed too.

  A key-down on a closed net plays the blocked tone and notifies the reason;
  a transmission a cut-off closes is ended (its key-up goes out). When the
  condition ends the channels are reopened as they were and the PTT is put
  back on the active net. RF's `tx` and `activeNet` node state follow his
  transmissions.

## What the push-to-talk sends

**Every PTT input counts** (the adapter's `ptt` hook; VON: inputAction of
Push To Talk, the VON toggle and the per-channel keys All, Side, Command,
Group, Vehicle, Direct). A per-channel key transmits on that channel, so the
transmission belongs to the net mapped to it (Group = his TEAM net, Vehicle =
VEH, Direct = DIRECT, untouched).

**Speaker-pushed keying.** On his key-down and key-up the speaker himself
sends `jmfsb_voice_keyed` `[speaker, net, on]` - one event per edge, never per
frame - to everyone who can hear him there (the adapter's `audience`, without
him; nobody for DIRECT). Each listener's client sets his volume at once from
its current quality (the adapter's `keyed`), raises `jmfsb_voice_talk` and
plays the squelch and static. So talking indicators, sounds and volume do not
depend on the engine reporting remote players; the adapter's per-frame check
(VON: `getPlayerChannel`) only covers a speaker whose key-down did not arrive.
On a radio net he holds no set for the blocked tone plays (the event still
goes out, so he is muted at the listeners).

The game's own push-to-talk key sends on the current VON channel.
`setActive` / `stepActive` (the device arrows) set the current channel to the
active net's: TEAM = Group (3), C2-kind = the C2 custom channel, A2G = its
custom channel, a CALL = its custom channel, VEH = Vehicle (4), DIRECT = Direct
(5). The game's channel-change keys still work: a channel that is one of his
nets becomes the active net. A call that goes live becomes the active net; the
net before it comes back when it ends. The game's per-channel push-to-talk
keys (Group, Vehicle, Direct) send on that channel whatever the active net is.

## Calls

- One custom channel per call, up to 8 people, 8 calls at once.
- **Dial** (`call`): needs reach on DATA. The client refuses with nobody
  reachable; the server re-checks every callee, refuses those out of reach
  (no route) and those in another call (busy), and rings the rest. A ringing
  call is no answer after the ring time (setting, 20 s).
- **Accept / decline / hang up / add** as the API. Adds ring until they
  accept, skip people out of reach or busy, and stop at 8. The call goes live
  at two members and ends when one is left; the caller hanging up before
  anyone answered ends the dial.
- **Drops:** a member of a live call with no DATA route to any other member
  for longer than the drop time (setting, 10 s) is dropped.
- **FLASH:** with every slot taken, a FLASH call from the RTO (`isRto`) or an admin marks
  the oldest ROUTINE call; its members hear the priority warning for the bump
  warning time (setting, 3 s), then it ends and the FLASH dial is made again.
- **Callback** (`callBack`): held by the server. Expires after 15 min
  (setting); one per pair, 3 per player (setting); waits while either person
  is in a call, held while either is on EMCON 3; when both reach each other on
  DATA and a slot is free, both phones ring.
- Failures are notified with the reason; no route, busy and no answer say
  CALL BACK is available.

## Sounds

The radio's own sounds are the game's (`A3\Dubbing_Radio_F\sfx\*.ogg`, they
ship with Arma 3); the net switch, blocked and call tones are ours,
`sounds/*.wav`, made by `tools/voice_sounds.py` (16-bit mono, deterministic).
Every cue is played locally by file path (`playCue`, table `CUES` in
`script_component.hpp`): both ears with `playSoundUI`, one ear with a local
`playSound3D` to that side of the camera. No CfgSounds.

| Cue | Sound | When |
|---|---|---|
| `txChirp` / `rogerBeep` | game `in2b.ogg` / `out2b.ogg` | he starts / stops talking on a radio net |
| `squelchOpen` / `squelchTail` | game `in2a.ogg` / `out2a.ogg` | a speaker he can hear (mesh volume above 0) starts / stops |
| `static` | game `radionoise1.ogg` (5.7 s) | under that speaker at (1 - quality); started again after 5.5 s or when his quality changes, stopped (`stopSound`) when he stops |
| `cutTone` | game `out2c.ogg` | that speaker's route drops mid-transmission |
| `netSwitch` | ours | the active net changes |
| `blocked` | ours | he talks with no route or no set, or keys a net a cut-off closes |
| `dialTone`, `ringback` | ours | he dials; his dial rings out |
| `ring` | ours | a call or callback rings for him |
| `busy` | ours | a call failed (no route, busy, no answer, declined, dropped, bumped) |
| `connect` / `hangUp` | ours | his call goes live / ends or someone leaves |
| `joinChime` | ours | someone joins his call |
| `priorityWarning` | ours | his ROUTINE call is about to be bumped |

Pitch per net: C2 low, TEAM mid, A2G high, CALL two-tone (radio cues only).
Settings (each player's own): radio beeps, call beeps, beep volume, pitch per
net, static by quality.

## RTO nets

User, 2026-10-22: "add an rto skill or trait, and on the radio app allow rtos
to add custom channels". An RTO (`isRto`) or a logged-in admin makes a net on
the tablet's RADIO > MANAGE (`netAdd [name, squads, uids]`), peoples it by
squad callsign and by player (`netMembers`), and removes it (`netRemove`).
The server holds them (`GVAR(customNets)`) and publishes them as
`jmfsb_voice_customPub`; every machine's `planRefresh` folds the rows into the
plan as kind `custom`, so chips, mesh, RF, the roster and the adapter treat
one like C2 - except that each has its own VON custom channel for the rest of
the mission (the adapter's `reserve` hook; a removed net's channel is kept by
name and reused), so the calls get what is left of the ten. `jmfsb_voice_customNetsMax`
(server, default 2) caps how many exist at once. Every request is re-checked
on the server with `canFlash`; a refusal comes back as `jmfsb_voice_netFailed`
(`notRto`, `badName`, `taken`, `full`, `noChannel`, `unknown`) and is said in
words. The id is the name, upper-cased: 2-10 letters, digits, spaces or
dashes, none of the reserved ids. Under TFAR / ACRE there are none.

## Not built

- Patches, listen-only members, rekey, PACE, EMCON and signal plan load /
  export: the RADIO app's MANAGE actions (no API for them here yet; the tabs
  show them as not built, with no buttons). Who may open MANAGE is decided
  (the RTO job above); of the actions only the RTO nets are built.
- Recorded voice notes (VON cannot record from script; DESIGN_VOICE.md).
- A loaded or captured key showing its net while held: membership follows the
  fill only.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_rf`
- `jmfsb_notify`
- `cba_main` _(external)_
- `cba_xeh` _(external)_
- `cba_settings` _(external)_

## Ships

89 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_voice_grace` | SLIDER | Grace time (sec) |
| `jmfsb_voice_ringTime` | SLIDER | Ring time (sec) |
| `jmfsb_voice_callDrop` | SLIDER | Call drop time (sec) |
| `jmfsb_voice_bumpWarning` | SLIDER | FLASH bump warning (sec) |
| `jmfsb_voice_callbackExpire` | SLIDER | Callback expiry (min) |
| `jmfsb_voice_callbacksPerPlayer` | SLIDER | Callbacks per player |
| `jmfsb_voice_radioBeeps` | CHECKBOX | Radio beeps |
| `jmfsb_voice_callBeeps` | CHECKBOX | Call beeps |
| `jmfsb_voice_beepVolume` | SLIDER | Beep volume |
| `jmfsb_voice_pitchPerNet` | CHECKBOX | Pitch per net |
| `jmfsb_voice_staticByQuality` | CHECKBOX | Static by quality |
| `jmfsb_voice_customNetsMax` | SLIDER | RTO nets at once |

## Functions

<details><summary>89</summary>

- `jmfsb_voice_fnc_a2gNet`
- `jmfsb_voice_fnc_activeNet`
- `jmfsb_voice_fnc_airSeat`
- `jmfsb_voice_fnc_applyBlock`
- `jmfsb_voice_fnc_blockLevel`
- `jmfsb_voice_fnc_blockNeed`
- `jmfsb_voice_fnc_c2Net`
- `jmfsb_voice_fnc_call`
- `jmfsb_voice_fnc_callAccept`
- `jmfsb_voice_fnc_callAdd`
- `jmfsb_voice_fnc_callBack`
- `jmfsb_voice_fnc_callDecline`
- `jmfsb_voice_fnc_callFailed`
- `jmfsb_voice_fnc_callSlots`
- `jmfsb_voice_fnc_callbacks`
- `jmfsb_voice_fnc_calls`
- `jmfsb_voice_fnc_canFlash`
- `jmfsb_voice_fnc_canGlobal`
- `jmfsb_voice_fnc_canManageNets`
- `jmfsb_voice_fnc_channelUse`
- `jmfsb_voice_fnc_checkActive`
- `jmfsb_voice_fnc_clientTick`
- `jmfsb_voice_fnc_contacts`
- `jmfsb_voice_fnc_crewOf`
- `jmfsb_voice_fnc_customList`
- `jmfsb_voice_fnc_customNets`
- `jmfsb_voice_fnc_customValid`
- `jmfsb_voice_fnc_dataReach`
- `jmfsb_voice_fnc_externalTick`
- `jmfsb_voice_fnc_fill`
- `jmfsb_voice_fnc_frame`
- `jmfsb_voice_fnc_global`
- `jmfsb_voice_fnc_hangUp`
- `jmfsb_voice_fnc_heard`
- `jmfsb_voice_fnc_inCall`
- `jmfsb_voice_fnc_isRto`
- `jmfsb_voice_fnc_keyed`
- `jmfsb_voice_fnc_linkQuality`
- `jmfsb_voice_fnc_members`
- `jmfsb_voice_fnc_netAdd`
- `jmfsb_voice_fnc_netFailed`
- `jmfsb_voice_fnc_netKind`
- `jmfsb_voice_fnc_netMembers`
- `jmfsb_voice_fnc_netName`
- `jmfsb_voice_fnc_netQuality`
- `jmfsb_voice_fnc_netRemove`
- `jmfsb_voice_fnc_netState`
- `jmfsb_voice_fnc_nets`
- `jmfsb_voice_fnc_nodeIds`
- `jmfsb_voice_fnc_planNet`
- `jmfsb_voice_fnc_planRefresh`
- `jmfsb_voice_fnc_playCue`
- `jmfsb_voice_fnc_playSound`
- `jmfsb_voice_fnc_quality`
- `jmfsb_voice_fnc_radios`
- `jmfsb_voice_fnc_reachable`
- `jmfsb_voice_fnc_receiveCalls`
- `jmfsb_voice_fnc_receiveRoster`
- `jmfsb_voice_fnc_registerAdapter`
- `jmfsb_voice_fnc_rfNet`
- `jmfsb_voice_fnc_ringTick`
- `jmfsb_voice_fnc_roles`
- `jmfsb_voice_fnc_selfTest`
- `jmfsb_voice_fnc_serverTick`
- `jmfsb_voice_fnc_setActive`
- `jmfsb_voice_fnc_setEar`
- `jmfsb_voice_fnc_setMute`
- `jmfsb_voice_fnc_srvAdd`
- `jmfsb_voice_fnc_srvAnswer`
- `jmfsb_voice_fnc_srvCall`
- `jmfsb_voice_fnc_srvCallTick`
- `jmfsb_voice_fnc_srvCallback`
- `jmfsb_voice_fnc_srvCallbacks`
- `jmfsb_voice_fnc_srvCheck`
- `jmfsb_voice_fnc_srvEnd`
- `jmfsb_voice_fnc_srvLeave`
- `jmfsb_voice_fnc_srvNetAdd`
- `jmfsb_voice_fnc_srvNetMembers`
- `jmfsb_voice_fnc_srvNetPublish`
- `jmfsb_voice_fnc_srvNetRemove`
- `jmfsb_voice_fnc_srvPublish`
- `jmfsb_voice_fnc_srvStart`
- `jmfsb_voice_fnc_stepActive`
- `jmfsb_voice_fnc_talkSync`
- `jmfsb_voice_fnc_talking`
- `jmfsb_voice_fnc_teamNet`
- `jmfsb_voice_fnc_toTeam`
- `jmfsb_voice_fnc_transmit`
- `jmfsb_voice_fnc_updateQuality`

</details>
