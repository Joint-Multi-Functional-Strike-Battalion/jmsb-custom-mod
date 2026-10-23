# Support Air

`jmfsb_support_air`

Air support for TAC//SUPPORT: **CAS**, **transport**, **logistics drops** and
**QRF insertion**, one asset per placed module. Phase 2 of
`docs/DESIGN_SUPPORT.md`. A provider of the support core (`addons/support`,
contract in its README) with kind `air`; asset ids are `air:<n>`, n the
module's placement index. No module, no asset.

**They act like Simplex Support Services** (user, 2026-10-20) - Simplex is a
behaviour reference only (GPLv2, never a dependency, no code copied). See
`docs/DESIGN_SUPPORT.md`, "Air modules act like Simplex", for what is matched
and what is not.

Every module is in **JMSB Modules** (`jmfsb_modules`), shaped like the CAS
drone module in `addons/cas`. No side attribute: the players' side comes from
the slots (D59). The module is the **airbase**: an aircraft class is created
over it and removed over it on return; a CAS or transport module **synced to
an aircraft** flies that aircraft from where it stands, parks it back there
(helicopters on their stand, planes at the nearest airfield) and repairs,
refuels, re-arms and **re-crews** it there - the crew it was placed with in
Eden is photographed at mission start and put back seat for seat
(`fnc_restoreCrew`). The server flies everything; the client only asks.

## Every module

- **Respawn Delay (sec)** - a lost aircraft is replaced after the delay: a
  synced one is rebuilt on its stand with its Eden crew (`fnc_respawn`), a
  class one lets the asset fly again; the row reads REPLACING meanwhile. -1:
  the loss is the asset gone for good (EXPENDED). A transport that cannot fly
  (pilot dead, too shot up) counts as lost. A transport's Airframes Available
  still caps the losses.
- **Cooldown Starts** - at the end of the sortie (default) or at the request.
- **Task markers.** Every row carries the plan it is flying (row field 8) so
  TAC//SUPPORT draws it on its map.

## Modules

| Module | Row type | Tasks | Key attributes |
|---|---|---|---|
| JMSB - CAS | `cas` | SAD, LOITER, ATTACK RUN | aircraft class (crewed or drone) or synced aircraft; callsign; sorties; altitude; run-in distance; time on station; terminal search; ingress distance; friendly range; response delay; cooldown + starts; respawn delay |
| JMSB - Transport | `transport` | PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE, HELOCAST, PARADROP, SLINGLOAD (each can be switched off) | helicopter class or synced helicopter; callsign; seats; airframes; flight height; extract wait; paradrop height; response delay; cooldown + starts; respawn delay |
| JMSB - Logistics Drop | `logistics` | SUPPLY DROP (parachute or sling) | aircraft class; callsign; method; PAC arsenal lists (`;` between loads); magazines / other gear per class; crate class; crate signal; drops; drop height; response delay; cooldown + starts; respawn delay |
| JMSB - QRF Insertion | `qrf` | STATIC LINE, AIR ASSAULT (each can be switched off; air assault needs a helicopter) | aircraft class; callsign; squad (CfgGroups path) or unit classes; on the ground (defend / join); defend radius; squads; static-line height; response delay; cooldown + starts; respawn delay |

FASTROPE is offered only where ACE fast-roping is loaded and the airframe can
take FRIES (`fnc_canRope`); SLINGLOAD only for a helicopter with a cargo hook.

Blank aircraft classes are the side's vanilla ones (`fnc_defaultClass`): CAS
`B_Plane_CAS_01_dynamicLoadout_F` / `O_Plane_CAS_02_dynamicLoadout_F` /
`I_Plane_Fighter_03_dynamicLoadout_F`; transport `B_Heli_Transport_01_F` /
`O_Heli_Light_02_unarmed_F` / `I_Heli_Transport_02_F`; logistics and QRF
`B_Heli_Transport_03_unarmed_F` / `O_Heli_Transport_04_covered_F` /
`I_Heli_Transport_02_F`. A blank QRF squad is the side's vanilla rifle squad.

## Request options (parameter slots 8-9, 20-30, 40-48)

A "MODULE" entry (index 0) means the module's own value. Slots 28 and 29 are
retired and left empty; 32-39 are support_fires'.

