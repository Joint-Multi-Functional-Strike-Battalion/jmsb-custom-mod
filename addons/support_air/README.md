# Support Air

`jmfsb_support_air`

Air support for TAC//SUPPORT: **CAS**, **transport** and **QRF insertion**,
one asset per placed module. Phase 2 of
`docs/DESIGN_SUPPORT.md`. A provider of the support core (`addons/support`,
contract in its README) with kind `air`; asset ids are `air:<n>`, n the
module's placement index. No module, no asset.

**Logistics moved out** (user, 2026-11-01): the JMSB - Logistics Drop is now
`addons/support_logistics` (kind `logi`, the same `logistics` tab), JMSB -
Logistics with a catalog, airdrop and sling. Its old class
`jmfsb_support_air_moduleLogistics` is defined there, hidden, and read into
the new module, so missions that placed it still load. It uses this addon's
`moveTo`, `sweep`, `flightTime`, `readParam` and `bool`; slots 27, 46 and 47
went with it.

**They act like Simplex Support Services** (user, 2026-10-20) - Simplex is a
behaviour reference only (GPLv2, never a dependency, no code copied). See
`docs/DESIGN_SUPPORT.md`, "Air modules act like Simplex", for what is matched
and what is not.

Every module is in **JMSB Modules** (`jmfsb_modules`), shaped like the CAS
drone module in `addons/cas`. No side attribute: the players' side comes from
the slots (D59). The module is **the base**: an aircraft class is **virtual
until tasked** - made over the module when a task is accepted and removed
there when it comes home (below, "Virtual until tasked"). A CAS or
transport module **synced to an aircraft** flies that aircraft from where it
stands, parks it back there
(helicopters on their stand, planes at the nearest airfield) and repairs,
refuels, re-arms and **re-crews** it there - the crew it was placed with in
Eden is photographed at mission start and put back seat for seat
(`fnc_restoreCrew`). The server flies everything; the client only asks.

The ask goes by `remoteExecCall` to `fnc_order`, and the server trusts none
of it (review S6): the requester is the sending machine's own player, he must
pass the Support tasking tag gate, the module must be his side's, and the
whole client check (`fnc_check`: available, a task this asset offers, the
point, an LZ where one is needed, water for HELOCAST, a QRF squad) is run
again for him. A refusal there is told to him alone.

## Every module

