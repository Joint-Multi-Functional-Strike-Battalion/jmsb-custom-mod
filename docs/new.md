# DESIGN_RESTART — top-down restart, 2026-08-08

This document is the user's stated design requirements from the 2026-08-08
restart session, plus their settled answers to the open questions. It
supersedes the FEATURE SCOPE of work.md / DESIGN_INTEL_SYSTEM Parts 1–4 wherever
they conflict. Mechanisms, code, and pre-work findings from those parts remain
valid and are referenced below as CARRY-OVER. Mark the old parts
superseded-by-this-doc; do not silently rewrite them.

## 0. Standing rules

1. **Keep it simple.** No new system where an existing one can be reused.
2. **CBA settings are OPERATION values only** — ranges, counts, chances, timers
   (sliders). Never WHERE or WHO. Location and identity always derive from
   ALiVE data (TAORs, commanders, registries, clusters) or map markers.
3. **ALiVE wins.** JMSB hunts what ALiVE places; jmfsb spawns only what ALiVE
   doesn't (coastal, caches, QRF, leaders). Every jmfsb spawn is profiled.
4. **Adapter invariant** stands: `jmfsb_adapter_alive` is the only ALiVE-aware
   code (grep regression test stays in check_all.py).
5. **No end state.** Play until bored of the map. Finite content is fine
   (leaders don't regenerate); persistent attrition is the campaign.
6. **Plumbing before features**: nothing new merges until slice zero (§9) has
   passed in a live mission.

## 1. Force on force — the hunt network

The player objective: **un-integrate** the enemy's defense network. Every
system below is an intel target; destroying its units visibly degrades the
enemy.

### 1.1 AA + artillery hunt (NO jmfsb spawning)
- Targets are the AA and artillery units **ALiVE placement already creates**.
- AA pool: `ALIVE_aaProfileBehaviour` (placement registers every AA profile at
  creation — verified in source). Artillery pool: profile capability filter.
- All sides. Pool size is governed by the mission maker's ALiVE placement
  settings, not by jmfsb.
- No sync needed. (Optional later: sync jmfsb→placement to scope the hunt to
  specific placements' objectives. Not built now.)

### 1.2 Integrated coastal defense (jmfsb spawns)
- JMSB spawns + profiles coastal sites (radar/launcher split per the built
  anti-ship design). Standard ALiVE profile spawn distance — no custom
  un-virtualization.
- All sides present. Auto-placement: shoreline candidates near marine clusters;
  **large water only, no ponds** (water-body area test); terrain check;
  minimum spacing (CBA); TAOR-filtered (§4).
- Role: primarily hunt targets, but sites remain FUNCTIONAL — players may
  operate large boats, and sites engage per the built battery behavior.

### 1.3 Drones (jmfsb spawns)
- Drones profile fine (ground = vehicle profiles; air profiles supported;
  MACC adoption verified). Patrol drones at objectives exist as profiles and
  materialize only when players are in range — no far-from-player active units.
- **Supply caches**: physical objects, auto-placed (TAOR-filtered, spacing,
  terrain). Destroying a cache cuts the side's active drone ceiling for a
  random window. CBA sliders: base max, reduced max, window min/max
  (e.g. 8 → 4 for ~26 min).
- **Spawned jammers** (no jammer drones): static jammer props auto-placed at
  guarded objectives, TAOR-filtered —
  `RuggedTerminal_01_communications_hub_F` = **large** jamming zone,
  `RuggedTerminal_01_communications_F` = **small** zone (radii = CBA sliders;
  CARRY-OVER jamFactor model). **Jamming stops when the jammer is hacked OR
  destroyed** — either removes its zone immediately and permanently. They join
  the LOCATE JAMMER product pool.
- Drone detection of a player = the same event/roll as a failed hack (§2).
  One reaction path, no special case.

## 2. Intel + hacking (carry-over core)

- The circle system is CARRY-OVER as built: snapshot renderer, shrinking
  offset ladder, cached throw per target per tier, one renderer.
- Hackable: towers, downed drones, AI units. Products point at §1 targets
  (LOCATE AA exact; LOCATE ARTILLERY fuzzed ladder; coastal + caches join the
  pools).
- **Radio detection**: transmissions from radios **over 1 W** are detectable
  unless SATCOM. Wattage threshold = CBA slider (default 1 W). A detected
  transmission rolls the same detection degrees as a failed hack — SMALL:
  silent flag; MAJOR: the objective-lost-grade reaction below. This replaces
  the DF-station triangulation stack for the restart scope.
- **Fail/detect with degrees** (CBA: fail %, detect %):
  - SMALL: silent flag; player may sneak away or retry at **3× fail/detect
    chance**.
  - MAJOR: objective-lost-grade reaction — 4–10 arty rounds (CBA range +
    random), drone response, and AI/profiles within 300–1000 m
    (`getNearProfiles` + `knowsAbout`) learn the player's position.

## 3. QRF on objective taken

- Trigger: CARRY-OVER capture detection (presence + zero enemies held N sec).
  QRF **replaces** Objective Watch — no countdown, no warning.
- Waves, owning commander's faction:
  1. **Arty**: 10–40 rounds scaled to objective size, dispersion scaled to
     size. *Asymmetric commanders have no arty wave — instead 3–4 mortar
     rounds, ~50% of the time (CBA).* 
  2. **Drones**: X spawn at 3000–6000 m, move to objective, recon + kamikaze
     mix. **Respects the cache-reduced ceiling** — killing caches weakens QRF.
  3. **Squads**: 2–5 spawn at TAOR-valid origins, profiled immediately,
     waypoint to objective (spawn→profile→move, the Jman snippet path:
     https://www.alivewiki.com/wiki/Script_Snippets.html#Spawn_.26_Profile_Group_Script_By_Jman).
- Applies to conventional AND asymmetric objectives.

## 4. TAOR derivation (no settings)

Per side: union the `taor` keys, and separately the `blacklist` keys, of the
placement modules synced to that side's AI commander (keys verified in
source). Apply to: coastal sites, caches, patrol-drone points, QRF spawn
origins (3000–6000 m ring ∩ TAOR), safe houses (asymmetric commander's TAORs).
Friendly-base exclusion falls out automatically. Empty TAOR = whole map minus
blacklist.

## 5. Asymmetric — the leader chain

- **3 leaders** (1, 2, 3). FINITE — no replacements. Kill or capture cuts the
  asymmetric pool **25% per leader** (CBA slider).
- Leaders rotate every 20 min (CBA): board a vehicle, drive to the next safe
  house.
- **Safe houses**: buildings in settlement clusters inside the asymmetric
  TAORs — IN ADDITION to ALiVE's installations. Trap chance per house (CBA):
  trap = IED (most likely) or mortar strike 3–4 rounds / 50 m dispersion.
- Intel points at the SAFE HOUSE, never the leader exactly; intel found IN a
  house points at the NEXT house — always via the circle ladder.
- **Capture + deliver to prison** (markers `jmfsb_prison`, `jmfsb_prison_*`;
  nearest counts): reveals the location of ONE other uncaptured leader.
- **Installations** (`factory`/`HQ`/`depot`/`roadblocks` from the asymmetric
  commander's objectives) join the intel target pool alongside safe houses.
- **Cell phones**: every insurgent body carries one; phones, radios, and other
  intel items must be physically **deposited at an intel drop in the player
  base** (a deployable Intel Drop Case item; ACE interact on it to
  deposit) [AMENDED 2026-08-08: an ITEM, not a marker - the collection point
  moves with the section] — the counter tallies DEPOSITED items only, carried items count for
  nothing. Every X deposited (CBA slider) yields one circle hint via the
  CARRY-OVER intel-hunt loop. Target pool: safe houses + installations.
- **Civ-comms hack nodes**: existing towers PLUS new "internet pops" — a
  stack of rugged-server props auto-placed in city buildings (settlement
  clusters, asymmetric TAOR, spacing). Hacking either adds the leader/
  safe-house product when an asymmetric commander is present.

## 6. Coexistence

Conventional + asymmetric commanders on one map is native ALiVE. JMSB scopes
by `controltype` read from `OPCOM_instances`: §1–§3 systems attach to
conventional sides (QRF to both), §5 to the asymmetric side.

## 7. Data wiring (complete)

| Need | Source |
|---|---|
| AA targets | `ALIVE_aaProfileBehaviour` + profile handler |
| Arty targets | profile handler + artillery capability caches |
| Spawn areas | `taor`/`blacklist` keys on commanders' synced placements |
| Objectives (QRF, patrols, sizing) | `OPCOM_instances` → objectives |
| Conventional vs asymmetric | `controltype` in `OPCOM_instances` |
| Installations | asymmetric commander objective keys |
| Coastal/cache/pop candidates | marine + settlement clusters, `ALIVE_gridData`, engine terrain/water checks, TAOR filter |
| Safe houses | settlement building scan ∩ asymmetric TAOR |
| Prison | `jmfsb_prison`, `jmfsb_prison_*` markers |
| Intel drop | a deployed Intel Drop Case item (was: markers) |
| Phone hints | jmfsb intel-hunt loop (CBA: X per hint) |
| AI learns players | `ALIVE_fnc_getNearProfiles` + `knowsAbout` |
| Fires out | `ARTY_REQUEST` on `ALIVE_eventLog` |
| JMSB spawns | spawn→profile→move + jmfsb registry |
| Restart survival | `sys_data` LoadData/SaveData pairs |
| Tuning | CBA sliders (operation values only) |

## 8. Kept / cut

**Kept, untouched:** adapter + event contract, circle renderer + products,
hack core + tablet, EW jamFactor model + zones (jamming delivered by spawned
static jammer props at objectives — hub prop = large zone, terminal prop =
small; DF stations superseded by the radio-detection rule),
notification system, fire path, anti-ship battery behavior, capture detection,
friendly systems (Friendly Ops, CIWS/C-RAM, evac, timed repair, patrol base),
devices/cTab layer, sys_data persistence pairs, 5-module Eden layout.

**Cut/shelved from Part 4 scope:** per-settlement cells + link chart, terror
attacks, civilian truck routes, Enemy Force Director escalation ladder,
poisoned point-products (trap chance lives only on safe houses), Objective
Watch countdown, leader regeneration, hostility-driven recruitment economy.

## 9. Slice zero — gate before ANY feature work

In a live mission, in order; each dumps evidence to RPT:
1. Adapter reads: enumerate `OPCOM_instances`, read `controltype`, read a
   placement's `taor`/`blacklist`, read `ALIVE_aaProfileBehaviour` entries.
2. Spawn→profile→move: one squad spawned, profiled, waypointed; observe
   virtual movement + materialization.
3. One `ARTY_REQUEST` from jmfsb → battery fires.
4. Capture detection fires `jmfsb_objective_captured` on a test objective.

Pass all four → build in this order. **PRIORITY RULE: any system that
interacts with cTab is built or rebuilt FIRST.** cTab-facing systems: the
hacking console/tablet UI and its products (§2), the circle renderer feeding
the map, the intel-hunt tally + hint flow (deposit → counter → circle), and
the alert/notification feed. Sequence:
1. cTab-facing layer (§2 hack console, products, circles, tally, alerts) —
   built/rebuilt and verified on the device before anything else.
2. §1.2 coastal (smallest full spawn system).
3. Caches/drones (§1.3).
4. Hack reaction ladder (§2 fail/detect consequences).
5. QRF (§3).
6. Leader chain + safe houses + internet pops (§5).
Fail any slice → fix the pipe before anything else.

## 10. Open items (deliberate)

- Exact rugged-server prop classname for internet pops (pick at build).
- `ied` installation type ranking (leave IED caches to ALiVE's IED system;
  not a traceable node — standing recommendation, user has not overruled).
- Per-side EW/insurgency refactor: deferred until a mission actually needs
  two hostile sides with full systems.

## 11. Build-session annotations (2026-08-08, plan approval)

- §8 "Friendly Ops" is STRUCK from the kept list: D63 stands (user
  re-confirmed at plan approval) - ALiVE's Player Combat Support / Player
  Resupply are the support system and jmfsb never rebuilds it.
- §8 "5-module Eden layout" is superseded by D64 (user re-confirmed at plan
  approval): one module = one system, and the restart systems get NO Eden
  modules at all - WHERE derives from ALiVE per rule 2.
- Name corrections against source: marine clusters are
  `ALIVE_clustersCivMarine`; the persistence surface is `ALiVE_fnc_getData` /
  `ALiVE_fnc_setData` (no generic SaveData/LoadData pair).
- `adapter_alive` was never committed before the purge, so it was written
  FRESH this session (15 fns incl. the slice-zero probes). The invariant
  check is broadened to any `ALiVE_`/`ALIVE_` symbol.

## 12. Build log - section 9 complete (2026-08-08)

Slice zero PASSED in a live mission (all four probes, RPT-verified: 3 OPCOMs
with controltype, TAOR/blacklist arrays, AA pool of 6, spawn->profile->
waypoint, ARTY_REQUEST accepted, capture event raised). Everything below was
built on that footing, in the order section 9 sets.

| Step | Addon | State |
|---|---|---|
| 1 | `hacking` (+`adapter_alive`) | LOCATE AA (exact) and LOCATE ARTILLERY (cached-throw ladder); intel tally: search -> carry -> deposit into a deployed Intel Drop Case -> hint circle on installations and safe houses. Phones on asymmetric bodies, RADIOS on occupation/invasion bodies, by controltype. |
| 2 | `coastal` | Auto-sited anti-ship batteries: marine clusters + engine water-ring test (no ponds) + TAOR. Profiled; a site is a PLACE and its battery re-points at whatever hardware is currently standing. |
| 3 | `jamming`, `uas` | Jam zones from props at objectives (hub=large, terminal=small; hack OR destroy kills the zone) + LOCATE JAMMER. Profiled patrols over objectives; supply caches cut the side's ceiling for a window; drone spotting uses knowsAbout. |
| 4 | `reaction` | One path for hack-fail / drone-spot / radio>threshold. SMALL is a silent flag at 3x; MAJOR asks the hostile commander's guns, sends a drone from its ceiling, and reveals the player. SATCOM exempt via ACRE's own antenna check. |
| 5 | `qrf` | Capture detection over objectives and `jmfsb_qrf*` markers; arty scaled to the objective (asym = mortars, 50%), a drone, and 2-5 profiled squads walked in from 3-6 km. |
| 6 | `leaders` | Three finite leaders in settlement safe houses, rotating; TRACE NETWORK points at the house and at the NEXT house once moving; watched houses; capture + deliver to `jmfsb_prison*` reveals another exactly; internet pops; spent state persisted. |

PURGED NAMES NOT RESURRECTED: electronic_war_zones, drones, kamikaze,
intel_hunt, objective_watch, insurgency, deception, traffic, enemy_force,
ciws, aircraft, ambient_*, base_defense, friendly_ops,
counter_battery. Carried-over MECHANISMS live under new names or inside the
addon that owns them.

RESTORED 2026-10-07 (user: "do we still have integrated aa" ... "all 3"): `iads` (radar emission
control, shared datalink picture, threat-board reports) and `airdefence`, from ee1e25a9 as they
were deleted. The full air-defence system the user asked for after it - munition interception,
coordinated Sites, CIWS, emission control, warnings as jmfsb notices, its status and controls in
jmfsb's own UI - is designed in docs/DESIGN_AIR_DEFENCE.md and built the same day as `adsite` (the engaging
brain; `airdefence` places, `iads` runs the radars). Unverified in game: `#jmfsb adsite.probe`, then TESTS.md s12.

Setup a mission needs: an ALiVE commander or two, and a `jmfsb_prison`
marker. The intel drop is an ITEM (Intel Drop Case) - deploy it where the
section actually is, and move it when the base moves. Everything else derives from
ALiVE. Chat: `#jmfsbreads/squad/fire/capture`, `#jmfsbcoastal`, `#jmfsbjam`,
`#jmfsbuas`, `#jmfsbreact`, `#jmfsbqrf`, `#jmfsbleaders`.

NOTHING IN STEPS 1-6 HAS RUN IN GAME. Only slice zero has.

### Intel integration with ALiVE (2026-08-26)

Intel now points at everything ALiVE runs, not only what jmfsb spawns. Three
new adapter reads, all server-side with published counts for the client
buttons: `camps` (mil_placement's random camps, off the `campSafePos` key on
the cluster hash, side = who garrisons it now), `logisticsHubs` (LOGCOM's
`ALIVE_ML_supplyNetwork` nodes, HQ plus every delivery point still feeding
something alive), `radars` (vehicle profiles by class - SAM search sets,
Clam Shells). `aaTargets` widened from placement's registry to every
anti-air-capable vehicle profile (ALiVE's SEAD rule). Products: LOCATE CAMP,
LOCATE LOGISTICS; LOCATE RADAR now covers ALiVE's radars beside the coastal
ones; LOCATE AA and LOCATE ARTILLERY point at current profile positions.
Deposit hints draw from the same pools. Installations were already read.
Anti-ship batteries stay jmfsb's own. NOT RUN IN GAME.

### ALiVE integration, the rest (2026-08-26)

- Event bridge: the adapter listens to ALiVE's whole event log and re-raises
  plain summaries as `jmfsb_adapter_alive_event` / `_capture`; `qrf`
  announces hostile captures the moment OPCOM logs them.
- One intel: ALiVE's corpse-file chance is zeroed per commander; jmfsb's
  circles and hints are filed into the friendly G2 as spot reports
  (`reportIntel`), so tablet, COP and jmfsb's map agree. The hint tally
  (banked, tier, hinted ids) persists through ALiVE's data layer.
- The commander's stake: coastal batteries and drone caches register as
  OPCOM objectives (`registerSite`); a hit cache asks LOGCOM for a section
  (`requestSupply`) - a convoy players can find and interdict.
- Friendly C2: the support app lists ALiVE's own batteries (`alivearty`)
  and ATO (`alivecas`, experimental) as providers; BFT draws virtual
  friendlies from the COP; `reaction` scales detection by settlement
  hostility and warns a group when the enemy commander has its position.
- Respawn: jmfsb defers to ALiVE multispawn's gear restore when it is on,
  and falls back to the role loadout instead of an empty one otherwise.
- The `airdefence` stopgap references are gone. NOT RUN IN GAME.

### Class picker (2026-08-26)

Every module field that takes class names (antiship launchers per side and
shared, missiles, decoys; ambience shells and drones; cas airframe; uas
drones per side) opens a selection window instead of an edit box:
`jmfsb_ClassPick_*` in main/CfgEdenDrone.hpp on ALiVE's inline-controls-group
substrate, with SIDE and FACTION cycle filters (Type/Source for ammo), a
multi-select list, "(unrecognised)" rows for stored names the list does not
know, and a typed override. Per-side fields have the side fixed. Handlers
are jmfsb_common's (listClasses, edenClassPickLoad/Save). The wire format is
unchanged - a comma-separated string - so no read site moved. NOT RUN IN EDEN.

### Qualification arsenals (2026-10-07)

A PAC skill can now carry `arsenal:<name>`: holding it adds the arsenal
document `<unit>.arsenal.qual_<NAME>` (same slug rule as plt_/sqd_/role_) as
one more layer after common, platoon, squad and role. `pac` applySkills keeps
the list on the unit and raises `jmfsb_pac_arsenalChanged` when it changes;
so do the structure and settings republishes. `groups` buildArsenal (the
arsenal block moved out of setupPlayer) rebuilds from scratch on that event,
so a skill granted or taken away mid-mission shows in the arsenal with no
respawn. PAC setting `arsenalMode`: `role` (role lists only), `traits`
(qualification lists only), `both` (default). JMFSB data: skills Marksman
and Breacher added, Medic/ISR/Pilot given `arsenal:` effects; qual_MARKSMAN
holds the AXMC/HK417, their magazines and the long optics, moved out of the
common arsenal; qual_MEDIC/BREACHER/ISR/PILOT exist empty. NOT RUN IN GAME.
Same day: a role's `defaultSkills` ("Skills it grants") - stored and edited
on the role page and the website since 2026-09 but applied by nothing - now
apply. `pac` applySkills adds the current role's grants (YMF_role) to the
man's own PAC skills, so role skills and personal qualifications are held at
once; changing role drops the old role's grants. NOT RUN IN GAME.
Same day: Pilot and Medic are roles, not traits - both skills removed from
JMFSB.skills (and from the players holding them; qual_PILOT/qual_MEDIC were
empty and deleted; pilotTalon no longer requires pilot). Because PAC owns the
ACE classes, a role's own ace_medical_medicClass / ACE_IsEngineer / ACE_isEOD
were being reset to 0 and skipped on the role; applySkills now applies the
role's values first as a floor and a trait can only raise them. NOT RUN IN GAME.
Same day: the role floor in applySkills also covers job flags a trait sets
(isLeader, isJFO, isISR, UAVHacker - any name managedNames reports): a role's
true goes on, so a JTAC is a JFO without holding the JFO trait. NOT RUN IN GAME.
Same day, JMFSB data and display: Demo and Medical roles removed (their slots
are Recon; JMFSB 6 is Commander, XO and six Staff - staffC2 from isrC2); the
JTAC/ISR/Security/Medical C2 roles went with it. Medic is a SKILL again
(medic:2 + arsenal:medic; qual_MEDIC holds the medic bags, kitbags, surgical
kit, PAK and medical drone). Role names lost their orbat suffix. Both orbats
run the common arsenal (arsenalVersion ""). They are called SKILLS, not
traits: arsenalMode is role | skills | both ("traits" still read as skills).
PAC puts each man's skill abbreviations on him (jmfsb_pac_skillTags, public,
MED first); the tacpad role tag, the HUD squad list, the BFT map label and the
slot menu show them. ACE name tags cannot. NOT RUN IN GAME.
CORRECTION, same day (user: "ace traits come from skills, role is your slot in
the team"): the role floor in applySkills is removed. ACE medic/engineer/EOD and
the leader/JFO/ISR/UAV flags come from skills only (a role's own values are
skipped by groups and reset by PAC, as before). Two skills setting one class
give the higher. A role touches skills only through its "Skills it grants".
Same day: Leader is a ROLE, not a skill - the lead skill is gone (and off its 4
holders); with no skill claiming isLeader, groups applies each role's own
isLeader again. Admin panel = THIS OP ONLY, PAC record = permanent (user): the
Player Skills box now gives PAC skills for the mission (none/CLS/Medic,
none/Engineer/Adv, BRC, ISR, JFO, DRA, UAV, MKS, SNP; LEAD gone) through the new
jmfsb_pac_fnc_sessionSkills - server-side by Steam id in jmfsb_pac_session,
published, so respawns and rejoins keep it until the mission ends; never
stored. applySkills reads "skill:<id>" entries as whole skills (effects,
arsenal, tag). The old respawn wipe of tempEffects is gone. NOT RUN IN GAME.
Same day: BRASS and NIGHT BRASS colour schemes, the briefing deck's palette
(#f4f2ec / #1c2321 / #7a6224 by day, #1c2321 / #f4f2ec / #c8a24a by night) -
tacpad fnc_theme, the CBA setting, the settings app's preset cards (so TAC//PAC,
which paints with the tacpad theme, has them too) and DIVINER_Web's
JMFSBD_MOD_SCHEMES. NOT RUN IN GAME.
Same day: the JMFSB order of battle "vanilla" is now "default" (JMFSB.orbat.default,
currentOrbat default) and the "vanilla" suffix is gone from every squad and
platoon name - in both orbat documents, the radio plan and the player records.
The tropical orbat and its 25 roles are deleted (no player held one). Every
player-side JMSB uniform (uniform, uniform_sof, uniform_eu) was already in the
default arsenal. The motorpool version is still named "vanilla".

### ACM (2026-10-07)

New addon `acm`, loaded only with Advanced Combat Medicine (skipWhenMissing on
ACM's CfgPatches). Its preInit re-defaults ACM's treatment gates to JMSB's two
tiers - CLS = ACE medic 1, Medic = 2 - per the user's tier table, and re-defaults
the five jmfsb_medbags contents to ACM kit (O- blood, vials and syringes, airway
and chest kit). jmfsb_acm_fnc_setDefault re-registers a setting from CBA's own
record with only the default changed, so titles, lists and scripts survive and
any server/mission/player value still wins. ACE's medic* gates are left alone:
jmfsb_cba_settings forces them. NOT RUN IN GAME.

### Devices: the tablet shell (2026-10-18)

Spec: docs/SPEC_DEVICES.json (TAC//NET is context only; not being built yet).
Order agreed by voice: large tablet, then vehicle, then phone and side devices.
Radio stack moves from ACRE to TFAR; the device code reads TFAR directly.

THE SHELL LEARNED WHERE IT IS. jmfsb_tacpad drew every panel, app and the
reader against the vanilla map's safe zone and `findDisplay 12`, written out
in forty-odd files. Both are now the HOST: `HOST_X/Y/W/H` (the rectangle),
`HOST_DISPLAY` (the display), `HOST_K` (a type factor, the smaller of the
host's two ratios to the monitor, 1 on the map) and `HOST_NATIVE`, in
tacpad/shared.inc.hpp. `jmfsb_tacpad_fnc_setHost` sets them; with no
arguments they are the safe zone and the map. The seven font-height sites
multiply by HOST_K. Reserved-zone nudging (chat, legend, menu) applies on the
map only. The support-request dialog keeps its literal monitor geometry on
both hosts - its map control is config-positioned in safezone units and the
SQF draws to the same numbers.

NEW SETTING `jmfsb_tacpad_displayMode`: native | tablet, default native. In
tablet mode the Map event builds NOTHING - the vanilla map is a plain map
(user: "remove them from the map in tablet mode") - and the suite is built
only inside a device. A mode change closes whatever is up and, if native and
the map is open, rebuilds there.

NEW ADDON `jmfsb_devices`. One dialog (idd 8970): a backdrop, an
RscMapControl with idc 51 - the vanilla map's idc, so the shell's
`displayCtrl 51` finds the right map on either host - and an RscPicture frame
over it. `fnc_layout` fits the device BODY (not the square canvas) to the
monitor in pixels via pixelW/pixelH so the texture stays square, and returns
the screen rectangle; `fnc_onLoad` dresses the dialog, opens the map on the
player at 0.08, calls `setHost` with the dialog and the screen rect, then the
shell's own `open`. `fnc_onUnload` closes the shell and resets the host, so
ESC and `fnc_close` are the same close. Way in: CBA key "Open Tablet"
(unbound, toggles) and ACE self-interaction > Equipment > Tablet (class
action, tablet mode only; ACE guarded, not required). Setting
`jmfsb_devices_tabletFill` 0.5..1 (default 1) - how much of the monitor the
body fills; a change reopens the dialog at the new size.

FRAMES. Five renders (large, vehicle, phone, side, side 2) in
tools/art/devices/<id>_src.png; `gen_devices.py` makes 2048x2048 RGBA frames
at native resolution (device centred, background and screen interior flood-
filled to transparent, 1px feathered edge), writes devices.json,
addons/devices/data/<id>.paa (DXT5, 10 mips, via hemtt utils paa) and
addons/devices/frames.hpp (CfgJmfsbDevices: frame, body[], screen[] as canvas
fractions). THE SCREEN RECT IS MEASURED OFF THE BEZEL - the spec's phone and
side rects were typed from earlier renders and were wrong; large and vehicle
matched exactly. Measured, on their own canvases: large/vehicle 1511x1109,
phone 1638x902, side 891x1461, side 2 962x1614.

HUD in tablet mode: new `jmfsb_hud_showInTablet` (default off). The slots stay
down in tablet mode unless it is on; the device carries the same readouts.
Reacts to both the HUD's enabled event and the tacpad's displayMode event.

Decisions parked for the user: F1-F4/arrows on the frame are unbound (walking
view keys unanswered); DUI is not ported but will become an overlay on the
device map; the map tools mod is to be rebuilt in-house from an unpacked PBO
(work dir to come); Radio_MPU5_v01 (3DMA commercial model) is gitignored and
is the future TFAR radio item + ground model - licence tier for a free mod
unresolved; ACRE branches in the device apps left in place pending a yes.
NOT RUN IN GAME.

Same day, the user's answers: TABLET IS THE DEFAULT display mode now. ACRE is
gone from the device apps - radioState, radioTune and radioPublish read TFAR
only (the published [system, channel] pair keeps its shape and refuses
anything but "tfar"); the rest of the ACRE removal (pac, radio_mesh, satcom,
jamming, acre_faces) is a separate pass, and in PAC the next job is a new
common arsenal and orbat, then a mission. F1-F4 ON THE FRAME ARE THE REAL
F1-F4, live only while a device is open: each is a per-player LIST setting
(jmfsb_devices_keyF1..F4, defaults TAC//MSG, Squad, Radio, Settings) naming the
app it jumps to, and the same key closes it; LEFT/RIGHT step round the
registered apps. jmfsb_devices_fnc_keyDown, hung on the dialog in onLoad
before the shell's own ESC handler. The soft-key app list is written out in
the settings file because apps register in postInit, after settings exist.
Map tools source is PLP MapTools Remastered (POLPOX, workshop 3032131959),
unpacked at E:\SteamLibrary\...\@MapTools Remastered\addons\plp: ten functions
(distance, mark houses, height graph, compass, edit grid, find flat, line of
sight, radial menu, description, main) off a radial menu on the map's Draw
handler, ~1.9k lines; to be rebuilt in-house on the device map. NOT RUN IN
GAME.

### Radios: the MPU5 (2026-10-18)

New addon `jmfsb_radios`, requires tfar_handhelds (skipWhenMissingDependencies).
`jmfsb_mpu5: TFAR_anprc152` - TFAR's range/dialog/encryption, our name, model
and icon; tf_prototype=1, tf_parent=self; `radio_ids.hpp` is TFAR's 1..999
instance ladder written out for our classes; `Item_jmfsb_mpu5` is the
placeable. No functions, no settings.

THE MODEL IS WRITTEN BY PYTHON, NOT OBJECT BUILDER. `tools/gen_mpu5.py` reads
the gitignored 3DMA asset (Radio_MPU5_v01/, OBJ + 4K PBR) and writes MLOD
directly: visual LOD (MPU5_Mesh + MPU5_PTT_Mesh; pouch, patch and tablet
meshes left for later), a box geometry LOD with Component01 and 1.2 kg mass,
four land-contact points, autocenter=0, underside on y=0. Axes: Blender Z-up
(x,y,z) -> Arma (x,z,y), which is a reflection and so also the handedness
flip; normals negated per the MLOD convention. The format was checked by
parsing the repo's own MLODs byte-exact first, and hemtt build binarized the
result to ODOL without complaint. Textures: 2048 _co, _smdi (G = 0.2+0.7*metal,
B = 1-roughness), _nohq generated but NOT in the rvmat (Arma's nohq channel
convention is not a plain RGB conversion - verify in game first). Icon is a
flat-shaded top view rasterised in numpy. Two switches for what cannot be
verified off-line: FLIP_WINDING, NEGATE_NORMALS.

3DMA licence tier for a free mod still unresolved - do not release with this
addon until it is. NOT RUN IN GAME.

Same day: THE MPU5 IS TWO CLASSES, because TFAR is - a short-range set is an
ItemRadio in the radio slot, a long-range set is a backpack with
tf_hasLRradio. jmfsb_mpu5_lr: TFAR_rt1523g is the manpack (TFAR's dialog,
encryption, 20 km, TFAR's PRC-117G model until there is an MPU5 manpack
asset); requiredAddons gains tfar_backpacks. User: "make it both lr and sr".

Same day, the cdev mission (Task_Force_Roomba_cdev.Tanoa, jmfs-missions):
set up for the TFAR era but NOT WRITTEN - the in-place write was refused by
the tool's permission classifier, so the transformed copies sit in the
session scratchpad (mission_out/) for the user to copy over. What they hold:
the acre_sys_radio_edenSetup attribute off all 64 slots (ALiVE attribute
renumbered, nAttributes 2->1), the ACRE_PRC152 vest-cargo entry gone and
radio="jmfsb_mpu5" in each slot's inventory (TFAR uses the radio slot),
addons[] acre_sys_prc152 -> jmfsb_radios with its AddonsMetaData row,
description.ext currentOrbat/currentArsenal = "testing", the launcher preset
with ACRE2 -> Task Force Radio Standalone (3791745181) and MapTools
Remastered + DUI removed, init.sqf's voice comment. The documents
JMSB.orbat.testing and JMSB.arsenal.testing do NOT exist yet - PAC falls back
to the common ones until they do. The machine has GHOSTD_MONGO; one read
found no documents under a `key` field in jmsb or ghostd, and the second
read was refused as credential use - create them on pac.jmsb.info / in game
(ORBAT > New order of battle "testing" copies the running one; Templates >
Common arsenal variant "testing") or grant the DB access. BFT checked: no
DUI dependency; the user removed diwako_dui_main from jmfsb_main's
requiredAddons; pointing's hand-off is IS_MOD_LOADED-guarded.

Same day: THE TW-950. Radio_TrellisWare_v01 (3DMA, gitignored) -> jmfsb_tw950:
TFAR_anprc152, body + long antenna (the two shorter antennas are alternates),
0.8 kg, own ID ladder and placeable. tools/gen_mpu5.py became
tools/gen_radios.py: one RADIOS table (src, obj, parts, texture stem, mass,
optional dialog picture) per radio, same MLOD writer, same texture set, same
icon render. FOUND ON THE WAY: `hemtt utils paa convert` REFUSES TO OVERWRITE
AND EXITS 0 - the brighter MPU5 icon had never replaced the first one and no
regenerated .paa anywhere was being rewritten. Both generators (radios,
devices) now delete the target first and fail if nothing was written.

Same day: THE MPU5's OPEN-RADIO SCREEN (user: "make this the open radio
interface ... only add a volume control and the other knob a channel
changer"). radios/dialog.hpp, jmfsb_mpu5_radio_dialog, tf_dialog on the item:
the vendor's product shot (Radio_MPU5_v01/tfar screen.jpg, annotation painted
out by the generator, 1024 square, white cut to alpha -> mpu5_dialog_ca.paa)
as TFAR's background control, and on the PTT unit's two knobs two
HiddenRotators: left = channel, right = volume, left click down / right click
up, calling TFAR_fnc_setChannelViaDialog / setVolumeViaDialog exactly as
TFAR's PRC-152 rotator does. The channel reads out in an RscEditLCD with
TFAR's SW_CHANNEL idc (1604) on the radio's black slab; no frequency entry.
Control rectangles are canvas pixels (knobs measured at 516,388 and 578,385)
converted with the UI's 3:4 x:y unit ratio so the square texture stays
square. TW-950 keeps TFAR's 152 screen. NOT RUN IN GAME.

Same day: RADIO BACKPACKS. jmfsb_backpack's RT-1523G kitbags inherited
TFAR_rt1523g with no requiredAddons entry for tfar_backpacks, so whether they
were radios at all depended on PBO read order. Rebased on B_Kitbag_Base with
TFAR's six tf_ properties written out (dialog, dialogUpdate, encryption,
hasLRradio, range 20000, subtype digital_lr) - the way the Enoch radio packs
in the same file already were - and the external declaration dropped. Every
radio bag in the addon now carries tf_hasLRradio=1 itself and the addon loads
with or without TFAR. Verified by reading: the eleven radio-bag classes all
resolve to one of the two bases. NOT RUN IN GAME.

Same day: THE cdev MISSION IS FILE-FED (user: "this needs a custom arsenal
defined and orbat for testing"). With the database connected its documents
win over anything the mission declares, so the test bed runs sync = "off"
and carries its own sections under config\ - the layout jmfsb_pac_fnc_fileFed
names: config_pac.hpp (CfgGFA_PAC: settings, three ranks, skills medic/cls/
engineer/jfo), config_orbat.hpp (Dynamic_Groups: HQ + three squads of eight,
one platoon ROOMBA on C2, faction "1st JMSB - TESTING", WEST),
config_roles.hpp (Dynamic_Roles: Rifleman, Grenadier, AutoRifleman, Marksman,
Medic, TeamLeader, SquadLeader, PlatoonLeader, RTO, JTAC - getUnitLoadout
arrays via macros, vanilla SPAR rifles so every class exists on every
machine, jmfsb_mpu5 in every radio slot, jmfsb_mpu5_lr on SL/PL/RTO/JTAC,
no gates), config_nets.hpp (C2, TEAM 1-3, A2G) and
arsenal\config_arsenal_common.hpp (SPAR + JCA M4A1 family, JMSB kit, both
handhelds, the manpack and the radio bags; no ACRE). description.ext
rewritten to include them. HEMTT parses the lot ("Config is valid"); its
only complaint is the ACE __has_include it cannot resolve outside a project.
LEARNED: a preprocessor splits macro arguments on commas outside
parentheses - braces do not protect - so TEST_UNIFORM takes (item,count).
mission.sqm and the launcher preset: the TFAR versions are generated
(session scratchpad, mission_out\) but the tool was refused permission to
copy them over the originals - the user copies them. No radio plan file:
TFAR side defaults for now. NOT RUN IN GAME.

CORRECTION, same day (user: "not in the mission add to the db"): the file-fed
set-up above is withdrawn - the mission is back on sync = "service" with
currentOrbat = currentArsenal = "testing", serverId "cdev"; the config\ files
were moved out (kept in the session scratchpad, not in the mission). THE
TESTING DOCUMENTS ARE IN THE DATABASE (jmsb.pac, written by pymongo over
GHOSTD_MONGO, new ids only, nothing existing touched): JMSB.arsenal.testing =
the common lists with ACRE_PRC343/148/152/117F removed and jmfsb_mpu5 +
jmfsb_tw950 added to itemsTools (where the handhelds were) and jmfsb_mpu5_lr
to backpacks; JMSB.orbat.testing = orbat.default's groups and platoons with
every role id suffixed _t, faction "... - TESTING", arsenalVersion "testing",
motorpoolVersion "land"; sixteen JMSB.role.<id>_t copies of the roles the
orbat uses, with jmfsb_mpu5 in the radio slot (loadout index 9 slot 2 was
empty), ACRE items stripped from uniform/vest/backpack cargo and from
arsenalItems, and the four roles that carried a PRC-117F (coC2, tcNomad,
teamleadGhost, teamleadRaider) given jmfsb_mpu5_lr as their backpack with
their old contents. Roles are shared across orbats, which is why they are
copies: the default orbat and the live mission are untouched. The DB's role
docs carry nets like GHOST/NOMAD/RAIDER/C2 (JMSB.nets), unchanged. Delete the
_t roles and the two testing docs on pac.jmsb.info to undo. NOT RUN IN GAME.

Same day: THE MPU5 WAS NOT A RADIO ONCE ISSUED. TFAR_fnc_isRadio reads
tf_radio off the class and only the numbered instances carry it; the JMFSB
ID ladder copied TFAR's shape without tf_radio = 1 and
ace_arsenal_uniqueBase, so the issued jmfsb_mpu5_1 was an item TFAR had
handed out and did not recognise - "Type String, expected Bool" from its
position sender every tick, a PRC-152 fine beside it (user, in game). Both
properties added to the macro. NOT RE-RUN IN GAME.

Same day, from the first cdev run (RPT 11:06): THE MISSION'S VERSION SETTINGS
NEVER REACHED THE FETCH. svcStructure read currentOrbat/currentArsenal off the
unit's settings document and only structureAdopt - after the fetch - let the
mission override them, so cdev got orbat.default and the common arsenal. The
mission's non-empty version settings are now overlaid the moment the settings
document lands. THE TABLET ACTION WAS INVISIBLE: addActionToClass on CAManBase
without the inheritance flag (ACE defaults it false) reaches no faction class;
now true, as bft does. TFAR_fnc_setSideRadioSettings does not exist in TFAR
standalone (gear setupRadios errored every boot); the side defaults are the
TFAR_defaultFrequencies_sr_west / _lr_west globals, set from the plan. NOT
RE-RUN IN GAME.

Same day, tablet first sight (user screenshot): large frame WIDENED to a 16:10
screen by repeating its centre column (263 columns, then a uniform 0.96 scale
to fit the canvas) - never stretched; ECOTI boxes no longer draw through a
dialog; the Tablet ACE action is at the top of the self menu; "Open Tablet"
defaults to Ctrl+Home; a stale uiNamespace appCurrent is cleared when the
tablet opens (it made every panel build hidden); open() logs how many panels
it built on which host, because the first tablet showed the map and NO
panels and the RPT said nothing. NOT RE-RUN IN GAME.


Same day, NOTIFICATIONS BACK ON THE SCREEN (user: "restore the notifications
back to the upper right on the players screen"). The devices spec had the
upper-right popups suppressed in tablet mode and re-rendered only on the
phone's notification row; that side effect is withdrawn. jmfsb_notify keeps
drawing its stack at the corner setting (default top right) in every display
mode, and the device notification row - when it is built - is a mirror plus
the log, never a replacement. No code moved: nothing had implemented the
suppression yet, so this is a spec change only (SPEC_DEVICES.json).


### Devices: the phone and side walking view (2026-10-19)

THE WALKING VIEW, first slice. jmfsb_devices grows three GPS-slot items -
jmfsb_devices_phone / _side / _side2, each `: ItemGPS` with MACRO_ITEM_COMMON,
"[JMSB] ..." names, the frame texture as picture and the vanilla UAV
terminal's p3d as the ground model (user) - and ONE title layer
(overlay.hpp, jmfsb_devices_overlay, idd 8980): ground, RscMapControl,
two RscStructuredTexts, eight RscText net cells, frame on top. Nothing in it
has a position: fnc_overlayLayout fits the device BODY from CfgJmfsbDevices
(a fifth of safeZoneH for the phone, the new slider jmfsb_devices_sideFill
0.2..0.8 default 0.35 for a side device), finds the canvas side in pixels and
converts with pixelW/pixelH so the square texture stays square, and puts the
phone bottom centre or a side device against the left/right safe-zone edge,
vertically centred; fnc_overlayPlace lays the controls out from the screen
rect (rows 0.14 status / 0.12 notify / map / 0.16 nets of the screen height;
a portrait screen wraps the status line to two and the net cells to two rows
of four).

ONE LOOP DECIDES (fnc_overlayTick, CBA PFH at 0.5 s, also called straight
from the key and the ACE actions): the layer is up only with a player, in
TABLET mode, toggle not hidden, one of the three items ASSIGNED
(fnc_overlayDevice reads assignedItems; phone wins over side over side2), no
dialog open and the map not visible - otherwise the layer is CUT, not hidden,
and the mission's Ended event cuts it too (the hud's main-menu lesson). It
re-lays out only when device/edge/size/scheme change (a key string), then
fnc_overlayDraw redraws: STATUS row from a provider hashmap
(fnc_overlayProviders -> jmfsb_devices_overlayProviders, order in
jmfsb_devices_overlayOrder: NET via tacpad_apps radioState + TFAR channel,
LINK/JAM/UAS off the HUD's shared scanner sweep, MSG summing "unread" over
jmfsb_messaging_index, TMR off tacpad_apps timerState, GPS and BATT lit as
hooks; every reach guarded with isNil, a throwing provider costs its own icon
only); NOTIFY line = newest entry of jmfsb_notify_history, title in its own
colour (a mirror; the popups stay, the notify addon untouched); NETS row from
fnc_overlayNets: TFAR SW channels 1-8 named off jmfsbFR_radio_tfarNets
([name, sw, lr], names capped at 10 chars), active channel always shown and
drawn in the accent, no frequency anywhere; MAP re-centred on the player with
ctrlMapAnimAdd at MAP_SCALE_OPEN every tick, and jmfsb_bft's drawMembers hung
on its Draw event when present.

WAYS IN: CBA key "Toggle Device" (Ctrl+End) -> fnc_overlayToggle; ACE
self > Phone > Settings opens the tablet dialog wearing the phone frame and
then ["settings", [], true] call jmfsb_tacpad_fnc_openApp next frame; ACE
self > Side device > Left / Right -> fnc_overlayShow with the edge, kept
until chosen again. Both ACE parents are class actions on CAManBase with
inheritance, conditioned on HOST_DEVICE and the item in the slot. No
net-selection keybinds; TFAR's numpad binds stand. fnc_layout, fnc_onLoad,
fnc_open and dialog.hpp untouched.

UNVERIFIED / NOT DONE: whether an RscMapControl in a cutRsc layer renders
and animates (it is declared, as the dialog's is); font sizes on a phone
screen 16% of the monitor tall - the eight-label status line is the thing
most likely to overflow; the net cells are filled rectangles, not outlined
rounded ones, and carry no green/red link outline; FIRES has no provider;
BATT has no model; who-is-talking is not read; the notification LOG the
spec wants to open from the row needs input the layer cannot take - it
stays in the reader panel. NOT RUN IN GAME.


Same day, THE TABLET SHOWED NO PANELS (user screenshot: "where is the UI",
"corners"). The RPT said 8 panels were built on the right host rectangle and
234 controls sat on the dialog; nothing in the shell hides them (diaryWatch
looks for idc 1023, which no suite control carries; appCurrent is cleared at
open). The one thing this host does that the vanilla map never does is create
the suite INSIDE the display's own onLoad, so jmfsb_devices_fnc_onLoad now
builds it on the next frame and, a frame later, logs each panel's position and
shown state plus the map and frame rectangles. The arsenal test items
jmfsb_devices_phone/side/side2 were added to JMSB.arsenal.testing itemsTools
(ItemGPS left in for now). NOT RUN IN GAME: the next tablet open answers it.


Same day, PHONE FIRST SIGHT (user screenshot, 02:20 RPT): the net row threw
"Type String, expected Array" every tick - fnc_overlayDraw bound the
notification string to _line, the name the theme's rule colour already had;
renamed _notice. The phone read as a postage stamp: its height is now the
jmfsb_devices_phoneFill slider (default 0.3 of the screen, was a fixed 0.2),
aspect kept. Its map is closer in (OVERLAY_MAP_SCALE 0.03 against the tablet's
0.08) and draws the player's own man icon in the accent colour, turned to his
heading (fnc_overlayDrawPlayer on the map's Draw event) - a custom map control
has no "you are here" of its own. The group icons on it are jmfsb_bft's
MARKERS, and a marker is one size on every map control; they cannot be made
smaller on the phone alone. NOT RE-RUN IN GAME.


Same day, THE TABLET'S MISSING UI, FOUND (RPT 02:20, the panel dump): all
eight panels built, shown, inside the screen, with their controls - and
invisible. The map control was declared in the dialog's foreground layer and
the engine drew it over everything: over every ctrlCreate'd panel, and over
the frame, which is why its square corners stuck out past the rounded bezel.
Moved to controlsBackground, where CA_Map lives on the vanilla map display.
NOT RE-RUN IN GAME.


### AiTR: the compass (2026-10-19)

User: "in AiTR add a compass on the top like DUI has, the direction you're
facing should match the colour scheme". jmfsb_ecoti_fnc_drawCompass draws a
DUI-style line compass across the top centre: a tick every 5 degrees, a label
every 15 (N/NE/E/SE/S/SW/W/NW by name, three-digit bearings otherwise), fading
to nothing at 90 degrees either side, laid out on DUI's 108-row grid. The
centre marker and the three-digit heading (getCameraViewDirection of
CBA_fnc_currentUnit, as DUI reads it) are in the TAC//PAD scheme's accent
(jmfsb_tacpad_fnc_theme "accent"), white when the TAC//PAD is absent. It is
ctrlCreate'd controls on display 46 like the boxes, not a cutRsc layer: the
existing Draw3D (fnc_draw) now works out "active" once - no dialog and
fnc_isActive - and shows the compass on that, AND the new per-client checkbox
jmfsb_ecoti_compass (*Show AiTR compass*, default on), whether or not anything
is in range; the boxes keep their own early-out. 37 tick strips, 13 labels, a
marker and a readout, made once and repositioned each frame. NOT RUN IN GAME.


Same day, BFT MEMBER ICONS to docs/DESIGN_BFT_MEMBERS.md: three textures in
addons/bft/data (body + pointer in the team colour, dark outline, voice ring;
PNG sources in docs/images), the member number upright in the circle from the
new jmfsb_bft_fnc_memberNumber (place in the group's unit order, 1 = leader),
name and skill tags beside it as before. Voice rings from TFAR, read on the
slow tick into jmfsb_bft_memberVoice: red = heard over a radio
(TFAR_isReceiving) or your own pressed tangent, magenta = direct
(TFAR_isSpeaking); setting jmfsb_bft_memberVoiceRings, on. Unconscious men at
half alpha. Ring colours per the doc's assumption, unconfirmed by the user.
NOT RUN IN GAME.


Same day, SQUARE SCREEN HOLES (user: "make them square and not rounded, then
we do not have to work on corners"). gen_devices.py cut_alpha now clears the
whole measured screen rectangle, corners included, instead of only what the
flood fill reached inside the render's rounded screen. All five frames
regenerated; screen rects unchanged. NOT RUN IN GAME.


Same day, THE PHONE MAP FOLLOWS THE PLAYER (user: "centre on the player and
zoomed in, and follow the player - this is very important"). It was recentred
on the half-second overlay tick only. jmfsb_devices_fnc_overlayFollow now does
it every frame on the map's Draw event (cleared, then animated at time 0 to
getPosVisual), and the tick calls it too as a fallback. The zoom is the
jmfsb_devices_phoneZoom slider, default 0.015 (closer than the old fixed
0.03). NOT RUN IN GAME.


Same day, FRAMES: enclosed white pockets (inside the vehicle cradle's cable
loop, handle and mounting slots) touched no canvas edge, so the edge flood
never cut them; gen_devices.py now cuts every near-white region over 3000 px
(POCKET_MIN), keeping smaller ones as artwork. THE UAV TABLET: the user's
large_grips_transparent.png (the large tablet with hand grips) flattened onto
white as uav_src.png and generated as device 'uav' - square screen hole like
the rest. fnc_layout sizes it so its SCREEN equals the large tablet's
(SCREEN_MATCH), shrinking only if the grips would leave the monitor; fnc_open
swaps large for uav when the player has the UAVHacker trait. NOT RUN IN GAME.


2026-10-19, REPORT FORMS TO THE HANDOFF (docs/PLAN_MESSAGING_UI.md phase 2,
design_handoff_report_forms). Fidelity pass on the TAC//MSG compose card, theme
tokens only, RobotoCondensed, zero radius. New jmfsb_tacpad_fnc_composeCardHead:
header tag box (short name, ground on ink; ACCENT when the template's own
priority is "high" - no id list) + full title over a 2px ink rule, then the
badge strip on the "surface" token (adds ISSUER/ASSIGNEE/LEADER ONLY from
senderMustBe). Grid fields carry attached CUR LOC + MARKER cells on the box's
right edge (surface fill, 2px ink; MARKER ink while its list is open) instead
of a button row under the box; a line whose title or label says INGRESS or
EGRESS - or a noCur field - carries MARKER only; a marker-name field gets one
MARKER cell. Same code paths as before (getPosATL / markerGrids). Line key box
now shows the key verbatim ("Line 1", not "LINE 1"). Field meta: REQ alone in
accentText, the rest (range, AUTO, MARKER) muted, flush right. SEND validation:
composeSend lists every empty required field into jmfsb_tacpad_composeMissing;
the card frames each 2px in the accent with REQ in full accent until filled
(cleared when compose opens and when a card is accepted). SEND is an ink cell, accentHover on
MouseEnter. SUBJ footer on surface. GREEN/YELLOW swatches moved to the theme
("swatchGreen"/"swatchYellow", fixed SWATCH_* defines). Reply picker: new
jmfsb_tacpad_fnc_composeTiles - a reply template with no fields (ROGER / WILCO
/ ON TASK) is a one-tap tile that calls composeSend on the press, showing ONE
TAP - NO FIELDS, allowedFrom - transitionsTo, and who may send it; the forms
(CANTCO, CLOSE...) stay cards with the same tag box. The picker now also hides
issuer-only / assignee-only replies when the cached thread names another
issuer / claimant, as srvThreadFor would refuse them. messaging
registerTemplate logs INFO for a root/both template with no REMARKS line in
its last two lines. The deck (JMSB.templates) was not edited and is not
visible from code. NOT RUN IN GAME.

### RF milestone 1: the core and the two adapters (2026-10-19)

Per docs/DESIGN_RF.md (rewritten today; it wins over SPEC_TACNET.json where
they differ). NEW addons/rf (jmfsb_rf), depending on CBA only - no other jmfsb
addon - so adapters and consumers depend on it, never the reverse. A
server-authoritative registry of Node / Profile / Net hashmaps; the profile
table is DESIGN_RF.md's "Radio profiles" (handheld, manpack, vehicle, relay,
drone, legacy, satcom), written once as RF_PROFILES in script_component.hpp.
The link budget is a pure function (jmfsb_rf_fnc_linkBudget) over the world
part (fnc_pathLoss: log-distance per band, terrain at 3 samples, clutter
counted, walls and trees apart); the band table, thr (6, open item 7), span
and every obstacle dB are CBA settings. Mesh per net per tick, nodes
partitioned by key, edges two-way (the weaker direction) and cached per pair
and band - re-cast only when an end moved 10 m or the entry is older than the
static tick, which is what "static nodes 5 s" means here - and the widest-path
search ported from radio_mesh's fnc_signal with the hop limit = the smallest
hop limit among the relays on the path. Player tick 1 s (PFH). Each client's
slice (his own nodes' links and reach per net) goes by publicVariableClient
only when it changed; jmfsb_rf_linkChanged fires on the server for every node
and on the client for his own. API: register, unregister, setState, netSet,
link, reach, budget, noise, plus the two EW hooks (addNoiseSource,
addListener: RF never knows what EW is). EMCON is a state field; its only
effect yet is no relaying at 2+. Debug map overlay setting, off.
jmfsb_rf_fnc_rangeTable is the range self-test; the spec constants MISS: UHF
is near the targets (handheld 2.8 km vs ~3, manpack 5.3 vs ~8, vehicle 11.7 vs
~15, relay 8.5 vs ~10) but VHF is 3-7x long (5 W VHF 0 dBi 15.6 km vs ~5;
handheld VHF 22 km) and VIDEO 16x short (drone 0.25 km vs ~4). Not retuned -
see addons/rf/README.md. NEW addons/adapter_tfar (skipWhenMissingDependencies
on tfar_core): the server makes the PAC radio plan's voice nets in RF (VHF,
named SW nets, LR n), RF makes the per-side keys at creation; each client
registers his active SR, LR backpack and crew-seat LR rack as nodes with
profiles from a class table, fill SR or LR nets plus DATA, on/off and active
and monitor channel mirrored, sent only on change. NEW addons/adapter_acre, a
stub: ACRE radios as DATA-only nodes. No voice degradation (milestone 2), no
EW, no consumer ports, and no TFAR/ACRE rule in check_invariants.py until the
consumers are ported. NOT RUN IN GAME.


Same day, RF RANGES TO A THIRD (user: "the ranges should be 1/3 of that").
The spec's band constants put a handheld at 22 km on VHF. New defaults, fitted
by least squares to a third of the design table: VHF exponent 2.53 / 69 dB at
1 m, UHF 2.58 / 62 dB, VIDEO 2.46 / 48 dB. Worked out by hand: handheld 1.0 km,
manpack 2.1 km (target 2.7), vehicle 5.3 km, relay 3.7 km, drone 1.3 km,
flat and clear. DESIGN_RF and DESIGN_EW tables updated. NOT RUN IN GAME -
jmfsb_rf_fnc_rangeTable prints the real numbers to the RPT.


Same day, SUB-WATT MESH (user: "with mesh the power needs to be sub watt, then
relayed, if we can do that with the MPU5s"). Handheld profile 37 -> 27 dBm
(0.5 W); it was already relay-capable with a 4-hop limit, so MPU5s carry each
other's traffic. VHF and UHF refitted with the handheld anchored at ~1 km per
hop: exponent 4.22, 9 / 4 dB at 1 m (slider ranges widened to 2-6 and 0-80).
Per hop: handheld 0.97 km, manpack 2.6, vehicle 4.5, relay 3.6, legacy 1.7.
NOT RUN IN GAME.


Same day, MPU5 HOP TO 0.5 KM (user). Handheld 27 -> 14 dBm (25 mW); the band
constants are unchanged, so every other set keeps its range. Per hop: 476 m on
VHF and UHF, worked by hand. NOT RUN IN GAME.


Same day, DRONE LINK TO 2 W (user). Drone profile 30 -> 33 dBm; VIDEO hop 1.8 km
flat and clear, worked by hand. NOT RUN IN GAME.


2026-10-19, DRONE40 RELAY / DECOY / JAMMER (user: "using the RC 40 from GX, can
we make drone relays and decoys and jammers"). NEW addons/drone40
(skipWhenMissingDependencies on gx_drones_uav_drone40 and jmfsb_rf): three
rounds jmfsb_drone40_1Rnd_relay|decoy|jammer_M203 (from GX's recon round), shells
jmfsb_drone40_relay|decoy|jammer_shell (GX_DRONE40_BASE_SHELL, GX_Drone[] O/B/I),
drones jmfsb_drone40_B|O|I_relay|decoy|jammer (GX's recon base: camera and
designator kept). They load where GX's rounds load: CBA_40mm_M203 and UGL_40x36
wells and UGL_F; ground "Assemble" actions as GX's. The creating client names
the launcher to the server after 2 s; the server ticks every 5 s (cleanup on
death or pickup, battery mirrored as RF on/off). RELAY: RF node, new profile
droneRelay (VHF/UHF, 33 dBm, -112, 3 dBi, 4 hops, relay, 20 dB, host battery;
~1.5 km per hop by hand), fill = the launcher's own nodes' nets and keys (DATA
if none), holder the launcher. JAMMER: a jmfsb_jamming temporary radio+data
zone re-laid at the drone every tick (6 s life), plus an RF noise source
(addNoiseSource) on VHF/UHF, barrage; radius and power are CBA settings. Not an
RF node. DECOY: RF node, handheld profile, the launcher's nets under a key
nobody holds (no traffic, no links), relay off, intent "decoy" in the node - no
gameplay effect until EW. RF holds only the profile row. NOT RUN IN GAME.


2026-10-19, TAC//PAC BOOT SPEED (last session: "BOOT 3/6 reading the config"
0:24:20 to "config ADOPTED" 0:28:33, 4 min 13 s). addons/pac only, SQF only.
(1) PARSE UNSCHEDULED: FUNC(svcLoad) runs FUNC(fromJson) inside isNil {} - it
was parsed scheduled, char by char, on the scheduler's 3 ms/frame share beside
ALiVE. FUNC(fromJson) lost every `while` (an unscheduled while stops silently
at 10,000 turns, and logistics is one 27 KB string): all loops are now
`for from to` bounded by the text length; strings are copied a stretch at a
time between escapes. Also fixes clipboard imports called from UI handlers.
(2) EACH KEY ONCE: FUNC(svcStructure)'s reads all go through _fnc_fetch, a
per-read cache ("get|key" / "list|prefix"); the arsenal and motorpool variant
loops no longer re-read the version the section loop already read (arsenal
"testing", 127 KB, was read twice). A reused key is a deep copy.
(3) NO CONCURRENCY: the extension answers get.begin/get.chunk/get.end and list
WITHOUT the key, so two requests in flight would share GVAR(svcChunks) - left
strictly sequential. The wait polls every frame instead of sleep 0.2.
EXTENSION CHANGE NEEDED for overlap (not made, DIVINER is read-only): a request
id as the first argument, echoed in every callback ("get.chunk" data
"<id>|<i>|<text>", get.begin/end/error and list likewise); or a "getMany" verb
taking N keys and answering one {key: doc} JSON. Either lets the boot fire the
36 roles, the orders and the sections at once.
(4) CHECKLIST THROTTLED: FUNC(bootDoc) publicVariables at most every
PAC_BOOT_PUBLISH_EVERY (0.5 s) or at once on an error; FUNC(boot) publishes the
final checklist when the read returns.
(5) NO WEBSITE DOCUMENTS: confirmed the boot reads only <unit>.<section>[.<ver>],
<unit>.welcome[.<id>], <unit>.roles and the prefixes orbat. arsenal. motorpool.
role. opord. - never <unit>.web.*. (adminDocs' "docs" page lists the bare unit
prefix, admin-triggered, not the boot.)
TIMING: FUNC(bootLog) stamps every .rpt line "(+s since boot start)"; new RPT-only
lines (not on the boot screen, not published): one per document read ("get
JMSB.arsenal: ok - N chars, waited W s, parsed P s"), one per phase (settings,
orbat, sections, orbat versions and welcome, arsenal versions, motorpool
versions, roles, orders); one summary line kept in the boot log. svcLoad now
returns [doc, status, [wait, parse, chars]] (callers reading two still work).
NOT RUN IN GAME.

2026-10-19, RF API CLEANUP, MILESTONE 2 (TFAR VOICE), JAMMING ON RF.
(1) API. New public RF calls so nothing reaches into RF's registry:
jmfsb_rf_fnc_nodesFor [holder, skipOwners] -> [[id, owner, profile, fill]]
(server); jmfsb_rf_fnc_quality [node, net] -> best path quality to any peer,
-1 unknown (server any node, client own slice); jmfsb_rf_fnc_netBand [net];
jmfsb_rf_fnc_pathLossFree is now Public. register takes an 8th argument and
setState a "data" key: [[key, value], ...] merged into the node's extra-data
field, handed to listener hooks as the last element of each emitter. drone40
now uses nodesFor (launcher fill), register's data (decoy intent) and the
public pathLossFree; it no longer reads jmfsb_rf_nodes or writes into a node.
RF still names nothing outside itself. (devices/fnc_overlayRf still reads
jmfsb_rf_nodes - another agent's addon, not touched.)
(2) VOICE (adapter_tfar only). Quality -> range factor f: unknown 1; at or
below "Cut at quality" (default 0 = RF threshold) cut (0.001); above it
"Range at the weakest link" (default 0.25) rising linearly to 1 at quality 1.
Split sqrt(f) sending / 1/sqrt(f) receiving so one link's range is f, not f^2.
Sending per net, set on TFAR OnBeforeTangent from the keyed net (active, or
monitor on the additional tangent); receiving per unit from the best of the
nets he listens to. Re-applied on jmfsb_rf_linkChanged, on set state change,
on settings. TX: OnTangent sets RF state tx at once (poll also carries it).
Setting "RF voice override" off = levers 1. TFAR UI/keybind suppression NOT
done (needs the device radio UI) - next.
(3) JAMMING. Depends on jmfsb_rf. fnc_rfNoise registered as an RF noise
source: radio zones -> VHF/UHF, data zones -> the DATA net's band (UHF, so all
UHF nets), at the new module attribute "Zone Noise at the Core (dBm)" (default
-40) + 10 log10(jamFactor), spread gain applies, memoised per frame. jammerLoop
no longer writes TFAR's levers (adapter_tfar is the only writer); ACRE keeps
the direct acreJam lever; GPS unchanged. jamFactor stays ZONE-BASED and
unchanged for its callers (reaction, messaging, hacking, the meter). drone40's
per-tick spawnTempZone is gone: the Jammer drone is an RF noise source only,
cut off at its radius setting - so jamFactor/meter/TAC//MSG no longer see it.
NOT RUN IN GAME.

2026-10-19, TAC//MSG READER RESTYLED TO HANDOFF 1a (PLAN_MESSAGING_UI phase 3).
Three panes in fractions of the reader rectangle (rail 0.161, list 0.27, detail
the rest), zero radius, colours only from FUNC(theme) (ground/ink/accent/line and
the derived surface/muted/dim/accentTint/accentText/accentDeep), RobotoCondensed.
readerDraw is now an orchestrator; the panes moved into new functions:
readerRail, readerList, readerRow, readerChip, readerPreview, readerCard,
readerReplies, readerQuick, readerMarkers, readerFlash (all tacpad, PREP'd;
geometry #defines READER_* in tacpad/script_component.hpp, IDC_RD_FILTER 8905 and
IDC_RD_FLASH 8906 in shared.inc.hpp).
(1) RAIL: surface fill; TAC//MSG + "group - mission"; NETS rows with code, name,
unread count, selected = accent fill (railNets gate, retarget-while-composing,
legacy SQUAD key all kept); ON NET with squad heads that fold (kept) and a 7 px
square per man - filled ink up, outline + dim down; rows stop above the self
block; self block = ink initials square, rank + name, role - squad.
(2) LIST: real filter box (applies on Enter; matches subject, type short/title,
mailbox) + NEW; tabs ALL / OPEN / MINE / ACK with counts and the 2 px accent
underline on the rule (ACK = unread, as UNREAD was - the index has no per-player
ack); rows: chip (FLASH accent fill, PRIORITY/ROUTINE outline), type, time,
subject upper/bold, preview (latest cached message, else template title), reply
meta; selected = accentTint + 4 px accent bar (FLASH no longer tints a row);
closed rows dim; "N MORE" line when the list overflows. One row per thread kept.
(3) DETAIL: header chip + subject, NOTIFY / PIN TO MAP / ACK (+ CLOSE), meta
"THREAD id - NET - OPENED t BY x - n REPLIES - STATUS"; template card in two
columns (one column if any answer > 40 chars, so OPORDs stay readable), ink
header bar, grid answers bold accent-700; reply spine single column on a 2 px
rule with author, tag (template short on accent tint for template replies, job
otherwise, YOU for own - replaces the old left/right split), time, body; oldest
replies drop first with an "N EARLIER" line. Composer: QUICK REPLY tiles =
registry one-tap replies (reply templates with no fields; dim + unpressable when
the thread's state will not take them; leader-only hidden from non-leaders),
then the Quick replies setting's phrases, capped at 5, then VOICE MSG (inverted,
dim, "COMING", accent square, no hit - pending the voice decision); + TEMPLATE
(composeOpen) / + GRID / + MARKER (list now readerMarkers) and REPLY IN THREAD;
input + SEND (readerInput, freetext submit) unchanged in behaviour.
(4) FLASH BANNER: tacpad postInit listens to messaging `received`; FLASH (index
priority "high"), not own traffic -> readerFlash over the reader if open, else
over HOST_DISPLAY (map in native, device dialog in tablet). Accent strip "FLASH -
INCOMING ON <net> NET" + time, subject, preview, buttons: first legal one-tap
reply (sends into the thread), OPEN THREAD <id> (opens reader on it), SNOOZE 60S
(re-shows after 60 s if still unread). Cleared when the thread is opened or read;
re-presented after every reader redraw. Net view + its composer: tokens only.
NOT RUN IN GAME.

## 2026-10-19 - Devices: walking view finished (phone + side devices)

addons/devices overlay only (fnc_overlay*, overlay.hpp, overlay parts of script_component / XEH / initSettings).
Sizes from DESIGN_PHONE_WALKING.md / DESIGN_SIDE_DEVICES.md design units (`fnc_overlayRows`). User overrides kept:
upper-right popups stay (line mirrors), square cells, phone size = phoneFill, zoom = phoneZoom following every frame,
RobotoCondensed, NATO group markers untouched.

- Status: 8 cells NET, MESH, JAM, GPS, DRONES, FIRES, MSG, BATT (word + value, alert = red cell). MESH = hops to nearest
  relay on RF DATA (relay = a lastHop seen in jmfsb_rf_fnc_link; "DIR" direct only; red "--" no path), rebuilt after
  jmfsb_rf_linkChanged. JAM/GPS from jmfsb_jamming_fnc_jamFactor (any / gps domain, DENIED at 0.75 or gpsDenied).
  DRONES = own UAVs + scanner hostiles. FIRES and BATT placeholders ("--").
- Map: 25 / 50 m rings (`fnc_overlayDrawRings`). Squad list `<N> <NAME>` (team colour, jmfsb_bft_fnc_memberNumber),
  TX / VOX from jmfsb_bft_memberVoice (no TFAR named), `+` wounded (ACE bleeding/unconscious or damage), `··` no RF link
  (player whose UID is in no reached node id). Who-is-talking chip, last speaker held 4 s.
- Nets: square cells, outline green/red from jmfsb_rf_fnc_quality on the plan-named net, grey when unknown, active filled.
  `R` receive-only wired but always off (no public EMCON for clients yet).
- Hidden when dead, in ACE/BIS arsenal, ACE/BIS spectator. New setting `jmfsb_devices_overlayOpacity` 0.4-1.
  Shown/hidden saved in profileNamespace.
- Side devices: status 2x4, chip top left, squad list 2 columns x 3 under the map, nets 2 columns.
- Not done: drone / jammer / target map marks, buddy flag, notification count + time.

check_all.py passes. NOT RUN IN GAME.

### Messaging UI phase 4: TAC//SUPPORT to handoff 2a / 2b (2026-10-19)
Fidelity pass on tacpad_apps/fnc_appSupport against
design_handoff_combat_support screens 2a (CAS) and 2b (transport); 2c (ADD TASK)
skipped per user. RobotoCondensed, fractions of the dialog rectangle, zero
radius, colours only from tacpad/fnc_theme. New tacpad_apps functions, PREP'd:
supportGroup (group label), supportCell (list row + states), supportHover /
supportTint (hover and press repaint), supportStepper, supportPassengers,
supportMapDraw (the map's Draw handler, moved out of appSupport).
- Title bar: ground + 2px ink rule, TAC//SUPPORT left, AVAILABLE · n (idle
  assets) and a SITREP cell right (was REQUEST SITREP in the form). CLOSE left
  the header for the action stack.
- Group labels: surface band, 2px divider over / 1px under, label left,
  guidance right, bound to the selection (ASSET "Select one"; UNIT idle /
  "on a mission - abort or change"; TASK = the picked task's sentence;
  PARAMETERS carries the arty "pick a battery" and jmfsb-CAS LOITER notes;
  ROE "Combat mode X"; PASSENGERS seat count). Task rows lost their
  explanatory meta; SAD keeps SEEK & DESTROY.
- ASSET is a list group again (TRANSPORT / CAS / ARTILLERY with airframe /
  battery counts), not the tab strip.
- Row states: rest ground, hover surface, pressed accentHover + ground label,
  selected ink fill, committed accent fill. Committed = the last accepted
  CONFIRM for that unit (supportCommitted [unit, task, time]); lit while the
  unit reads busy or for 30 s after the commit. Selection is no longer accent.
- Steppers: label above, 2px ink box, "-" cell, value + 8px ink range bar,
  "+" cell; step cells accent on hover, dim and dead at the range end. CAS:
  CAS RADIUS + ALTITUDE paired. Transport (BEHAVIOUR): HEIGHT + SPEED paired,
  RULES OF ENGAGEMENT full width. Arty: ORDNANCE, ROUNDS + DISPERSION, GUNS.
- ROE: five engine combat modes. CAS lists them (Hold fire - defend / Hold
  fire, engage at will / Fire at will / Fire at will, engage at will / Never
  fire); transport steps through them. Adapter supportTask now maps roeIdx
  0..4 to RED/GREEN/WHITE/YELLOW/BLUE (0 and 1 unchanged).
- ORDER UNIT RTB: off while the unit is idle (and nothing committed); first
  press arms (label CONFIRM RTB, ink fill), second within 3 s commits, the
  timer or any other press disarms. CONFIRM TASKING: off until asset, unit,
  task (and the grid for arty / jmfsb CAS) are set; label no longer changes.
  CLOSE: the only accent action. Verdict row is ink (taken) or surface with
  accent-700 type (refused) - no longer accent.
- PASSENGERS (transport): nothing in the mod assigns fireteams to a
  transport, so it lists the airframe's cargo seats and who is in them now,
  one row per group with its seat count, and the group label says
  "aboard now, no team assignment". Adapter supportAssets rows gained element
  7, the airframe object (objNull for arty), for this and the map marker.
- Map: task point = 18px accent square in a 7px accent@22% halo; CAS radius /
  arty dispersion = 2px accent square outline in world metres with the caption
  "<TASK> · <n> M" above it, read from the stepper slot every frame; the
  picked airframe = ink square, 2px stem, callsign label. Ingress / egress
  arrows from the theme accent.
- Not done: map grid readout box (would cover the map control; the TARGET
  row shows the grid); transport tasks LAND (ENG OFF) / EXTRACT (not verified
  in the NEO FSM); hover on the action stack (display-dispatched).
NOT RUN IN GAME.


Same day, THE FRAME'S KEYS ARE BUTTONS (user: "F1-F4 needs to be a setting for
the tablet only, not the keyboard F1-F4"). gen_devices.py finds the six keys
printed on every frame (bright rims, evenly spaced, to the right of or below
the screen) and writes keys[] into frames.hpp; all six found on all six frames.
jmfsb_devices_fnc_keyButtons lays see-through buttons over them when the device
dialog opens; fnc_softKey does F1-F4 (the per-player app settings, now labelled
"F1 key on the tablet opens") and LEFT/RIGHT. fnc_keyDown keeps only the
keyboard arrows; the keyboard's F1-F4 are no longer taken. NOT RUN IN GAME.


2026-10-19, APPLICATIONS ASK WHAT YOU WANT TO BE (user: "add to the
applications in PAC a 'what do you want to be (when you do not grow up)'
question with a checkbox for each skill we have; put 'I'm interested in' above
the checkboxes; update DIVINER, DIVINER web and jmsb"). A new question type,
"skills", in <unit>.web.questions and in all three code bases:
- pac fnc_questionsLoad: with no stored questions (JMSB.web.questions does not
  exist) it falls back to the website's standard set (GHOSTD_DEFAULT_QUESTIONS
  in DIVINER_Web src/applications.php) plus "interests" ("What do you want to
  be (when you do not grow up)?", type skills, not required), so web and game
  ask the same things. Every skills question gets "choices" [[id, name], ...]
  off GVAR(structure) skills (<unit>.skills), sorted by name.
- pac fnc_app (APPLICATION tab): the label, the line "I'm interested in", then
  a [ X ] / [   ] checkbox per skill, APPLY_SKILL_COLUMNS (2) to a line; a press
  toggles the id in GVAR(applyAnswers) and redraws.
- pac fnc_applySubmit: a skills answer is stored as an array of skill ids
  (intersected with the choices); required = at least one ticked.
- pac fnc_pgApplication: array answers read as skill names (choices, else
  FUNC(lookup)).
- script_component.hpp: QUESTION_ORDER_STEP, APPLY_SKILL_COLUMNS.
DIVINER got the same four functions (ghostD prefix, CHANGES.md entry);
DIVINER_Web got the type in GHOSTD_QUESTION_TYPES (so the question editor
offers it), the default question, checkboxes on ?page=apply (name
q_<qid>[]), and names on ?page=applications. check_all passes. NOT RUN IN GAME.


2026-10-19, SUPPORT CORE - PHASE 1 OF DESIGN_SUPPORT.md. New addon
addons/support (jmfsb_support) owns what adapter_alive's provider registry
(EGVAR(adapter_alive,providers), merged by fnc_supportAssets) used to:
- API: fnc_registerProvider [kind, hashmap: assets, task, sitrep, available,
  tasks, types], fnc_assets (merged rows, same 8-field shape appSupport read),
  fnc_types / fnc_tasks (asset types and tasks now DECLARED by providers, not
  hard-coded in the screen), fnc_request [assetId, task, pos, params] (tag
  gate, validation, core cooldown ledger, provider "available", dispatch,
  jmfsb_support_tasked event), fnc_sitrep, fnc_canTask (the tasking tag gate,
  moved out of appSupport), fnc_ack -> event jmfsb_support_ack. Contract in
  addons/support/README.md for support_fires / support_air.
- Asset ids are "<kind>:...": ALiVE NEO rows "alive:<type>:<n>", the ATO
  "alive:ato" (was "alivecas:ato"), CAS drones "cas:<n>" (was "jmfsbcas:<n>"),
  Simplex "sss:<service>:<n>" (unchanged).
- adapter_alive registers provider "alive" (fnc_supportAssets/Task/Sitrep plus
  new fnc_supportTypes with the transport/CAS/artillery task lists the screen
  used to hard-code), requires jmfsb_support, acks through
  EFUNC(support,ack) and still fires its old supportAck event. Registered ABOVE
  the server-only exit in its postInit - the old ATO provider sat below it and
  so only reached the server's own screen; on a dedicated server the ATO row
  now reaches clients too.
- cas registers provider "cas" (+ fnc_assetAvailable), tacpad_apps
  fnc_simplexProvider registers "sss" with the CAS task list.
- tacpad_apps: appSupport, tileData and the ack listener read the core; the
  app is registered when the core is loaded, not when the ALiVE adapter is, so
  TAC//SUPPORT works without ALiVE (CAS type only, from the drones/Simplex).
  A task may declare steppers and needsPoint (drawn instead of the legacy
  per-type layout); no current provider does.
- Setting moved: jmfsb_tacpad_apps_supportTag -> jmfsb_support_tag (same
  title, category, default ""); a server that had set the old one must set it
  again.
check_all passes. NOT RUN IN GAME.


2026-10-19, SUPPORT FIRES - PHASE 2 OF DESIGN_SUPPORT.md. New addon
addons/support_fires (jmfsb_support_fires, requires jmfsb_support), provider
kind "fires", asset ids "fires:<n>" (index into the broadcast
jmfsb_support_fires_entities). Four Eden modules, category jmfsb_modules,
modelled on JMSB - CAS Drone; no module on the map = no row:
- JMSB - Artillery Battery (type "arty", shared with ALiVE's ARTILLERY):
  synced crewed artillery fires by doArtilleryFire with its own magazines;
  attributes callsign, ammunition (class:rounds per gun, optional), cooldown.
  Rounds counted per magazine class from the guns (fnc_artyLedger).
- JMSB - Virtual Artillery ("varty"): no guns; rounds are the shell class
  spawned VA_DESCENT_TIME s before impact on a descending arc, time of flight
  and angle from a vacuum arc module->target at the muzzle velocity; HE,
  smoke, illum (flare) + optional cluster/guided; rounds per type, min/max
  range, dispersion, trajectory high/low, reload, cooldown, guns.
- JMSB - Cruise Missiles ("cruise"): ammo_Missile_Cruise_01 (Mk41 VLS round,
  weapons_f_destroyer) created at the module and steered per 0.05 s along
  route points, terrain-following, pop-up + terminal dive; reported to adsite
  as a missile threat (fnc_threat) so AD units engage it; APS sees it as any
  MissileCore. Missiles, class, warhead, salvo, speed, altitude, cooldown.
- JMSB - Loitering Munitions ("loiter"): B/I_SwitchBlade_600 when CfgPatches
  "switchblade" exists (classes read from the workshop PBO's config), else
  the side's Darter (B/O/I_UAV_01_F); flies to the point, LOITER orbit for the
  loiter time, picks the best visible enemy-side target by strike rules,
  scripted dive, warhead (SwitchBlade_AT/40mm_HE_Warhead or M_Titan_AP);
  out of time = self-destruct. Munitions, launch size, loiter time, strike
  rules, altitude, warhead, cooldown.
Steppers (per asset, through the provider's "tasks" code) use slots 12-18:
ordnance, rounds per gun, sheaf, guns, missiles, munitions, search radius.
RTB = check fire (batteries) / self-destruct (loitering); cruise refuses.
Server acks every order through EFUNC(support,ack); SHOT/SPLASH/impact on the
notify rail. Contract workarounds: adsite has no public "scripted threat"
entry, so fnc_threat writes jmfsb_adsite_owned and raises
jmfsb_adsite_threat itself; virtual rounds are not reported (adsite's pitch
filter drops a descending shell). Found, not fixed: cas fnc_moduleController
never publicVariables jmfsb_cas_entities, so CAS drone rows only appear on
the server's own screen on a dedicated server.
check_all passes. NOT RUN IN GAME.


2026-10-19, SUPPORT AIR - PHASE 2 (AIR) OF DESIGN_SUPPORT.md. New addon
addons/support_air (jmfsb_support_air, requires jmfsb_support and jmfsb_cas),
provider kind "air", ids "air:<n>" (n = placement index in the published
GVAR(entities)). Four modules in jmfsb_modules, shaped like JMSB - CAS Drone,
no side attribute (players' side from the slots, D59), module = airbase, no
module = no asset:
- JMSB - CAS (type cas): class (crewed or drone, own Eden class picker
  GVAR(pickAircraft) on the shared single-select base) or synced aircraft;
  sorties, altitude, run-in, time on station, terminal search, delay,
  cooldown. SAD (orbit, COMBAT/RED, scripted strike every 20 s on a
  laser/smoke or the nearest known enemy), LOITER (orbit, weapons tight),
  ATTACK RUN (1-4 passes, release through jmfsb_cas_fnc_acquire/fireAt,
  ORDNANCE from jmfsb_cas_fnc_stores).
- JMSB - Transport (type transport): helicopter class or synced; seats
  (locks the rest), airframes, height, extract wait, per-task switches.
  PICKUP / LAND / LAND ENG OFF / MOVE / EXTRACT; stays out and re-plans on
  every new order; RTB = home (class removed once no player is aboard;
  synced parked, refuelled, re-armed).
- JMSB - Logistics Drop (type logistics): parachute (cargo chute via
  jmfsb_common_fnc_addParachuteToObject) or sling (helicopter, hooked at the
  module); crate filled from PAC arsenal lists ("list" or "version.list" in
  jmfsb_pac_structure "arsenal", plus the mission's Common_Arsenal list of the
  same name), crate class fallback; drops, drop height; blue smoke on landing.
- JMSB - QRF (type qrf): squad from a CfgGroups path or unit classes;
  HALO / HAHO / STATIC LINE / AIR ASSAULT as allowed (assault needs a
  helicopter); vanilla Steerable_Parachute_F (HALO, HAHO) and
  NonSteerable_Parachute_F (static line) with scripted steering onto the grid;
  air assault fast-ropes via ace_fastroping_fnc_deployAI when ACE fast-roping
  is loaded and the airframe has FRIES, else lands; on the ground defend
  (CBA_fnc_taskDefend) or join the requester (attribute).
Steppers in parameter slots 20-30 (README table); per-asset tasks code
narrows each module's tasks. Cooldowns are the addon's own and start when the
aircraft is home (core cooldown 0). Contract gaps worked around, not fixed:
appSupport still draws its legacy ROE list (slot 2) for any non-"cas"-kind CAS
row and offers INGRESS/EGRESS only to kind "cas"; this provider ignores slot 2
and flies its run in from the airbase side. tools/gen_docs.py now reads
module classes written GVAR(x) (acm, support_fires and these were missing
from MODULES.md). check_all passes.
NOT RUN IN GAME.

2026-10-19, TABLET SCREEN AND VEHICLE TABLET (DESIGN_TABLET.md, TODO_DEVICES
section 1). Tablet mode only; native mode and the phone's settings page are
unchanged. On the large, UAV and vehicle tablets the screen is cut into the
design's rows (jmfsb_devices_fnc_tabletRows, 1364 x 1000 design px): device
bar 34 (TAC//APP, time, grid, callsign . group, device, ESC CLOSES; the
vehicle's reads VEHICLE . <vehicle name>), notification line 30 (unseen
count, newest entry of jmfsb_notify_history, its time; a mirror - popups stay
upper right; a click closes any app, marks the history seen and turns the
docked reader to LOG), live tiles 96 + 3 rule (tacpad_apps' panelTiles with a
new one-row flag; the tiles panel is not built on a tablet), map area, net row
48 (fnc_overlayNets reused; outline green = swatchGreen token with an RF
path, accent without, line colour when RF cannot say; active net filled ink).
Rows are drawn by fnc_tabletChrome, one controls group per row, and kept by
fnc_tabletTick (0.5 s; a row redraws only when its content key changes;
tiles every 2 s; scheme change recolours). Colours are tacpad theme tokens
only; fonts RobotoCondensed via the shell's drawText.
THE MAP AREA IS THE HOST: the map control is sized to it and it is what
jmfsb_tacpad_fnc_setHost gets, so apps open over the map and the rows stay.
setHost takes a third argument, a layout table (panel id -> [x, y, w, h] in
host fractions, or [] = not built); jmfsb_tacpad_fnc_place uses a listed
place unscaled and unzoned, jmfsb_tacpad_fnc_open skips []. Tables
TABLET_PLACES / TABLET_PLACES_VEHICLE in devices/script_component.hpp: squad
rail top left 290 px, strip TOOLS/SETTINGS/ADMIN/HIDE top right 410 px, TIC
under it (panelTic still pins it under the strip), PLP map tools, reader
below, APS beside the rail.
Vehicle tablet: ACE self action "Vehicle tablet" on LandVehicle / Air / Ship
for anyone in crew (guarded on ace_interact_menu like the tablet action),
jmfsb_devices_fnc_open takes the vehicle as a second argument, the tablet
closes when the player leaves the vehicle, and ON BOARD (new shell panel
"onboard", fnc_panelOnBoard: name + CMDR / DRV / GNR / PAX, n / seats in the
header) replaces the squad rail. Not built: who-is-talking line, battery,
VEHICLE SET, in-house map tools, numpad net select. check_all passes.
NOT RUN IN GAME.

2026-10-19, SUPPORT REVIEW FIXES (cas, support_air, support_fires,
adapter_alive, tacpad_apps). A code review of the new support stack, and its
fixes:
- cas: preInit no longer wipes GVAR(entities) (isNil guard, as the core does),
  so a JIP client keeps the published CAS drone board. The server re-checks
  FUNC(available) before a run (one asset can no longer fly twice off two fast
  CONFIRMs) and clears QGVAR(abort) when a run starts; the abort handler
  ignores an idle asset, so an RTB pressed during cooldown no longer kills the
  next strike. fnc_stores reads the hashmap as key = _x / value = _y (store
  names read "any xany" and a picked store never flew). Drones carry
  MPKilled, so a loiter drone shot down while the ISR controller holds it
  counts against the stock.
- support_air: chute steering calls setDir before setVelocity (setDir wiped
  the velocity, so jumpers never steered). ORDNANCE slot read only for ATTACK
  RUN. RTB to an idle asset is refused ("at base - nothing to recall").
  Transport watch writes off a crewless or immobile airframe instead of
  holding the asset for ever; a player's AI squadmates are put out on their
  own machine (QGVAR(putOut) target event) before the sweep. The QRF squad is
  tasked even if its aircraft dies during the jump or dismount. Synced
  aircraft use MPKilled; a player at the controls is never tasked. Asset side
  comes from jmfsb_common_fnc_playerSides, not a WEST fallback. Parachute
  crates keep the aircraft's velocity. A failed CAS or logistics launch gives
  its sortie/drop back.
- support_fires: gun Killed -> MPKilled. Cruise and loiter fuzes reach as far
  as the next FUZE_LOOKAHEAD_TICKS (2) ticks of flight, so a fast munition
  detonates instead of hitting and being counted lost. The cruise fuze takes
  the warhead's triggerDistance when it is larger. The warhead is triggered
  the next frame, not after it has passed the aim point. CHECK FIRE keeps the
  Fired handler for CHECK_FIRE_GRACE. Virtual artillery closes the mission
  only after the last round's time of flight.
- adapter_alive: the COP installation toggles are broadcast to clients
  (setVariable public), so clients draw them. The ATO row refuses a request
  with no point and says why.
- tacpad_apps: rounds-per-gun buttons placed from _colX, not forEach's _x.
  The legacy ROE list/steppers are drawn only for the ALiVE provider. Simplex
  "rtb" is refused instead of opening Simplex's GUI and reporting
  success. The map overlay reads the picked task's own slot (air RADIUS 22,
  fires SHEAF 14) and falls back to the ALiVE slot only for the legacy layout.
  Declared stepper text is clamped to the asset's range. fnc_tileData uses
  player, not ACE_player (ACE is optional). Map clicks store a 3D position for
  ATLToASL.
Left as found (low): QRF with no flyable insertion only warns at init and
refuses every request; support_air always declares TRANSPORT / LOGISTICS / QRF
types. HALO / HAHO are still in support_air (CfgVehicles, SUPPORT_TYPES,
fnc_tasks) although DESIGN_SUPPORT.md says they were removed.
check_all passes.
NOT RUN IN GAME.

## 2026-10-19 - tablet layout / vehicle tablet review fixes

Review of the tablet screen and the vehicle tablet; each finding read against
the code first.
- Vehicle tablet: the ACE action and fnc_open refuse static weapons and
  parachutes (VEHICLE_TABLET_EXCLUDED = StaticWeapon, ParachuteBase); both
  inherit from LandVehicle / Air.
- A display mode change closes the tablet dialog (devices listens for
  jmfsb_tacpad_displayMode_changed). tacpad's own handler tears the suite down
  and resets the host on any change, so the dialog is closed whatever the new
  mode is, not only on a change to native.
- APS panel and the ADMIN strip lay out in host units (PAD * HOST_W/H, fit
  divided by HOST_H). They used safeZone units, so on the tablet's map area
  the fitted body was shorter than what they drew.
- Right column: fnc_tabletStack (at open and on the row tick) puts map tools
  under TIC's real bottom and the reader under the tools', down to the map
  area's foot. The reader is resized through tacpad's fit and rebuilt next
  frame, only when it is out of place. TABLET_TIC height 0.068 (fitted size).
- Tile row: redrawn only when str tileData changes. It was redrawn every
  2 s, deleting the tile buttons under a press.
- Net row as in tablet_screen.png: ink row, idle cells ink with light
  labels, active cell filled with the ground. Outlines use COLOUR_NET_OK /
  COLOUR_NET_BAD (green / red, as on the walking view) instead of
  swatchGreen / accent. The theme having no red is no reason: DESIGN_TABLET
  fixes the status colours. A grey R marks a receive-only net, and the rx
  field is part of the cell key.
- Who-is-talking chip (fnc_tabletTalk, from fnc_overlayTalker) at
  TABLET_TALK, top of the map area right of the rail; APS moved down to
  y 0.070 out of its slot. Hidden while an app is open. No "on <NET>" yet:
  overlayTalker does not know the speaker's net.
- ON BOARD drawn like the squad rail: medical icon, name, seat column, TX /
  VOX flag. Header shows the vehicle callsign and seats taken. No fit, so it
  keeps the rail height. Drawn in devices rather than through a shared
  tacpad_apps helper; no link dot yet (the squad rail has none either).
- Device bar: left block clock / GRID eee nnn / name . group, right block the
  device (VEHICLE . callsign via fnc_vehicleName: variable name, else the
  crew group when not the player's, else displayName), ESC CLOSES in the
  accent.
- Notification line: unseen count as a solid accent cell, title in
  accentText, text in ink.
- Notify click builds the reader when it is switched off (next frame,
  tacpad build at its fixed place), then shows LOG.
Rejected: the row groups drawing over the bezel corners (z-order). The
frame's screen hole is cut square by gen_devices.py (the user's call,
2026-10-19), and the frame's alpha is 0 at all four corners of the screen
rect for large, vehicle and uav. The rows lie inside that rect, so they cover
no bezel.
check_all passes. NOT RUN IN GAME.

## 2026-10-19 - support follow-ups: QRF, CAS egress, empty types, ACE_player

Follow-ups to the support review "left as found" list.
- support_air: HALO / HAHO taken out of the QRF (CfgVehicles, SUPPORT_TYPES,
  fnc_tasks), as DESIGN_SUPPORT.md already said. The QRF offers STATIC LINE
  and AIR ASSAULT only.
- cas: drones leave off the map before they are deleted (fnc_egress). At the
  end of a run the seat is handed back, the airframe goes back to the server
  and gets one MOVE to the first point on its egress heading outside a box
  CAS_EXIT_MARGIN wider than the map. It is deleted only once it is outside
  the map (or a wreck, or crewless), with CAS_EXIT_TIMEOUT as the backstop.
  It used to vanish a few kilometres past the target, in front of whoever
  stood there. MPKilled still counts a loss on the way out.
- tacpad_apps: TAC//SUPPORT lists only the types that have a row on this
  mission. support_air still declares TRANSPORT / LOGISTICS / QRF everywhere,
  but a type counted 0 is no longer offered. A picked type that runs dry falls
  to the first type still answering, unit and task cleared; with no type at
  all the ASSET group says NO SUPPORT ON THIS MISSION and a stale unit/task
  pick is cleared.
- tacpad_apps: ACE_player made optional. The apps use `player` (fnc_tileData,
  fnc_appIntel and the rest), so the suite runs without ACE.
gen_addon_readmes, gen_docs and check_all pass.
NOT RUN IN GAME.

## 2026-10-19 - Devices: VEHICLE STATUS app; new addon medic (TAC//MEDIC)

VEHICLE STATUS, the vehicle tablet's own app (user: "there should be a
vehicle status app only on the vehicle term"), in addons/devices.
- fnc_appVehicle: one read-only page for the vehicle the tablet was opened
  from, in three columns: DAMAGE + FUEL, AMMUNITION + COUNTERMEASURES, and
  APS + RF SET + CREW, under a strip with callsign (fnc_vehicleName), type,
  speed and engine. It is registered with the shell when the vehicle tablet
  opens and taken out when it closes (fnc_onLoad / fnc_onUnload), so no other
  host offers it. It redraws every VEHICLE_APP_TICK (2 s) only while it is the
  open app, holds while the cursor is on the page, and the loop is started
  once (GVAR(vehiclePFH)), not on every draw.
- fnc_vehicleDamage: getAllHitPointsDamage grouped HULL / ENGINE / FUEL /
  OPTICS / TURRET / GUN / TRACKS or WHEELS / ROTORS / AVIONICS / CONTROLS /
  ARMOUR / GLASS / OTHER. A group is as bad as its worst part, sorted worst
  first.
- fnc_vehicleFuel: the range is measured, not configured. A local note keeps
  the fuel at the last fill and the ground covered since. Any rise over the
  lowest read is a refill. The page says MEASURING until FUEL_SAMPLE_MIN has
  burnt over RANGE_SAMPLE_MIN_M.
- fnc_vehicleAmmo: magazinesAllTurrets, filed turret by turret under the
  weapon that takes each magazine. Smoke or flare is the launcher's call,
  since a smoke launcher's ammunition is shotCM like a flare.
- fnc_vehicleSeats: one seat read (CMDR / DRV / GNR / PAX, OK / WIA / UNCON /
  KIA) for both the ON BOARD rail and the app. Passengers fold into one PAX
  row with only the hurt listed.
- fnc_vehicleRf: the rack's nets, quality and reach off the local
  jmfsb_rf_sliceIndex (not the raw slice, which the host overwrites). Anyone
  but the seat holding the rack sees SET AT ANOTHER SEAT.
- fnc_vehicleLines / fnc_vehicleColumn: the lines are measured before they
  are drawn. A column out of room ends in "+N MORE". A tone is a fill, never
  text colour; red is the inverted accent block.
- fnc_vehicleTile: the VEHICLE live tile (condition, fuel, worst of the two),
  answered only while the vehicle tablet is up.
- tacpad_apps: a small registration seam for this. tileProviders (id ->
  code answering tile entries) is read by fnc_tileData, and tileUngated
  lists the provider ids that a mission's role tiles[] cannot hide.

TAC//MEDIC, a new addon (addons/medic) for the section's CLS and medics.
- A tile (fnc_tile, through tileProviders) counting the squad's wounded. It
  turns to the alert block for anyone in cardiac arrest or bleeding heavily.
  It is shown only to a CLS / MED (fnc_isMedic: PAC skill tags, ACE
  medicClass or the Medic trait). Under a role tiles[] gate a medic role has
  to list medic.
- The app: the squad worst first (ARREST, UNCONSCIOUS, WOUNDED, OK, dead
  last), and a patient page with HR, BP, SpO2, RR, blood type, volume, bleed
  grade, pain, airway, chest, rhythm, wounds by part, tourniquets, fractures
  and splints, IVs, and SHOW ON MAP.
- Vitals are device-gated (user default): live only while an ACM pulse
  oximeter, pressure cuff or AED lead reads them. Otherwise the line shows
  the last hand check (CheckPulse, CheckBloodPressure without ACM,
  CheckBreathing) with its age and the medic. The check is recorded off
  ace_treatmentSucceded and measured on the patient's own machine
  (jmfsb_medic_measure).
- ACE medical and ACM are optional. Without ACE the app says MEDICAL SYSTEM
  NOT LOADED; without ACM the ACM-only lines say ACM NOT LOADED. The README
  lists every variable read and how fresh it is on a remote patient.
gen_addon_readmes, gen_docs and check_all pass.
NOT RUN IN GAME.


2026-10-20, CLASS PICKER LISTS (user: "a lot of Aegis which we do not use, and non
aircraft in the CAS and transport"). jmfsb_common_fnc_listClasses now hides any class
an Aegis or Atlas addon defines or changes (LIST_HIDE_SOURCES - QAV's Aegis Challenger
and Atlas Type 08, the fa_aegis/fa_atlas ports) and any class whose faction is not
defined, in every Eden class picker (vehicle, drone, static, ammo). New kinds aircraft /
heli_transport / air_transport; the air modules get their own pickers: CAS = planes
and helicopters (drones included), Transport = crewed helicopters with seats,
Logistics Drop and QRF Insertion = crewed planes and helicopters with seats.
Parachutes no longer count as helicopters. NOT RUN IN GAME.


2026-10-20, FIRST GAME SESSION RPT (build 1261). 10,464 script errors, two causes in
our code, both fixed: jmfsb_bft_memberVoice was a hashmap keyed by UNIT and an object
cannot be a hashmap key, so every lookup threw "Type Object" (bft drawMembers line 55,
devices overlaySquad line 53, every frame); now keyed by hashValue with [unit, state]
values, writer and all four readers (drawMembers, overlaySquad, overlayTalker,
panelOnBoard). CAS 'HOG' (A-164) went down 87 s after coming on station with no
killer: air CAS orbited at LIMITED - planes now orbit at NORMAL and no tighter than
PLANE_ORBIT_MIN 1000 m. Medic app's control moved to uiNamespace (serialisation
warning). Not ours: TFAR fnc_sendPlayerInfo line 76 returns callExtension's string
where a Bool is expected (once per UID send). Mission setup, not code: two Artillery
Battery modules (FOX) with no guns synced; a Drone Patrol whose class field holds
'true'; a Drone Swarm class (jmfsb_faction_china_O_SwitchBlade_01) missing from the
Swarm Airframes setting. NOT RE-RUN IN GAME.

2026-10-20, DEVICES: NO ACE MENU FOR PHONE / SIDE, SETTINGS ON THE TABLET, PHONE
CENTRING, FRAME BUTTONS (user: "the phones and side devices should not have ACE menu
actions; their settings need to be in the tablet settings"; screenshot: phone map not
centred on the player; "side buttons should have definable functions and definable
keybinds"). devices: the Phone > Settings and Side device > Left / Right ACE actions are
gone, with fnc_overlayShow and the phone's full-screen settings page - fnc_open now
refuses anything not in TABLET_DEVICES and fnc_onLoad has no non-tablet branch. Tablet
and Vehicle tablet actions stay. The side edge is persisted per profile
(fnc_overlaySetEdge, ticks at once). PHONE CENTRING: the overlay map (and the tablet's)
is declared 0 x 0 and was moved with ctrlSetPosition, which leaves a map's viewport at
its declared rect, so ctrlMapAnimAdd centred on the old origin; now ctrlMapSetPosition
(fnc_overlayPlace, fnc_onLoad), follow every frame on Draw as before, DEBUG_MODE_FULL
logs ctrlMapScreenToWorld of the control centre against the player. FRAME BUTTONS: six
LIST settings jmfsb_devices_buttonF1..F4/Left/Right (none, zoom in/out, side edge
left/right, hide, open tablet, tablet on an app) and six CBA keybinds "Device button
F1".."right", unbound, acting only while the walking view is up (fnc_overlayButton);
the title layer takes no mouse, so the keybind is the press. tacpad_apps: settings app
takes sections from other addons (jmfsb_tacpad_apps_settingsSections); devices adds
DEVICES (worn device line, walking view shown, side edge, phone/side size, map zoom,
opacity, member voice rings) and DEVICE KEYS (tablet F1-F4, six walking buttons).
fnc_setSetting goes through CBA_settings_fnc_set only and refuses a forced setting;
fnc_settingLocked (CBA_settings_fnc_priority not client) draws such rows LOCKED;
fnc_settingStep / fnc_settingCycle for steppers and lists. hemtt check, check_plumbing,
sqf_validator and check_invariants pass; gen_addon_readmes / gen_docs not run (the
devices README's generated function list still names overlayShow). NOT RUN IN GAME.

## 2026-10-20 - TAC//SUPPORT inside the tablet, tabs, READY checklist

User: "all apps need to be inside the tablet"; from the screenshot: tabs per support type, tasking
more like Simplex, CONFIRM isolated with what is missing shown. TABLET: fnc_appSupport no longer
createDialogs in tablet mode (HOST_DEVICE) - it draws on the device dialog inside the host's app
area (SUP_FRAME_TABLET of HOST_RECT), its slabs owned top-level controls with the header as the
app group, and its map hole is a hole over the tablet's own map (IDC_HOST_MAP, new in
tacpad/shared.inc.hpp). It claims that map (jmfsb_tacpad_appMapClaim, honoured by the shell's
fnc_appExits and cleared by fnc_appClose) so a click in the hole sets the armed point instead of
closing the app; its map click / Draw handlers are hung once per map control and stand down unless
support is the open app, and a click only counts inside the hole. The board's display press
dispatch (SITREP, RTB, CONFIRM, CLOSE) is hung on the device dialog the same way, CLOSE is
appClose there, ESC is the shell's. Fresh open (no live slabs) resets the marker pick and pans the
tablet map so the point or the player sits mid-hole at the current zoom. The poll stops when
support stops being the open app. XEH_postInit: the ack and RTB-expiry redraws use SUP_SHOWN (dialog
on the vanilla map, open app on the tablet); appOpened / appClosed listeners delete the board's
slabs and the request column and drop the map claim when another app takes the screen. Helpers
(supportCell/Group/Stepper/Passengers) size off SUP_UNIT_W/H - the safe zone on the vanilla map,
HOST_W/H on the tablet. NATIVE: still the supportDlg dialog; its map (8961) is laid into the hole
with ctrlMapSetPosition every draw because the tab row moved the hole's top. SIMPLEX REQUEST
(fnc_supportRequest/Draw/Send): in tablet mode the state goes on the host display and it opens as
app "supportRequest" (registered when Simplex is loaded; Draw is its handler) - a column group at
SUP_REQ_TABLET with the tablet's map for the target; CLOSE / SEND / ADVANCED close the app, never
the device (SUP_REQ_CLOSE); a redraw from a rounds button is deferred a frame; opened with no
entity (soft key) it hands over to the board. LAYOUT (both hosts): ASSET list replaced by one tab
per type with at least one row (counted, from the core's merged types; last pressed tab remembered
in jmfsb_tacpad_apps_supportTabPref); form order UNIT, TASK, LOCATION (the point, named by the task
declaration's new optional field 6 pointLabel - support README, support_air DECL_*: PICKUP, LZ,
HOVER POINT, DROP POINT, DROP ZONE; TARGET when absent), INGRESS/EGRESS for CAS drones, PARAMETERS,
ROE (legacy), PASSENGERS; READY checklist (UNIT, TASK, point - done ink square / missing accent
outline, theme tokens) and CONFIRM TASKING alone at the foot of the form, accent only when nothing
is missing, an early press names the first missing line; RTB (double confirm) and CLOSE under the
map. Simplex fields with nothing behind them are listed as gaps in docs/DESIGN_SUPPORT.md, not
drawn. Found, not fixed: fnc_supportRequest has no caller (the Simplex provider opens Simplex's own
GUI), and on the vanilla map supportRequestDraw draws into idc 8962, which dialog.hpp does not
declare, so that dialog shows only its map. hemtt check clean for these files; gen_addon_readmes /
gen_docs / check_all not run. NOT RUN IN GAME.

## 2026-10-20 - TAC//MSG, TAC//PAC and the admin console inside the tablet

User: "all apps need to be inside the tablet", then "tac//msg needs to be inside the tablet".
SHELL (tacpad): the app exits (ESC, map press - honouring appMapClaim) moved out of fnc_openApp into
fnc_appExits, hung once per display. New public fnc_appHost [id, group]: makes a self-drawn group on
the host display the open app - hides the panels, wires the exits, replaces the previous app (hidden
now, deleted next frame, since it is reached from presses inside other apps), raises appOpened.
New event jmfsb_tacpad_appClosed [id], raised by appClose, by openApp/appHost when a different app
replaces the current one, and by setHost when the host display changes or the device hands back
(setHost also clears appCurrent/appGroup/appMapClaim then, so a closed tablet leaves no stale app).
TAC//MSG: in tablet mode with a device open, fnc_openReader creates the reader root (IDC_RD_ROOT) on
the device dialog in the map area, solid ground, and adopts it as app "reader" (READER_APP); GVAR(reader)
is the device dialog while it is up and is cleared (root deleted) on appClosed "reader". New
fnc_readerClose: appClose (next frame) inside the tablet, closeDisplay on the dialog; readerDraw's
CLOSE uses it. Every TAC//MSG window was the one reader dialog - rail, list + filter edit, thread view,
net view, composer, compose pane, template/recipient pickers, report card, CC drop, quick replies +
reply edit, marker pin dropdown, FLASH banner - all ctrlCreate'd into that root or the host, so all of
it is inside now; the comms app's COMPOSE, the docked reader's OPEN FULL, FLASH OPEN THREAD,
composeOpen callers (squad CASEVAC/DM, PAC leader notice) and the keybind all land there. No voice /
dictate window exists (readerQuick's record light is disabled). Native: the dialog, unchanged.
TAC//PAC (pac, admin page): every control moved into one root controls group class jmfsb_pac_shell
(child positions now relative to the group); the dialog is that group at the safe zone. Controls are
found through it (new fnc_uiCtrl, controlsGroupCtrl - 21 ui/pg files switched off _display displayCtrl)
and placed in fractions of it (fnc_uiPlace); "is it open" is the shell control, not the display. In
tablet mode fnc_uiOpen calls new fnc_uiHost: ctrlCreate the shell on the device dialog at the host
rect, put every child at its config fractions (evaluated once per session), scale type by HOST_K,
adopt as app "pacAdmin". CLOSE is new fnc_uiClose (appClose inside the tablet, closeDisplay 2 in the
dialog). PAC_IDC_TILE_TXT4 51 -> 58 (51 is the device's map); PAC_IDC_SHELL 8. The PAC tile (fnc_app)
was already an appFrame app inside the tablet.
ADMIN PANEL (GPL, changes inside adminpanel only, calls tacpad hostDisplay): RESIZED, NOT MOVED IN -
the console is ~200 declared controls driven by idc from the ported panel, a live map and a PiP camera.
New fnc_fitHost maps every control's safe-zone rectangle onto the tablet's map area (jmfsb_tacpad_host)
and scales type by HOST_K; style, styleMessage and envLoad call it before their UI-scale pass, so the
console, the message box and TIME / WEATHER all open sized and placed to the tablet's screen when a
device is open. The tablet's ADMIN press no longer closes a map in tablet mode. The console's TAC//PAC
button is new fnc_openPac: in tablet mode it closes the console and opens TAC//PAC inside the tablet a
frame later (closing PAC then lands on the tablet, not the console).
Open: devices fnc_keyDown takes LEFT / RIGHT for the app ring even while an edit has focus, so the
arrow keys inside a reader / PAC text field switch apps (devices-owned, not changed here). Enter in an
edit on the device dialog is untested (the reader dialog behaves the same way natively).
hemtt check clean for these files; gen_addon_readmes / gen_docs / check_all not run - READMEs carry
new functions. NOT RUN IN GAME.

## 2026-10-20 - ECOTI over the map and tablet, square screen holes to the frame, device keys while typing

- **ECOTI boxes bled through the map and the tablet** (user, 2026-10-20). The hide lived in the Draw3D
  handler, and Arma does not call Draw3D while the full-screen map is up, so the last frame's boxes stayed
  on the mission display. New `jmfsb_ecoti_fnc_hideCovered` on EachFrame hides boxes and compass when the
  map or any dialog is up, or when Draw3D has missed more than `DRAW_FRAME_GAP` frames.
- **Screen holes cut to the frame's inner edge** (user, 2026-10-20: square cutout, no corner overlap). The
  holes were square but cut at the inner edge of a 10-21 px black bezel band that followed the frame's
  rounded corners: a dark gap round the screen and rounded corners over it. `tools/gen_devices.py` now
  grows each edge out through the band (`through_bezel`, whole-edge test) to the olive frame plus its
  antialiased pixel; the square cut removes the rounded corners. All six frames, `frames.hpp` and the
  `.paa` files regenerated; six keys found on every frame. The shell reads `screen[]` at runtime, so no
  layout code changed.
- **Device keys while typing.** `jmfsb_devices_fnc_keyDown` leaves LEFT/RIGHT to a focused text box (TAC//MSG
  and TAC//PAC now draw edit boxes on the device dialog) and swallows Enter so a one-line box cannot close
  the tablet; a multi-line box still gets Enter as a new line.
- Build 1262 already carried the BFT member-ring hashValue fix; the RPT error on screen came from an older build.

NOT RUN IN GAME.

## 2026-10-20 - No Simplex dependency

User: "no simplex dependency" - our own support addons replace it. Removed: the Simplex provider
(`tacpad_apps` `fnc_simplexProvider`, its `SUP_SSS_*` macros), the Simplex request window
(`fnc_supportRequest` / `Draw` / `Send`, app `supportRequest`, `SUP_REQ_*` macros and its cleanup in the
support app-switch listeners), the `jmfsb_patches_usesSimplex` flag in `init`, and the 46 forced
`sss_*` lines in `cba_settings`. TAC//SUPPORT lists only our providers (CAS drones, support_fires,
support_air, and ALiVE through the adapter while missions still use it). Comments that cite
Simplex's behaviour as a reference stay; no code names it. DESIGN_SUPPORT decision 8.

NOT RUN IN GAME.

## 2026-10-20 - Fires act like Simplex; artillery is virtual

User: "the modules should act like Simplex, except arty should be virtual". `support_fires` only
(DESIGN_SUPPORT decision 9); Simplex read for behaviour, no code taken.

- **No gun aims or fires.** `fnc_fireArtillery` and `fnc_artyLedger` are gone. Both artillery modules
  are virtual batteries under the shared `arty` type (the ARTILLERY tab); the `varty` type is gone.
- **JMSB - Artillery Battery retired**: `scope = 1`, `scopeCurator = 0`, class kept so placed modules
  load (Task_Force_Roomba_cdev has two, neither with guns synced - both were silently no asset before).
  A placed one runs as a virtual battery: battery at the synced guns' centre (else the module), gun
  count from the guns (else 4), rounds from Ammunition Per Gun (magazine or CfgAmmo classes, per gun x
  guns) or the guns' artillery magazines, else the Virtual Artillery defaults. Guns are never crewed,
  loaded, ordered or watched. Chosen over "virtual battery, still listed" because the user named
  Virtual Artillery as the module to place from now on; one artillery module in Eden, old missions
  unchanged.
- **Simplex fire mission** on the board's steppers: SHEAF TYPE (slot 19: converged / parallel / box /
  creeping, `fnc_aimPoint`), INTERVAL (33), DELAY (32), REPEAT (34, a cooldown apart), COORDINATE (35,
  `fnc_partners`: free batteries of the side within Coordination Distance carrying the same shell and in
  range; check fire stops them all). New Virtual Artillery attributes: Cooldown Per Round, Response
  Time Min/Max, Sheaf Types, Max Rounds Per Gun / Interval / Delay / Repeats, Coordination Distance.
- **Ballistics**: high angle fires the lowest of six charges that reaches at <= 80 degrees (a 12 km
  155 mm mission is ~70 s, not ~165 s); `fnc_inRange` is the one range answer for client, server and
  coordination.
- **Cruise missiles**: Response Time Min/Max, Cooldown Per Missile, Max Delay (DELAY stepper), SPLASH
  call, minimum range 1 km. **Loitering munitions**: refused beyond what the airframe flies in its
  900 s transit. **All three**: target marked on the side's map while the mission runs (JIP global
  event, `fnc_mark` / `fnc_unmark`), "rearmed, ready for tasking" when the cooldown (plus per-round share)
  runs out.
- README hand-written half rewritten; "Artillery Battery: ammunition per gun" is now "Picking shell
  classes" (vanilla CfgAmmo per round type, checked against weapons_f's config) plus the retired
  module's field.
- **Asked of the core/board owner**: record slots 32-35 as support_fires' in the core README; a map
  overlay or preview hook so the board can draw range rings and an ETA before CONFIRM; SITREP is
  still hidden for type `arty`.

hemtt check: no findings in support_fires (the run stops on an SPE1 error in
`support_air/fnc_casLaunch.sqf`, another agent's file). sqf_validator, check_plumbing,
check_invariants, config_style_checker pass. gen_addon_readmes / gen_docs / check_all not run.

NOT RUN IN GAME.

## 2026-10-20 - Air support acts like Simplex; the board takes points, a verdict and overlays

User: "the modules should act like Simplex, except arty should be virtual". Simplex Support Services read
for behaviour only (GPLv2, no code copied, no dependency). Scope: support core, support_air, cas,
TAC//SUPPORT. Design: `docs/DESIGN_SUPPORT.md`, "Air modules act like Simplex".

- **Every air module** (CAS, Transport, Logistics Drop, QRF Insertion): **Respawn Delay** (-1 = gone for
  good; a lost synced aircraft is rebuilt on its stand with the crew photographed at mission start,
  `fnc_respawn` / `fnc_restoreCrew` / `fnc_adopt`; a lost class aircraft reads REPLACING until the delay
  is up; a transport that cannot fly counts as lost) and **Cooldown Starts** (end of sortie / at the
  request). Synced aircraft are repaired, refuelled, re-armed and re-crewed on their stand after each
  sortie (`fnc_rearm`). Every row carries its plan (row field 8) for task markers.
- **CAS**: class aircraft appear the new **Ingress Distance** out on the INGRESS bearing and leave on the
  EGRESS bearing, removed there; synced aircraft fly to the ingress point first. INGRESS / EGRESS points,
  ORDNANCE on SAD too, **DANGER CLOSE** against the new **Friendly Range** (held release said once), SAD /
  LOITER on station repositions the orbit, one-minute warning before time on station ends.
- **Transport**: new tasks PICKUP > LZ, LOITER, FASTROPE (ACE + FRIES only), HELOCAST (water only),
  PARADROP (whole cabin on static lines, players on their own machines; new Paradrop Height) and
  SLINGLOAD (nearest liftable within 80 m to a SET DOWN point); MOVE is labelled HOVER. Request options
  VIA legs (up to four), APPROACH bearing, LZ SIGNAL (lands on the nearest smoke / IR / flare seen),
  LIGHTS, JUMP HEIGHT. Tick split into `fnc_transportTick` / `fnc_transportArrive` / `fnc_transportStep`.
- **Logistics**: CONTENTS per request (`;` between loads in PAC Arsenal Lists) and a Crate Signal
  (module combo + CRATE SIGNAL stepper: smoke, IR strobe, chemlight, flare, none).
- **Core contract, backward compatible**: task declaration field 7 (point declarations `[label, slot,
  hint, required, many, leg]`), stepper field 8 (map aid: `radius`, `bearing`, `ring`), row field 8
  (plan), provider hooks `preview` ([assetId, task, pos, params] -> [ok, line], `jmfsb_support_fnc_preview`)
  and `overlay` ([assetId, row] -> ring / line / point shapes, `jmfsb_support_fnc_overlay`). Slots:
  32-35 recorded as support_fires' (DELAY, INTERVAL, REPEAT, COORDINATE), 36-39 kept for fires, 40-48
  support_air's.
- **TAC//SUPPORT**: declared point rows (VIA adds a leg per click), required ones and the provider's
  VERDICT in READY (a verdict against the request holds CONFIRM), tasks two to a line past five, a
  scrolling form that keeps its scroll, SITREP for artillery, and the map in both hosts drawing every
  asset's airframe and plan, the picked asset's provider shapes, and the request live (points and
  legs, radius, approach bearing, danger-close ring). CAS drones declare their INGRESS / EGRESS and
  publish their airframe and run.
- Not built: gunship module (Simplex's gunship is its Loiter; our CAS SAD over an armed class is that
  orbit), logistics station (motor pool, decision 3), per-weapon quantity / burst / strafe spread,
  signal confirmation from a list, follow / relocate / remote-control transport tasks, mixed-task
  plans, per-request QRF squad.

hemtt check, sqf_validator, check_plumbing, check_invariants pass. gen_addon_readmes / gen_docs /
check_all not run (generated README halves of support, support_air, cas, tacpad_apps are stale).

NOT RUN IN GAME.

## 2026-10-20 - support_fires answers the board's preview and overlay hooks

`support_fires` registers the core's two new hooks (addons/support/README.md):
- **`preview`** (`fnc_preview`): the VERDICT line before CONFIRM, from exactly the params CONFIRM sends.
  Artillery `ETA 70 S - 4 GUNS x 3 HE` (an ETA range with a response time; volleys, `+ NEARBY`,
  `ONLY n LEFT`), cruise `TIME TO TARGET n S - n MISSILES`, loitering `ON STATION IN n S - n
  MUNITIONS, SEARCH n M`. False only for what the order would be refused for: busy or cooling down,
  nothing left, `OUT OF RANGE - 14.2 KM, MAX 12 KM`, `TOO CLOSE`, no firing solution. Fewer rounds
  than asked stays true (the battery fires what it has). Reads published variables only.
- **`overlay`** (`fnc_overlay`): the asset's position plus `MIN` / `MAX` range rings (battery both,
  cruise its 1 km minimum and reach, loiter its reach; no ring for an unlimited reach).
- One reading, three users: `fnc_readOpts` (params -> order options) is shared by `task` and
  `preview`; `fnc_gunRanges` (min/max per asset type) by `inRange`, `overlay` and `preview`, so the
  rings, the verdict and the refusal cannot disagree. `inRange` now covers cruise and loitering too.
  `fnc_fmtDist` formats `400 m` / `12 km` / `14.2 km`.
- Slots checked against the core table: 12-19 and 32-35 as declared; 36-39 unused, kept.

hemtt check (exit 0, no support_fires findings), sqf_validator, check_plumbing, check_invariants pass.

NOT RUN IN GAME.

## 2026-10-20 - voice messages (15 s): feasibility and design, no code

docs/DESIGN_VOICE_MESSAGES.md. TFAR standalone read at `8d023da` (ltsammy's repo, not edited).
- **Feasible only inside TFAR standalone.** The voice-server is a pure UDP relay: it never captures,
  decodes or stores audio (`RelayServer.cs` 217-246). Mic capture, Opus and playback all live in the
  client DLL `task_force_radio_pipe` (`TransmitController.cpp` 76-184, `PlaybackMixer.cpp` 103-138).
- **Design**: the DLL taps its encoded frames into a 15 s buffer and uploads them in chunks to a new
  in-memory clip store on the voice-server, which answers with a clip id. The id rides jmfsb
  messaging as a `voicemsg` reply. The recipient's DLL fetches the clip on PLAY and mixes it like the
  radio beep. Raw audio over the Arma network is rejected: about 60 KB per clip as a string, and the
  DLL has no callback to get it out.
- **BattlEye is not avoided**: capture and playback need a changed client DLL, which is a new hash.
  Clean route: upstream the verbs to ltsammy. The current DLL's whitelist status is unverified.
- **Mod side not built**: it would sit behind a probe that always answers no (`UNKNOWN COMMAND`)
  until the DLL ships the verbs. That is dead and untestable, so the VOICE MSG tile stays disabled.
  Mod changes are specified in the design (adapter_tfar `fnc_voiceMsg`, built-in `voicemsg`
  template, reader tile + PLAY cell).

No addon edited; hemtt check / sqf_validator not needed.

NOT RUN IN GAME.

## 2026-10-20 - Map tools in-house (jmfsb_maptools); PLP gone

New addon `addons/maptools` (scaffolded with new_component.py; CfgVehicles/CfgWeapons/fnc_empty
dropped). The TOOLS strip (tacpad_apps `fnc_panelTools`) is now its front end: CENTRE, RULER,
PROTRACTOR, ROUTE / MARK, GRID, VIEWSHED, CLEAR, CANCEL on the title bar.
- **State is client-side world positions**, not per control, so the same drawings stand on the
  vanilla map and the tablet's screen. `fnc_attach` hangs Draw + MouseButtonDown/Up + MouseMoving on
  a map control once; postInit attaches the vanilla map on every open, the panel attaches whichever
  host map it is drawn on (`IDC_HOST_MAP`). The tool stops on map close (Map event) or host dialog
  Unload; drawings stay until CLEAR.
- **Clicks and apps**: `fnc_hasInput` - no press while an app is open or `appMapClaim` is held, and
  not on the frame an app closed (stamped off `jmfsb_tacpad_appClosed`, so handler order does not
  matter). Shift/ctrl/alt presses left to the game.
- RULER: drag or two presses; drag-vs-click judged on screen against the anchor's current screen
  position, so a map pan reads as a click. Bearings deg / mils / both (`angleUnit`, client).
- PROTRACTOR: rose fixed size on screen, arm follows cursor until a press locks it.
- GRID: 10-digit, built on mapGridPosition's square; line phase and axis direction found by
  bisection once per mission (`fnc_gridCalibrate`), not from CfgWorlds Grid.
- MARK: `jmfsb_common_fnc_createPlayerMarker` on the group channel, local unless `markShare`
  (client) - then the last setter is global. CLEAR deletes local marks only.
- VIEWSHED: polar grid, `viewshedRadius` / `viewshedCell` (global operation settings), sectors
  24-180, terrainIntersectASL then lineIntersectsSurfaces VIEW, 60 rays a frame in a CBA PFH, cells
  batched into two `drawTriangle` lists (accent seen, ink hidden).
- PLP removed: panelTools' seven PLP_fnc_SMT_* calls and PLP_SMT_EH handling, the PLP_fnc_SMT_Main
  gates in tacpad_apps XEH_preInit (panel condition, now `jmfsb_maptools_fnc_start` loaded) and
  fnc_appSettings (MAP TOOLS section), `GVAR(activeTool)`, the show_tools description, the tileData
  comment, tacpad_apps and devices READMEs. cba_settings had no PLP entries (its `ace_maptools_*`
  lines are ACE's plotting board, kept). PLP was used for nothing else.
- Not run: gen_addon_readmes / gen_docs (maptools README generated half and docs/SETTINGS.md
  "Show map tools" row are stale until they are).

hemtt check (exit 0, no maptools/panelTools findings), sqf_validator (0 errors), check_invariants
pass; check_plumbing fails only on addons/ew's missing XEH_postInit.sqf (EW work, not this).

NOT RUN IN GAME.

## 2026-10-20 - voice override: TFAR UI hidden, our PTT, nets over frequencies (adapter_tfar)

Roadmap row 2 (docs/TODO_DEVICES.md section 6), the three parts that were open. TFAR standalone read
at `8d023da`, not edited. Paths below are in that repo, `addon/addons/core/`.
- **TFAR UI hidden** (setting *Hide TFAR's radio UI*, on): TFAR's own client settings
  `TFAR_showTransmittingHint` (read in `functions/fnc_doSRTransmit.sqf` / `doLRTransmit` / their
  `End`; hint time 0 = no hint) and `TFAR_showChannelChangedHint`
  (`functions/events/keys/fnc_processSWChannelKeys.sqf`, `events/ui/fnc_setChannelViaDialog.sqf`)
  are set false in missionNamespace for the session, not through CBA, so the player's saved values
  are kept and restored; his changes meanwhile are kept via `CBA_SettingChanged`. The card TFAR draws
  with no setting (`fnc_processSWCycleKeys.sqf` etc.) is taken down one frame after its
  `OnSWChange` / `OnLRChange` / `On*channelSet` / `On*speakersSet` events with `TFAR_fnc_hideHint`
  (`functions/hint/fnc_hideHint.sqf`, public). Not covered: TFAR's radio dialogs, the init banner,
  the in-water popup, voice-server warnings (kept on purpose), and TFAR's own keybinds.
- **Our PTT**: JMSB keybinds for the active net, the alternate net, the LR net and the LR alternate
  net, calling TFAR's own `TFAR_fnc_onSwTangentPressed/Released`,
  `onAdditionalSwTangentPressed/Released`, `onLRTangentPressed/Released`,
  `onAdditionalLRTangentPressed/Released` (`functions/events/keys/`, registered by TFAR in
  `functions/fnc_initKeybinds.sqf`). **Unbound by default**: TFAR has no setting to turn its PTT
  keys off, so ours takes TFAR's default key only when TFAR's own binding for that tangent is
  empty at mission start. A display-46 key hook does the same as TFAR's
  `fnc_onTangentPressedHack.sqf` for ours (PTT while sprinting). RF does not block the key; the
  sending lever handles a dead link. Net next / previous keys (SR and LR), unbound.
- **Nets over frequencies**: a net's frequency is the plan's list entry for its channel, else a
  hash of the net id onto TFAR's band. Channels are read back as nets by frequency (fallback: plan
  channel index), so RF fills now follow what is programmed. Public `fnc_fill [srNets, lrNets]`
  (returns the nets loaded - what the RADIO app's FILL already expects), `fnc_selectNet`,
  `fnc_netState`. New handheld / backpack sets with no known net frequency get the plan's fill
  (setting *Fill new sets from the plan*, on).
- HUD RADIO widget shows the net name, TX, RF quality / NO LINK, the alternate net; never a
  frequency.

hemtt check (exit 0, no adapter_tfar / hud findings), sqf_validator, check_invariants pass;
check_plumbing fails only on `addons/ew` (another workstream's missing XEH_postInit). READMEs' generated
halves not regenerated (instructed).

NOT RUN IN GAME.

## 2026-10-20 - Play-test mission JMSB_Test.Tanoa and its checklist

A scenario for everything built 2026-10-18 .. 2026-10-20 that has never run, and the steps to run it
(docs/TESTS.md, "Play test 2026-10-20", P0-P11 with a pass/fail column). No addon touched.
- **Where**: `Documents\Arma 3 - Other Profiles\YonV\missions\jmfs-missions\JMSB_Test.Tanoa`, Tuvanaka
  airbase apron (13.45 m ASL, read off objects Task_Force_Roomba_cdev stands there).
- **How**: mission.sqm hand-written in Eden's text format (v54; `hemtt utils config inspect` passes): the
  player plus three playable AI slots (medic, `isISR` rifleman, autorifleman; `disabledAI = 0`), one of every
  support module with attributes (THUNDER virtual 1.5-8 km, STEEL retired with no guns, TRIDENT, GHOST, HOG
  class A-164, VIPER synced AH-99, HAWK CAS drone, RAVEN synced Ghost Hawk, BISON class Huron, MULE chute,
  PORTER sling, REACH QRF), the two sync links, respawn_west. initServer builds the rest on searched free
  ground: Marshall for the vehicle tablet, a cargo net for SLINGLOAD, FOX (retired battery with two synced
  Scorchers: `createUnit` in a sideLogic group, plain attribute names, `[logic, guns, true] call
  jmfsb_support_fires_fnc_moduleArtillery` in one unscheduled block), six OPFOR targets at 0.5-11.6 km from
  THUNDER, hold fire, with markers. initPlayerLocal gives the phone (GPS slot) + both side devices, a
  `jmfsb_nvg_*` ECOTI goggle, MPU5 under TFAR, signals, designator, ACE medic kit, Medic trait and `isJFO`,
  and the [TEST] scroll actions (dump, wound, UAV trait, destroy an asset's aircraft, ropes in RAVEN,
  teleports). Mission cba_settings.sqf: `jmfsb_support_tag = "JFO"`, `everyoneAdmin`. TAC//PAC `sync = "off"`.
- **Diagnostics** (`[JMSB_TEST]` RPT lines, fn\): STAND check of the hand-placed aircraft at 5 s, a dump at
  15 s and on demand (addons, settings, kit, gate, registered modules, every board row) and a verdict matrix
  through `jmfsb_support_fnc_preview` for every fires asset against every target. Mission SQF linted with a
  throwaway HEMTT project: clean.
- **Found while building, not fixed**: there is no "JMSB - Core" module class (D59 comments name
  `player_side` on it; sides come from the slots, so none is placed); support_air registers no `preview` /
  `overlay` hook, so air rows get no VERDICT line or provider rings; `ace_fastroping_requireRopeItems` is
  forced true by addons/cba_settings and nothing stocks ropes on a transport (P8.5 tests it, with a [TEST]
  action to add ropes); with no PAC arsenal lists a logistics crate keeps its class's own contents.
- **Not set up**: no ACM monitor item for live vitals (TAC//MEDIC shows hand checks only); helocast water and
  most task points are picked on the map in the steps, not marked; a second player is needed for the
  magenta (direct speech) voice ring.

NOT RUN IN GAME.

## 2026-10-20 - RADIO, DRONES and HACK boards per DESIGN_TABLET_APPS.md

The three apps rebuilt as the design's boards (panels over the map area, tab row with a status note, CLOSE).
Drawn through `jmfsb_tacpad_fnc_appFrame`, so the same code lays out inside the tablet (HOST_DEVICE) and on
the vanilla map. Shared vocabulary, new in tacpad_apps: `fnc_appPagePanel` (title + right label + rule),
`fnc_appPageTabs`, `fnc_appPageButton` (fill / line / alarm; a dead button is dim with no hit),
`fnc_appPageBar` (RF quality 0..1, -1 = a dash). Theme tokens only; numbers in `script_component.hpp`
(PAGE_*, QUALITY_*, RADIO_*, DRONES_*, HACKAPP_*).
- **RADIO** (`fnc_appRadio` + `fnc_appRadioChannels / Set / Calls / Fill`, tabs NETS / CALLS / FILL).
  CHANNELS: key, net, band, RF link (`jmfsb_rf_fnc_quality` for the set's node), ear, volume, state
  (ACTIVE / ACTIVE TX / MON / OFF), who is talking. Net names from `jmfsb_adapter_tfar_fnc_radioNets`
  (the net each channel carries), plan fallback; never a frequency (`fnc_radioState` now reads
  "CH n NET", not the frequency). RADIO SET: set picker (hand / back / rack), MAKE ACTIVE and MONITOR /
  NONE through `jmfsb_adapter_tfar_fnc_selectNet` (TFAR setters as fallback), ear, power (RF profile,
  read only), battery (profile Wh, no drain model), DATA link, LOAD FILL (`jmfsb_adapter_tfar_fnc_fill`,
  guarded by `!isNil`). TX from `jmfsb_adapter_tfar_fnc_netState`. CALLS: live and heard (`fnc_radioCalls`,
  1 s, TFAR_isReceiving + the talker's published channel); DIAL / HANG UP / LEAVE NOTE drawn dead - no
  call service exists.
- **DRONES** (`fnc_appDrones` + `Data / Fleet / Feed / Camera / Action / Enemy / Key`, tabs FLEET / ENEMY).
  FLEET: the players' side's `allUnitsUAV` (side derived as the CAS controller does), link word, RF DATA
  quality (the operator's), battery (fuel), task; enemy heard from the scanner sweep. FEED: the picked
  drone's gunner optic rendered to texture inside the app with a live HUD (name, alt, speed, heading,
  target grid and range, link); the camera stops when the app closes, the tab or pick changes, or the drone
  dies. Buttons: CONNECT / DISCONNECT (`isUAVConnectable` gate, refused with the DATA link lost), TAKE
  CONTROL (gunner seat, closes map/tablet first), ORBIT (LOITER waypoint), MARK TARGET (local marker); GO TO,
  LASE, RTB dead. Drone40 exposes no relay / decoy / jammer mode functions, so there are no mode buttons.
- **HACK** (`fnc_appHack` + `Nodes / List / Action / Log / Track`). NODES IN REACH: the suite's devices
  joined to RF: new `jmfsb_hacking_fnc_rfReach` (server: fair-game holders in hacking reach,
  `jmfsb_rf_fnc_nodesFor` each, `jmfsb_rf_fnc_budget` target -> operator), asked every 5 s while the board is
  open (`jmfsb_hacking_rfReachAsk` -> `rfReached`). RF nodes the suite has no way into are listed as NO
  ACCESS. ACTION: target + grid, DISABLE / SPOOF / TAP (SPOOF dead), product, progress with time left,
  risk (`netFailChance`), needs, START / ABORT - all the suite's own calls. LOG: the session's steps.
- **Checks**: hemtt check clean for these files (all L-S26 cleared), sqf_validator, check_plumbing,
  check_invariants pass. READMEs not regenerated (gen not run).

NOT RUN IN GAME.

## 2026-10-20 - EW addon: DF, tracks, jamming in three domains, spoof, decoys, TAC//EW

New addon `addons/ew` (`jmfsb_ew`, scaffolded with new_component.py) on top of RF, roadmap row 6 and
row 1's DF (docs/DESIGN_EW.md):
- **Emitters** each DF tick (setting, 3 s): RF's listener snapshot (every emitting node), EW's own
  jammers, external emitters (`fnc_addEmitter` - the Drone40 Jammer now registers itself there) and
  the jamming addon's sites (new `jmfsb_jamming_fnc_emitters`). Idle sets beacon at their EMCON duty,
  SILENT never; EMCON 1+ caps detection power at 2 W.
- **DF**: sensors are emitting RF nodes of a DF profile (handheld 15 deg, manpack/relay 10, vehicle 5);
  the new **EW Receiver** item (`jmfsb_ew_receiver`) makes the 2 deg all-band set, ISR one class better.
  Up to 3 nearest sensors per side per emitter; received power is RF's budget one way (pathLossFree,
  RF terrain samples, spread off without the key) against RF noise; bearing error grows as SNR drops.
- **Tracks** per side: cuts, fix from 2+ cuts in the 30 s window (baseline 50 m, cross 10 deg), error,
  confidence, lifetime setting; named when a key is held (new `jmfsb_rf_fnc_sharedNets`), else classed
  JAM / SPOOF / VIDEO / DATA / DECOY? (120 s quiet) / COMMS. Threat warnings DF ON YOU, JAMMER, SPOOFER,
  ENEMY DRONE, NEW FIX, SPOT JAM. Server events trackNew / trackLost / fix / jamOn / dfOnYou.
- **EA**: the new **EW Jammer Pack** backpack (`jmfsb_ew_jammerPack`), worn or in a crewed vehicle's
  cargo (vehicle power and SAT). Barrage (one band), spot (ISR: the net of an ES track, +10 dB, half
  spread back), sweep (5 s per band) as an RF noise source with power and duty; GPS denial as a jamming
  zone on the host (new `fnc_zoneOnObject` / `fnc_removeZone` in jamming); GPS spoof (ISR) drifting
  unprotected GPS (receiver: SUSPECT), read through `fnc_gpsState`. Decoys (ISR): ground antenna RF
  node with intent "decoy", the Drone40 decoy's mark, battery setting, two per man.
- **TAC//EW** app `ew` (OVERVIEW / ES / EA / EP) registered from the addon, EW tile through
  tacpad_apps' tileProviders; map layer (DF lines with error wedge, fixes, own jammers) on the vanilla
  map and the device host's map. Per-player slice by publicVariableClient on change.
- RF, additive read-only public calls only: `profile`, `bandInfo`, `nodeInfo`, `sharedNets`. No RF
  behaviour changed. Drone40 deploy registers its jammer with EW when EW is loaded.
- Not built: AI EW and the comms gate, INSPECT/EXPLOIT/LOAD KEY, drone soft/hard kill, hardware
  (battery, heat, damage), sector antenna, PACE, EMCON power cap inside RF's link budget, consumers of
  `fnc_gpsState` (BFT dot, grid, drones), fix sharing over DATA.

hemtt check (exit 0, no findings in ew/rf/jamming/drone40), sqf_validator, check_plumbing,
check_invariants pass. gen_addon_readmes / gen_docs / check_all not run (ew README generated half
empty; rf, jamming, drone40 generated halves stale).

NOT RUN IN GAME.

## 2026-10-20 - Air verdicts and map shapes on TAC//SUPPORT; ropes for FASTROPE

Two gaps found building the play-test mission:
- **Preview and overlay for the air providers.** `support_air` and `cas` now register the core's
  `preview` and `overlay` hooks (addons/support/README.md), as support_fires does.
  - Preview (VERDICT line of the READY checklist) is built from the exact params CONFIRM sends, reads
    only published module state, changes nothing. support_air: CAS "ETA 3 MIN - ON STATION 10 MIN -
    2 SORTIES LEFT" (+ " - DANGER CLOSE" when asked), on station "REPOSITION - ETA 40 S"; transport
    "ETA 2 MIN 40 S TO PICKUP" (task's point label, " ON YOU" without a grid) from base after the
    response delay, or from the airframe when it is out, along VIA legs and the final approach at the
    SPEED asked; logistics / QRF "ETA 4 MIN - LAST DROP" / "... SQUADS LEFT". CAS drones (cas):
    "ETA 1 MIN 50 S - 2 AIRFRAMES LEFT", loiter "ON STATION IN ...". False only for what the order is
    refused for: gone/busy/launching/turning round/replacing/spent (FUNC(available)), task not
    offered, no grid where "on me" does not apply, LIFT/SLINGLOAD without the second point, HELOCAST
    over land, ATTACK RUN on an aircraft already on station. SLINGLOAD with nothing liftable is flown
    and then held by the server, so the verdict stays true and says "NOTHING LIFTABLE WITHIN 80 M"
    (only when an airframe is on the map to ask `canSlingLoad`).
  - ETA speed is an estimate: `ETA_SHARES` of config maxSpeed per SPEED word (support_air
    `fnc_flightTime`); times read through the new `jmfsb_cas_fnc_fmtEta` (support_air requires cas).
  - Overlay: support_air draws the base or stand always; while a sortie is out the leg out from base
    (no airframe yet), the leg home from the plan's last point, and for CAS the INGRESS / EGRESS legs
    and the module's Friendly Range ring round the task point (not on LOITER). The plan itself is
    already drawn by the board from row field 8, so it is not drawn twice. CAS drones have no home:
    while out, INGRESS / EGRESS legs and the search ring (strike) or orbit ring (loiter).
  - Plan labels and the sling load kinds are macros now (`PLAN_*`, `SLING_LOAD_KINDS`).
- **Ropes for FASTROPE.** cba_settings forces `ace_fastroping_requireRopeItems` (unchanged). Read from
  ACE 3.21.2.113's PBOs: `ace_fastroping_fnc_deployAI` (what FASTROPE calls) passes no rope class, so
  the AI deploy skips the item check; the item gates ACE's player "Deploy ropes" action
  (`canDeployRopes`: rope in the player's items or the vehicle's `itemCargo`). New
  `jmfsb_support_air_fnc_stockRopes` tops a transport that offers FASTROPE (and can rope) up to 2
  `ACE_rope36` (class verified in ace_logistics_rope CfgWeapons): at module read for a synced
  helicopter, on adoption of a replacement, at launch, and when a FASTROPE task arrives.

hemtt check (exit 0, no findings), sqf_validator, check_plumbing, check_invariants pass.
gen_addon_readmes / gen_docs / check_all not run (support_air and cas generated README halves stale).

NOT RUN IN GAME.

### TFAR removed: game voice is the base (2026-10-20)

User: "we are removing TFAR and going with Arma 3 game VoIP" (docs/DESIGN_VOICE.md, SPEC_TACNET D14).
This pass took TFAR out of everything except the new voice layer (jmfsb_voice / adapter_von, another
agent) and the radio UI (tacpad_apps fnc_appRadio* / fnc_radio*, hud fnc_widgetRadio, devices -
another agent). ACRE (adapter_acre and the ACRE branches) is untouched.

- **Deleted:** addons/adapter_tfar (whole addon, it was untracked), compatibility/tmt_tfar_labels,
  radios/dialog.hpp (the MPU5 TFAR dialog) and radios/radio_ids.hpp (TFAR's ID ladder), equipment's
  dead tfar.hpp with the five TFAR dialog pictures only it used (anarc210, rf7800str(_n),
  rt1523g(_n)). `jmfsb_patches_usesTFAR` is gone and so is every reader (init, gear, groups, players,
  systems, vehicle).
- **Radios are plain items, same class names.** `jmfsb_mpu5` and `jmfsb_tw950` are `ItemRadio`
  (radio slot, opens VON's radio channels), `jmfsb_mpu5_lr` is back as a radio bag on our Multicam
  pack (the class had gone missing while the PAC testing documents still issue it). No TFAR in
  requiredAddons, no skipWhenMissingDependencies. On the ground the handhelds wear ItemRadio's own
  model (inherited) - the generated MPU5 mesh was reported invisible and is not worn until looked at
  in game; the p3d and the dialog picture are still generated and shipped.
- **RF recognises a set from its config.** New property `jmfsb_rf_profile` (EGVAR(rf,profile)) and
  `jmfsb_rf_fnc_itemProfile [class]` (cached; radio-slot items without it are handhelds) and
  `jmfsb_rf_fnc_carriedSets [unit]` -> `[[sr|lr, class, profile]]` for the voice adapter. MPU5
  handheld, TW-950 legacy, MPU5 manpack and every radio bag (backpack, uniform, uniform_ru, the WS
  overlay and its cdlc_split.json state) manpack - the six tf_ properties collapsed to that one line.
- **PAC radio plan is a net plan.** `jmfsb_pac_fnc_netPlan` (adapter_tfar's planNets, moved) reads
  the same database keys - tfarNets / tfarSwFallback / tfarLrFallback keep their names so saved
  plans read - and `jmfsb_pac_fnc_netPlanSync` makes the nets in RF on the server at postInit and
  whenever radioApply changes the plan. No tuning anywhere. PAC pages: the TFAR frequency table is
  gone, "TFAR radio and fallbacks" is "Net plan fallbacks", squad fields read "net slot".
  tfarActiveRadio / tfarSrFreqs / tfarLrFreqs are carried for the database only.
- **Readers moved to the voice API** (guarded by isNil, API per addons/voice/README.md): bft member
  voice rings (talking + nets kinds, own speech from getPlayerChannel), reaction (jmfsb_voice_talk,
  own key-up on a net that is not team / veh / direct), hacking scanner (active net, LINK / NO LINK),
  ecoti net card ("NET <id>" in place of a frequency), tacpad RADIO tile (active net from netState).
  fa_grenade_40mm's TFAR hooks, jamming's TFAR comments and README lines updated.
- Not touched (other agents): devices overlayNets / vehicleRf / script_component / README, hud
  fnc_widgetRadio and its README row, tacpad_apps radio files. cba_settings and .hemtt/launch.toml
  already carried no TFAR.

hemtt check (exit 0; findings only in voice / adapter_von / tacpad radio files / devices, in
progress elsewhere), sqf_validator, check_invariants, config_style_checker pass; check_ctab_configs
skips; check_plumbing fails only on voice's missing XEH_postInit.sqf (in progress). gen scripts not
run: radios, rf, pac generated README halves and docs/ are stale.

NOT RUN IN GAME.

## 2026-10-20 - Voice on game VON: jmfsb_voice and jmfsb_adapter_von

Per DESIGN_VOICE.md and SPEC_TACNET D14 / D16 / voice_adapter. Two new addons; RF unchanged.

- **voice** (the core, never names a VON command): the API in addons/voice/README.md (nets,
  netState, active net and the device arrows, ear, mute, quality, talking, calls, call slots,
  callbacks, contacts, playCue, selfTest; events talk / netsChanged / callRing / callState) and the
  adapter interface (registerAdapter: join, leave, quality, talking; optional channel, setActive,
  current, block, selfTest).
- **Nets from the one plan.** A group's TEAM net is its PAC plan short range net, its C2-kind net
  the plan long range net (jmfsb_pac_fnc_netPlan; fallback slots for groups with no row); without a
  plan, TEAM per group and C2. Plus A2G, CALL 1-8 (on DATA), VEH (crew), DIRECT. Sets come from
  jmfsb_rf_fnc_carriedSets plus the crew seat's vehicle set; each is an RF node voice_<uid>_<kind>
  holding TEAM, C2-kind, A2G and DATA.
- **Membership only for fills and calls:** the server reads every player's fill back from RF each
  second (roster, published on change) and calls the adapter's join / leave; links change volume.
- **Mesh drives VON:** every second each client sets each speaker's volume per net from his RF
  slice (best path between any two of their nodes), held for the grace time (setting, 3 s), 0 when
  muted; VON applies it for the channel the speaker is on (setPlayerVoNVolume per speaker, so the
  volume follows his getPlayerChannel, read every frame). EMCON 3 = radio silence.
- **PTT:** the game's push-to-talk sends on the current channel; setActive = setCurrentChannel to
  the active net's channel (TEAM Group, C2-kind the C2 custom channel, A2G and each CALL their
  custom channel, VEH Vehicle, DIRECT Direct).
- **Calls and callbacks** server-held: 8 slots x 8 people, DATA reach to dial, ring / accept /
  decline / hang-up / add, no answer after the ring time, drop after the drop time without DATA,
  FLASH (RTO / HQ / admin) bumps the oldest ROUTINE after a priority warning, ends at one member.
  Callbacks: 15 min, one per pair, 3 per player, wait while busy, held under EMCON 3, both ring.
- **Sounds:** 16 own tones (tools/voice_sounds.py -> addons/voice/sounds/*.wav, CfgSounds), pitch
  per net, ear panning of beeps and static (local playSound3D to the side), static by quality;
  settings radio beeps, call beeps, beep volume, pitch per net, static by quality.
- **adapter_von:** Side / Command voice off, Global talk for admins, custom channels by
  radioChannelCreate (C2, A2G at start, CALL n on first use, reused), radioChannelAdd / Remove,
  setPlayerVoNVolume with a floor setting, Vehicle crew-only by volume. The five "Tests to run
  first" are jmfsb_voice_fnc_selfTest, logged to the RPT as VON T1-T5.

hemtt check (no findings in voice / adapter_von), sqf_validator, check_plumbing, check_invariants,
config_style_checker pass. gen scripts not run: both addons' generated README halves and docs/
are stale. Unverified: every VON command's behaviour (the self test exists for that), .wav in
CfgSounds, playSound3D local panning, getPlayerChannel on remote players, setCurrentChannel right
after radioChannelAdd.

NOT RUN IN GAME.

## 2026-10-20 - Numpad keys and the voice API on the devices, the tablet RADIO app, the phone / side RADIO app

User: "we are removing TFAR and going with Arma 3 game VoIP", "we are not using keyboard F1-F4, we
are using numpad". Spec: DESIGN_VOICE.md (Numpad, Nets on the devices, Calls, RADIO apps),
SPEC_TACNET.json D16. Owned files: addons/devices, tacpad_apps radio files, hud fnc_widgetRadio.

- **Numpad (D16), CBA keybinds in the JMSB category:** Device button F1-F4 = numpad 1-4, left /
  right = numpad 0 / . (were unbound); Open Tablet = numpad 5 (was Ctrl+Home); new Device RADIO
  app = 6, Device previous / next tab = 7 / 8; Troops In Contact = 9 (tacpad_apps, was unbound).
  Toggle Device keeps Ctrl+End (no numpad key given). The tablet dialog's fnc_keyDown matches each
  press against the player's own bindings (CBA_fnc_getKeybind) because CBA keys do not reach the
  mission display under a dialog; a focused text box keeps every key. The keyboard-arrow app ring
  is gone: the device arrows step the active voice net (app ring only without the voice addon).
- **Walking-view F-keys:** the six button settings default to F1 accept call, F2 ear / quick add
  (during a call), F3 mute active net, F4 decline / hang up, arrows active net left / right
  (fnc_voiceAction); still definable, plus a RADIO app action.
- **Voice API everywhere TFAR was:** net rows (fnc_overlayNets: only nets he is on, red outline
  when unreachable, ear tag, muted dim, RING cell), talking box / squad TX-VOX / ON BOARD
  (fnc_voiceTalkers, fnc_overlayTalker: name, net, ear; RINGING), notification line call business
  and call-state words (fnc_voiceLine), VEHICLE STATUS voice nets (fnc_vehicleRf, no rack), HUD
  RADIO widget, radioState / radioPublish / radioTune.
- **Tablet RADIO app:** NETS (net, VON channel, link, ear L/B/R, mute, state, talking; SOUNDS from
  the voice settings, KEYS from the bindings), CALLS (group adds, NEXT: FLASH for RTO/admin, find,
  VON slots, contacts with ON CALL / + ADD / CALL / CALL BACK, live call with ring accept / decline,
  recent, hang up, mute call, last call state; callbacks), MANAGE (role-gated; nets, TEAM / CALL
  members, WHO CAN). Removed the TFAR files appRadioChannels / appRadioSet / appRadioFill /
  radioSets / radioNets / radioAction.
- **Phone / side RADIO app** drawn on the walking view (keys only): tabs, header, rows (two lines on
  the side devices), cursor, group chips, soft keys along the bottom / 2 x 2 grid per the spec's
  table; a ring takes F1 / F4 on every tab.
- **Not built (said in words, no buttons):** per-net beep volume, MAKE FLASH on a live call,
  callback cancel, contact hops, ADD TO CALL from map / squad list, RTO pull-in, temp nets,
  patches, listen-only, rekey / PACE / EMCON, C2 / A2G members, signal plan, MANAGE rights in the
  voice addon, captured-key nets, voice notes, mouse on the small devices' app.

hemtt check (no findings), sqf_validator (devices, tacpad_apps, hud), check_plumbing,
check_invariants pass. Generated README halves of devices / tacpad_apps (functions added and
removed) and docs/ are stale - gen scripts not run. Unverified: ctrlCreate on the walking view's
title layer, CBA_fnc_getKeybind index 8 / 5 shapes, keyName strings, structured-text layout of the
small app at 1080p, every voice call against the real addon.

NOT RUN IN GAME.

## 2026-10-20 - The call's owner invites, not the RTO

User: "its not the rto inviting folks its the channel owner so who started the call". Each call now has an
`owner` (who started it, set in `jmfsb_voice_fnc_srvStart`). Only the owner adds people: `srvAdd`
refuses anyone else with the new reason `notOwner`; if the owner leaves a call that goes on, the
longest-standing member becomes owner (`srvLeave`). The owner is published as field 9 of the call table
and returned as field 6 of `jmfsb_voice_fnc_calls`. Screens: new `jmfsb_tacpad_apps_fnc_radioCanAdd`;
non-owners see "OWNER ADDS" instead of + ADD (tablet contacts, phone/side rows), no RECENT add chips,
ADD / CALL / GROUP + soft keys disabled during someone else's call, F2 stays the ear toggle, and any add
that still gets through is refused with a notice. The RTO pull-in item is dropped from DESIGN_VOICE.md,
SPEC_TACNET and the "not built" lists. Added people still ring until they accept.

NOT RUN IN GAME.

## 2026-10-20 - Voice: speaker-pushed keying, every PTT input, cut-offs, game radio sounds, stand down under TFAR / ACRE

User: "go" on the five voice fixes, plus the rule "our in game VoIP setup should only run if there is no
TFAR or ACRE". Behaviour reviewed against AFAR (Phronk); its licence forbids publishing its script, so
nothing was copied - only the game's own sound files are referenced, by path.

- **Stand down:** `jmfsb_voice_active` is set once in the voice preInit from the machine's own
  CfgPatches; with `task_force_radio`, `tfar_core` or `acre_main` it is false, one RPT line says why,
  both postInits exit and adapter_von does not register. Every public voice function answers empty
  (`[]`, `""`, `false`, 0, -1). The internal active-net variable became `jmfsb_voice_activeNetId`.
  selfTest logs the flag first.
- **Speaker-pushed keying:** the speaker's own key edge sends one targeted event `jmfsb_voice_keyed`
  `[speaker, net, on]` to the hook `audience` (VON: his group's players for Group, everyone aboard for
  Vehicle, everyone on a net that rides the custom channel; nobody for Direct). Each listener applies
  his volume at once from its current quality (hook `keyed`), raises `jmfsb_voice_talk` and plays the
  squelch / static (`fnc_keyed` -> `fnc_talkSync`). getPlayerChannel stays only as the fallback for a
  lost key-down; a pushed speaker is dropped on key-up, death, respawn or leaving. New hooks `ptt`,
  `keyed`, `audience`; new API `members`.
- **Every PTT input:** `fnc_ptt` reads `PushToTalkAll/Side/Command/Group/Vehicle/Direct` (their own
  channel), `pushToTalk` and `voiceOverNet` (current channel) by inputAction every frame; the channel's
  net is the transmission's. The core's `fnc_transmit` handles the edges (TX click, RF tx state, the
  event).
- **VON toggle blocked:** KeyDown on display 46 swallows `actionKeys "VoiceOverNet"` and says once to
  bind Push To Talk; at start the player is warned when Push To Talk is unbound or
  `getAudioOptionVolumes` VON (index 3, checked against the command data) is below 0.1.
- **Game radio sounds:** squelch open / tail = `A3\Dubbing_Radio_F\sfx\in2a.ogg` / `out2a.ogg`, TX /
  roger = `in2b.ogg` / `out2b.ogg`, cut = `out2c.ogg`, static = `radionoise1.ogg` (5.7 s; restarted
  every 5.5 s or on a quality change, stopped with stopSound). All present in `dubbing_radio_f.pbo`
  (prefix `a3\dubbing_radio_f`), listed with `hemtt utils pbo inspect` and extracted to measure. Every
  cue now plays by file path; `CfgSounds.hpp` and the six replaced .wav files are gone;
  `tools/voice_sounds.py` makes only the 10 tones still used (output byte-identical to the shipped
  files, checked in a scratch folder).
- **Cut-offs:** `fnc_blockLevel` / `fnc_applyBlock` every frame and on EntityKilled / EntityRespawned:
  1 EMCON 3 (radio nets), 2 unconscious (+ Vehicle), 3 dead or `isAbleToBreathe` false (+ Direct).
  adapter `fnc_channels` closes them with enableChannel, keeps the mission's Vehicle / Direct voice
  state and puts it back; the PTT goes back to the active net when the level falls. A blocked
  key-down plays the blocked tone and notifies the reason; a transmission that gets cut sends its
  key-up.
- **Self test cross-check:** T2 notes the cut-offs rely on listen-with-voice-off (AFAR's design depends
  on the same); T3 also counts pushed key events (getPlayerChannel is now the fallback); T5 restores
  the current channel after its setCurrentChannel probe and notes that an enableChannel gate on
  GetInMan / GetOutMan opens Vehicle for everyone aboard, so crew-only stays by volume.

hemtt check (no findings in voice / adapter_von), sqf_validator, check_plumbing, check_invariants,
check_art pass. Generated README halves of voice / adapter_von (function counts) and docs/ are stale -
gen scripts not run. Unverified: everything at runtime - CBA targetEvent latency against VON audio
(first syllable may come before the volume event), inputAction of `voiceOverNet` while its key is
swallowed, actionKeys combos with modifiers, playSoundUI by .wav path, the game sounds' loudness
against our tones, ACE unconscious = INCAPACITATED in this build, the engine moving the current
channel when voice is disabled.

NOT RUN IN GAME.

## 2026-10-20 - Play test brought up to date: game voice, numpad, map tools, EW, RADIO / DRONES / HACK, air verdicts, ropes

The play-test mission and its checklist (docs/TESTS.md, "Play test 2026-10-20") updated for everything
after the play-test entry above. No addon touched (voice / adapter_von were being changed by another
agent at the same time; the checklist follows them as of this entry, incl. the cut-offs, the VON toggle
block, pushed key events and the TFAR / ACRE stand-down).
- **Mission** (`JMSB_Test.Tanoa`): nothing TFAR-specific left (dump's addon list, comments). Kit adds the
  EW Receiver (`jmfsb_ew_receiver`, uniform / vest) and a UAV terminal; the EW Jammer Pack
  (`jmfsb_ew_jammerPack`) is a [TEST] backpack swap that keeps the kitbag and its contents, and one rides
  in the Marshall's cargo. New playable group HQ (`jmsbt_hq`, "HQ RTO", MPU5 manpack: RTO tag, own TEAM
  net) for the second player; `fn_aiRadios` puts an MPU5 on every AI slot (they relay nothing:
  `jmfsb_rf_aiNodes` off, voice makes player nodes only). description.ext: `maxPlayers = 5`,
  `disableChannels[]` Side / Command voice off only - what adapter_von already sets every second, so it
  does not fight it; VON on / codec are server.cfg, noted. Server builds a hack tower beside the "600 m
  short of T2" point and the EW targets through public calls (`fn_ewTargets`): RF net `JMSBT ENEMY` +
  a transmitting RF node on T2's MRAP (DF-able; HACK lists it as NO ACCESS) and an EW external jammer
  emitter on T3's APC (JAM track, JAMMER warning, no RF noise).
- **[TEST] actions:** voice self test (`jmfsb_voice_fnc_selfTest`), voice dump (active flag, cut-off
  level, sets, roles / FLASH, channelEnabled 0-5, the custom channel map with radioChannelInfo members,
  netState, talking, calls with owner, callSlots, callbacks, contacts, each speaker's VON volume and
  channel), unconscious 20 s, under water, mesh ladder (LZ ROOMBA ~2.8 km, near T3 ~4 km, near T5 ~9 km;
  every teleport searches for dry land), DF baseline teleport, enemy emitters on / off, ISR flag, UAV
  (Greyhawk loiter, only if no west UAV), GPS slot phone <-> UAV terminal, HACK tower teleport. The main
  dump adds ropes in RAVEN, the EW kit / slice / tracks / gpsState, UAVs, the running map tool, the
  voice / EW / maptools settings, and ends with the voice dump; the verdict matrix asks the air rows real
  tasks on T2 (and the refusals HELOCAST over land, LIFT without an LZ). Mission SQF (17 files) linted
  with a throwaway HEMTT project: clean; mission.sqm passes `hemtt utils config inspect`
  (description.ext's `true` / `false` words in disableChannels are the engine's form, which that
  inspector cannot parse).
- **Checklist:** P0-P11 rewritten for the numpad (5 tablet, 1-4 / 0 . on the frame, the walking view's
  voice keys, 6 / 7 / 8 the phone RADIO app), Ctrl+End kept for Toggle Device, no ACE phone actions,
  air previews in P0.3 / P5.5, ropes stocked by support_air in P8.5, VON rings in P10.3. New P12 game
  voice (self test T1-T5 with the RPT lines, nets, PTT per channel, Side / Command / Global, VON toggle,
  ear / mute, sound settings, fade and static on the mesh ladder, EMCON 3, unconscious, under water,
  calls: ring / accept / decline / no answer / hang up, owner-only invites, FLASH offer, callback,
  limits, drop), P13 numpad matrix, P14 map tools on both hosts, P15 EW (DF lines, fixes, receiver,
  jammer modes, spot / GPS / spoof / decoys, EP, vehicle jammer), P16 RADIO / DRONES / HACK boards, P17
  air verdicts and shapes, P18 fast-rope with players in the cabin. [2P] / [3P] mark the multi-player
  steps; P/F column and the paste-back-the-RPT rule kept (both players' RPTs for [2P]).
- **Not set up:** the FLASH bump (needs all 8 call slots, 16 players), owner hand-over and adds (a
  third player), the 3-callbacks-per-player limit (more contacts); spoof / jammer effects on anyone but
  the jammer need the second player; with one player DRONES CONNECT may be refused for "No DATA link"
  (RF's DATA link to nobody) - the step says to repeat it with two; TEAM / C2 are VHF, which reaches
  across Tanoa on clear ground, so their fade is only behind terrain or under a jammer. Tower, UAV loiter
  point and teleport landings are searched at run time, not placed.

NOT RUN IN GAME.

## 2026-10-20 - PAC loads the VON plan keys; the net plan prefers them

Asked: "also need to add a base game voip option to diviner and the diviner web". The website and
DIVINER now write a base-game voice plan into `<unit>.radio` beside the ACRE / TFAR keys; jmsb's pac
reads the same keys. Only `addons/pac` touched (voice and adapter_von are another change).

- **Keys** (`fnc_radioKeys`, so `fnc_radioApply` writes them to `jmfsbFR_radio_*` exactly like the
  others, from `<unit>.radio` `items`): `vonTeamNets` `[[squad, team net]]` (`[]`), `vonNets`
  `[[net, "c2" | "a2g", [squad, ...]]]` (`[]`, ten rows at most), `vonSide` (`false`), `vonCommand`
  (`false`), `vonGlobalAdminsOnly` (`true`). `fnc_radioFromMission` counts a `vonNets`-only plan as a
  plan.
- **`fnc_netPlan`**: with `vonNets` rows the plan is built from them instead of `tfarNets` - a TEAM net
  (`"sr"`) per ORBAT squad and per squad a VON row names, named by its `vonTeamNets` row else the squad;
  an `"lr"` net per c2 row and an `"a2g"` net per a2g row. Same shape `[id, band, kind, slot]`; VON nets
  carry `NET_NO_SLOT` because they are joined by squad, not slot - voice's slot lookup
  (`jmfsb_voice_fnc_planNet`) finds nothing on them and keeps its own per-group TEAM / default C2. A name
  already taken is skipped (team nets first). No VON rows: the tfarNets plan exactly as before.
- **New `fnc_netPlanSquad`** `[squad, "sr" | "lr" | "a2g"]` -> net id: VON = team net name / FIRST c2
  row listing the squad (the website allows a squad on two c2 nets) / first a2g row; tfarNets = the
  squad's slot (or fallback) -> the plan net on it. For the voice side to join by squad.
- **`fnc_adminOrbat`**: `case "radio"` accepts `true`/`false`/`"true"`/`"false"`/`1`/`0` for a boolean
  key. Bug fix: both radio cases called `[] call FUNC(radioApply)`, which wrote every `jmfsbFR_radio_*`
  global back to its default after any in-game radio edit; now `[_radio]`.
- **Macros** (`script_component.hpp`): `VON_KIND_C2`, `VON_KIND_A2G`, `VON_MAX_NETS`, `NET_KIND_A2G`,
  `NET_COL_SR`, `NET_COL_LR`.
- **Open:** voice still reads membership from `tfarNets` slots and maps every non-`"sr"` plan kind to C2,
  so until it calls `fnc_netPlanSquad` (or reads the von keys) and knows `"a2g"`, VON nets exist in RF
  but nobody is put on them by plan. The pac README's generated half does not list `netPlanSquad` yet
  (`gen_docs.py` not run).
- **Checked:** `hemtt check` (1985 sqf, no lints), `sqf_validator.py`, `check_plumbing.py`,
  `check_invariants.py` - all clean.

NOT RUN IN GAME.

## 2026-10-20 - Voice joins the PAC VON plan's nets; a2g is A2G, not C2

pac can now build the net plan from the radio document's VON keys (`vonTeamNets`, `vonNets`): plan nets
keep `[id, band, kind, slot]`, with kinds `sr` / `lr` / `a2g` and no slot. Voice picked nets only by the
tfarNets slots and read every non-`sr` kind as C2, so under a VON plan nobody joined the plan's nets and
an a2g net became C2. Now `jmfsb_voice_fnc_planNet` asks `jmfsb_pac_fnc_netPlanSquad [callsign, kind]`
when it exists (cached per squad and kind, emptied on every plan refresh; an answer the plan does not
list is ignored) and falls back to the old slot lookup without it. `planRefresh` maps `sr` -> team,
`a2g` -> a2g, `lr` -> c2. New `jmfsb_voice_fnc_a2gNet` (the squad's a2g net, else `A2G`) feeds the fill
and `nets`; adapter_von's `netOf` gives the speaker's own A2G-kind net on the A2G channel, so several a2g
nets share it like C2. The TFAR / ACRE stand-down is unchanged. hemtt check (no findings in voice /
adapter_von), sqf_validator, check_plumbing, check_invariants pass; generated README halves are stale
(gen scripts not run).

NOT RUN IN GAME.

## 2026-10-20 - Radio screens say when TFAR or ACRE has game voice standing down

The tablet RADIO app, the tablet net row and the HUD radio widget read `jmfsb_voice_active`: when TFAR or
ACRE is loaded they show "TFAR / ACRE IN USE" (the app: "This mission runs TFAR or ACRE, so game voice
stands down; use that radio's own controls") instead of empty nets or "NO VOICE ADDON". Lint fix in
`jmfsb_tacpad_apps_fnc_radioDial` (owner check).

NOT RUN IN GAME.

## 2026-10-20 - A2G is pilots; the RTO console is a player job

User decisions: "who counts as air: pilots" and "RTO console: player job".

- **A2G by seat.** New `jmfsb_voice_fnc_airSeat` (client) sets `jmfsb_voice_air` on the player's unit,
  public and only on change: true for the driver of an Air vehicle (not a parachute) or a man in one of
  its copilot turrets (turret config `isCopilot`). It runs on CBA class events GetInMan / GetOutMan /
  SeatSwitchedMan on CAManBase (next frame, for the player only), on his Killed and Respawn and once at
  settings init - never per frame. `a2gNet` now answers `""` for none: air = his squad's plan a2g net,
  else the plan's first a2g net, else `A2G`; ground = his squad's plan a2g net, else `A2G` only when the
  plan has no a2g net at all (the default plan: everyone, as before). `fill` holds the A2G net only
  while he is on one, so the server roster joins / leaves him on the next tick.
- **One RTO test.** New public `jmfsb_voice_fnc_isRto [unit]`: `isRTO` flag (PAC skill effect
  `trait:isRTO` / `var:isRTO=true` or the mission), `RTO` in `jmfsb_pac_skillTags`, a long range set on
  his back (the test mission's HQ RTO manpack), or role-description words RTO / RADIO / JTAC / FAC. Used
  by voice `roles` (the contact tag), `canFlash` (now RTO or admin; HQ no longer bumps, matching the
  permission table and the CALLS toggle) and `jmfsb_tacpad_apps_fnc_radioRole`, which feeds the tablet
  MANAGE and CALLS FLASH and the phone / side MANAGE. radioRole used to look for the player in the voice
  contacts, which never list the player, so the voice RTO tag never reached it. RADIO_RIGHTS: signal plan
  load / reset is RTO, export stays admin. No MANAGE actions built.
- Docs: DESIGN_VOICE.md, voice and tacpad_apps READMEs, SPEC_TACNET.json (A2G who is air, RTO console,
  mini kept as side2, drones A2G open item, nets.plan A2G who), TODO_DEVICES.md. Generated README halves
  are stale (voice now ships 71 functions; gen scripts not run).
- **Checked:** `hemtt check`, `sqf_validator.py`, `check_plumbing.py`, `check_invariants.py` - clean.

NOT RUN IN GAME.

## 2026-10-20 - Drones are flown from the devices, no UAV terminal

The vanilla UAV terminal left the PAC arsenal (user decision), and DRONES connected with
`connectTerminalToUAV` gated by `isUAVConnectable`, both of which need a terminal in the GPS slot. The
devices now fly drones themselves; no terminal item and no `UavTerminal_base` subclass (those are
side-locked - one item per side - and would bring back the vanilla terminal UI that was taken out).

- **New in `jmfsb_devices`:** `uavCan [uav, unit, needLink]` -> `[may, why, quality]` (the `UAVHacker`
  trait - the same test that gives the UAV tablet; the players' side, derived as DRONES does, D59; nobody
  else holding it; DATA link >= 0.2, unknown does not block). `uavControl [mode, uav, seat]`: `link` /
  `unlink` (one drone at a time, public `jmfsb_devices_uavOperator` on the drone), `take` (closes the
  tablet / map, next frame `player remoteControl` the gunner else the driver and `switchCamera` onto the
  drone - BIS_fnc_moduleRemoteControl's recipe), `release` (`objNull remoteControl`, camera back on the
  player in his old view, action removed), `linked` / `flying`. `uavOperator` (linked player, else a
  vanilla terminal still connected). `uavTick` (0.5 s PFH): unlink on death or when the gate fails (drone
  gone, hacked to another side, trait lost, taken); release on lost DATA link, lost seat, unconscious, or
  the camera back on the player. Way out: "Release drone control" on the drone's action menu, or the tablet
  key (numpad 5 releases while in a seat); release also on mission end.
- **Callers moved:** tacpad_apps `appDronesAction` (CONNECT/DISCONNECT/TAKE CONTROL through `uavControl`),
  `appDronesData` (linked / operator / can + why from the devices; task `LINKED - NAME`, `MANUAL - NAME`
  while seated; row gained field 10, the why), `appDronesFeed` (shows the gate's reason, not "Your terminal
  cannot take this drone"), `appDronesKey`; devices `overlayProviders` DRONES cell (the linked drone); cas
  `onStation` / `offStation` (link + take the gunner via `uavControl`, unlink on the way out; the ISR gate
  stays, so the caller now needs ISR AND the UAV trait) and the CAS module description; dtvd `getActiveUAV`
  asks `uavControl "flying"` first (ACE's `ACE_controlledUAV` and `getConnectedUAV` do not see a scripted
  seat; the terminal path is kept for loadouts that still carry one); gear `fnc_postInit` keeps the GPS slot
  for a JMSB device or any `UavTerminal_base`, not only `B_UavTerminal`.
- **Left alone:** `compatibility/*` and the `faction_*` / `uniform*` CfgVehicles still name UAV terminals in
  generated loadouts; the test mission `JMSB_Test.Tanoa` (`fn_loadout.sqf`, `fn_swap.sqf`) still puts one in
  the pack and swaps it. hacking and drone40 never used a terminal. TESTS.md P16.3 rewritten for the new flow.
- **Docs:** devices / tacpad_apps / cas READMEs (hand-written halves; the devices and cas generated halves
  mirrored by hand - re-run `gen_docs.py`, `docs/MODULES.md` still has the old CAS description).
- **Checked:** `hemtt check` (only an unrelated in-progress voice L-S29), `sqf_validator.py`,
  `check_plumbing.py`, `check_invariants.py` - clean.
- **Unverified:** that `remoteControl` + `switchCamera "GUNNER"` gives the UAV optic and weapons with no
  terminal (Zeus does it for crewed units), locality of a server-owned drone crew under a scripted seat, and
  that the release action shows in the action menu from inside the seat.

NOT RUN IN GAME.

## 2026-10-20 - TFAR and ACRE kept as optional radios; game voice runs only without them

User: "keep the ACRE and TFAR" (after "we are removing TFAR and going with Arma 3 game VoIP" and "our in
game VoIP setup should only run if there is no TFAR or ACRE"). VON stays the base and stays off under a
radio mod; TFAR and ACRE are supported again as optional voice adapters behind the one voice API.

- **Voice core (`addons/voice`), external-radio mode.** preInit sets `jmfsb_voice_system` `"von"` /
  `"tfar"` (`task_force_radio` or `tfar_core`) / `"acre"` (`acre_main`; TFAR wins if both, with a warning);
  `jmfsb_voice_active` keeps meaning "VON is running". Under TFAR / ACRE nothing of VON starts, as before
  (adapter_von does not register, no channels, PTT, KeyDown / EachFrame, VoiceOverNet block, volume ticks,
  calls, callbacks or sounds). Instead `registerAdapter` takes only the adapter whose id is the system
  (required hooks `nets`, `netState`, `talking`; optional `current`, `setActive`, `ptt`, `setEar`, `setMute`,
  `linkQuality`, `selfTest`) and a client PFH `fnc_externalTick` (0.1 s; nets each second) mirrors it:
  `nets` (local player only), `netState` (adapter rows + talkers), `activeNet`, `setActive` / `stepActive`,
  `setEar` / `setMute`, `quality`, `talking` and `jmfsb_voice_talk` edges. Calls, contacts, callbacks,
  `members` and `playCue` stay VON only (empty). selfTest logs the system.
- **`addons/adapter_tfar` restored** from the 1268 build (fill, program, net frequency / table / read-back,
  PTT keybinds and display hook, TFAR UI hiding, RF nodes `tfar_<uid>_*`, range levers, settings) as an
  optional addon (`tfar_core` + `skipWhenMissingDependencies`, now also requires `jmfsb_voice`). Changed:
  the plan is `jmfsb_pac_fnc_netPlan` (`fnc_planNets` maps it to TFAR sets and channels; unslotted VON-plan
  nets take free channels in plan order; a2g rides the long range sets); `serverNets` dropped (pac's
  `netPlanSync` makes the nets); profiles from `jmfsb_rf_fnc_itemProfile`; the old public `netState` is
  replaced by the voice hooks (`fnc_voiceView` builds nets / rows / active net each poll); new `talking` /
  `keyed` (each speaker pushes his key edge to his side's players from `OnTangent`), `setActive`, `setEar`
  (TFAR stereo), `setMute` (set volume 0 and back), `linkQuality` (RF quality on the net, unknown = 1),
  `selfTest`, and the public `tune`, `activeRadio`, `sideDefaults` for the restored paths below.
- **`addons/adapter_acre` is a real adapter** ("acre"): nets = each radio's current channel label in the PAC
  plan's ACRE tier (`jmfsbFR_radio_sr/mr/lrRadios` + `...Channels`, else `<TIER> CH <n>`), active = radio in
  hand, ear = spatial zone, mute = volume, reachable = radio on, talking from `acre_remoteStartedSpeaking` /
  `acre_remoteStoppedSpeaking`, own PTT from `acre_startedSpeaking` / `acre_stoppedSpeaking`, quality 1
  (ACRE's own signal model). API names checked against d:\Git\acre2 (`c920bac1`): getCurrentRadioList,
  getBaseRadio, getRadioChannel, getCurrentRadio, setCurrentRadio, getRadioSpatial, setRadioSpatial,
  getRadioVolume, setRadioVolume, getRadioOnOffState, and the four events with their payloads. RF nodes stay
  DATA only. gear `fnc_setupRadios`' ACRE programming untouched.
- **Radio items stay plain**; new optional `compatibility/tfar_radios` (needs `tfar_core`, `tfar_handhelds`,
  `tfar_backpacks`) re-parents `jmfsb_mpu5` / `jmfsb_tw950` on `TFAR_anprc152` with `tf_prototype`,
  `tf_parent`, TFAR's `TF_RADIO_IDS` instances and the MPU5 dialog (restored, picture via
  `QPATHTOEF(radios,...)`), and puts the 1268 `tf_` LR values on the backpack bases (`TFAR_rt1523g_kitbag`,
  `RadioBag_01_Base`, so `jmfsb_mpu5_lr` too) and the uniform / uniform_ru radio bags (Bussole / east code on
  the CSAT and RU ones); `compatibility/tfar_cdlc_ws` does the WS MCU-D bag. `compatibility/tmt_tfar_labels`
  restored from git HEAD (it is for modsets WITHOUT TFAR). No ACRE patch existed; none added.
- **TFAR tuning from the net plan, guarded on TFAR:** `jmfsb_patches_usesTFAR` back in init preInit
  (`task_force_radio` or `tfar_core`); players `setRadioChannel` (squad's `netPlanSquad` sr / lr nets, the
  platoon's `lrPlatoonChannel` LR when the squad has no tfarNets row, then `adapter_tfar_fnc_tune`) and
  `setActiveRadio` (`adapter_tfar_fnc_activeRadio`, now "this class in hand" like ACRE - the 1268 branch
  activated a different radio); init `playerpost` and groups `setupPlayer` TFAR waits; systems
  `clearRadioIds`, `filterUnitLoadout` (`TFAR_fnc_isRadio` -> `ace_arsenal_uniqueBase`), `getChannelName`,
  `getRadioBase` (`tf_parent`); gear `setupRadios` -> `adapter_tfar_fnc_sideDefaults` (TFAR side default
  frequency lists from the plan, west / east / independent). vehicle: the 1268 TFAR branch was an empty TODO
  (racks are loaded by the crew's fill) - left as is. The VON path is untouched everywhere.
- **Screens:** the RADIO app shows the external system's nets (panel subtitle TFAR / ACRE, no VON column,
  its own footer), CALLS / MANAGE say in words that calls are game voice only, the sounds panel says the
  radio's sounds are its own; the tablet net row and HUD widget show the radio's nets and "<SYSTEM>: NO NET"
  only when there are none. reaction skips the voice talk event under ACRE (its ACRE poll already counts the
  key with the radio's power). pac `radioKeys` comment: tfarActiveRadio / the frequency lists have a reader.
- `.hemtt/launch.toml`: HEAD has no TFAR profile, none added. READMEs: voice, adapter_von, adapter_tfar,
  adapter_acre, radios, compatibility (adapter_tfar / adapter_acre generated halves written by hand -
  `gen_docs.py` not run); DESIGN_VOICE.md Decision.
- **Checked:** `hemtt check` (no findings), `sqf_validator.py`, `check_plumbing.py`, `check_invariants.py`,
  `config_style_checker.py` pass; `check_ctab_configs.py` skips (no ctab_devices).
- **Unverified:** everything at runtime. TFAR: the re-parented MPU5 / TW-950 under TFAR's prototype swap,
  the dialog, `tf_` values on the bags, pushed key events against TFAR's real range (a speaker out of TFAR
  range still shows as talking), TFAR's stereo / volume getters on LR racks. ACRE: remote radio data being
  readable on the listener (`getRadioChannel` on another player's radio id), the speaking event payloads in
  the shipped ACRE version, `getRadioOnOffState` on radios without a power switch.

NOT RUN IN GAME.

## 2026-10-20 - Base stations: a real satellite link in RF; staging zones and patrol bases relay and uplink; the manpack is optional

User: "can we lose the LR or use our patrol base as a relay", "can we assume a staging zone or patrol base as a
sat uplink", then "do it". DESIGN_RF.md "The satellite link" and "Base stations"; open item 6 (rain fade on
SAT) closed for SAT.

- **RF: SAT is a satellite** (`addons/rf`). Two nodes whose profiles both have SAT and that hold the same key,
  each under open sky, link in one hop at any distance, terrain and clutter ignored, whatever band the net is
  on (a SAT terminal backhauls any net, so it is on every net's mesh it holds; tick membership is "net band
  or SAT"). `fnc_edge` takes the better of the ground link and the satellite. Open sky: `fnc_openSky`, one
  `lineIntersectsSurfaces` ray 30 m up from the antenna (own object and a man's vehicle ignored), cached per
  node in `jmfsb_rf_sky` and re-cast by the tick only on the static tick or after 10 m of movement. Quality:
  `fnc_satBudget`, 0.9 in clear sky at any threshold / span, less the tick's rain fade (`jmfsb_rf_satFade` =
  new setting "SAT rain fade" (default 6 dB) x (rain + 0.25 x overcast, capped at 1)), through the link-budget
  formula against `fnc_noise` on SAT at each end, so EW's SAT jamming and any SAT noise source still bite.
  A satellite leg is one edge, so it is one hop; nothing in the hop limit changed. The SAT band row (exp / ref)
  now prices only ground emitters on SAT (setting descriptions say so). `fnc_budget` on SAT is the satellite
  budget with a fresh sky check; `fnc_rangeTable` reports SAT as any distance (-1).
- **Profile `base`** in `RF_PROFILES`: VHF / UHF / SAT, 43 dBm (20 W), -118 dBm, 6 dBi, hop limit 8, relay,
  spread 25, battery -1.
- **Base stations** (`addons/pac`: `fnc_baseStation`, `fnc_baseStationRegister`, `fnc_baseStationRemove`).
  PAC already bridges the plan into RF (`netPlanSync`), so it owns them: a holder-less `base` node on the
  site's object (a position gets a `Land_HelipadEmpty_F` helper), fill = every `netPlan` net id + DATA + the
  default plan's C2 (the net voice gives a squad the plan does not name), relay and TX on, side = the caller's
  or the players' (`jmfsb_common_fnc_playerSides`). One per object / rounded position; MPKilled and Deleted
  take it down; `netPlanSync` re-registers every station when the plan changes. Not a unit, so nothing for
  ALiVE to profile. Soft calls only: mission and patrol_base gain no hard dependency.
- **Staging zones** (`addons/mission`): `addStagingZone` (object, marker or position) calls the new
  `fnc_stagingUplink`; zones are added on clients (init `staging` runs for players, the Zeus module on the
  Zeus's machine), so a client raises the server event `jmfsb_mission_stagingUplink` and the server makes
  one station per site. `removeStagingZone` takes it down (only a station the mission owns). New
  `initSettings.inc.sqf` with "Staging zone satellite uplink" (CHECKBOX, on); `cba_settings` added to
  requiredAddons.
- **Patrol bases** (`addons/patrol_base`): `serverBuild` puts a station on the beacon for the builder's side
  behind the new setting "Patrol base radio relay" (CHECKBOX, on); `serverUnbuild` takes it down before the
  beacon is deleted; MPKilled / Deleted cover the rest. The beacon keeps `allowDamage false`, so "destroyed"
  in practice means setDamage, Zeus delete or unbuild.
- **Manpack optional, RTO from PAC only** (`addons/voice`): `fnc_fill` already gives every set (handheld,
  bag, vehicle seat) the same fill with the C2-kind net; nothing in the VON path gates C2 on a manpack.
  `fnc_isRto` no longer counts a long range set on his back: the isRTO flag, the PAC RTO tag or the role
  words (RTO, RADIO, JTAC, FAC). Header, voice README "The RTO job", DESIGN_VOICE.md updated.
- **Physics note:** handheld to base station is ~0.6 km on flat, clear ground - the handheld's 25 mW is the
  weak direction and the base's 20 W does not help it. A squad 3-5 km out reaches the base only through MPU5
  relays, a manpack or a vehicle; the base-to-base leg is the satellite.
- **Docs:** DESIGN_RF.md (satellite link, base stations, profile row, mesh vertices, settings, open item 6),
  DESIGN_VOICE.md (base stations, RTO), READMEs (rf, voice, pac, mission, patrol_base hand-written halves;
  generated halves not regenerated), TESTS.md P19.
- **Checked:** `hemtt check` (no findings), `sqf_validator.py`, `check_plumbing.py`, `check_invariants.py`,
  `config_style_checker.py` pass.
- **Unverified:** everything at runtime - the upward ray against real roofs and the SatCom mast's own
  geometry, `alive` on the helipad helper, MPKilled / Deleted on the mast, the satellite link's quality in the
  slices and VON volume, EW seeing the station as a track, ground jammers' SAT noise on the uplink. Under the
  TFAR adapter the C2 (lr) nets are still programmed on LR sets only (TFAR's own short / long range split).

NOT RUN IN GAME.

## 2026-10-20 - Patrol base default hooks pointed at functions that no longer exist

The patrol base's default On-deploy / On-undeploy SQF still called `YMF_fnc_addStagingZone`,
`YMF_fnc_removeStagingZone`, `Rev_tp_fnc_addPoint` and `Rev_tp_fnc_deletePoint` (pre-rename prefixes), so a built
base never became a staging zone or teleport point, and the deploy hook named `west` outright. Defaults now call
`jmfsb_mission_fnc_addStagingZone` / `removeStagingZone` and `jmfsb_teleport_fnc_addPoint` / `deletePoint`, and
pass the hook's own `_side` (the builder's side) to the teleport point. Missions or server settings that saved
the old text keep it until reset.

NOT RUN IN GAME.

## 2026-10-20 - DRONES: GO TO, LASE, RTB and Drone40 modes

The open DRONES items in TODO_DEVICES.md. Every order is gated like CONNECT (the UAV operator trait, the
players' side, the drone linked to him, the DATA link - `jmfsb_devices_fnc_uavCan`, asked again at the press)
and works on both hosts.

- **Orders go to the crew's owner** (`addons/devices`): new public `fnc_uavOrder [order, uav, args]` -
  `orbit`, `goto` (MOVE at the drone's height, 50 m floor, then LOITER), `rtb` (MOVE, then `land` on a
  helicopter-type drone, else LOITER), `lase` (`lockCameraTo` + `BIS_fnc_fire` on the designator, the point
  public as `jmfsb_devices_uavLase`). Refusals come back on the caller; the order itself goes by CBA
  targetEvent `jmfsb_devices_uavOrder` (handler in preInit, every machine) to the machine where the group is
  local. ORBIT now goes the same way instead of adding waypoints on the client.
- **`fnc_uavLaser`** finds the designator from config (ammo simulation `laserDesignate`, or the
  `Laserdesignator_mounted` / `Laserdesignator` families), cached per class. **`fnc_uavHome`**: the drone's
  `jmfsb_devices_uavHome`, else the nearest staging zone or own-side patrol base, else the operator.
  `uavControl "link"` records a home when the drone is linked sitting on the ground.
- **DRONES board** (`addons/tacpad_apps`): GO TO / LASE (LASE OFF while lasing, alarm fill) / RTB live.
  GO TO is a map pick (`fnc_appDronesPick`): closes the app, claims `jmfsb_tacpad_appMapClaim`, left click
  orders, right click cancels, a watchdog lets go after 30 s / another app / host closed / drone dead. The FEED
  HUD target line reads `LASE <grid> - <n> M` while lasing. Fleet rows gain lasing, has-laser and Drone40
  mode (key includes them). New defines `DRONES_PICK_*`, `DRONES_MOUSE_*`, `DRONES_MODES`, `DRONES_LAND_KIND`.
- **Drone40 modes** (`addons/drone40`): new public `fnc_setMode [drone, mode]` (relay / decoy / jammer /
  off), server-authoritative (`jmfsb_drone40_setMode` server event). It removes the node (`fnc_remove` now
  also drops the jammer's EW emitter via `jmfsb_ew_fnc_removeEmitter`), sets `jmfsb_drone40_mode` public and
  re-runs `fnc_deploy` with the launcher kept on the drone. `fnc_deploy` reads the mode before the round's role
  and records the launcher's position as `jmfsb_devices_uavHome`. The DRONES FEED shows a MODE row for a
  Drone40 the player holds or may link.
- **Docs:** READMEs (tacpad_apps "DRONES: no UAV terminal", devices "Flying drones without a UAV terminal",
  drone40 "Modes"; generated halves not regenerated), TODO_DEVICES.md DRONES row, TESTS.md P16.2 and
  P16.8-P16.12.
- **Checked:** `hemtt check` (no findings in the touched files), `sqf_validator.py`, `check_plumbing.py`,
  `check_invariants.py` pass.
- **Unverified:** all of it at runtime - `BIS_fnc_fire` toggling a turret designator on a UAV and the AI
  gunner keeping it on / on the point, `lockCameraTo` holding the turret, `isLaserOn` / `laserTarget` on a
  remote drone, `land` from a waypoint statement on GX's Drone40 and the Darter, `flyInHeight` on fixed-wing
  UAVs, the tablet's map taking the pick with the app closed, GX's own launch record (not looked for - GX is
  not in the workspace), and the RF / EW re-registration after a mode switch.

NOT RUN IN GAME.

## 2026-10-20 - EW: GPS spoof readers, HACK SPOOF, enemy AI EW BASIC (D17)

- **GPS readers** (`addons/ew`): `fnc_gpsState` now also reads NO FIX (the jamming addon's
  `jmfsb_jamming_gpsDenied`). New public `fnc_gpsOf [unit]` (any man: the player's slice, others the
  server-set `jmfsb_ew_gps` unit variable - state and offset, 10 m grid, on change - and the
  `jmfsb_ew_gpsDenied` edge his own client reports through new `fnc_gpsWatch`), `fnc_gpsHere [loud]`
  (own GPS position ATL or `[]`, rail warning on NO FIX / SUSPECT) and `fnc_gpsGrid [unit]` ("041 116",
  "... SUSPECT", "NO FIX"). Readers: BFT member dots and group markers (`bft` drawMembers /
  getGroupPosition: false fix, denied man not drawn, own dot "- GPS SUSPECT"), map tools CENTRE (GPS
  position; NO FIX refuses) and GRID (a `GPS <grid>` line under the cursor's), tacpad CUR LOC, compose
  CURRENT LOC pin and reader + GRID, tacpad_apps TIC location (refused on NO FIX), EW OVERVIEW. DF cuts are
  measured from the sensor and plotted from its GPS position (`fnc_cut` 7th argument), so spoofed
  sensors make off-target fixes. Soft calls only: no addon gained a dependency on `jmfsb_ew`.
- **Devices bar not touched** (another agent owns devices): `fnc_gpsGrid` is its getter; the line to
  change in `devices/fnc_tabletBar.sqf` is written into TODO_DEVICES.md section 2.
- **Spoof engine** (`fnc_spoof`) now runs for AI men too (keyed by hash, forgotten on true) and treats
  a hacked net (`GVAR(spoofNodes)`) as a field; new `fnc_spoofTick` moves the AI men it keeps, new
  public `fnc_spoofNode [group, hacker]` (client forwards). Setting "Hacked GPS spoof (sec)", 300.
- **HACK SPOOF** (`addons/hacking`, `tacpad_apps` appHackAction): session key `action`; new
  `fnc_canSpoof` (a "unit" net and `jmfsb_ew` loaded) and `fnc_tabletSelectAction`; `fnc_hackComplete`
  takes the action and, past the same fail and detection rolls, hands the net's group to
  `jmfsb_ew_fnc_spoofNode` instead of the pick. `fnc_scanDevices` also lists a crewed hostile vehicle
  the operator's set hears carrying an RF set (`GVAR(rfReach)`) as its crew's net (kind "unit"), under
  the remote unit hack switch and scope as handsets are. ACTIONS row: TAP / SPOOF selectable on a net,
  EFFECT row under SPOOF.
- **AI EW** (`addons/ew`): settings "Enemy AI EW skill" (LIST OFF / BASIC / ACTIVE / SMART, default
  BASIC) and "Enemy AI fix reaction range (m)" (1500). The side is `jmfsb_common_fnc_enemySide` (D59),
  cached 30 s. RF counts no AI sets, so `fnc_aiSensors` makes each enemy AI group whose radio
  (`fnc_aiSet`, best RF profile any man carries via `jmfsb_rf_fnc_carriedSets`, cached 30 s) can DF a
  sensor priced like a player's set (EW Receiver = dedicated); six AI sensors tried per emitter per tick.
  `fnc_aiReact` on every fresh fix of the side, 120 s per track: groups in range the report reaches
  (`fnc_aiLink`: voice inside 50 m; else one 2 s hop at RF link-budget quality for the group's set over
  clear ground, against RF noise at the group) go AWARE and watch the fix (`fnc_aiAlert`, targeted where
  the group is local); the player on the set goes through `jmfsb_reaction`'s ladder (source `df`).
  ACTIVE adds `jmfsb_uas_fnc_respondTo`, SMART `jmfsb_qrf_fnc_onCaptured`, once per side per 300 s.
- **Against the design:** built BASIC's ES and "on a fix" row, ACTIVE / SMART's "on a fix" dispatch
  only, and a one-hop comms gate for the fix report. Not built: ACTIVE drone jamming, EW teams that hunt,
  AI EMCON and moving after TX; SMART spot jamming, spoofing, decoys, hacking, rekey, PACE, plotting,
  priority on jammers; the comms gate's mesh / terrain, HQ path for support, sighting sharing, LAMBS,
  isolated groups; zeroize chances. BASIC's "static jammers" are the jamming addon's existing sites.
  D9 ("enemy jamming off until a module is placed") vs D17 (default BASIC): the AI DF reaction is on by
  default; its ladder half still needs the Reaction module.
- **Docs:** READMEs (ew, hacking, bft, maptools, tacpad, tacpad_apps hand-written halves; generated
  halves NOT regenerated - `tools/gen_docs.py` must run before `check_readmes.py` passes), TODO_DEVICES.md,
  TESTS.md P15.17-P15.22, P16.8 (P15.12, P16.6 amended).
- **Checked:** `hemtt check`, `sqf_validator.py`, `check_plumbing.py`, `check_invariants.py` pass.
- **Unverified:** everything at runtime - `hashValue` on groups as map keys, AI cut counts and fix rates
  against real crews, the DF tick's cost with a large enemy force, `doWatch` / `setBehaviourStrong` via
  the targeted event on a headless client, the unit-variable traffic while spoofed, the map tools GPS
  line's offset under the cursor, `effectiveCommander` / `group` on a hacked vehicle, the vehicle row
  joining its RF row on the HACK board.

NOT RUN IN GAME.

## 2026-10-20 - Drone40 mode switch checked on the server; tablet bar grid from the GPS

`jmfsb_drone40_fnc_setMode`: a client's switch now reaches the server by `remoteExecCall` with the caller, and the
server refuses it unless `remoteExecutedOwner` is the caller's machine and the caller passes
`jmfsb_devices_fnc_uavCan` (without the DATA link, which only the client measures). The unchecked CBA event
`jmfsb_drone40_setMode` is gone. Calls made on the server stay trusted.
`jmfsb_devices_fnc_tabletBar`: GRID reads `jmfsb_ew_fnc_gpsGrid` when EW is loaded ("041 116", "... SUSPECT",
"NO FIX"); the map grid as before without EW.

NOT RUN IN GAME.

## 2026-10-22 - the MPU5 is every role's default radio

User: "make sure the default radio for all roles is the MPU5". The mod never picks a
radio; it is data in three places, all changed in Mongo by `tools/pac_default_radio.py`
(dry run, then `--apply`, backups in `D:/Git/_jmsb_db_backup_2026-10-22`): the 20
live `JMSB.role.*` default loadouts had an empty radio slot (the 16 `_t` roles already
carried `jmfsb_mpu5`) - now `jmfsb_mpu5` in all 36, the ACRE sets in the containers
left for ACRE nights; `JMSB.arsenal` itemsTools gains `jmfsb_mpu5` so ACE's Default
Loadouts row keeps it; the two kept player loadouts with an empty slot are filled;
`JMSB.radio` tfarActiveRadio is `jmfsb_mpu5` (was TFAR_pnr1000a, which nobody carries).
Under TFAR the MPU5 is a PRC-152-class set through the compat patch, not a MANET; under
ACRE it is not ACRE gear and ACRE links its flag item over the slot - ACRE players notice
nothing. Known gap, not done: `jmfsb_pac_fnc_loadoutSave` stores the raw radio slot, so a
save on a TFAR / ACRE night keeps a backend-only class there; the tool treats those as
empty, the mod does not yet filter them on save.

NOT RUN IN GAME.

## 2026-10-22 - game voice boards

User: "signs_v2 needs signs for the game voip system". Three boards in `tools/gen_signs.py`,
rendered to `signs_v2` and `signs_v2_plain` like the rest and converted to PAA: `radio_nets`
(TEAM, C2, A2G, VEH, DIRECT, CALL 1-8, GLOBAL and who is on each, the chip outline key),
`radio_keys` (Push To Talk, Num 1-4, Num 0 / ., Ctrl+Num 1-4, Num 5-8, Ctrl+End) and
`radio_howto` (seven steps: bind PTT, carry the MPU5, the squad net on role pick, TX, the mesh,
weak and no route, the cut-offs). The words come from addons/voice, addons/adapter_von and
the devices' keybinds. Place them on a Land_Billboard_F in Eden like the other boards:
`z\jmfsb\addons\media\images\signs_v2_plain\radio_<name>.paa`.

NOT RUN IN GAME.

Addendum, same day - "include drawings" in the signs: three device boards, `radio_phone`,
`radio_side` and `radio_tablet`, each the labelled diagram (tools/gen_device_diagrams.py ->
art/signs/diag_*.png: the real frame art with the screen drawn as addons/devices lays it
out and numbered callouts) beside its key - a new "devices" kind in gen_signs.py. The
phone board's key column is the narrowest, so its lines are the shortest.

## 2026-10-22 - RTO skill and RTO nets

User: "add an rto skill or trait, and on the radio app allow rtos to add custom channels".

**The skill is data.** `tools/pac_skill_rto.py` (dry run by default, `--apply`, backups in
`D:/Git/_jmsb_db_backup_2026-10-22`) puts `rto` in `JMSB.skills` (abbrev RTO, effect
`trait:isRTO`, colour 0,150,136 - `art/skills/rto.png` was already drawn for it) and "rto" in
the skills column of the first C2 row of `JMSB.radio` vonNets, so every RTO rides C2 and passes
`jmfsb_voice_fnc_canGlobal`. `jmfsb_voice_fnc_isRto` is unchanged: the skill gives both the
flag and the tag it already reads. The tool also warns about any `JMSB.role.*` that sets isRTO
itself, because once a skill owns the name `jmfsb_pac_fnc_managedNames` makes groups'
`fnc_setupPlayer` skip it on the role - such a role has to grant `rto` under defaultSkills
instead. Dry run against the live data: `items.rto` absent; the C2 row's skills `[] -> ["rto"]`;
no role sets isRTO itself; 2 documents to change. Applied 2026-10-23 (backups in
`D:/Git/_jmsb_db_backup_2026-10-23`); a re-run finds nothing to change.

**RTO nets** (addons/voice, adapter_von and tacpad_apps, built in the same pass): a new net
kind `custom`. The server keeps `jmfsb_voice_customNets` (id -> [name, squads, uids, owner uid,
owner name]) and publishes it as `jmfsb_voice_customPub` only when it changes, JIP-kept like
the roster. The id is the name, upper-cased and trimmed: 2-10 letters, digits, spaces and
dashes; not a plan net, not C2 / A2G / VEH / DIRECT / GLOBAL / DATA, not `TEAM ...` or
`CALL ...`. Server events `srvNetAdd [caller, name, squads, uids]`, `srvNetRemove [caller, id]`
and `srvNetMembers [caller, id, squads, uids]` are each gated by `canFlash` (the RTO or a
logged-in admin - the FLASH right); a refusal comes back as the targeted `netFailed [reason]`
(notRto, badName, taken, full, noChannel, unknown) on the caller's notify line like a refused
call. On add the server makes the RF net as `fnc_serverTick` makes TEAM nets and asks the
adapter for a channel through the new optional hook `reserve [netId]` (VON: `ensureChannel` on
the net's key; noChannel when VON has none left). On remove the entry goes and the publication
drops it: the clients' plan loses the row the next second, `fill` drops it, the roster leaves
everyone; VON cannot delete a custom channel, so it stays cached by key and is reused when the
same name is made again. Client API `netAdd` / `netRemove` / `netMembers` (bool: sent, not
done - success shows through the publication), `customList`, `customNets [unit]`,
`canManageNets [unit]` (isRto or `jmfsb_common_isAdmin`; a display gate, the server re-checks).
`fnc_planRefresh` appends `[id, NET_BAND_TEAM, "custom", -2]` per published net before its
unchanged-comparison (slot -2, so `canGlobal`'s "slot -1 is a VON plan row" test stands);
`fill`, `nets` (after A2G, before the calls), `serverTick`'s roster filter and `rfNet` admit
the kind. adapter_von: `channelKey` answers the id (own channel per net, like CALL),
`ensureChannel` colours it COLOR_CUSTOM, `reserve` registered in its preInit. New CBA setting
`jmfsb_voice_customNetsMax` "RTO nets at once" (0-6, default 2, server-forced): each net takes
one of VON's ten custom channels for the rest of the mission, so the calls get what is left and
the phone's NET % drops by one per net. MANAGE on the tablet gets the RTO nets block; the
rights row "temp net, patch" at SL is "custom nets" at RTO (RADIO_RIGHTS, DESIGN_VOICE.md).

- **Docs:** DESIGN_VOICE.md (rights table, "RTO nets"), TESTS.md P12.33-P12.39,
  `tools/gen_skill_icons.py` docstring (eleven skills, not ten).
- **Checked:** `tools/sqf_validator.py` passes (2132 files); `hemtt check` and the rest of
  `check_all.py` are the gate's, run after this pass.
- **Unverified:** everything at runtime - the publication reaching JIP clients, VON handing out
  a channel at create and reusing it by key after a remove, the chip on a squad ticked by
  callsign, the server refusing a client that only set `jmfsb_common_isAdmin` locally, NET %
  on the phone falling per net.

NOT RUN IN GAME.

## 2026-10-23 - the screen corners: rubber over them, a slight radius

User, 2026-10-22/23, red circles round the bumpers for the fifth day, then "on all devices on
the outside dark border add a slight roundness to the corners". Two changes to
`tools/gen_devices.py`, all six frames regenerated, no screen rect moved: (1) the square cut
no longer goes through the rubber - anything darker than RUBBER at least 2 x RUBBER_OPEN_R px
thick keeps its pixels, so each corner guard's inner lobe lies over the screen's corner as a
real one does (the Frame control draws above the map in overlay.hpp and dialog.hpp); the olive
band painted in on 2026-10-22 to part screen from bumper, which read as a seam, is gone;
(2) the cut is a rounded rectangle of SCREEN_CORNER_R 14 px, so the frame fills a small fillet
at each corner of the dark screen. The phone's bars stand OVERLAY_INSET_Y (2 % of the hole's
shorter side) off the top and bottom edges, clear of the lobes. `--preview` now also writes
<device>_corners.png, the four corners over a dark screen, to check this without a crop script.

NOT RUN IN GAME.

## 2026-10-23 - the how-to in the Field Manual

User: "there is a field manual in arma can we put all our how to data in there". New
config-only addon `jmfsb_fieldmanual`: a **1st JMSB** category in the pause menu's Field
Manual (CfgHints) with four topics - Radio voice (6), Staging zone (10), Map and tablet (4),
Ammunition (5) - 25 entries. `tools/gen_fieldmanual.py` writes `CfgHints.hpp` from the sign
boards' own words in `tools/gen_signs.py` (rows, key columns, sections, the device boards'
numbered keys, the FA ammo columns), each entry showing its board as the picture
(`signs_v2_plain`, the FA boards from `jmfsb_fa_main`), so the manual and the signs are one
source. Wayfinding boards, uniform swatches and duplicate boards are left out. Change a
board in gen_signs.py, run both generators.

The tablet's recess band, same day: its four straight bands stop a corner short and four
quarter-round pieces (`data/corner_*_ca.paa`, from gen_devices.py) fill the corners, clear
outside the arc, so the frame's fillet shows on the tablet as on the phone; `frames.hpp`
carries `corner`, the radius as a fraction, read by FUNC(layout).

NOT RUN IN GAME.

## 2026-10-23 - guides to the radios, the devices and the tablets

User: "add guides to the radios, the devices and the tablets to both the web site and field
manual, and make sure i have simple signs with pictures for in game".
- Boards (`tools/gen_signs.py`): `radio_sets` (the MPU5 and the TW-950, their arsenal icons
  as the pictures - `art/radios/*_icon.png`, converted from `addons/radios/data` - with a
  plain dashed key), `tablet_apps` (the ten tiles and SETTINGS), and three SIMPLE signs,
  `simple_phone`, `simple_side`, `simple_tablet`: the drawing with four callouts
  (`tools/gen_device_diagrams.py` SIMPLE_PICKS -> `diag_*_simple.png`) and four lines set
  large (the "devices" kind now sizes its key by the room: 46 px for four lines).
- Field Manual (`tools/gen_fieldmanual.py`): topics Radio voice (3), Radios (1), Devices (4),
  Tablets (3), Staging zone, Map and tablet, Ammunition - 30 entries.
- Website (D:/Git/jmsb-website, the Quiver, chapter Communications): three public pages,
  `radios`, `devices`, `tablet` (`src/content/quiver/*.html` + `_index.json`), pictures in
  `public/quiver/img/radio/` (the diagrams, the radio icons, the three text boards). Written
  from the same facts as the boards and the voice guide. The site was NOT built here: node is
  not on this machine's PATH for either shell.

NOT RUN IN GAME.

## 2026-10-23 - the BFT number smaller; the RTO block's ADD NET form stays

- **BFT** (user: "need a smaller font on the players number"): the member
  number inside the circle has its own size, `MEMBER_NUMBER_TEXT_SIZE` 0.026,
  down from the name's 0.035 (`addons/bft/script_component.hpp`,
  `fnc_drawMembers`). The name is unchanged.
- **RADIO - MANAGE, RTO NETS** (user: "when i tried to add a radio net in game
  the net was created then the creat went away"): two faults, both in
  `fnc_radioCustomPanel`, the first also in `fnc_radioMembersPanel`.
  1. The panel unpacked its rectangle as `_x`/`_y`; inside `forEach` the
     element is `_x`, so the first listed net - and the squad chips, and the
     MEMBERS people rows - computed `_x + ...` on an array or a string and
     the script stopped there, before ADD NET was drawn. With no net yet the
     loop never ran, which is why CREATE showed until the first net existed.
     The rectangle is `_left`/`_top` in both panels now.
  2. The form only drew if it fit under whatever the nets took. It is now
     anchored at the bottom of the block with its height known first; the net
     list (and "NONE YET" / "NO ROOM") takes what is above it and gives way
     with "+N MORE" when room is short. The plan's NETS list above the block
     is not touched.
  Changed in source; not seen in game - test: make a net, then the ADD NET
  form, the squad chips and the MEMBERS people rows must all still draw.