| Slot | Stepper / point | Tasks |
|---|---|---|
| 8, 9 | INGRESS, EGRESS points (shared with the CAS drones) | CAS |
| 20 | PASSES 1-4 | ATTACK RUN |
| 21 | ORDNANCE - this aircraft's stores, AUTO first (per asset) | ATTACK RUN, SAD |
| 22 | RADIUS 400-1500 m (map: the area) | SAD, LOITER, transport LOITER |
| 23 | ALTITUDE (MODULE, 300 ... 2000 m) | CAS |
| 24 | HEIGHT (MODULE, 40 ... 300 m) | transport |
| 25 | SPEED (NORMAL, LIMITED, FULL) | transport |
| 26 | DOOR GUNS (RETURN FIRE, FIRE AT WILL, HOLD FIRE) | transport |
| 27 | DROP HEIGHT (MODULE, 150 ... 600 m) | parachute drop |
| 30 | WAIT (MODULE, 2 ... 30 min) | EXTRACT, PICKUP > LZ, FASTROPE, HELOCAST |
| 40 | DANGER CLOSE (NO, YES; map: the friendly-range ring) - only while Friendly Range > 0 | SAD, ATTACK RUN |
| 41 | LIGHTS (ON, OFF) | transport |
| 42 | APPROACH (AUTO, FROM N ... FROM NW; map: the leg in) | landings, HOVER, FASTROPE, HELOCAST |
| 43 | LZ SIGNAL (NONE, ANY, SMOKE, IR STROBE, FLARE) | landings |
| 44 | VIA - up to four points, flown in order first | every transport task |
| 45 | LZ / SET DOWN point (required) | PICKUP > LZ, SLINGLOAD |
| 46 | CONTENTS - the module's loads (only when it names more than one) | SUPPLY DROP |
| 47 | CRATE SIGNAL (MODULE, SMOKE, IR STROBE, CHEMLIGHT, FLARE, NONE) | SUPPLY DROP |
| 48 | JUMP HEIGHT (MODULE, 150 ... 600 m) | PARADROP |

## How each asset flies

- **CAS.** ATTACK RUN and LOITER fly CARELESS/BLUE with targeting off; SAD
  COMBAT/RED with targeting on (`fnc_casPosture`). The release is the CAS
  drones' own (`jmfsb_cas_fnc_acquire` for laser/smoke inside the terminal
  search radius, `jmfsb_cas_fnc_fireAt` for the strike, `jmfsb_cas_fnc_stores`
  for the ORDNANCE list). **Where it comes from, Simplex-style:** a class
  aircraft appears the Ingress Distance out on the INGRESS bearing (the
  module's side of the target when none is picked) and, the sortie over,
  leaves the same distance out on the EGRESS bearing (straight through when
  none) and is removed there. A synced aircraft takes off from its stand,
  flies to the ingress point at the run-in distance, turns in, and goes home
  afterwards. A run releases inside 700 m of the grid, turns out the run-in
  distance on the egress bearing and comes back - by the ingress point when
  there is one - for each pass. SAD orbits the grid and every 20 s strikes a
  painted target or the nearest enemy the crew knows inside the radius; LOITER
  orbits weapons tight. **Danger close:** a release whose aim has the players'
  own side within the module's Friendly Range is held (said once, the pass
  flown dry) unless the requester set DANGER CLOSE. On station, a new SAD or
  LOITER **repositions** the orbit without a new sortie; a minute before time
  on station ends the side is told. Winchester sends it home.
- **Transport.** Stays out between orders: every new order re-plans the
  helicopter in the air (`fnc_transportPlan`): lights, door guns, height, the
  VIA legs in order, then the final approach point APPROACH_LEG out on the
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
  is empty or the wait is up, then climbs to a hover; PARADROP crosses the
  drop zone at the jump height and puts the whole cabin out one a second on
  static lines (players too, on their own machines - `jmfsb_support_air_jumpOut`),
  then goes home; SLINGLOAD hooks the nearest object it can lift within 80 m
  of the load point, carries it to the set-down point and lowers it. Players
  otherwise get out themselves. Bingo fuel sends it home. A class helicopter
  is removed at base once no player is aboard.
- **Logistics drop.** Parachute: the crate leaves behind the tail two
  seconds' flying short of the grid under a cargo chute
  (`jmfsb_common_fnc_addParachuteToObject`). Sling: the crate is hooked on at
  the module, set down from 12 m over the grid. The landed crate sets off its
  signal (the module's Crate Signal or the requester's). Contents: the load
  picked as CONTENTS (or the only one) - the classes on its PAC arsenal lists
  (`list` from the common arsenal, `version.list` from a named version) plus
  the mission's `Common_Arsenal` list of the same name; nothing found keeps
  the crate class's own contents.