- **Flying a helicopter** (2026-11-05; `fnc_heliOrder`, `fnc_heliOrderTick`,
  `fnc_heliTake`, `fnc_heliFrame`, `fnc_heliRelease`; `fnc_heliHeld` tells
  another provider's watch whether the control holds the airframe and in
  what phase; `heliTake`'s `hang` argument is what hangs below the airframe -
  a sling's rope and load - kept off the ground ahead as well). Flight control
  modelled on how Simplex Support Services pilots a helicopter; no code of it
  used. The user's two runs of 2026-11-05 (RPT 16:23, 17:13): the UH-80 made
  over its module hovered with no waypoint on it. A helicopter gets no group
  waypoint any more:
  - **Transit** is an order on the airframe itself (`doMove`), given again
    every 2 s while the AI is idle short of the point, done inside 200 m of
    it airborne and idle (the AI hovers there); a LOITER is the ring flown
    60 deg at a time. On the ground within 200 m of a point it is sent 200 m
    past it first. Five orders in a row without 20 m of progress climb it
    50 m (the AI refusing nap of the earth over what is under it). The RPT
    says when an order is given again and what the airframe is doing.
  - **The final approach, the hover and the landing** are this addon's own
    flight control, each frame, by velocity only (players aboard ride it):
    to a hover over the pad - 10 m for a landing; the rope, cast and hook
    heights for those - held 15 m over whatever is 2 s ahead, no faster than
    20 m/s, accelerating at most 5 m/s2, pitch within 12 deg, bank within
    15 deg; the gear ordered down every second from 150 m out; then a damped
    touchdown at 0.5-2.5 m/s. Engine off for LAND: handed back to the AI.
    Engine running for GET IN and GET OUT: held on the ground by the control
    until the next order - handed back with the engine on, the AI lifted it
    straight back to a hover. The helocast drift is flown the same way; a
    sling load is carried and lowered by the AI. RPT: one line when the
    control takes the airframe, one when it is down and held, one when it
    hands it back.
  - Every caller of `moveTo` - CAS, QRF, the jumpmaster, logistics - gets
    this for a helicopter; a fixed-wing flies its group waypoint as before.
    The pilot is made the crew group's leader.
- **Tactical flight** (user, 2026-11-01; the support core's README,
  "Tactical flight"). Every aircraft of every module, every task:
  - **Lights only over its airfield** - the module it was made over, or the
    stand a synced aircraft stands on, within 1500 m. Everywhere else
    collision lights, landing light and searchlights are off and the crew is
    kept from switching them back on. A CAS class aircraft made in the air on
    its ingress has no airfield and is dark throughout.
  - **Helicopters nap of the earth**: 30 m above the ground from the base to
    the task point and back - CAS helicopters on station too. A load on the
    hook lifts it by the rope, the load and 10 m. Only the task's own height
    breaks it: a landing, a hover, a fast-rope or helocast hover, a sling
    set-down, a paradrop's jump height or a static line's height (climbed to on
    the final leg).
  - **Fixed-wing at 4000 m ATL**: attacks from 4000 m; on a SAD or LOITER it
    holds **8 km outside the map edge nearest the grid**, 3 km round, at
    4000 m, and a SAD comes in from there only for a laser, smoke or an enemy
    the requester knows inside the radius, then goes back to the hold. That
    hold is the flow's station - kept; a class jet is made over the module and
    flies out to it, and home to the module from it.
  - The ALTITUDE (23), HEIGHT (24) and LIGHTS (41) steppers and the CAS
    Altitude and Transport Flight Height attributes are retired; a mission
    that set the attributes still loads, the values are not read.
- **Drone escorts** (user, 2026-11-02: "drone escorts is based on lz
  security for helos and always for fix wings"; the support core's README,
  "Drone escorts"; `fnc_escortLaunch`). Two drone wingmen:
  - a **fixed-wing** lead (a CAS jet, a QRF plane) **always** takes two of the
    module's **Fixed-Wing Escort Class** - empty: the side's vanilla UCAV
    (`B_` / `O_` / `I_UAV_02_dynamicLoadout_F`) - at 4000 m, through the
    off-map hold, the strike from station and home;
  - a **helicopter** lead takes two of the **Rotary Escort Class** **only**
    when the request's LZ security is YELLOW or RED. Read 5 s after launch off
    the asset's open thread in TAC//MSG: the `hlz` card's Line 4, the
    EXTRACTION's and the CASEVAC's LZ SECURITY. GREEN, a card with no security
    line (`cas`, `qrf`, `airdrop`), none ticked, or no thread: none. Empty
    rotary class: none. A transport decides once, at the launch.
  - Made beside the lead over the module when it is made, they fly dark like
    it, nap of the earth or 4000 m, its route, its hold; engage what threatens
    it and what is round the target or LZ; put out flares when a missile is
    fired at it or them; come home with it and are removed with it
    (`fnc_finish` for a synced aircraft on its stand). Lead lost: they fly
    back to where they were made and are removed. Lost escorts are not
    replaced.
  - A class not in the mission, or not the lead's kind: no escort, one RPT
    warning per module and attribute. Transport has the rotary class only.
    The CAS drones (`addons/cas`) take none.
  - The **Drone Escorts** on/off attribute is retired (2026-11-02); a mission
    that set it still loads, the value is not read.
  - **ALL ATTACK** (user, 2026-11-02): a fixed-wing CAS flight with escorts up
    can be cleared ALL ATTACK - below, "CAS messaged in TAC//MSG".
- **Respawns** and **Respawn Delay (sec)** (user, 2026-11-02: "make sure
  there is a respawn count for each support, default no respawns";
  `fnc_lost`, `fnc_replace`). Respawns (default 0) is how many replacement
  airframes the asset has after a **loss**. Only an airframe LOST - destroyed,
  its crew dead, or disabled - uses one: the row reads REPLACING for the
  delay, then a synced aircraft is rebuilt on its stand with its Eden crew
  (`fnc_respawn`) and a class module's next task makes a new airframe over
  the module. Going home after a task and being removed there uses **none**.
  None left: the asset is gone - off the SUPPORT list (`fnc_assets`), and a
  card to its box gets CANTCO `UNABLE - NO AIRFRAME` (`fnc_srvThread`). It
  folds in the CAS Sorties, the transport's Airframes Available, the QRF's
  Squads and the old Respawn Delay -1, which are retired (a mission that set
  them still loads; the values are not read). Any aircraft that cannot fly
  (no pilot, pilot dead, too shot up) for 10 s counts as lost, to the last
  thing that hit it; the RPT names the failed test and the airframe's state
  (`fnc_writeOff`, `fnc_flightFault`). An airframe is counted once (`counted`
  on it).
- **Virtual until tasked** (user, 2026-11-02: "all support aircraft needs to
  be virtual till tasked, then they spawn in at alt over the support module
  location"; built, not seen in game - it replaced the same day's "on station
  from the start"). A module that flies a class - not one synced to an
  aircraft - has **no airframe** until a task is accepted. The row lists it
  READY with its respawns; the ETA is from the module to the task at the
  type's cruise speed (`fnc_reach`, `fnc_preview`).
  - **Tasked** (the WILCO - a board order, a card accepted, a REQUEST ON
    STATION): the airframe is made at once, on the next frame after the
    WILCO, **in the air directly over the module** at its height - a
    helicopter nap of the earth (30 m), a fixed-wing at 4000 m, a static-line
    QRF on its approach slope - engines on and flying (`fnc_spawnAircraft`,
    the support core's `spawnAirborne`: a plane at 60 % of its top speed), at
    least 150 m clear of any other aircraft (offset in rings, else stacked
    higher), dark, crewed and profiled as any, full of fuel and stores. Its
    escorts are made beside it, stacked above it. Then it flies the flow as
    built. A transport has its first leg ordered at the launch, not a tick
    later (`fnc_transportLaunch`, 2026-11-05); each leg is an order on the
    airframe itself, given again while it is idle short of the point ("Flying
    a helicopter", above). Every `fnc_moveTo` and transport plan is one RPT
    line, and a lift's reason for holding the watch one line each time it
    starts.
  - **Home**: after the task - RTB, CLOSE, ABORT, BINGO, NO RESPONSE,
    Winchester, a BDA's EGRESS (by its egress point), the transport's card
    egress (user, 2026-11-02: "rtb via egress"), the QRF's insertion - it
    flies back to the module and is **removed there** (`fnc_homeTick`: inside
    600 m of the module, crew and airframe deleted, no wreck; a transport
    lands, unloads and is removed once no player is aboard). Not home in 30
    min: removed where it is. The module is virtual again; the next task
    makes a fresh airframe. Going home uses no respawn.
  - CAS: a fixed-wing's on-station hold 8 km off the map is kept - it is the
    flow's station (the strike from station comes from it); only the spawn
    and the way home moved to the module. CAS Time on Station still limits a
    task. A board ATTACK RUN to an aircraft on station is flown from there as
    a cleared strike from station.
  - Retired with it (2026-11-02; a mission that set them still loads, the
    values are not read): **Response Delay** (made at once), the CAS
    **Ingress Distance** (made over the module, not out on the bearing; an
    INGRESS picked is flown to as the run-in point), and the standing
    machinery (`standUp`, `standHold`, `standTick`, `casStation`, the support
    core's `standEntry` and `standFuel`, refuelling while holding).
- **Cooldown Starts** - at the end of the sortie (default) or at the request.
- **Task markers.** Every row carries the plan it is flying (row field 8) so
  TAC//SUPPORT draws it on its map.

## Modules

| Module | Row type | Tasks | Key attributes |
|---|---|---|---|
| JMSB - CAS | `cas` | SAD, LOITER, ATTACK RUN | aircraft class (crewed or drone) or synced aircraft; callsign; run-in distance; time on station; terminal search; friendly range; cooldown + starts; respawns; respawn delay; fixed-wing / rotary escort class |
| JMSB - Transport | `transport` | PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE, HELOCAST, PARADROP, SLINGLOAD (each can be switched off) | helicopter class or synced helicopter; callsign; seats; extract wait; paradrop height; cooldown + starts; respawns; respawn delay; rotary escort class |
| JMSB - QRF Insertion | `qrf` | STATIC LINE, AIR ASSAULT (each can be switched off; air assault needs a helicopter) | aircraft class; callsign; squad (CfgGroups path) or unit classes; on the ground (defend / join); defend radius; static-line height; cooldown + starts; respawns; respawn delay; fixed-wing / rotary escort class |

FASTROPE is offered only where ACE fast-roping is loaded and the airframe can
take FRIES (`fnc_canRope`); SLINGLOAD only for a helicopter with a cargo hook.

Blank aircraft classes are the side's vanilla ones (`fnc_defaultClass`): CAS
`B_Plane_CAS_01_dynamicLoadout_F` / `O_Plane_CAS_02_dynamicLoadout_F` /
`I_Plane_Fighter_03_dynamicLoadout_F`; transport `B_Heli_Transport_01_F` /
`O_Heli_Light_02_unarmed_F` / `I_Heli_Transport_02_F`; QRF
`B_Heli_Transport_03_unarmed_F` / `O_Heli_Transport_04_covered_F` /
`I_Heli_Transport_02_F`. A blank QRF squad is the side's vanilla rifle squad.

## Request options (parameter slots 8-9, 20-30, 40-48)

A "MODULE" entry (index 0) means the module's own value. Slots 28 and 29 are
retired and left empty; 32-39 are support_fires'. 27, 46 and 47 went to
support_logistics with the Logistics Drop (2026-11-01). 23 ALTITUDE, 24 HEIGHT
and 41 LIGHTS are retired (2026-11-01) and left empty: tactical flight sets
every height and the lights.

| Slot | Stepper / point | Tasks |
|---|---|---|
| 8, 9 | INGRESS, EGRESS points (shared with the CAS drones) | CAS |
| 20 | PASSES 1-4 | ATTACK RUN |
| 21 | ORDNANCE - this aircraft's stores, AUTO first (per asset) | ATTACK RUN, SAD |
| 22 | RADIUS 400-1500 m (map: the area) | SAD, LOITER (helicopter), transport LOITER |
| 23 | retired 2026-11-01 (was ALTITUDE) | |
| 24 | retired 2026-11-01 (was HEIGHT) | |
| 25 | SPEED (NORMAL, LIMITED, FULL) | transport |
| 26 | DOOR GUNS (RETURN FIRE, FIRE AT WILL, HOLD FIRE) | transport |
| 30 | WAIT (MODULE, 2 ... 30 min) | EXTRACT, PICKUP > LZ, FASTROPE, HELOCAST |
| 40 | DANGER CLOSE (NO, YES; map: the friendly-range ring) - only while Friendly Range > 0 | SAD, ATTACK RUN |
| 41 | retired 2026-11-01 (was LIGHTS) | |
| 42 | APPROACH (AUTO, FROM N ... FROM NW; map: the leg in) | landings, HOVER, FASTROPE, HELOCAST |
| 43 | LZ SIGNAL (NONE, ANY, SMOKE, IR STROBE, FLARE) | landings |
| 44 | VIA - up to four points, flown in order first | every transport task |
| 45 | LZ / SET DOWN point (required) | PICKUP > LZ, SLINGLOAD |
| 48 | JUMP HEIGHT (MODULE, 150 ... 600 m) | PARADROP |

## How each asset flies

- **CAS.** ATTACK RUN and LOITER fly CARELESS/BLUE with targeting off; SAD
  COMBAT/RED with targeting on (`fnc_casPosture`). **Every release is a pass**
  (2026-11-05, user: "the back end should be based on simplex"; CAS runs
  modelled on Simplex Support Services; no code of it used) - the CAS drones'
  (`addons/cas` README, "The pass"), begun by `fnc_casStrike` and ticked by
  `fnc_casRun` / `fnc_casTick` / `fnc_casJob`: `jmfsb_cas_fnc_acquire` for
  laser/smoke inside the terminal search radius, then the aircraft is lined up
  on the ingress bearing by this addon's `fnc_moveTo` orders, dived on the aim
  by script, the store (`jmfsb_cas_fnc_stores` for the ORDNANCE list) released
  on a ballistic solution - a jet from its 4000 m, a helicopter from 150 m - and
  handed back to the AI; a helicopter's own transit order is dropped for the
  dive. Before, one trigger pull inside a 700 m ring from wherever the AI had
  it. **Where it comes from** (user, 2026-11-02: virtual until tasked): a class
  aircraft is made over the module when tasked, a synced one takes off from
  its stand; either flies to the ingress point at the run-in distance when an
  INGRESS is picked, and goes home to the module afterwards - a class one is
  removed there. A run flies its pass on the ingress bearing (from the INGRESS
  point, else from the module's side), turns out the run-in distance on the
  egress bearing and comes back - by the ingress point when there is one - for
  each pass; a pass that put nothing down says `no release, coming round`. A
  helicopter's SAD orbits the grid and every 20 s flies a pass from its orbit
  at a painted target or the nearest enemy the crew knows inside the radius,
  then orbits again; its LOITER orbits weapons tight. A fixed-wing's SAD and
  LOITER orbit the off-map hold instead (Tactical flight, above); every 20 s a
  SAD looks for a painted target or one the requester knows, flies a pass from
  the hold's bearing at 4000 m and goes back to the hold. **Danger close:** a
  release whose aim has the players' own side within the module's Friendly
  Range is held (said once, the pass not flown) unless the requester set
  DANGER CLOSE. On station, a new SAD or LOITER **repositions** the orbit
  without a new sortie; a minute before time on station ends the side is told.
  Winchester (nothing aboard, `fnc_casWinchester`) sends it home. A pass under
  way is finished before the time on station ends the sortie; a recall ends it
  at once.
- **Transport.** Stays out between orders: every new order re-plans the
  helicopter in the air (`fnc_transportPlan`): door guns, speed, nap of the
  earth, the VIA legs in order, then the final approach point APPROACH_LEG out on the
  picked bearing, then the point. On final it looks once for the requested LZ
  signal (`fnc_findSignal`, nearest inside 300 m) and lands on it when seen.
  At the point (`fnc_transportArrive`, then `fnc_transportStep`): PICKUP lands
  engine running and waits; LAND puts AI passengers out and waits; LAND ENG
  OFF shuts down; HOVER holds a hover; LOITER orbits at the radius; EXTRACT
  waits for the requester's group (or the wait) and flies home; PICKUP > LZ
  does the same and flies them to the LZ instead, landing there as a LAND;
  FASTROPE hovers at 18 m with ACE ropes out until the cabin is empty or the
  wait is up, then cuts them and holds; HELOCAST comes down to 3 m over water
  (refused over land), puts AI out and drifts slowly forward until the cabin
  is empty or the wait is up, then climbs to a hover; PARADROP climbs out of
  nap of the earth on the final leg and crosses the drop zone at the jump height and puts the whole cabin out one a second on
  static lines (players too, on their own machines - the server sends
  `jmfsb_support_air_fnc_jump` there by remoteExec, AI passengers put out by
  `jmfsb_support_air_fnc_putOut` the same way; both take only the server's word,
  as does `jmfsb_support_air_fnc_sayLocal`, the side's line on the notify rail),
  then goes home; SLINGLOAD hooks the nearest object it can lift within 80 m
  of the load point, carries it to the set-down point - nap of the earth plus
  the rope, the load and 10 m - and lowers it. Players
  otherwise get out themselves. Bingo fuel sends it home. A class helicopter
  is removed at base once no player is aboard.
- **QRF.** The squad (players' side) is created in the cargo seats. STATIC
  LINE: out at the transit height, onto the static-line height on the way in,
  then a slow pass centred on the grid,
  `NonSteerable_Parachute_F` (not steered) 1 s after exit. Jumpers leave
  0.7 s apart, behind the tail, and are not damageable until on the ground.
  AIR ASSAULT: fast-rope (`ace_fastroping_fnc_deployAI`) when ACE fast-roping
  is loaded and the airframe has FRIES, else land and dismount; the helicopter
  then leaves.
  On the ground the squad defends the grid (`CBA_fnc_taskDefend`) or joins the
  requester's group.

Cooldowns are this addon's own; the provider returns no core cooldown.

## CAS messaged in TAC//MSG (2026-11-01)

A JTAC tasks a CAS module by filing a card to its box, `B:SUPPORT:air:<n>`
(`docs/DESIGN_SUPPORT_MESSAGING.md` steps 3 and 4, and 1.1). The support core
hands the card to `jmfsb_support_air_fnc_srvThread` on the server, after the
issuer's tasking gate and side (`jmfsb_support_air_fnc_side`). Transport and
QRF: the next section (step 7). Built, not seen in game.

**Fixed-wing: on station first, then the strike** (user, 2026-11-01).

1. **REQUEST ON STATION** (`onstation`: time on station in minutes, the
   AREA - a map marker, required since 2026-11-02 (user: "REQUEST ON STATION
   should require a map marker"; a typed grid is refused at SEND) - remarks).
   This is its task (user, 2026-11-02: virtual until tasked): the WILCO
   makes the airframe - a class jet over the module at 4000 m, a synced one
   takes off. TASKED when it is already out on another; REPLACING after a
   loss until the Respawn Delay is up.
   The aircraft takes its station from the marker: it launches as a LOITER on
   it (an older deck's empty area: the issuer's position), flies dark to its
   hold 8 km off the map edge nearest it (a helicopter loiters over it), and answers `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss`
   (the flight from the module or the stand to the hold at cruise);
   it holds the time asked, never more than the module's Time on Station. An
   order to get in the air, not a fire mission (user, 2026-11-02): no danger
   close, target, laser or stores is asked of it. At the hold it files
   an **AIRFRAME CHECK-IN** in the thread as itself (below).
2. **A `cas` card** (CAS REQUEST - the one CAS card since 2026-11-02) to the
   aircraft **on station**: WILCO with
   the ETA from where it is. It holds until the issuer's CLEARED HOT, then
   comes in at 4000 m ATL - by the card's ingress point when it gave one -
   strikes once (ON TASK), leaves by the card's egress point when it gave
   one, and goes back to the hold (`jmfsb_support_air_fnc_casJob`). Since
   step 5 it holds there for the BDA and what follows (below); a strike that
   never released closes there. One strike at a time: a second is
   CANTCO `TASKED`. A `cas` to a fixed-wing **not** on station: CANTCO
   `NOT ON STATION`. So the composer asks for the right one (2026-11-01):
   a CAS row carries `stationFirst` (row field 9, support README) - true for
   a fixed-wing the AI flies - and an @ mention of it opens REQUEST ON
   STATION until the row reads ON STATION, then `cas`. A helicopter, or an
   aircraft with a player at the controls, opens `cas`.
3. **Off station**: recalled (the board's RTB, or the issuer's CLOSE / ABORT
   / RTB in the REQUEST ON STATION thread) - `RTB`; the time on station run
   out - `BINGO`; nothing left aboard - `WINCHESTER`. Both threads close with
   that word and it flies home to the module, where a class aircraft is
   removed, virtual again (2026-11-02).

**ALL ATTACK** (user, 2026-11-02: "add an all attack for the fixed flight
where the drones also attack the target or targets in the area"; built, not
seen in game). The `allattack` reply (ALL ATTACK, FLASH) is CLEARED HOT for a
fixed-wing flight's jet **and** its two escort drones. It is offered beside
CLEARED HOT - the `cas` card's quick replies, AWAITING CLEARED HOT and
RE-ATTACK - ... - AWAITING CLEARED HOT (answers `clearedhot,allattack,...`)
when the lead is a fixed-wing with an escort up (`fnc_canAllAttack`), from
the same men who may clear it (issuer, observer, FIRES net). The jet runs
its strike from station as CLEARED HOT and answers `ON TASK - ALL ATTACK -
FLIGHT IN HOT`; the drones break off (`fnc_allAttack`, the support core's
`escortAttack`) and attack every hostile inside 300 m of the target with
their own weapons, each its own target - vehicles and statics first, then
men - never one with the players' own men inside the module's Friendly Range
unless the card's DANGER CLOSE was ticked. They rejoin when the area is
clear, when they are Winchester (flares only), after 5 min, or when the jet
egresses or goes home. The jet's OFF waits for them (up to 120 s) and counts
what they destroyed: `OFF - RETURNING TO STATION - DRONES DESTROYED <n> -
REQUEST BDA`. No escort up, or a helicopter: `NO ESCORTS - USE CLEARED HOT`
(FLASH, answers CLEARED HOT / ABORT). Helicopter flights do not get it this
time; the CAS drones (`addons/cas`) answer the same refusal.

**Helicopter: no on-station step.** A `cas` card is an ATTACK RUN that holds
an orbit the run-in distance short of the target until CLEARED HOT; a REQUEST
ON STATION is a LOITER over the area, dark, weapons tight - the same WILCO and
no strike checks (2026-11-02). Any aircraft already on station takes a
`cas` card as a strike from there.

**The AIRFRAME CHECK-IN** (user, 2026-11-02: "in the support system an
aircraft when it arrives on station needs to send an AIRFRAME CHECK-IN";
built, not seen in game). Every CAS aircraft files one in its thread as
itself, once a sortie, when it gets on station: a fixed-wing at its off-map
hold, a helicopter over the grid (REQUEST ON STATION), a helicopter's ATTACK
RUN where it holds short for CLEARED HOT (cleared before it got there: where
it holds short after the pass). Back at the hold after a strike, or
moved on station, it does not check in again; a board order has no thread
and checks in nowhere. `jmfsb_support_air_fnc_checkIn` gives the support
core's filler (`jmfsb_support_fnc_checkIn`, support README) the module's call
sign, the station (the hold, or the point it holds short at), the station
height (a run held short: its own), the minutes left (a run: no more than the
module's Time on Station) and the remarks (`HOLDING OFF THE MAP, DARK`,
`OVER THE GRID, DARK`, `HOLDING SHORT FOR CLEARED HOT`); the core reads the
airframe, ordnance, capabilities and laser code off the aircraft and makes
the abort code. Transport and QRF sorties do not go on station and do not
check in.

| Card field | The order |
|---|---|
| Line 1 grid | the target; none - CANTCO `NO TARGET LOCATION` |
| Line 3 / Line 4 | ingress / egress points; empty - the aircraft picks |
| Line 5 | the description, repeated in the WILCO |
| Line 6 range + DC tick | danger close (the core's `dangerClose`, 300 m) - CANTCO `DANGER CLOSE NOT ACKNOWLEDGED`; ticked, it also lets the release through the module's Friendly Range. A release the Friendly Range still holds: CANTCO with the same words, back to the hold |
| Line 7 LASER + code | a laser-guided store (`jmfsb_cas_fnc_orderStore`) or CANTCO `CANNOT LASE <code>` |
| PREFERRED MUNITIONS | the store, when carried; else AUTO |

Busy, turning round or spent: the reach card's word (`TASKED`, `RTB`,
`COOLDOWN n S`, `REPLACING`, `EXPENDED`); nothing aboard: `NO STORES`.

**The prompts and the BDA** (2026-11-01, `docs/DESIGN_SUPPORT_MESSAGING.md`
5.4, step 5; built, not seen in game). The words are the support core's
(`casPrompt`, `promptCleared`; `jmfsb_support_air_fnc_casSay`), for a strike
from station (any aircraft) and a helicopter's ATTACK RUN alike:

| When | It says / asks | Answers and what they do |
|---|---|---|
| WILCO, no CLEARED HOT in 60 s | `AWAITING CLEARED HOT` (FLASH) | CLEARED HOT - in; ABORT - the strike is off (a helicopter's run: home) |
| Cleared, in from the hold / in from short | `IN` (ON TASK with it from the hold) | |
| The release, on the way back to its station (2026-11-02: "bda while returning to on station") | one message: `OFF - RETURNING TO STATION - REQUEST BDA` | BDA - kept on the thread by the core; or a new `cas` card (the CAS tile) |
| After it | a strike from station goes back to the hold and holds there; a helicopter holds the run-in distance short again - its passes no longer send it home | |
| A BDA whose DECISION is EGRESS (user, 2026-11-02: "reattack or egress"; EGRESS = LEAVE) | it flies the strike's egress point - the card's Line 4, else the sortie's - and goes home (`casTick` "egressOut"); every thread it answers CLOSED `EGRESS - RTB` | |
| A BDA whose DECISION is RE-ATTACK, a store left (`jmfsb_cas_fnc_storesLeft`, the rounds in it) | `RE-ATTACK - <n> <store> LEFT - AWAITING CLEARED HOT`, FLASH | CLEARED HOT - in again, on the BDA's TARGET grid when it gave one, else the same grid, and back to OFF - RETURNING TO STATION - REQUEST BDA (rinse and repeat); a new `cas` card - re-tasked; ABORT - the strike is off |
| A BDA, nothing left | home, both threads CLOSED `WINCHESTER` | |
| NO, or an older deck's BDA with neither decision | `<n> MIN ON STATION - FURTHER TASKING?` (its time left) | a new `cas` card in the thread (`jmfsb_support_air_fnc_casRetask`: the card's checks again on the airframe in the air, WILCO with the ETA from where it is, held for CLEARED HOT; a helicopter's run takes the new target). One it cannot fly: the same question, the reason in front. RTB - home (from a strike from station too); CLOSE - a strike from station ends, the aircraft stays on station for the REQUEST ON STATION thread (doc 1.1); a helicopter's run - home |
| BINGO (below) | `BINGO IN 2 MIN` (FLASH) in every thread it answers | RTB / CLOSE as above; else it leaves 2 min on, CLOSED `BINGO` |
| Any prompt silent 3 min / 5 min | `NO RESPONSE - HOLDING` / a strike from station dropped, CLOSED `NO RESPONSE`; the sortie's own thread - home, `NO RESPONSE - RTB` | |

**BINGO's source.** A fixed-wing on station: its time on station (the one
asked, no more than the module's Time on Station). A helicopter's thread run:
the module's Time on Station from its first pass (the sortie's 30 min cap
before that). Every sortie answering a thread: also its fuel, at a quarter of
a tank (`CAS_BINGO_FUEL`). BINGO comes 2 min (`CAS_BINGO_LEAD`) before the time runs
out, or at once on the fuel, and it leaves 2 min after that.

## Transport and QRF messaged in TAC//MSG (2026-11-01)

`docs/DESIGN_SUPPORT_MESSAGING.md` step 7 (user, 2026-11-01: "per the doc i
want to use the messaging system to call ai support"). A card filed to a
transport's or a QRF's box, `B:SUPPORT:air:<n>`, goes to
`jmfsb_support_air_fnc_liftThread` / `qrfThread`; the answers in its thread
to `liftReply` / `qrfReply`. Built, not seen in game.

**The cards to a transport** (`liftLegs`, `liftJob`):

| Card | Field | The order |
|---|---|---|
| `pickup` | Pickup | PICKUP (user, 2026-11-08: the pickup report split from the insertion): lands there and shuts down; none - the issuer's position. Always safe: no 1 MIN OUT, no circle, no mark, no clearance - `WHEELS DOWN AT PICKUP <grid>`, then `ON DECK AT PICKUP, SHUT DOWN - SEND THE INSERTION` (`hlz` / `rtb`). The `hlz` filed in its thread: WILCO `INSERTION <grid>` (and the method, the load), then `TROOP LOAD - ALL IN?` - a RED LZ asks `HOT LZ - CONFIRM` first. Filed while it is still on the way, it asks ALL IN at wheels down |
| | Pax, Marking, Wind, Obstacles, Remarks | the load and the pickup's notes |
| `hlz` | (no pickup line) | INSERTION (HLZ). In a PICKUP's thread: the leg from that pickup. Filed alone: PICKUP > LZ from the issuer's position - it lands there and shuts down, `WHEELS DOWN AT PICKUP <grid>` |
| | Line 1 (Line 2 as a marker) | the LZ; none - CANTCO `NO TARGET LOCATION` |
| | Line 3 | PAX / LOAD, repeated in the WILCO. The passengers are the side's men on foot within 150 m at touchdown; it holds on the ground until ALL IN (the `allin` reply, or the scroll or ACE action aboard) and lifts on nothing else (2026-11-06) |
| | Line 4 | security: RED is a hot LZ - WILCO `HOT LZ - REPLY CONFIRM TO LAUNCH - ETA m:ss` (user, 2026-11-01: it says what to do), it launches only after the issuer's CONFIRM; RTB or ABORT instead: CANTCO `HOT LZ NOT ACKNOWLEDGED`. YELLOW / RED also bring the drone escorts |
| | Line 5 | the marking: SMOKE, IR, PYRO / FLARE is the LZ signal it looks for, and what 1 MIN OUT tells the issuer to pop (`POP SMOKE`, `POP IR`, `POP FLARE`; none - SMOKE) |
| | Line 6 A-D | the ROUTE (user, 2026-11-02: "flight path"): up to four points flown in order from the pickup to the LZ, nap of the earth; none - direct (`liftJob` `lzVia`). An older card's single ingress is a route of one |
| | Line 7 A-D | the EGRESS: up to four points flown in order after the drop (PAX OFF), then home; none - home direct (`homeVia`) |
| `casevac` | Line 1 | PICKUP there, engine running; none - `NO TARGET LOCATION` |
| | Line 2 / 3 | the patients (Line 2, or Line 3's sum when Line 2 is empty - the 6-LINE CASEVAC, user 2026-11-02: "the 6-line only") |
| | Line 4 | as `hlz` |
| `airdrop` | Line 1 | the PARADROP card since the report-card review (2026-11-02; supplies go by RESUPPLY): PARADROP over it, the cabin jumps at the module's jump height; a module that does not fly it: `CANNOT PARADROP` |
| | Contents | who or what jumps, repeated in the WILCO |
| | Marking | what 1 MIN OUT tells the issuer to pop, as `hlz` Line 5 |
| `extract` (2026-11-02) | Station | the STATION (a map marker; none - `STATION_SHORT`, 1 km, short of the HLZ on the side it comes from): flown first (the order's VIA), it holds there - an orbit, dark, nap of the earth - and asks `ON STATION - READY FOR EXTRACTION` (extract / abort, no D9) until EXTRACT |
| | Pickup | EXTRACTION (HLZ) - the pickup is the hot zone: PICKUP > LZ at it with the destination as the LZ, or - no destination - EXTRACT, home base after; none - `NO TARGET LOCATION`. A module that does not fly the one it needs: CANTCO `<callsign> does not fly LIFT` / `EXTRACT` |
| | Security | as `hlz` Line 4 - of the pickup: RED is a hot LZ, CONFIRM before it launches |
| | Marking | the pickup's mark: what 1 MIN OUT tells the issuer to pop and what the circle looks for |
| | Passengers | repeated in the WILCO (`LAUNCHING - ON STATION IN 2:40 - 4 PAX`); every man of the side within 150 m at touchdown is loaded; ALL IN lifts it, as `hlz` |
| | Egress A-D | up to four points flown in order from the HLZ, before the destination (or home base); none - direct |
| | Destination | the LAND after the pickup - with its own INBOUND, 1 MIN OUT, circle and CLEARED TO LAND, as the caller gave it; empty - home base, landed on and unloaded without them, the thread CLOSED there |

**The extraction** (user, 2026-11-02: "LIFT REQUEST (HLZ) seems to only be
toward the drop off, need a pick up version where the pick up is the hot
zone"; built, not seen in game). LIFT REQUEST (HLZ) stays the insertion card;
EXTRACTION (HLZ) asks the landing questions about the pickup: the 1 MIN OUT -
POP SMOKE - LZ STATUS? comes on the way in to the pickup (`liftJob`'s `askAt`
is the pickup leg), it holds short of a hot pickup until CONFIRM, circles the
pickup while the mark is verified (`LZ_CLEAR_TASKS` has `EXTRACT`), lands on
CLEARED TO LAND, loads every man of the side in range (`paxNear` for `EXTRACT`
too - `liftGo`, `transportStep`) and lifts when they are aboard or the
module's Extract Wait is up. Then the destination: a caller's grid or marker
is flown as the LZ, with the same clearance; none is home base, where it lands
and unloads as any sortie ends.

**The HLZ and extraction flows** (user, 2026-11-02: "hlz insertion: 1) pick up
site (always safe) 2) troop load, all in (need an ace interaction while in
heli for all in) 3) flight path 4) insertion 5) egress. extraction: 1) on
station 2) extraction 3) troop load, all in 4) egress"; built, not seen in
game):

- **Insertion** (`hlz`): the pickup is always safe - no 1 MIN OUT, no circle,
  no mark, no clearance (`liftJob` `safePickup`); it lands and shuts down
  (user, 2026-11-08: "pick up with the helo lands turns off"); `WHEELS DOWN AT PICKUP
  <grid>`, `TROOP LOAD - ALL IN?` (allin / abort, no D9, no timeout); ALL IN
  and only ALL IN lifts it; the ROUTE (Line 6 A-D) to the LZ; the LZ's full
  landing procedure (1 MIN OUT - POP SMOKE - LZ STATUS?, circle, I SEE,
  READY TO LAND - CLEARED?, a RED LZ's CONFIRM); `WHEELS DOWN - PAX OFF?`;
  PAX OFF - the EGRESS (Line 7 A-D) and home, CLOSED `EGRESS - RTB` (`liftEnd`).
  HOLD, RTB OR NEXT LIFT? is no longer asked after an insertion; a casevac's
  and an extraction's destination still ask it.
- **Rope insertion** (the LIFT REQUEST's INSERTION line, 2026-11-08: "on
  insertion we also need to add a fast rope option ... come in to the
  insertion point as fast as possiable and leave quickly ... a simplex like
  repel"): LAND is the landing above. FAST ROPE is ACE's fast rope (FRIES
  fitted where the airframe takes them, rope items topped up); an airframe
  with no FRIES rappels instead. RAPPEL is this addon's own, any helicopter
  or VTOL: a rope each side, everyone in the cabin down them in turn (players
  too, on their own machines), kept from harm on the way. Either way the leg
  is flown at FULL, the flight control's cap raised to
  `INSERT_APPROACH_SPEED`, 1 MIN OUT called and nothing asked - no LZ STATUS,
  circle or clearance; the hover is `FASTROPE_HOVER` / `RAPPEL_HOVER` m; the
  moment the cabin is empty (or `INSERT_ROPE_WAIT` s) the ropes are cut and it
  is gone on its EGRESS, CLOSED `EGRESS - RTB`.
- **WAVE OFF** (2026-11-08: "on insertion add a wave off scroll command",
  "then send a notice to who tole the flight to wave off"): a scroll and an
  ACE self action aboard, for the issuer or a group leader, from ALL IN until
  it is down on the LZ or its ropes are in (`canWaveOff`, `srvWaveOff`). It
  goes around: ropes in, out to hold short, `LZ STATUS?` asked again - COLD
  takes it in again (a landing by the circle and clearance, ropes straight
  in). Everyone on the side gets `<CALLSIGN> WAVED OFF BY <NAME> - GOING
  AROUND, HOLDING SHORT OF <grid>`, upper right ("ever one gets the wave off
  notice").
- **Extraction** (`extract`): WILCO `LAUNCHING - ON STATION IN m:ss - <n>
  PAX`; it flies to the STATION and holds (`JOB_STATION`): `ON STATION -
  READY FOR EXTRACTION` (extract / abort); EXTRACT (the `extractnow` card) -
  in to the HLZ with the full approach (LZ STATUS?, circle, mark,
  CLEARED?), then a LOW HOVER (`EXTRACT_HOVER` m) - it never touches down
  (user, 2026-11-08: "extraction should be a low hover never touching ... then
  rtb on all in"); ALL IN as the insertion's; then its EGRESS (A-D) and home.
  No destination since 2026-11-08.
- **ALL IN** (`JOB_ALL_IN`): the `allin` reply from the issuer (or the
  observer / the FIRES net, the core's follow-up rule), the **scroll action
  ALL IN** (2026-11-06, on the player, ACE or not) or the **ACE self action
  ALL IN** on a helicopter's class - both shown to a man inside a support
  helicopter that is loading at its pickup (the vehicle carries `[thread,
  issuer uid]`, `QGVAR(allIn)`, while it does), when he is the request's
  issuer or a group leader (`canAllIn`). Their effect goes to the server by
  `remoteExecCall` (`srvAllIn`), which checks the sender again - aboard, the
  job loading, the issuer or a group leader. **Nothing else lifts it**
  (user, 2026-11-06: "hold the landing till told all in via message or
  scroll action"): not the men there being aboard, not the module's Extract
  Wait; it sits engine running, held down by the flight control, until ALL
  IN or ABORT. A board order, with no thread to say ALL IN in, still lifts
  when the requester's group is aboard or the wait is up. A mission that
  whitelists `CfgRemoteExec` must list `jmfsb_support_air_fnc_srvAllIn`.

**Circle till the mark is verified, then cleared to land** (user,
2026-11-02: "support trans needs to circle till smoke is verified, caller pops
smoke helo verifies color, either way transport needs final permission to
land"; built, not seen in game). Every landing a lift or a QRF air assault
tasked by message makes: at the point (inside 250 m) it circles, 200 m out
and 50 m up (`LZ_CIRCLE_RADIUS`, `LZ_CIRCLE_HEIGHT`), and the support core's
landing wait (`jmfsb_support_fnc_lzClear`) verifies the caller's mark and
asks for the final clearance; `liftCleared` marks the job cleared and the
watch (`liftTick`, `qrfTick`) lands it. A hot LZ still needs its CONFIRM
first, and then this clearance too. The mark is the support core's: smoke
always, and the card's IR strobe, chemlight or flare when Line 5 asks for one;
the colour from the class (`SmokeShellRed` - RED, plain `SmokeShell` - WHITE).
The board's own land-on-the-signal (on final, the LZ SIGNAL stepper) is not
flown for a lift by message - the caller verifies instead. A board order
lands as before. A QRF circling unanswered for 5 min (D9): the insertion is
off, home, CLOSED `NO RESPONSE - RTB`.

**A clear spot for the rotor** (2026-11-02, the user's RPT 07:37:53: "RAVEN
transport cannot fly - canMove false - too damaged to fly (damage 0.00; hit
points hithrotor 1.00 ... on the ground ... never hit)" - the same write-off
as the day before; built, not seen in game). The pickup was close to the
start (1 MIN OUT and the final signal look came in the launch's own second),
so the new airframe went almost straight down onto a pad `findEmptyPosition`
had found room for - room for the body, not the rotor disc; what it struck
is not in the RPT. Now (`clearSpot`) a helicopter's start (`spawnAircraft`), its stand
when that is on the ground (`respawn`) and every landing pad (`landAt`; home
too when the stand is on the ground) are checked for anything taller than 2 m
inside its bounding radius plus 3 m - trees, buildings, walls, rocks, mission
objects, a parked aircraft; never a man or an aircraft in the air - and, on
the ground, for water and a slope over about 16 deg. Blocked: the nearest
clear spot in 10 m rings (out to 200 m for a start, 80 m for a pad or a
stand), said in the RPT with what blocked it. The safety net (`rotorRepair`):
a transport whose only damage is a rotor, that nothing hit and that has not
yet been 600 m from its airfield is repaired once a sortie and logged, not
written off; a second time it is written off as before.

Not read: `hlz` Wind (the composer fills it from the game for a player
pilot), Obstacles and Remarks; `extract` Wind, Obstacles and Remarks;
`airdrop` Line 6 (its Line 7 is the way home after an RTB). The paradrop's DZ
height, mark, friendlies and winds lines left the deck in the review.

**The transport's thread** (user, 2026-11-01: "did get 2 messages roger
wilco which is one message, need more information like after rw inbound eta
etc etc and an alert to pop smoke when its close"; built, not seen in game).
One `ROGER, WILCO - ETA m:ss - <what>` (the core folds its receipt into a
WILCO this quick), WHEELS UP `INBOUND - ETA m:ss` and ON TASK at the launch,
then (`liftTick`, on its watch; the words are the support core's `inbound`):

| When | It says / asks | Answers |
|---|---|---|
| every minute on the way in to the pickup (not the LIFT REQUEST's, always safe - 2026-11-02) and to the card's LZ | INBOUND `ETA m:ss - <grid of the aircraft>` | |
| a minute out from the pickup (or an airdrop's DZ; not the LIFT REQUEST's pickup) | `1 MIN OUT - POP SMOKE` (the card's marking), FLASH, and the issuer's popup `<CALLSIGN> 1 MIN OUT - POP SMOKE` (upper right) | |
| an extraction at its STATION (2026-11-02) | `ON STATION - READY FOR EXTRACTION` - it holds, orbiting | EXTRACT: in to the HLZ. ABORT: home, CLOSED `RTB` |
| a minute (or 1 km) out from the card's LZ (the hlz's LZ, the casevac's pickup) | `1 MIN OUT - POP SMOKE - LZ STATUS?`, FLASH, one message, and the popup - and holds short 1 km out, orbiting, until it is answered | COLD: in. HOT: `HOT LZ - CONFIRM`, still holding; CONFIRM: in |
| at every landing point - the hlz's LZ (its pickup is always safe), the extraction's HLZ (it hovers there), the casevac's pickup and destination (2026-11-02) | it circles the point (200 m out, 50 m up) and does not land; the support core looks for the mark within 150 m: `I SEE RED SMOKE` (or `IR STROBE`, `GREEN CHEMLIGHT`, `FLARE`), FLASH | CORRECT: verified. WRONG: that one is ignored, it looks again |
| circling, no mark seen for 45 s | `CIRCLING - NO SMOKE SEEN - POP SMOKE` (routine, once) | NO SMOKE: no verification, the grid |
| verified, or NO SMOKE | `READY TO LAND - CLEARED?`, FLASH | CLEARED TO LAND: it lands on the verified mark (the grid after NO SMOKE). HOLD: still circling, asked again 30 s later. ABORT: home, CLOSED `RTB` |
| wheels down at a LAND (the hlz's LZ, a casevac's destination) | WHEELS DOWN `<grid>`, `WHEELS DOWN - PAX OFF?` | PAX OFF; HOLD - `HOLDING - PAX OFF?` |
| after PAX OFF - an insertion (`hlz`, 2026-11-02) | its EGRESS points, home, CLOSED `EGRESS - RTB` | |
| after PAX OFF - a casevac's destination | `HOLD, RTB OR NEXT LIFT?` | HOLD: it holds there, asking nothing more; RTB; a new `hlz` (or `casevac`, `airdrop`) in the thread |
| wheels down and shut down at a lift's pickup (2026-11-02; engine off 2026-11-08) | WHEELS DOWN `AT PICKUP <grid>`, `TROOP LOAD - ALL IN?` (no D9) | ALL IN (or the ACE action aboard): it starts up and flies the insertion. ABORT: home |
| in the low hover at an extraction's HLZ (2026-11-08) | `TROOP LOAD - ALL IN?` (no D9) | ALL IN (or the ACE action aboard): its EGRESS and home. ABORT: home |
| wheels down at a casevac's pickup | WHEELS DOWN; it loads | |
| the patients aboard, or the wait up | `PATIENTS ABOARD - DESTINATION?` (`n ABOARD - ...` on the wait) | DESTINATION (`destination` card: a grid; empty = DEFAULT), or a message giving a grid, a marker or DEFAULT. DEFAULT is the nearest medical facility (the support core's `medicalNearest`: a field hospital, else a terrain hospital), else its base |
| each leg after the first | WHEELS UP `TO <name> <grid>` | |
| an airdrop's stick out, going home | `PACKAGE AWAY - CONFIRM RECEIPT` | RECEIVED: CLOSED `RECEIVED`; NOT FOUND: CLOSED `NOT FOUND - DROPPED AT <grid>` |

**A NEXT LIFT** is a task card filed in the thread while it is out: WILCO
again with the ETA from where it is (a RED LZ waits for CONFIRM again), then
it is flown; one with no LZ: `NO TARGET LOCATION - HOLD, RTB OR NEXT LIFT?`.
**RTB, ABORT or CLOSE**: home by the egress points (an insertion's; an
extraction's are flown from its HLZ only), CLOSED `RTB`
(`liftEnd`); still launching: stood down. **D9** (`threadPrompt`,
`threadTimeout`, through the support core's `prompt`): silent 3 min - `NO
RESPONSE - HOLDING`; silent 5 min - a hot LZ never confirmed: CANTCO `HOT LZ
NOT ACKNOWLEDGED`; a receipt: CLOSED `NO RESPONSE`; anything else: home,
CLOSED `NO RESPONSE - RTB`. A board order while it flies a card ends the
card's thread `RE-TASKED`. One thread at a time: a second is `TASKED`.

**The QRF card** (`qrf`, `qrfThread`): Line 2 the link-up point (none: `NO
TARGET LOCATION`); STATIC LINE when the route, attachments, action or remarks
say STATIC, PARA or JUMP and the module flies it, else AIR ASSAULT when it
flies that; Line 5 JOIN or REINFORCE - the squad joins the issuer, DEFEND /
HOLD / CORDON / BLOCK / SECURE / CCP - it holds the point, else (ASSAULT) the
module's On The Ground. Line 5 is a pick since the report-card review
(2026-11-02: CORDON, BLOCK, CCP, REINFORCE, ASSAULT, and a detail beside it).
Thread: `ROGER, WILCO - ETA m:ss - <method> - <who>`, WHEELS UP `INBOUND -
ETA m:ss` and ON TASK at the launch, INBOUND `ETA m:ss - <grid>` every minute
and `1 MIN OUT - POP SMOKE` (FLASH, the issuer's popup) on the way in to the
link-up (2026-11-01), an air assault circling the link-up till the mark is
verified and it is CLEARED TO LAND (2026-11-02, as a lift), WHEELS DOWN where it lands or ropes, then `SQUAD DOWN AT
<grid> - <n> MEN - HOLDING / YOURS - LINKED UP?` (received / close) - the
thread is held open past the sortie's end for it; RECEIVED: CLOSED `LINKED
UP - ...`; D9 closes it `... - NO RESPONSE`. RTB / ABORT in the air before
anyone is out: the insertion is aborted, CLOSED `RTB`.

## What the airframe says when it is hit

2026-11-05 (user: "needs messaging to notify of events like that"). Through the
support core's aircraft event (support README): `TAKING FIRE AT <grid>` once
per 30 s from the Hit watch (`prepareAircraft`), `MISSILE - FLARES OUT` and
`ESCORT DOWN - n LEFT` from the escort watch, `CANNOT FLY - <fault> - AT
<grid>` (`writeOff`), `DOWN AT <grid> - AIRFRAME LOST - NO REPLACEMENT` or
`REPLACEMENT IN n S` (`lost`, FLASH) before the thread closes. The handler in
XEH_postInit maps the aircraft to its module and files in the job's and the
sortie's threads.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_messaging`
- `jmfsb_support`
- `jmfsb_cas`
- `cba_xeh` _(external)_

## Ships

3 unit classes, 116 functions.

## Eden modules

### JMSB - CAS

`jmfsb_support_air_moduleCAS`, category jmfsb_modules

One taskable CAS aircraft on TAC , , , , , , , , Run-In Distance (m) - How far past the target a run turns out Time On Station (sec) - How long a SAD, LOITER or REQUEST ON STATION holds Terminal Search (m) - Laser/smoke search radius on a run; 0 for none Cooldown (sec) - Time after an aircraft is gone before it can be tasked again Respawns - Replacements after a loss; 0 for none Respawn Delay (sec) - Time after a loss before it can be tasked again Cooldown Starts - End of the sortie, or at the request Friendly Range (m) - Releases held this close to friendlies unless DANGER CLOSE Fixed-Wing Escort Class - A jet's two drones, always; empty for the side's UCAV Rotary Escort Class - A helicopter's two drones on a YELLOW or RED LZ; empty for none

<details><summary>12 attributes</summary>

- `aircraftClass`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `escortHeli`
- `escortPlane`
- `friendlyRange`
- `respawnDelay`
- `respawns`
- `runIn`
- `searchRadius`
- `stationTime`

</details>

### JMSB - Transport

`jmfsb_support_air_moduleTransport`, category jmfsb_modules

One taskable transport helicopter on TAC , , , , , , Seats - Passenger seats offered; 0 for all Extract Wait (sec) - How long an EXTRACT waits for the requester's group Task: ... - Which of PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE, HELOCAST, PARADROP and SLINGLOAD it offers Paradrop Height (m) - Height a paradrop crosses the drop zone at Cooldown (sec) - Time after it is home before it can be tasked again Respawns - Replacements after a loss; 0 for none Respawn Delay (sec) - Time after a loss before it can be tasked again Cooldown Starts - End of the sortie, or at the request Rotary Escort Class - Two drones on a YELLOW or RED LZ; empty for none

<details><summary>10 attributes</summary>

- `aircraftClass`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `escortHeli`
- `jumpHeight`
- `respawnDelay`
- `respawns`
- `seats`
- `waitTime`

</details>

### JMSB - QRF Insertion

`jmfsb_support_air_moduleQRF`, category jmfsb_modules

One taskable quick reaction force on TAC , , , , Squad (CfgGroups) / Unit Classes - Who is inserted Insert: ... - Which insertion methods are offered On The Ground - Defend the grid or join the requester Defend Radius (m) - Area a defending squad holds Static Line Height (m) - Height of the static-line pass Cooldown (sec) - Time after the aircraft is home before the next squad Respawns - Replacements after a loss; 0 for none Respawn Delay (sec) - Time after a loss before it can be tasked again Cooldown Starts - End of the sortie, or at the request Fixed-Wing Escort Class - A plane's two drones, always; empty for the side's UCAV Rotary Escort Class - A helicopter's two drones on a YELLOW or RED LZ; empty for none

<details><summary>13 attributes</summary>

- `aircraftClass`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `defendRadius`
- `escortHeli`
- `escortPlane`
- `groupClass`
- `onLanding`
- `respawnDelay`
- `respawns`
- `staticAlt`
- `unitClasses`

</details>

## Functions

<details><summary>116</summary>

- `jmfsb_support_air_fnc_adopt`
- `jmfsb_support_air_fnc_allAttack`
- `jmfsb_support_air_fnc_assetAvailable`
- `jmfsb_support_air_fnc_assets`
- `jmfsb_support_air_fnc_available`
- `jmfsb_support_air_fnc_bool`
- `jmfsb_support_air_fnc_canAllAttack`
- `jmfsb_support_air_fnc_canAllIn`
- `jmfsb_support_air_fnc_canRope`
- `jmfsb_support_air_fnc_canWaveOff`
- `jmfsb_support_air_fnc_casFlow`
- `jmfsb_support_air_fnc_casJob`
- `jmfsb_support_air_fnc_casLaunch`
- `jmfsb_support_air_fnc_casOrder`
- `jmfsb_support_air_fnc_casPosture`
- `jmfsb_support_air_fnc_casRetask`
- `jmfsb_support_air_fnc_casRun`
- `jmfsb_support_air_fnc_casSay`
- `jmfsb_support_air_fnc_casStrike`
- `jmfsb_support_air_fnc_casTick`
- `jmfsb_support_air_fnc_casWinchester`
- `jmfsb_support_air_fnc_check`
- `jmfsb_support_air_fnc_checkIn`
- `jmfsb_support_air_fnc_chuteTick`
- `jmfsb_support_air_fnc_clearSpot`
- `jmfsb_support_air_fnc_defaultClass`
- `jmfsb_support_air_fnc_entityRow`
- `jmfsb_support_air_fnc_escortCall`
- `jmfsb_support_air_fnc_escortLaunch`
- `jmfsb_support_air_fnc_findSignal`
- `jmfsb_support_air_fnc_finish`
- `jmfsb_support_air_fnc_flightFault`
- `jmfsb_support_air_fnc_flightTime`
- `jmfsb_support_air_fnc_heliFrame`
- `jmfsb_support_air_fnc_heliHeld`
- `jmfsb_support_air_fnc_heliNoRise`
- `jmfsb_support_air_fnc_heliOrder`
- `jmfsb_support_air_fnc_heliOrderTick`
- `jmfsb_support_air_fnc_heliRelease`
- `jmfsb_support_air_fnc_heliTake`
- `jmfsb_support_air_fnc_homeTick`
- `jmfsb_support_air_fnc_jump`
- `jmfsb_support_air_fnc_landAt`
- `jmfsb_support_air_fnc_liftCleared`
- `jmfsb_support_air_fnc_liftEnd`
- `jmfsb_support_air_fnc_liftFrago`
- `jmfsb_support_air_fnc_liftGo`
- `jmfsb_support_air_fnc_liftGoAround`
- `jmfsb_support_air_fnc_liftHold`
- `jmfsb_support_air_fnc_liftIntentions`
- `jmfsb_support_air_fnc_liftJob`
- `jmfsb_support_air_fnc_liftLegs`
- `jmfsb_support_air_fnc_liftLoad`
- `jmfsb_support_air_fnc_liftMove`
- `jmfsb_support_air_fnc_liftOrder`
- `jmfsb_support_air_fnc_liftReply`
- `jmfsb_support_air_fnc_liftResume`
- `jmfsb_support_air_fnc_liftSay`
- `jmfsb_support_air_fnc_liftThread`
- `jmfsb_support_air_fnc_liftTick`
- `jmfsb_support_air_fnc_liftZones`
- `jmfsb_support_air_fnc_logicOf`
- `jmfsb_support_air_fnc_lost`
- `jmfsb_support_air_fnc_moduleCAS`
- `jmfsb_support_air_fnc_moduleQRF`
- `jmfsb_support_air_fnc_moduleTransport`
- `jmfsb_support_air_fnc_moveTo`
- `jmfsb_support_air_fnc_order`
- `jmfsb_support_air_fnc_overlay`
- `jmfsb_support_air_fnc_prepareAircraft`
- `jmfsb_support_air_fnc_preview`
- `jmfsb_support_air_fnc_putOut`
- `jmfsb_support_air_fnc_qrfLanded`
- `jmfsb_support_air_fnc_qrfLaunch`
- `jmfsb_support_air_fnc_qrfOrder`
- `jmfsb_support_air_fnc_qrfReply`
- `jmfsb_support_air_fnc_qrfSquad`
- `jmfsb_support_air_fnc_qrfThread`
- `jmfsb_support_air_fnc_qrfTick`
- `jmfsb_support_air_fnc_rappel`
- `jmfsb_support_air_fnc_rappelRopes`
- `jmfsb_support_air_fnc_reach`
- `jmfsb_support_air_fnc_readParam`
- `jmfsb_support_air_fnc_readPoint`
- `jmfsb_support_air_fnc_rearm`
- `jmfsb_support_air_fnc_register`
- `jmfsb_support_air_fnc_replace`
- `jmfsb_support_air_fnc_respawn`
- `jmfsb_support_air_fnc_restoreCrew`
- `jmfsb_support_air_fnc_rotorRepair`
- `jmfsb_support_air_fnc_say`
- `jmfsb_support_air_fnc_sayLocal`
- `jmfsb_support_air_fnc_side`
- `jmfsb_support_air_fnc_sitrep`
- `jmfsb_support_air_fnc_spawnAircraft`
- `jmfsb_support_air_fnc_srvAllIn`
- `jmfsb_support_air_fnc_srvThread`
- `jmfsb_support_air_fnc_srvWaveOff`
- `jmfsb_support_air_fnc_status`
- `jmfsb_support_air_fnc_stockRopes`
- `jmfsb_support_air_fnc_sweep`
- `jmfsb_support_air_fnc_task`
- `jmfsb_support_air_fnc_tasks`
- `jmfsb_support_air_fnc_threadCard`
- `jmfsb_support_air_fnc_threadPrompt`
- `jmfsb_support_air_fnc_threadReply`
- `jmfsb_support_air_fnc_threadState`
- `jmfsb_support_air_fnc_threadTimeout`
- `jmfsb_support_air_fnc_transportArrive`
- `jmfsb_support_air_fnc_transportHome`
- `jmfsb_support_air_fnc_transportLaunch`
- `jmfsb_support_air_fnc_transportOrder`
- `jmfsb_support_air_fnc_transportPlan`
- `jmfsb_support_air_fnc_transportStep`
- `jmfsb_support_air_fnc_transportTick`
- `jmfsb_support_air_fnc_writeOff`

</details>
