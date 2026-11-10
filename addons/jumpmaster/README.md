# Jumpmaster

`jmfsb_jumpmaster`

HALO, HAHO and static-line jumps for a squad, asked for by its leader
(user, 2026-10-30). **By message since 2026-11-02** (user: "also want to
change the halo/haho/static app in to a message based one" ... "it also
needs a work flow"): the jump aircraft is a support asset, the leader files
a JUMP REQUEST to it in TAC//MSG, and the aircraft answers in the thread.
The JUMPMASTER app - its page, tile, walking-view button and map pick - is
gone; the flight is the same. Built, not seen in game.

## The JMSB - Jump Aircraft module

User, 2026-11-02: "Jump aircraft module" - class, call sign, altitudes,
side, several jump aircraft per side. Built, not seen in game.

**One module is one jump aircraft**, asset `jump:<n>` (its place in the
placement list), box `B:SUPPORT:jump:<n>`, listed in TAC//MSG by its call
sign. Place as many as wanted, on one side or several. Placed in Eden or by
Zeus (Zeus: the defaults below). It flies one run at a time.

**Virtual until tasked** (user, 2026-11-02: "all support aircraft needs to be
virtual till tasked, then they spawn in at alt over the support module
location"; it replaced the same day's "on station from the start"; built,
not seen in game). No aircraft exists at mission start: the row reads IDLE
(ready) with its respawns. The JUMP REQUEST accepted is the task: at the
WILCO the aircraft is made in the air **directly over the module, 2000 m
up**, engines on and flying (a plane fast enough not to stall), clear of any
other aircraft (the support core's `spawnAirborne`), dark, and orbits the
module - 1500 m round (a plane) or 800 m (a helicopter) - for the leader's
BOARD. After the run - or a stand-down, ABORT before BOARD, a run never
boarded, out of time - it flies back to the module at 2000 m and is
**removed there** (inside 600 m, nobody aboard; after 20 min wherever it is),
crew and airframe, no wreck. It is virtual again; the next JUMP REQUEST makes
a fresh one, full of fuel. While it flies home the row reads RTB. Not made at
the request: CANTCO `COULD NOT LAUNCH`.

**Drone escorts** (user, 2026-11-02: "drone escorts is based on lz security
for helos and always for fix wings"; support_air's `escortLaunch`). A plane
always takes two of the **Fixed-Wing Escort Class** (empty: the side's
vanilla UCAV), made beside it over the module, flying with it and removed
with it. A helicopter takes two of the **Rotary Escort Class** only for a
YELLOW or RED LZ security - a JUMP REQUEST has none, so none.

| Attribute | Default | What it does |
|---|---|---|
| Aircraft Class | blank | The class picker's crewed planes and helicopters with seats. Blank: the side's cargo aircraft (Blackfish for BLUFOR and independents, Xi'an for OPFOR). A class not in the mission, or not an aircraft: no asset, RPT warning |
| Callsign | SKYTRAIN | The TO picker's and `@` list's name, and the signature on its answers. Give each module its own |
| HALO Altitude (m) | 6000 | 1000-10000 |
| HAHO Altitude (m) | 6000 | 1000-10000 |
| Static Line Altitude (m) | 150 | 100-500 |
| Passes By Default | 1 | 1-4, when the card leaves PASSES empty |
| Exit By Default | Automatic | Automatic or Manual, when the card ticks no EXIT |
| In The Aircraft | Seats | Seats, or standing in the bay |
| Cooldown (sec) | 120 | After a run is over, before the next card. The row reads REARMING |
| Respawns | 0 | How many aircraft may be lost and replaced. Each loss uses one; going home uses none. 0: none - after its first loss the jump aircraft leaves TAC//MSG |
| Respawn Delay (sec) | 300 | After a loss, before the next JUMP REQUEST can make a new aircraft. The row reads REARMING (REPLACING IN n S) meanwhile |
| Fixed-Wing Escort Class | blank | The drone a plane's two escorts fly, always. Blank: the side's vanilla UCAV. Not a fixed-wing class: none, one RPT warning |
| Rotary Escort Class | blank | The drone a helicopter's two escorts fly, for a YELLOW or RED LZ only (a jump has none). Blank: none |

**The respawn count** (user, 2026-11-02: "make sure there is a respawn count
for each support, default no respawns"; virtual until tasked the same day).
It took the place of **Sorties** (retired with its SPENT); there is no
**Response Delay** - the aircraft is made at the request. Missions that set
them still load; the values are not read. Only a **loss** uses a respawn: the
aircraft destroyed, its pilot dead, or unable to fly (`airLost`). With a
respawn left, one is used and the row reads REARMING for the Respawn Delay,
then the module is ready again and the next request makes a new aircraft;
with none, the module is gone: no row, every card CANTCO `UNABLE - NO
AIRFRAME`, and the side's own aircraft does not come back. A run waiting for
its BOARD when the aircraft is lost is CLOSED `AIRCRAFT LOST`; a run in
flight ends `AIRCRAFT LOST`. Going home and being removed is not a loss.

**Fuel**: each request makes a fresh aircraft with a full tank; nothing is
refuelled in the air.

**The side** is never typed (D59): the side of the units synced to the
module; none synced, the players' side from the slots (as support_air's
modules read it; a dedicated server with no slot to read waits for the
first player).

**A side with no module** keeps one jump aircraft of its own, as before the
module: `jump:west` / `jump:east` / `jump:guer`, SKYTRAIN, the side's cargo
aircraft, flown with the settings' altitudes (HALO / HAHO one value),
passes, exit and bay, no cooldown, no respawn count, one run per squad at a
time. It is **not made over a module**: it is made at the run-in the frame
after its WILCO, the stick put aboard at once (no BOARD), and removed when it
leaves - the flow before 2026-11-02. Placing one module of a side takes that
side's own aircraft away, also once the module is gone.

**The settings** (decided 2026-11-02): which aircraft is WHAT, not an
operation value, so the Jump aircraft class setting is retired - a side's
own flies the side's cargo aircraft. HALO / HAHO altitude, Static line
altitude, Passes by default, Exit by default and In the aircraft are
operation values and stay, for a side's own aircraft only. HALO pull
altitude, Wind drift factor, HALO masks and Parachutes are every jump's.

## The workflow

Who sends what, in order. The leader writes in TAC//MSG; the jump aircraft
answers as itself in the thread under its call sign - SKYTRAIN below. D9 is
the support core's prompt wait: asked again at 3 min, its end at 5 min.

1. **Get ready.** Every man of the squad who jumps: a parachute (the
   Parachutes setting); HALO and HAHO a mask too (the HALO masks setting).
   The squad gathers at the pickup - within 200 m of it.
2. **Leader: NEW, card JUMP REQUEST, TO SKYTRAIN** (or `@SKYTRAIN`; each
   jump aircraft of his side is listed by its call sign). Tick the TYPE
   (HALO, HAHO or STATIC - required); PASSES 1-4 (empty: the aircraft's
   passes by default); EXIT AUTO AT GREEN or MANUAL (none ticked: its exit
   by default); RED LIGHT and GREEN LIGHT - a map click or a marker, both
   required: the aircraft flies the line through them, red to green; PICKUP
   - a strip or a marker, empty is where the leader stands; REMARKS. SEND.
3. **SKYTRAIN, at once - the readiness check.** Not ready: CANTCO with the
   reason - `2 MEN WITHOUT A PARACHUTE`, `1 MAN WITHOUT A MASK` (HALO /
   HAHO), `NOBODY AT THE PICKUP`, `SQUAD LEADERS ONLY`, `TASKED` (a run is up
   for the squad, or the module's aircraft is flying one or waiting for its
   BOARD), `COOLDOWN n S`, `REPLACING IN n S` (its aircraft lost, the
   Respawn Delay running), `RTB` (the last aircraft still flying home to be
   removed), `UNABLE - NO AIRFRAME` (no respawn left), `COULD NOT LAUNCH`
   (the aircraft could not be made), `NO JUMP AIRCRAFT`. The thread is over;
   fix it and file again.
4. **SKYTRAIN: ROGER, WILCO** - one message: the type and altitude, the
   men, passes and exit, `BOARD TO RED LIGHT m:ss` (a module's: from the
   module at the class's cruise; a side's own: `RED LIGHT IN m:ss`), and `SHIFTED n M FOR
   WIND` when the wind moves the stick 20 m or more (the aircraft shifts both
   lights upwind itself, so the stick lands on the green light asked for);
   `n NOT AT THE PICKUP` for men of the squad left behind.
5. **A module's: the aircraft is made at the WILCO** over the module, 2000 m
   up, orbiting it (escorts with a plane). **SKYTRAIN asks** `ON STATION -
   SEND BOARD WHEN READY` (answers BOARD, ABORT; no 3 / 5 min waits - a run
   never boarded is stood down after 30 min, `NOT BOARDED - STOOD DOWN`).
   The aircraft orbits the module. **Leader: BOARD** (user, 2026-11-02: "have team leader send a
   board message then move the team to cargo") - the stick is counted again
   as at the request: not ready, it asks again with the reason (`2 MEN
   WITHOUT A PARACHUTE - SEND BOARD WHEN READY`) and waits for the next
   BOARD; ready, every man within 200 m of the pickup is moved aboard where
   he is (a cargo seat, or standing in the bay - In The Aircraft), and
   **SKYTRAIN: ON TASK** `STICK ABOARD - 8 MEN - RED LIGHT IN 2:40`. It
   leaves its orbit for the start of the run-in, 3 km short of the red light,
   climbing or coming down from 2000 m to the jump's altitude (user,
   2026-11-02: "static 2000 then move to jump alt, halo haho 6k": the
   module's Static Line Altitude, or HALO / HAHO Altitude, 6000 m by
   default), and turns in there: **INBOUND** `PASS 1 OF 2 - RED LIGHT IN
   1:12`. ABORT, RTB or CLOSE before BOARD: CLOSED `NOT BOARDED - STOOD
   DOWN`, the aircraft flies home to the module and is removed.
   **A side's own: SKYTRAIN: WHEELS UP** `8 ABOARD - RED LIGHT IN 1:12` the
   next frame, ON TASK: every man at the pickup put aboard, the aircraft made
   in the air 3 km short of the red light at the settings' altitude.
6. **SKYTRAIN: RED LIGHT**, FLASH, `PASS 1 OF 2 - STAND BY` (static line
   `STAND UP, HOOK UP`). JUMP opens in every man's action menu; each man's
   notify rail says RED LIGHT.
7. **SKYTRAIN: GREEN LIGHT - GO**, FLASH. AUTO: `PASS 1 OF 2 - 4 OUT ON THE
   LIGHT` - this pass's share goes out one every 0.7 s. MANUAL: `JUMP FROM
   THE ACTION MENU` - each man presses JUMP in the 1.5 km past the light.
8. **SKYTRAIN: STICK OUT** `4 OUT - 4 ABOARD`. Passes left and men aboard:
   `- CIRCLING FOR PASS 2`, then **INBOUND** `PASS 2 OF 2 - RED LIGHT IN
   1:12` as it turns in, and 6-8 again.
9. **Last pass flown, men still aboard: SKYTRAIN asks** `MEN STILL ABOARD -
   HOLDING OVER THE DZ` (answers GO, ABORT) and orbits the green light, JUMP
   open. **Leader: GO** - the rest go out, GREEN LIGHT - GO `2 OUT OVER THE
   DZ`. ABORT - it keeps holding, each man jumps or stays. No answer (D9):
   `NO RESPONSE - HOLDING` at 3 min; at 5 min the rest are put out over the
   DZ (`NO RESPONSE - 2 OUT OVER THE DZ`).
10. **SKYTRAIN: CLOSE** when it leaves - `STICK OUT - LEAVING THE DZ`, or
    `CABIN EMPTY - LEAVING THE DZ` after a hold. Lost: `AIRCRAFT LOST`. A
    run older than 30 min from the BOARD (a side's own: from WHEELS UP):
    `OUT OF TIME - n PUT OUT`. A module's aircraft then flies back to the
    module at 2000 m and is removed there (RTB on the row until then; IDLE
    once its cooldown is run) - no respawn used. A side's own flies clear and
    is removed.

**Any time after BOARD (a side's own: after the WILCO), Leader: ABORT or
RTB** (CLOSE too) stands it down: no more passes, it holds over the green
light with JUMP open and posts a prompt, `ABORTED - HOLDING OVER THE DZ - n
ABOARD - JUMP WHEN READY`, GO its answer, with no 3 / 5 min waits - an abort
is never answered by putting men out. It leaves once the cabin is empty.
Before BOARD (a side's own: before WHEELS UP): CLOSED `NOT BOARDED - STOOD
DOWN` (`STOOD DOWN BEFORE WHEELS UP`), nothing flies, no cooldown.

**The map.** The thread's pin draws the card's RED LIGHT, GREEN LIGHT and
PICKUP; while the thread is ON TASK the leader's map also draws the run from
the aircraft: RUN-IN, RED, GREEN - the lights as flown, after the wind
shift.

## How it is built

- **The module** (`moduleJump`, server): reads the attributes onto the
  logic as public `jmfsb_jumpmaster_*` values, the side from the synced
  units or the slots, and adds it to the published `jmfsb_jumpmaster_entities`
  (never compacted: the index is the id). `modules` lists a side's. Nothing
  is made: the module is virtual until tasked.
- **The module's aircraft** (2026-11-02, virtual until tasked): the module's
  public `jmfsb_jumpmaster_airPhase` - `virtual` none made, `station`
  orbiting for the BOARD, `run`, `home` flying back to be removed,
  `replacing` after a loss, `gone`. `airUp` (from `srvThread` at the WILCO)
  makes it over the module at 2000 m (`spawnAircraft`, the support core's
  `spawnAirborne`, dark through the core's `tactical`), its MPKilled, its
  escorts (support_air's `escortLaunch`) and its watch `airTick` (every 2 s:
  the loss check - destroyed, pilot dead or cannot move - and, `home`,
  removal inside 600 m of the module with nobody aboard, or after 20 min).
  `airHome` (from `srvRelease`, every ending) sends it home; `airLost` is
  the respawn count - one used and REARMING for the Respawn Delay, or none
  left: `gone`; a run waiting for BOARD closed AIRCRAFT LOST, a run in
  flight ends AIRCRAFT LOST (`srvTick` reads the aircraft's `lost` flag).
- **The asset** (`asset`, one place for the row, reach and the card): a
  module's from its logic - class, call sign, altitudes, passes, exit, bay,
  its aircraft while one is made, and whether it can take a run (`gone`
  UNABLE - NO AIRFRAME, `busy` TASKED, `replacing` REPLACING IN n S, `home`
  RTB, `readyAt` COOLDOWN; else IDLE, ready); a side's own
  (`jump:<side>`, only while the side has no module) from the settings and
  `aircraftClass`.
- **The rows** (`assets`, provider kind and type `jump`): one per module of
  the viewer's side, else the side's own; platform the class's name. A
  module's row: IDLE (ready), TASKED from the WILCO to the end of the run,
  REARMING in its cooldown or after a loss, RTB while it flies home; no row
  once gone. Fields 7 and 8: the aircraft while one is made, or the run
  (aircraft and path) from the module's published `jmfsb_jumpmaster_run`. A
  side's own row: TASKED while the viewer's own squad has a run up (the
  group's `jmfsb_jumpmaster_run`). `reach`: those, and the ETA - a module's
  aircraft while one is made, to the point asked about; a virtual one from
  the module to the point at cruise (`runEta` with a distance); else WHEELS
  UP to the red light (`runEta`, the class's speed over the 3 km run-in) -
  and the three altitudes. `task`
  refuses: by message only.
- **Who sees it:** squad leaders and admins - the voice permission table's
  SL and ADMIN (`jmfsb_tacpad_apps_fnc_radioRole`, `isJumpmaster`); for anyone
  else `assets` answers no row, so no TO entry and no @ mention. The server
  asks its own question of the card (`srvThread`): the issuer leads his
  group, or is an admin (the server's admin flag) - the role words are the
  client's.
- **The card** (`jump`, the support core's built-in - the mod's own card
  always wins, read by `jmfsb_support_fnc_readOrder`, kind
  `jump`): `Type.A-C` HALO / HAHO / STATIC, `Passes.A`, `Exit.A-B` AUTO /
  MANUAL, `Red.A`, `Green.A`, `Pickup.A`, `Remarks.A`. The stick is the
  issuer's GROUP: its living men within 200 m of the pickup
  (`JUMP_PICKUP_RADIUS`).
- **The thread:** `srvThread` (the aircraft `asset`, readiness, the wind
  shift `windShift`, the WILCO through `threadState` under the aircraft's
  call sign, the run booked - a module's aircraft made, `airUp`, and busy); a module's:
  `srvAskBoard` 3 s on (the core's `prompt`, BOARD / ABORT, no D9) and
  `srvBoard` on the leader's BOARD (the stick counted again, then
  `srvLaunch`); a side's own: `srvLaunch` the next frame (spawn, WHEELS UP);
  `srvLaunch` boards the stick and goes IN_PROGRESS; `srvTick` the milestones
  (`threadCard`: `redlight`, `greenlight`, `stickout`, `inbound`) and the
  hold's ask (the core's `prompt`, D9 end `srvTimeout`); `srvReply` the
  leader's `stop` (`srvAbort`), `go` (`srvGo`) and `board` (`srvBoard`);
  `srvEnd` the CLOSE and the clean-up; `srvRelease` gives the aircraft back
  (cooldown after a flown run) and sends a module's home (`airHome`).
- **BOARD** is the support core's reply card `board` (`BOARD`, from ACCEPTED
  or IN_PROGRESS; the core's built-in), the
  follow-up word `board`; the JUMP REQUEST answers to it and TAC//MSG's row
  for its sender offers BOARD, ABORT, RTB, CLOSE.
- **The run** (server): a module's aircraft flies from its orbit over the module to the
  start of the run-in, 3 km short of the red light, changing height to the
  type's altitude on the way (`typeAlt`: the module's HALO, HAHO or
  static-line altitude); a side's own appears there at the settings'
  altitude. The squad is put aboard where each man is local (seats, or
  standing in the bay fixed to the hull), and it flies the line. Past the
  red light: JUMP in every man's action menu. Past the green light: with
  automatic exit this pass's share of the stick goes out one every 0.7 s,
  behind and below the tail with the aircraft's velocity. More passes: it
  circles back to the start of the run-in and flies the line again. Last
  pass flown with men still aboard: it holds over the drop zone. Empty: a
  module's flies home to the module and is removed; a side's own leaves and
  is removed.
- **Static line:** the round canopy (`NonSteerable_Parachute_F`) is pulled
  1 s after exit, `jmfsb_support_air`'s own chuteTick. HALO and HAHO fall
  free: each man opens his own.
- **Standing in the bay:** the engine does not carry a walking man in a
  moving aircraft, so "stand" fixes him to the hull in two files; an
  aircraft with a bay of its own gets "seats".
- **The wind** (2026-10-30; automatic since 2026-11-02): the engine carries
  a canopy with the wind and a free-falling man not at all, so the stick
  drifts the wind's vector for its seconds under canopy - from the HALO pull
  altitude (setting, 300 m), from the aircraft on a HAHO, from the static
  line's altitude - the run's own (`typeAlt`) - scaled by the wind-drift setting (`drift`). From 20 m of
  drift the aircraft moves both lights upwind by it (`windShift`) and says
  so in the WILCO; the stick lands on the green light the leader asked for.
- **The ALT readout** (2026-10-30): from the exit the phone's status row
  leads with ALT - height over the ground and the rate of fall, amber from
  the pull altitude down, red at half of it; under canopy the height alone -
  until the man is on the ground.
- **Who the server believes** (review S7): the card reaches the server
  through the support core, which asks the issuer's tasking gate and side;
  `srvThread`, `srvLaunch`, `srvReply`, `srvAbort`, `srvGo`, `srvTimeout`,
  `srvRelease`, `srvAskBoard`, `srvBoard`, `airUp`, `airHome` and `airLost`
  refuse a remote call. Each man's board, light and jump come from the
  server by `remoteExec` and are taken only from it.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_support`
- `jmfsb_tacpad_apps`
- `jmfsb_support_air`
- `jmfsb_messaging`
- `jmfsb_devices`
- `cba_xeh` _(external)_

## Ships

1 unit class, 47 functions.

## Eden modules

### JMSB - Jump Aircraft

`jmfsb_jumpmaster_moduleJump`, category jmfsb_modules

One jump aircraft in TAC , , , , , , , , , , HALO / HAHO / Static Line Altitude (m) - Height of each kind of run Passes By Default - When the request leaves PASSES empty Exit By Default - When the request ticks no EXIT In The Aircraft - Seats, or standing in the bay Cooldown (sec) - Time after a run before the next Respawns - Aircraft that may be lost and replaced; 0 for none Respawn Delay (sec) - Time after a loss before a new aircraft can be tasked Fixed-Wing Escort Class - Two drones with a plane, always; blank for the side's UCAV Rotary Escort Class - Two drones with a helicopter for a YELLOW or RED LZ only

<details><summary>13 attributes</summary>

- `aircraftClass`
- `bay`
- `callsign`
- `cooldown`
- `escortHeli`
- `escortPlane`
- `exit`
- `hahoAltitude`
- `haloAltitude`
- `passes`
- `respawnDelay`
- `respawns`
- `staticAltitude`

</details>

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_jumpmaster_haloAltitude` | SLIDER | HALO / HAHO altitude |
| `jmfsb_jumpmaster_staticAltitude` | SLIDER | Static line altitude |
| `jmfsb_jumpmaster_haloOpenAltitude` | SLIDER | HALO pull altitude |
| `jmfsb_jumpmaster_windFactor` | SLIDER | Wind drift factor |
| `jmfsb_jumpmaster_maskClasses` | EDITBOX | HALO masks |
| `jmfsb_jumpmaster_chuteClasses` | EDITBOX | Parachutes |
| `jmfsb_jumpmaster_passesDefault` | SLIDER | Passes by default |
| `jmfsb_jumpmaster_exitDefault` | LIST | Exit by default |
| `jmfsb_jumpmaster_bay` | LIST | In the aircraft |

## Functions

<details><summary>47</summary>

- `jmfsb_jumpmaster_fnc_aboard`
- `jmfsb_jumpmaster_fnc_airHome`
- `jmfsb_jumpmaster_fnc_airLost`
- `jmfsb_jumpmaster_fnc_airTick`
- `jmfsb_jumpmaster_fnc_airUp`
- `jmfsb_jumpmaster_fnc_aircraftClass`
- `jmfsb_jumpmaster_fnc_altCell`
- `jmfsb_jumpmaster_fnc_altWatch`
- `jmfsb_jumpmaster_fnc_asset`
- `jmfsb_jumpmaster_fnc_assets`
- `jmfsb_jumpmaster_fnc_board`
- `jmfsb_jumpmaster_fnc_classList`
- `jmfsb_jumpmaster_fnc_drift`
- `jmfsb_jumpmaster_fnc_isJumpmaster`
- `jmfsb_jumpmaster_fnc_jump`
- `jmfsb_jumpmaster_fnc_light`
- `jmfsb_jumpmaster_fnc_moduleJump`
- `jmfsb_jumpmaster_fnc_modules`
- `jmfsb_jumpmaster_fnc_reach`
- `jmfsb_jumpmaster_fnc_ready`
- `jmfsb_jumpmaster_fnc_runEta`
- `jmfsb_jumpmaster_fnc_say`
- `jmfsb_jumpmaster_fnc_side`
- `jmfsb_jumpmaster_fnc_spawnAircraft`
- `jmfsb_jumpmaster_fnc_srvAbort`
- `jmfsb_jumpmaster_fnc_srvAskBoard`
- `jmfsb_jumpmaster_fnc_srvBoard`
- `jmfsb_jumpmaster_fnc_srvEnd`
- `jmfsb_jumpmaster_fnc_srvFrago`
- `jmfsb_jumpmaster_fnc_srvGo`
- `jmfsb_jumpmaster_fnc_srvLaunch`
- `jmfsb_jumpmaster_fnc_srvLight`
- `jmfsb_jumpmaster_fnc_srvNoDrop`
- `jmfsb_jumpmaster_fnc_srvRelease`
- `jmfsb_jumpmaster_fnc_srvReply`
- `jmfsb_jumpmaster_fnc_srvRtbLand`
- `jmfsb_jumpmaster_fnc_srvThread`
- `jmfsb_jumpmaster_fnc_srvTick`
- `jmfsb_jumpmaster_fnc_srvTimeout`
- `jmfsb_jumpmaster_fnc_status`
- `jmfsb_jumpmaster_fnc_stick`
- `jmfsb_jumpmaster_fnc_task`
- `jmfsb_jumpmaster_fnc_threadCard`
- `jmfsb_jumpmaster_fnc_threadState`
- `jmfsb_jumpmaster_fnc_typeAlt`
- `jmfsb_jumpmaster_fnc_unload`
- `jmfsb_jumpmaster_fnc_windShift`

</details>