- **QRF.** The squad (players' side) is created in the cargo seats. STATIC
  LINE: a slow pass at the static-line height centred on the grid,
  `NonSteerable_Parachute_F` (not steered) 1 s after exit. Jumpers leave
  0.7 s apart, behind the tail, and are not damageable until on the ground.
  AIR ASSAULT: fast-rope (`ace_fastroping_fnc_deployAI`) when ACE fast-roping
  is loaded and the airframe has FRIES, else land and dismount; the helicopter
  then leaves.
  On the ground the squad defends the grid (`CBA_fnc_taskDefend`) or joins the
  requester's group.

Cooldowns are this addon's own; the provider returns no core cooldown.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_messaging`
- `jmfsb_support`
- `jmfsb_cas`
- `cba_xeh` _(external)_

## Ships

4 unit classes, 62 functions.

## Eden modules

### JMSB - CAS

`jmfsb_support_air_moduleCAS`, category jmfsb_modules

One taskable CAS aircraft on TAC , , , , , , Sorties - Taskings before it is spent; 0 for unlimited Altitude (m) - Working height above the terrain Run-In Distance (m) - How far past the target a run turns out Time On Station (sec) - How long a SAD or LOITER holds Terminal Search (m) - Laser/smoke search radius on a run; 0 for none Response Delay (sec) - Time from accepted request to launch Cooldown (sec) - Time after a sortie before it can be tasked again Respawn Delay (sec) - Time to replace a lost aircraft; -1 never Cooldown Starts - End of the sortie, or at the request Ingress Distance (m) - Where a class aircraft appears and leaves Friendly Range (m) - Releases held this close to friendlies unless DANGER CLOSE

<details><summary>13 attributes</summary>

- `aircraftClass`
- `altitude`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `friendlyRange`
- `ingressDistance`
- `respawnDelay`
- `runIn`
- `searchRadius`
- `sorties`
- `spawnDelay`
- `stationTime`

</details>

### JMSB - Transport

`jmfsb_support_air_moduleTransport`, category jmfsb_modules

One taskable transport helicopter on TAC , , , , Seats - Passenger seats offered; 0 for all Airframes Available - Losses before it is spent; 0 for unlimited Flight Height (m) - Height flown between points Extract Wait (sec) - How long an EXTRACT waits for the requester's group Task: ... - Which of PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE, HELOCAST, PARADROP and SLINGLOAD it offers Paradrop Height (m) - Height a paradrop crosses the drop zone at Response Delay (sec) - Time from the first request to launch Cooldown (sec) - Time after it is home before it can be tasked again Respawn Delay (sec) - Time to replace a lost helicopter; -1 never Cooldown Starts - End of the sortie, or at the request

<details><summary>11 attributes</summary>

- `aircraftClass`
- `airframes`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `height`
- `jumpHeight`
- `respawnDelay`
- `seats`
- `spawnDelay`
- `waitTime`

</details>

### JMSB - Logistics Drop

`jmfsb_support_air_moduleLogistics`, category jmfsb_modules

One taskable supply drop on TAC , , , , Method - Parachute, or sling for a helicopter PAC Arsenal Lists - List names that fill the crate; ';' between loads the requester picks from Magazines Per Class / Other Gear Per Class - Quantities Crate Class - The box; dropped with its own contents when the lists give nothing Drops - Crates before it is spent; 0 for unlimited Drop Height (m) - Parachute release height Response Delay (sec) - Time from accepted request to launch Cooldown (sec) - Time after the aircraft is home before the next drop Respawn Delay (sec) - Time before a lost aircraft is replaced; -1 never Cooldown Starts - End of the sortie, or at the request Crate Signal - Smoke, IR strobe, chemlight, flare or none on the landed crate

<details><summary>14 attributes</summary>

- `aircraftClass`
- `arsenalLists`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `crateClass`
- `dropHeight`
- `drops`
- `itemCount`
- `magCount`
- `method`
- `respawnDelay`
- `signal`
- `spawnDelay`

</details>

### JMSB - QRF Insertion

`jmfsb_support_air_moduleQRF`, category jmfsb_modules

One taskable quick reaction force on TAC , , , , Squad (CfgGroups) / Unit Classes - Who is inserted Insert: ... - Which insertion methods are offered On The Ground - Defend the grid or join the requester Defend Radius (m) - Area a defending squad holds Squads - Insertions before it is spent; 0 for unlimited Static Line Height (m) - Height of the static-line pass Response Delay (sec) - Time from accepted request to launch Cooldown (sec) - Time after the aircraft is home before the next squad Respawn Delay (sec) - Time before a lost aircraft is replaced; -1 never Cooldown Starts - End of the sortie, or at the request

<details><summary>12 attributes</summary>

- `aircraftClass`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `defendRadius`
- `groupClass`
- `onLanding`
- `respawnDelay`
- `spawnDelay`
- `squads`
- `staticAlt`
- `unitClasses`

</details>

## Functions

<details><summary>62</summary>

- `jmfsb_support_air_fnc_adopt`
- `jmfsb_support_air_fnc_assetAvailable`
- `jmfsb_support_air_fnc_assets`
- `jmfsb_support_air_fnc_available`
- `jmfsb_support_air_fnc_bool`
- `jmfsb_support_air_fnc_canRope`
- `jmfsb_support_air_fnc_casLaunch`
- `jmfsb_support_air_fnc_casOrder`
- `jmfsb_support_air_fnc_casPosture`
- `jmfsb_support_air_fnc_casStrike`
- `jmfsb_support_air_fnc_casTick`
- `jmfsb_support_air_fnc_chuteTick`
- `jmfsb_support_air_fnc_defaultClass`
- `jmfsb_support_air_fnc_dropLaunch`
- `jmfsb_support_air_fnc_dropOrder`
- `jmfsb_support_air_fnc_dropTick`
- `jmfsb_support_air_fnc_entityRow`
- `jmfsb_support_air_fnc_fillCrate`
- `jmfsb_support_air_fnc_findSignal`
- `jmfsb_support_air_fnc_finish`
- `jmfsb_support_air_fnc_flightTime`
- `jmfsb_support_air_fnc_homeTick`
- `jmfsb_support_air_fnc_jump`
- `jmfsb_support_air_fnc_landAt`
- `jmfsb_support_air_fnc_logicOf`
- `jmfsb_support_air_fnc_lost`
- `jmfsb_support_air_fnc_markCrate`
- `jmfsb_support_air_fnc_moduleCAS`
- `jmfsb_support_air_fnc_moduleLogistics`
- `jmfsb_support_air_fnc_moduleQRF`
- `jmfsb_support_air_fnc_moduleTransport`
- `jmfsb_support_air_fnc_moveTo`
- `jmfsb_support_air_fnc_order`
- `jmfsb_support_air_fnc_overlay`
- `jmfsb_support_air_fnc_prepareAircraft`
- `jmfsb_support_air_fnc_preview`
- `jmfsb_support_air_fnc_qrfLanded`
- `jmfsb_support_air_fnc_qrfLaunch`
- `jmfsb_support_air_fnc_qrfOrder`
- `jmfsb_support_air_fnc_qrfSquad`
- `jmfsb_support_air_fnc_qrfTick`
- `jmfsb_support_air_fnc_readParam`
- `jmfsb_support_air_fnc_readPoint`
- `jmfsb_support_air_fnc_rearm`
- `jmfsb_support_air_fnc_register`
- `jmfsb_support_air_fnc_releaseCrate`
- `jmfsb_support_air_fnc_respawn`
- `jmfsb_support_air_fnc_restoreCrew`
- `jmfsb_support_air_fnc_say`
- `jmfsb_support_air_fnc_sitrep`
- `jmfsb_support_air_fnc_spawnAircraft`
- `jmfsb_support_air_fnc_stockRopes`
- `jmfsb_support_air_fnc_sweep`
- `jmfsb_support_air_fnc_task`
- `jmfsb_support_air_fnc_tasks`
- `jmfsb_support_air_fnc_transportArrive`
- `jmfsb_support_air_fnc_transportHome`
- `jmfsb_support_air_fnc_transportLaunch`
- `jmfsb_support_air_fnc_transportOrder`
- `jmfsb_support_air_fnc_transportPlan`
- `jmfsb_support_air_fnc_transportStep`
- `jmfsb_support_air_fnc_transportTick`

</details>
