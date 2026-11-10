# Test plan — docs/new.md §9, steps 1-6

**Only slice zero has ever run.** Everything else below is unexecuted code.
Work down in order: each test assumes the ones above it passed, because a
failure high up makes everything under it meaningless.

Every check has a **fail meaning** — what it tells me if it does not do that.
Paste the RPT lines for anything that fails; the log line is worth more than
a description.

---

## Mission setup

| Place | Why |
|---|---|
| ALiVE Required + Virtual AI System | everything |
| **Military AI Commander** — conventional (occupation *or* invasion) | steps 1-5 |
| **Military AI Commander** — asymmetric | leaders, safe houses, QRF's mortar branch |
| **Military Placement** synced to each commander, with a TAOR marker | every TAOR read |
| ALiVE **artillery** module for a conventional side, with a battery in range | fire requests |
| A `jmfsb_prison` marker where you will hold prisoners | leader capture |
| An arsenal, or Zeus | to take an **Intel Drop Case** and a hacking tablet |

Terrain: one ALiVE has indexed. On an unindexed map the cluster globals do
not exist and coastal / caches / safe houses will say so and place nothing —
that is correct behaviour, not a bug, but it makes those tests untestable.

---

## 0. Boot

1. Load the mission. Read the RPT top to bottom once.

| Check | Pass | Fail means |
|---|---|---|
| No `Script ... not found` warnings for any jmfsb addon | ☐ | a CfgEventHandlers references a file that does not exist |
| No `Undefined variable` / `Error Params` from a `z\jmfsb\` file | ☐ | a real bug — paste it |
| `[JMFSB] (adapter_alive) INFO: ALiVE up after Ns - N commander(s)` | ☐ | the adapter never became ready; nothing below will work |

---

## 1. Slice zero — re-run it

The adapter changed since it last passed, so it is worth 60 seconds.

    #jmfsbreads
    #jmfsbsquad
    #jmfsbfire
    #jmfsbcapture

| Check | Pass | Fail means |
|---|---|---|
| Every commander prints `logic=resolved` | ☐ | the position-match broke; every TAOR read returns empty |
| `taor=[...]` non-empty for each side | ☐ | placements are not synced, or the key read is wrong |
| `AA pool n=` matches roughly the AA ALiVE placed | ☐ | the aaProfileBehaviour join is wrong |
| The squad profiles and walks to you | ☐ | spawn→profile→move is broken; QRF and patrols both depend on it |
| `#jmfsbcapture`: hold 10 s → `jmfsb_objective_captured raised` | ☐ | capture detection is broken; QRF cannot fire |

---

## 2. Coastal

    #jmfsbcoastal

| Check | Pass | Fail means |
|---|---|---|
| It lists one site per side, up to the slider | ☐ | no coastline passed the water test, or no marine clusters — the RPT says which |
| Each site reports `launchers=N radars=1` once you are near it | ☐ | the position-keyed refresh is not finding its own hardware |
| Sites are on real shore, not inland ponds | ☐ | the water-ring test is too loose |
| Radar and launchers are **separated**, not in a heap | ☐ | the inland placement pass failed |
| Fly/sail a large boat past → the battery engages | ☐ | the battery behaviour is not being driven |
| Walk away 3 km, come back → it still works | ☐ | **the important one.** Profiling deleted the hardware and the refresh did not re-point at the new objects |

---

## 3. Jamming

    #jmfsbjam

| Check | Pass | Fail means |
|---|---|---|
| Zones listed, roughly the objective share you set | ☐ | props missing from your mod set (RPT says so), or no objectives |
| Standing near a prop degrades your radio | ☐ | the applier is not running client-side |
| **Destroy** a prop → its zone leaves the list | ☐ | the prune is not catching destruction |
| **Hack** a prop → its zone leaves the list | ☐ | the hacked-flag branch of the prune is wrong |
| Once a zone is gone it stays gone | ☐ | something re-registers it |

---

## 4. Caches and patrols

    #jmfsbuas

| Check | Pass | Fail means |
|---|---|---|
| `ceilings west=N east=N` matches the slider | ☐ | settings not read |
| Patrol counts non-zero after adapter-ready | ☐ | patrols would not profile — check RPT for the delete-rather-than-leave-live warning |
| A patrol drone is **not** flying when you are far away | ☐ | it did not profile, and you have live aircraft on an empty map |
| Approach an objective → a drone materialises | ☐ | ALiVE is not spawning the profile |
| Find and destroy a cache → RPT logs `ceiling N for Ns`, and `#jmfsbuas` shows the outage | ☐ | the Killed handler or the outage map is wrong |
| While the outage runs, fewer drones come back | ☐ | `ceilingFor` is not being consulted where drones are made |

---

## 5. The hack console

Take a hacking tablet. Hack a comms tower.

| Check | Pass | Fail means |
|---|---|---|
| Buttons appear only for pools that have something | ☐ | the published counts are stale or wrong |
| **LOCATE AA** plots icons on ALiVE's AA, exactly | ☐ | pool or renderer problem |
| **LOCATE ARTILLERY** draws an offset circle | ☐ | as above |
| Hack again → the artillery circle **tightens** | ☐ | the ladder tier is not incrementing |
| Hack a third time at the same tier → **same circle, same place** | ☐ | the cached throw is being re-rolled — players can fish for a better centre |
| **LOCATE JAMMER** plots the props | ☐ | zone registry read |
| **TRACE NETWORK** appears only with an asymmetric commander | ☐ | the live-leader count gate |

---

## 6. The intel tally

Take an **Intel Drop Case** from the arsenal.

| Check | Pass | Fail means |
|---|---|---|
| Self-interact → **Deploy Intel Drop**; the case sits flat on the ground | ☐ | the surface trace failed |
| Kill an **insurgent** (asymmetric side) → body has **Search For Intel** | ☐ | the phone rule, or the side→controltype cache |
| Kill a **conventional** soldier carrying a radio → also searchable | ☐ | the radio test |
| Kill one with no radio → usually **not** searchable | ☐ | the documents roll is not gating |
| Search → you receive **Captured Intel**; counter does **not** move | ☐ | banking on pickup, which defeats the whole mechanic |
| Interact on the deployed case → **Deposit Intel**; RPT logs `N of M` | ☐ | the deposit path |
| Hit the threshold → a yellow hint circle appears on an installation or safe house | ☐ | empty hint pool — RPT says which |
| Deposit 20 at once with a threshold of 10 → **two** hints | ☐ | the batch loop pays out once |
| **Pack Up Intel Drop** → item returns to your inventory | ☐ | correspondingItem / pack path |

---

## 7. The reaction ladder

    #jmfsbreact

Set **Detect Chance** to 100 % temporarily so you are not testing dice.

| Check | Pass | Fail means |
|---|---|---|
| Fail a hack once → **nothing visible happens** | ☐ | SMALL is supposed to be silent; if you were told, the flag is leaking |
| `#jmfsbreact` now says **FLAGGED** | ☐ | the flag was not set |
| Fail again while flagged → shells, a drone, and enemies turn toward you | ☐ | MAJOR did not fire |
| The shells came from ALiVE's battery when one is in range | ☐ | the request path — check for `ARTY_REQUEST` in the RPT |
| With **no** artillery module, the fallback barrage lands instead | ☐ | fallback branch |
| Wait 5 minutes without incident → `#jmfsbreact` says **clean** | ☐ | the flag never decays |
| Transmit on a **long-range** radio in the open → eventually flagged | ☐ | radio watch not armed |
| Transmit on a **squad** radio → never flagged | ☐ | short-range is reaching the filter |
| Transmit with an **ACRE SATCOM antenna connected** → never flagged | ☐ | the SATCOM exemption |
| Let a drone see you → same ladder | ☐ | the drone-spot event has no listener |

---

## 8. QRF

    #jmfsbqrf

| Check | Pass | Fail means |
|---|---|---|
| The watch list holds ALiVE objectives and any `jmfsb_qrf*` marker | ☐ | gather |
| Clear an objective and stand on it → after the hold time it reports taken | ☐ | capture detection |
| **No countdown or warning appears** | ☐ | something is announcing it; QRF replaced Objective Watch on purpose |
| Artillery arrives, scaled to the objective's size | ☐ | wave 1 |
| An **asymmetric** objective gets mortars *or nothing*, never a full barrage | ☐ | the controltype branch |
| A drone comes | ☐ | wave 2 / ceiling |
| Squads appear **3-6 km out** and walk in — not on top of you | ☐ | origin ring or profiling |
| Retake the same objective inside the cooldown → no second QRF | ☐ | the cooldown |

---

## 9. The leader chain

    #jmfsbleaders

| Check | Pass | Fail means |
|---|---|---|
| Three leaders, each in a safe house, on the asymmetric side | ☐ | no asymmetric commander, or fewer than three houses — RPT says |
| They are the asymmetric faction's own men | ☐ | faction derivation |
| **TRACE NETWORK** circles a *house*, never a man | ☐ | product |
| Trace again → tighter circle | ☐ | ladder |
| Wait for a rotation → a leader moves; a trace now points at the **new** house | ☐ | the next-house pointer is set before the move |
| Enter a watched house → mortars | ☐ | trap arming |
| Kill a leader → RPT logs the pool cut, `#jmfsbleaders` shows `dead` | ☐ | Killed handler |
| **ACE-restrain one and carry him to `jmfsb_prison`** → logged `captured`, and another leader's position is revealed exactly | ☐ | the whole capture play |
| Kill all three → "That was the last of them", and **none respawn** | ☐ | finite is broken |
| Restart the mission with ALiVE persistence on → the dead stay dead | ☐ | save/getData |

---

## 10. Tacpad app layer — nothing sticks open

The suite's full-screen apps live over the map and redraw themselves by
reopening, which is where the stuck-window bugs live. These four races are the
ones the shell now closes by itself — each one was a real "the window will not
close" report. "Immediately" means within the same second, so the reopen the
first press queued is still in flight when the close lands.

| Check | Pass | Fail means |
|---|---|---|
| Open SQUAD, press a man, then CLOSE immediately — the window stays closed | ☐ | a queued reopen outlived the close; the stale-reopen guard missed a call site |
| Open TIMER, press +1 MIN, then CLOSE immediately — the timer does not come back | ☐ | same guard, the timer's reopen path |
| Open HACK, then open SETTINGS, wait several seconds — the hack screen does not tear itself down under settings | ☐ | appCurrent ownership broke |
| Hold the cursor on an open app while it is due to redraw — a slow press still lands | ☐ | the redraw hold (appIdle) regressed |
| The floating **FORCE CLOSE** strip sits over the open app and nothing covers it | ☐ | appBar is drawn under the app group |
| Press the floating FORCE CLOSE strip — the app closes and the strip disappears | ☐ | the bar's own close path |
| Open SUPPORT with tasking held by another tag — a blank screen is not the result; the strip is there and closes out | Withdrawn 2026-11-01: TAC//SUPPORT app removed | the gate refused before its dialog opened |
| Close the map with an app open, reopen it — no app, no strip, panels back | ☐ | appCurrent / appBar survived the map close |

---

## 11. IADS / EMCON — the net blinks, and Phase 0

**Run the probe before anything else in this section.** The addon was written
against a design whose four engine questions were never verified, and the probe
is those questions asked of a running game. Everything below is meaningless if
`setVehicleRadar` turns out to be missing or inverted.

Setup: a **JMSB - IADS / EMCON** module, and two or three enemy search radars
standing somewhere you can watch them (ALiVE placement, a `jmfsb_airdefence`
battery, or hand-placed in Eden). Turn **Debug Markers** on for this test only.

    #jmfsb iads.probe
    #jmfsb iads

| Check | Pass | Fail means |
|---|---|---|
| `setVehicleRadar: present`, `listRemoteTargets: present` | ☐ | P0-1 fails: the addon cannot switch anything and refuses to arm - the RPT says so |
| The probe names a radar and drives it, and forced ON and forced OFF look **different** on the dish or the RWR | ☐ | P0-1 is inverted: swap `IADS_RADAR_ON` and `IADS_RADAR_OFF` in `script_component.hpp` and nothing else |
| RPT: `listRemoteTargets element is a ...` once a hostile aircraft is up | ☐ | P0-2 unanswered - the datalink is empty, so nothing is being shared to read |
| While a set is forced OFF, does it still detect an aircraft close by? | ☐ | this IS P0-4, and either answer is a pass - write down which one you saw |
| `#jmfsb iads` lists radars per side with some lit and some dark | ☐ | the scan found nothing: sides are wrong, or nothing hostile carries a radar |
| Watch the markers for two minutes - sets flip at different moments, not together | ☐ | the jitter is not being re-rolled; every set is on one metronome |
| With Minimum Emitters 1, at least one marker is green at all times | ☐ | the duty-cycle floor is not holding - the whole side can go dark |
| Set Minimum Emitters to 0 and watch: the side does go fully dark sometimes | ☐ | the floor is being applied when it was switched off |
| An always-on class named in **Always-On Classes** never goes dark | ☐ | the pinned list is not matching - check the classname, case does not matter |
| Kill a radar: its marker disappears and `#jmfsb iads` counts one fewer | ☐ | the prune is not running, and dead hardware still counts towards the floor |
| With **Threat Board Debug** on (CBA, Common), fly a hostile aircraft past a lit radar: the RPT files a `contact ... (radar)` for the radar's side | ☐ | the reveal bridge is not filing, and the rest of the mod cannot see the air picture |

**P0-3 is not on this list because no script can answer it.** Park a radarless
launcher and a search radar on one side, fly a target in, and watch whether the
launcher *fires* on the shared track or only draws it. Only turn **Ambush Mode**
on after you have seen it fire.

---

## 12. Air Defence Sites — munitions and aircraft, layered

Setup: a **JMSB - Air Defence Site** module synced to a search radar, two
launchers and a gun or CIWS, all OPFOR; a player on OPFOR inside the protected
area, and something BLUFOR that can shoot into it (a mortar, a rocket
artillery piece, a jet).

    #jmfsb adsite.probe
    #jmfsb adsite

| Check | ☐ | If it fails |
|---|---|---|
| The probe says **A0-3 yes** (the server sees the round in flight) | ☐ | Sites cannot track munitions at all - the whole munition half rests on this |
| The probe says **A0-2 fired** and **A0-1 yes**, and the round is intercepted | ☐ | A0-2 no: `fnc_engage` falls back to forceWeaponFire - watch that it fires. A0-1 no: the fuse alone has to catch it; expect fewer kills |
| `#jmfsb adsite` lists the Site, its members with roles (LONG/SHORT/GUN/CIWS/SENSOR) and the radar | ☐ | `fnc_profile` read the vehicles wrong - their roles decide everything after |
| A mortar round fired AT the Site's area is engaged; one fired well clear of it is not | ☐ | `fnc_impact`'s prediction or the protected radius is wrong |
| A salvo is spread across the launchers, guns first on what is close, long-range held back | ☐ | `fnc_assign`'s layers |
| An OPFOR player gets **AIR DEFENCE ... radiating** once, and **INCOMING ...** once per salvo, not once per round | ☐ | `fnc_notice` |
| The tacpad shows the AIR DEFENCE panel for OPFOR only; STATUS, INTERCEPT and SETTINGS draw; the map shows the area and the tracks | ☐ | the board is not publishing, or the panel's condition is wrong |
| AUTOMATION OFF stops the Site; picking a track and pressing FIRE on a member engages it | ☐ | `fnc_order` "engage" |
| A BLUFOR player near the Site sees no panel; an OPFOR player outside the area with access "near" sees it read-only | ☐ | `fnc_canControl` |
| Two Sites with the same Link never put two weapons on one round beyond Shots Per Threat | ☐ | the shared coordinator in `fnc_tick` |
| Silent until cued: the radar stays dark until a track exists, then lights | ☐ | `fnc_emcon` and the iads `heldOff` lever |
| With Zeus Enhanced: right-click a member, the dialog opens and a change shows on the panel | ☐ | `fnc_zen` |

---

## What "pass" means

Not "the feature is good" — only **"the code ran and did roughly what it
claims"**. Tuning comes after something has run.

The chat reports are the cheap check; the RPT is the real one. Every system
logs what it decided and why it declined, so *not configured* and *not
working* look different.

---

## Play test 2026-10-20 — devices, tablet apps, every support module, game voice, EW, map tools

2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING. P6-P9 ordered on it: what the asset does still holds, ordered by a message to its box (P38, P42, P44); the steppers and verdicts only the app had are withdrawn.

Everything built 2026-10-18 .. 2026-10-20 (docs/new.md) that has never run in
game. One mission covers it:

**`%USERPROFILE%\Documents\Arma 3 - Other Profiles\YonV\missions\jmfs-missions\JMSB_Test.Tanoa`**

Updated the same day for what came after it was first written: TFAR removed
(voice is Arma 3's own VON through `jmfsb_voice` / `jmfsb_adapter_von`; the
MPU5 is a plain radio item), the device keys moved to the numpad, the in-house
map tools (`jmfsb_maptools`), the EW addon and TAC//EW, the rebuilt RADIO /
DRONES / HACK boards, air verdicts and rings, and ropes for FASTROPE.

**How it is built.** Two halves, chosen so the parts Eden is good at stay in
Eden:

- `mission.sqm`, hand-written in Eden's text format (version 54, checked with
  `hemtt utils config inspect`): the player's group (you + three playable AI
  slots: medic, ISR rifleman, autorifleman), a second playable group **HQ**
  (`jmsbt_hq`, one rifleman, "HQ RTO" in his role description - the slot for
  the second player in the voice steps), every support module with its
  attributes, the two synced aircraft (RAVEN's Ghost Hawk, VIPER's AH-99)
  with their sync links, and `respawn_west`. Everything stands on the
  Tuvanaka airbase apron (13.45 m ASL, read off objects Task_Force_Roomba_cdev
  places there). Open it in Eden to move anything; Eden rewrites the file
  properly.
- `initServer.sqf` → `fn\fn_buildServer.sqf` builds what needs free ground found
  at run time: the Marshall (vehicle tablet; an **EW Jammer Module** in its
  cargo for the vehicle jammer - the only jammer: no man packs), the sling-load cargo net, the retired
  Artillery Battery **with** two synced Scorchers (FOX: module made by
  `createUnit` in a `sideLogic` group, plain attribute names set, then
  `[logic, guns, true] call jmfsb_support_fires_fnc_moduleArtillery` in one
  unscheduled block - the module's own `in GVAR(entities)` guard makes any
  later framework call a no-op), the targets and their map markers, a **HACK
  tower** (`Land_Communication_F`, a hackable class) beside the "600 m short of
  T2" point, and the **enemy EW targets** (`fn\fn_ewTargets.sqf`, through the
  mods' public calls): an RF net `JMSBT ENEMY` (VHF, OPFOR's key) with an RF
  node on T2's crewed MRAP (transmitting; DF-able, and listed by HACK within
  800 m), and an EW external emitter on T3's APC (VHF + UHF, intent jam: a JAM
  track and a JAMMER warning; it puts no noise into anybody's links).
  `fn\fn_aiRadios.sqf` puts an MPU5 on every playable slot still held by AI
  (no man packs, the HQ RTO included). AI sets relay
  nothing: `jmfsb_rf_aiNodes` is off and the voice addon makes nodes for
  players' sets only.
- `initPlayerLocal.sqf` gives the kit (phone in the GPS slot, both side
  devices in the pack, the **UAV operator trait** (no UAV terminal - removed 2026-10-20), a `jmfsb_nvg_*` goggle with
  ECOTI, the **MPU5** (`jmfsb_mpu5`) in the radio slot, the **EW Receiver**
  (`jmfsb_ew_receiver`) in the uniform or vest, smoke / IR / chemlight /
  flare, laser designator, ACE medic kit, Medic trait, `isJFO`; the HQ RTO
  slot wears the kitbag too - no man packs) and the **[TEST]**
  scroll actions, again after a respawn. The **EW Jammer Pack**
  (`jmfsb_ew_jammerPack`) is a [TEST] backpack swap: the kitbag carries the
  side devices and the medic kit, so it is kept and put back by the same
  action.
- `cba_settings.sqf` (mission, not forced): `jmfsb_support_tag = "JFO"`,
  `jmfsb_adminpanel_everyoneAdmin = true`. `description.ext`: respawn at base,
  debug console for host and admins, TAC//PAC with `sync = "off"` (no PAC net
  plan: the voice addon's default plan, a TEAM net per group plus C2 and A2G),
  `maxPlayers = 5`, and `disableChannels[]` turning Side and Command **voice**
  off (chat stays) - the same thing `jmfsb_adapter_von` sets on every client
  every second, so the mission does not fight it; Global, Group, Vehicle,
  Direct and the custom channels are left to the adapter. VON on / codec /
  quality are server settings, not mission ones: a hosted game uses the
  defaults (VON on); a dedicated server needs `disableVoN = 0` in server.cfg.
  (`hemtt utils config inspect` cannot parse the `true` / `false` words in
  `disableChannels[]`; the engine's documented form is kept.)

**There is no "JMSB - Core" module** in the repo: the D59 comments name
`player_side` on it, but no class exists. The players' side comes from the
playable slots (`jmfsb_common_fnc_playerSides`), so the mission places none.

**Assets on the board** (13 rows expected):

| Tab | Callsign | Module | Set-up |
|---|---|---|---|
| ARTILLERY | THUNDER | Virtual Artillery | 4 guns, 96 HE / 24 smoke / 12 illum, range **1.5-8 km**, response 5-15 s, cooldown 30 s |
| ARTILLERY | STEEL | Artillery Battery (retired), **no guns** | `Sh_155mm_AMOS:10, Smoke_120mm_AMOS_White:4` x 4 default guns; 30 m from THUNDER |
| ARTILLERY | FOX | Artillery Battery (retired), **2 Scorchers synced** | ammunition blank, so rounds from the guns' magazines |
| CRUISE MISSILES | TRIDENT | Cruise Missiles | 6 missiles, salvo 2, cooldown 60 s |
| LOITERING MUNITIONS | GHOST | Loitering Munitions | 6, launch 2, loiter 300 s |
| CAS | HOG | CAS, class A-164 | ingress 6 km, friendly range 150 m, cooldown **at the request**, respawn 60 s |
| CAS | VIPER | CAS, **synced AH-99** on its stand | cooldown **at the end of the sortie**, respawn 60 s |
| CAS | HAWK | CAS Drone | Greyhawk, 3 airframes |
| TRANSPORT | RAVEN | Transport, **synced Ghost Hawk** | every task allowed, cooldown at end, respawn 60 s |
| TRANSPORT | BISON | Transport, class Huron | 2 airframes, cooldown at the request |
| LOGISTICS | MULE | Logistics Drop, parachute | default aircraft, blue smoke |
| LOGISTICS | PORTER | Logistics Drop, sling | Huron (unarmed), IR strobe |
| QRF | REACH | QRF Insertion | Huron, static line + air assault, 2 squads |

**Targets** (map markers `T1`..`T6`, OPFOR, hold fire, rooted; distance from THUNDER):

| | Where | What | Expected verdicts |
|---|---|---|---|
| T1 | 0.5 km | empty LSV, no crew | TOO CLOSE for THUNDER (1.5 km) and cruise (1 km); STEEL / FOX expected TOO CLOSE on the high-angle minimum (~0.8 km, the dump has the exact line); never picked by GHOST / CAS |
| T2 | 2.3 km | crewed MRAP + 4 infantry; **enemy net RF node on the MRAP** | in range for all; the CAS, drone and loitering target |
| T3 | 4.0 km | crewed APC + 4 infantry; **enemy jammer emitter on the APC** | in range for all |
| T4 | 7.2 km | crewed truck | in THUNDER's band, near its edge |
| T5 | 9.0 km | crewed truck | OUT OF RANGE for THUNDER (8 km); accepted by STEEL / FOX (no maximum set: the 155 mm's own reach) |
| T6 | 11.6 km | crewed truck | OUT for THUNDER; STEEL / FOX accept |

Destroying T2's MRAP or T3's APC (the fires and CAS steps) removes that
emitter for good: run the EW (P15) and HACK (P16.3) steps first, or restart
the mission before them.

**[TEST] actions** (every player has them):

| Group | Actions |
|---|---|
| State | dump state + verdicts to the RPT (ends with the voice dump) |
| Voice | self test (VON T1-T5, 15 s); dump voice state; unconscious for 20 s; teleport under water (3 m down, sea near base) |
| Mesh range | teleport mesh 1 - LZ ROOMBA (~2.8 km), mesh 2 - near T3 (~4 km), mesh 3 - near T5 (~9 km). Every teleport searches for dry land near its point (Tanoa is islands) and logs where it put you and how far that is from base |
| EW | get in the jammer vehicle (driver); enemy emitters at T2 / T3 on / off; teleport DF baseline (1 km off the base-T2 line); ISR flag on / off |
| Drones / hack | put up a UAV (a Greyhawk loitering 1.2 km out toward T2 at 500 m, weapons hold - only when no west UAV is up); UAV operator trait on / off; teleport to the HACK tower |
| Medic | wound a squadmate (light / heavy) |
| Support | destroy RAVEN's / VIPER's / HOG's aircraft; put 2 ACE fast-ropes in RAVEN (fallback - support_air stocks them itself now); teleport base / LZ ROOMBA / 600 m short of T2 |

**Run it:** Eden > Open > `jmfs-missions\JMSB_Test`, then Play > **Play in
Multiplayer** (you host, so you are the server and an admin). Your usual mod
set with CBA and ACE - **no TFAR** (it is removed; do not load it), voice is the
game's own VON. Addon Options > Tacpad > **Display mode = Tablet**. Controls >
Multiplayer: **Push To Talk** must have a key (the adapter warns at start when
it has none); Options > Audio: VON volume well above zero.

**Two players.** Steps marked **[2P]** need a second human on **another PC**
(one PC has one microphone): he joins your hosted game (LAN or direct
connect) and takes **`jmsbt_hq`** (HQ RTO: his own group, the RTO
tag - for C2, FLASH and "not on my TEAM net") or **`jmsbt_medic`** (your group:
the TEAM net). He gets the same kit and [TEST] actions. Steps marked **[3P]**
need a third; mark them N/A when you have only two. Without a second player
do every unmarked step and the single-player half of P12.1.

**Paste back** for every failed step: the step number, a screenshot, and the
newest RPT from **`%LOCALAPPDATA%\Arma 3\*.rpt`** - all `[JMSB_TEST]` lines plus
any `Error` / `jmfsb_` / `[JMFSB]` lines around the time of the step. In a
two-player step paste **both** players' RPTs (his is in the same folder on
his PC). **[DIAG]** marks the steps where the mission's own RPT output answers
the question. The voice addons log through CBA as `[JMFSB] (voice) INFO: ...`
and `[JMFSB] (adapter_von) INFO: ...`.

**Device keys are the numpad** (CBA keybinds, JMSB category, Configure
Addons): **Ctrl +** 1-4 the device's F1-F4 (2026-10-21), plain 1-4 SELECT NET
1-4 (the number on each net chip; Select net 5-9 start unbound), 0 / . its
left / right arrows, 5 the tablet, 6 the RADIO app, 7 / 8 the RADIO app's
tabs, 9 Troops In Contact. Toggle Device keeps Ctrl+End. The keyboard's own
F1-F4 and arrow keys are no longer taken by any device. Where this checklist
says "F1" on a device it means the device's F1, i.e. **Ctrl + numpad 1**.

### P0. Boot

| # | Do | Should happen | P/F |
|---|---|---|---|
| P0.1 | Start the mission, wait 20 s | No script-error popups. RPT: `[JMSB_TEST] server build done`, then five `STAND ... - OK` lines (RAVEN, VIPER, vehicle, crate, HACK tower). `hack tower: ... water false`; `EW targets ON: enemy net node 'jmsbt_enemy_t2' on ...; enemy jammer 'jmsbt_enemy_jam_t3' on ...`; `aiRadios:` one line per AI slot with `radio jmfsb_mpu5` (HQ: `backpack jmfsb_mpu5_lr`). **[DIAG]** A `CHECK IT` stand line means that object came in damaged, buried or floating - move it in Eden and save | ☐ |
| P0.2 | Wait for the start dump (15 s) | **[DIAG]** `board: 13 rows`, one per table row above; `addons absent: none` (or only what you do not load, e.g. `switchblade`); `loadout: ... radio jmfsb_mpu5, ... EW receiver true` with no `MISSING`; `tasking gate: [true,""]`; `TAC//MEDIC isMedic: true`; `ropes: RAVEN ... carries 2 x ACE_rope36`; `EW kit: receiver true, jammer host <NULL-object>`; `EW test emitters on: true` | ☐ |
| P0.3 | Read the `---- verdicts` block | **[DIAG]** THUNDER: T1 `TOO CLOSE`, T2-T4 `true, ETA ...`, T5 / T6 `OUT OF RANGE - ... MAX 8 KM`. STEEL / FOX: T1 TOO CLOSE (high-angle minimum), T2-T6 true. TRIDENT: T1 TOO CLOSE. Air rows (they have a preview hook since 2026-10-20): HOG / VIPER `SAD=[true,"ETA ... - ON STATION ... - n SORTIES LEFT"]`; HAWK `SAD=[true,"ETA ... - n AIRFRAMES LEFT"]`, `LOITER=[true,"ON STATION IN ..."]`; RAVEN / BISON `LAND=[true,"ETA ... TO LZ"]`, `HELOCAST=[false,...]` (T2 is land), `LIFT=[false,...]` (no LZ given); MULE / PORTER `DROP=[true,"ETA ... - ..."]`; REACH `STATIC=[true,"ETA ... - n SQUADS LEFT"]`. **No row says `NONE (no preview hook)`** | ☐ |
| P0.4 | Map (M) | Markers T1-T6 with their distances, THUNDER / STEEL / FOX / TRIDENT / GHOST dots, LZ ROOMBA, the red HACK tower triangle. In tablet mode the vanilla map has **no** suite panels | ☐ |
| P0.5 | Read the voice dump at the end of the start dump | **[DIAG]** `voice active true` (false = the voice layer stood down because TFAR or ACRE is loaded - unload it); `adapter von`; `sets carried: [["sr","jmfsb_mpu5","handheld"]]`; `block level [0,""]`; `netState`: a TEAM net (`TEAM WEST <your group's callsign>`, kind team), `C2`, `A2G`, `DIRECT` - no VEH on foot, no CALL; `channelEnabled ... 1 Side [true,false], 2 Command [true,false]`, `0 Global [..,true]` (you host); the custom channel map holds C2 and A2G with ids above 0 | ☐ |
| P0.6 | Look at the top right in the first seconds | No VOICE note about Push To Talk or the VON volume - if one shows, fix the binding / the audio slider and restart | ☐ |

### P1. Device frames and the tablet's keys

| # | Do | Should happen | P/F |
|---|---|---|---|
| P1.1 | **Numpad 5** (or ACE self > Tablet) | Tablet frame, the map fills the screen hole **to the olive frame edge**: square corners, no dark band, no rounded bezel over the map | ☐ |
| P1.2 | Look at the screen rows | Device bar (TAC//APP, time, GRID, callsign . group, TABLET, MENU, PAC, ESC CLOSES), notification line, live tiles, map area with the squad rail and the TOOLS / SETTINGS / ADMIN / HIDE strip, net row at the foot (one cell per voice net you are on, never a frequency) | ☐ |
| P1.3 | Click each of the six keys printed on the frame | F1 TAC//MSG, F2 Squad, F3 Radio, F4 Settings (defaults); the same key again closes the app. LEFT / RIGHT **step the active voice net** (the filled cell in the net row moves, a net-switch click) - they no longer step round the apps | ☐ |
| P1.4 | Ctrl + numpad 1-4, then plain numpad 1-3, then numpad 0 / . with the tablet up and no text box focused | Ctrl + numpad 1-4 press the frame's F1-F4 (same apps as P1.3); plain numpad 1-3 make net chips 1-3 active (each chip reads `<N> <NAME>`); numpad 0 / . step the active net. The keyboard's F1-F4 and arrow keys do nothing on the tablet (they are the game's again) | ☐ |
| P1.5 | Addon Options > Devices > Tablet fill 0.6 | The tablet closes and reopens smaller; the frame stays square, not stretched. Put it back to 1 | ☐ |
| P1.6 | [TEST] UAV operator trait on, reopen the tablet | The gripped UAV tablet frame; same screens. Trait off again | ☐ |
| P1.7 | ESC | The open app closes first, then the tablet; nothing stays stuck on screen | ☐ |
| P1.8 | Numpad 5 with the tablet up | It closes (Open Tablet toggles) | ☐ |

### P2. Walking view - phone and side devices

| # | Do | Should happen | P/F |
|---|---|---|---|
| P2.1 | Close the tablet | Phone frame bottom centre. Its map is **centred on you**: your man icon in the accent colour, turned to your heading, mid-screen; walk 100 m and it stays centred | ☐ |
| P2.2 | Read the phone | No status row and no notification line (2026-10-21): the **status row** on top (`NET 80%  MESH 1H  JAM 0%  GPS 0412 1163  DRONES 0  MSG 0`, two rows of three on a side device), the map under it, all inside a thin rim clear of the corner bumpers. NET is the custom channels still free and goes down while a call is live; GPS is your 8-figure grid (Device grid digits: 10 figures, and phone and tablet both show 10). Key push-to-talk on TEAM: that net chip turns red with **TX** in front until you release (tablet row too). Squad list `<n> <NAME>` for the four of you; 25 / 50 m rings; one net cell per voice net you are on reading `<N> <NAME>`, the active one filled, an ear tag (L / B / R) on each, the outline green when the net is good | ☐ |
| P2.2a | Net state colours: walk away from your squad until TEAM weakens, then out of reach; mute a net (Ctrl + numpad 3); EW barrage on its band (P15.8) | TEAM's outline goes green -> amber (weak or jammed) -> red (no route); a muted net's outline and name dim. The tablet's net row shows the same colours, and a muted chip there also has a red diagonal line through it (P28.20) | ☐ |
| P2.2b | GPS: P15.17's GPS denial, then a spoofer (P15.12) | The GPS cell reads **NO FIX** in red while denied; amber with an anti-spoof set; a spoofed set shows the spoofed grid in plain text | ☐ |
| P2.2c | A call rings (P12.20) on the phone | A dark call strip appears along the map's bottom (`CALL from ... - F1 accept - F4 decline`) and goes when the call business ends | ☐ |
| P2.2d | Switch to C2 with the game's channel keys; respawn (or restart the mission); then pick another role in the group menu | Each time you come back on your squad's TEAM net (chip 1 filled), not the last channel you used | ☐ |
| P2.2f | A slot with the UAV skill in PAC (not the test mission's hand-set trait): DRONES > CONNECT, TAKE CONTROL | Connects and flies - the skill now sets the engine's UAVHacker trait. Take the skill away (PAC admin): control is refused again | ☐ |
| P2.2g | Game voice: key push-to-talk on TEAM, then C2, then (as TL / ATL / HHC) GLOBAL, then the Direct key | Bottom left: no vanilla microphone square; a dark chip with a red dot reads `TX GHOST 1`, `TX C2`, `TX GLOBAL`, `TX DIRECT` while the key is held. Under TFAR / ACRE the vanilla microphone is back | ☐ |
| P2.2h | Tablet up, press **ADMIN**; then TIME / WEATHER and ADMIN MESSAGE from the console; CLOSE each; then ESC | The console opens inside the tablet's screen with the tablet frame, bar, tiles and net row still showing round it; PLAYER VIEW keeps its shape (not squashed). TIME / WEATHER and the message box open over the console, CLOSE returns to it; ESC closes the console back to the tablet | ☐ |
| P2.2e | As a TL, ATL or HHC slot (on C2 in the comm plan): tablet net row, press **GLOBAL**; talk; press it again. Then as a rifleman | TL/ATL/HHC: the cell turns red **ON GLOBAL**, the game's channel is Global and **[2P]** everyone hears you with no mesh static; second press puts you back on your active net. Rifleman: no GLOBAL cell. Respawning while on Global switches it off | ☐ |
| P2.3 | Ctrl+End twice (Toggle Device - still its default; it has no numpad key) | Hides, shows. Close and restart the mission: the hidden / shown choice is remembered | ☐ |
| P2.4 | Inventory: drag `[JMSB] Side Device` into the GPS slot | Side device against the screen edge, vertically centred; status 2 x 4, squad list 2 columns, net cells in two columns. Then `Side Device 2` the same. Phone back in the slot | ☐ |
| P2.5 | Open the map, then the inventory | The walking view goes while either is up and comes back after | ☐ |
| P2.6 | ACE self-interaction menu | **No** Phone or Side device entries (the small devices have no ACE menu; everything about them is on the tablet, SETTINGS > DEVICES). Tablet is there in tablet mode; Vehicle tablet only in a vehicle | ☐ |
| P2.7 | Walking view up, no call. Ctrl + numpad 2, 3; numpad 0, . ; then Ctrl + numpad 1 and 4 | Defaults (Configure Addons > JMSB, "Device button F1" .. "right"; Addon Options > Devices): **Ctrl+2** (F2) steps the active net's ear L / B / R - the tag on its cell changes; **Ctrl+3** (F3) mutes the active net - its name dims, press again to unmute; **0 / .** step the active net left / right with a click; **Ctrl+1** (accept) and **Ctrl+4** (decline / hang up) have nothing to act on and fall through to the game. With the walking view hidden none of them does anything | ☐ |
| P2.8 | [TEST] Wound a squadmate (light) | His row on the phone gets `+` | ☐ |
| P2.9 | Numpad 6 on the phone | The phone's RADIO app fills the phone screen over its map (you keep walking): tabs NETS / CALLS / MANAGE, header, rows, a cursor, soft keys along the bottom (NETS: MUTE / EAR / SET ACTIVE / BACK). Numpad 7 / 8 change tab; 0 / . move the cursor; 1-4 are the soft keys; numpad 6 again (or F4 BACK) closes it | ☐ |
| P2.10 | The same on a side device | Rows stacked on two lines, soft keys in a 2 x 2 grid; same keys. MANAGE: shown to leaders / RTOs / admins (you lead your group), its ADD / REMOVE / REKEY blank (not built) | ☐ |

### P3. Tablet SETTINGS > DEVICES and DEVICE KEYS

| # | Do | Should happen | P/F |
|---|---|---|---|
| P3.1 | Tablet > SETTINGS | Sections DEVICES and DEVICE KEYS beside the shell's own | ☐ |
| P3.2 | DEVICES | Worn device line (PHONE / SIDE), walking view shown, side edge, phone size, side size, map zoom, opacity, member voice rings - each changes the walking view at once | ☐ |
| P3.3 | DEVICE KEYS: set the tablet's F1 to Weather, press Ctrl + numpad 1 (and the frame's F1) | Weather opens. The six walking-view buttons are listed and settable here too, with the voice actions (accept call, ear / quick add, mute, decline / hang up, net left / right) and the RADIO app among the choices. Set F1 back | ☐ |
| P3.4 | Any row whose setting a server / mission forces | Drawn LOCKED, cannot be stepped (none of the device settings is forced by this mission - only if your server forces one) | ☐ |

### P4. Apps inside the tablet

| # | Do | Should happen | P/F |
|---|---|---|---|
| P4.1 | Ctrl + numpad 1 (TAC//MSG) | The reader opens **inside** the tablet's map area on solid ground - rail, list, filter box, thread view, net view; no separate full-screen window | ☐ |
| P4.2 | COMPOSE, write to your squad, SEND | Compose pane, template and recipient pickers, report card, CC drop, marker pin dropdown all open inside the tablet. The message appears in the list and on the notification line | ☐ |
| P4.3 | Type in a text box: letters, then numpad digits 0-9 and numpad . , then the keyboard arrows, then Enter | The numpad digits and . go **into the box** (they do not change nets, open the tablet or press F-keys while a text box has focus); the arrows move the cursor; Enter in a one-line box does not close the tablet; in a multi-line box it makes a new line | ☐ |
| P4.4 | Reader CLOSE; then click the notification line | CLOSE shuts the reader, tablet stays. The notify click closes any app and shows the reader on LOG | ☐ |
| P4.5 | Strip > ADMIN | The admin console opens **sized to the tablet's map area**, not full screen; TIME / WEATHER and the message box likewise. The tablet stays up | ☐ |
| P4.6 | Console > TAC//PAC | Console closes, TAC//PAC opens **inside** the tablet a frame later (PAC is empty: `sync = "off"`). Its CLOSE lands on the tablet, not the console. Numpad keys typed in a PAC text field stay in the field | ☐ |
| P4.7 | PAC on the tablet bar (the PAC tile on the map in Native mode) | Opens as a tablet app, closes cleanly | ☐ |
| P4.8 | Addon Options > Display mode = Native | The tablet closes; the map (M) carries the suite as before; ADMIN / SUPPORT / MSG open as their native dialogs (SUPPORT withdrawn 2026-11-01: TAC//SUPPORT app removed). Back to Tablet | ☐ |
| P4.9 | **[2P]** Open a thread he wrote in (TAC//MSG); press **CALL** in the action row under QUICK REPLY (next to + MARKER) | His phone rings; accept and you are on a CALL net together, as with the roster's CALL. A thread where nobody else is in game: CALL is dim and does nothing. Without game voice (TFAR / ACRE loaded) there is no CALL button | ☐ |

### P5. TAC//SUPPORT inside the tablet

Withdrawn 2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P5.1 | Open SUPPORT | Drawn inside the tablet; one tab per type: ARTILLERY, CRUISE MISSILES, LOITERING MUNITIONS, CAS, TRANSPORT, LOGISTICS, QRF. Map hole panned so you sit mid-hole | ☐ |
| P5.2 | Click in the map hole | Sets the point (does **not** close the app). Close and reopen SUPPORT: the last tab you pressed is the one open | ☐ |
| P5.3 | ARTILLERY > THUNDER, press CONFIRM before picking a task | READY checklist: UNIT / TASK / point squares, missing ones accent-outlined; CONFIRM stays non-accent and the early press names the first missing line | ☐ |
| P5.4 | THUNDER, FIRE MISSION | Range rings MIN 1.5 km and MAX 8 km round THUNDER on the map | ☐ |
| P5.5 | Point on T5, then T1, then T3 | VERDICT `OUT OF RANGE - 9 KM, MAX 8 KM` and CONFIRM held; `TOO CLOSE`; `ETA ... - 4 GUNS x n HE`. **[DIAG]** Same lines as P0.3. Air rows have their own VERDICT lines and map shapes now - P17 | ☐ |
| P5.6 | TRIDENT and GHOST rows | TRIDENT: 1 km minimum ring + reach ring; GHOST: reach ring | ☐ |
| P5.7 | ISR flag **off** (dump: `isISR false`). Debug console (local exec): `jmfsb_support_tag = "ISR"`, reopen SUPPORT | Refused - "Tasking is held by ISR" - **not** a blank screen; the FORCE CLOSE strip is there and closes it. RPT `canTask: gate refused`. Then `jmfsb_support_tag = "JFO"` (the ISR slot is the playable `jmsbt_isr`, so the tag names somebody) | ☐ |
| P5.8 | Close the tablet with SUPPORT open; reopen | No stale SUPPORT screen, panels back | ☐ |
| P5.9 | Display mode Native, map, SUPPORT | The same tabs and form in the native dialog, its map laid into the hole under the tab row | ☐ |

### P6. Fires

| # | Do | Should happen | P/F |
|---|---|---|---|
| P6.1 | THUNDER, HE, ROUNDS 2, CONVERGED, T3, CONFIRM | Accepted; target marked on the map while it runs; SHOT / SPLASH on the notify rail; rounds come down on T3 (no gun anywhere fires); round count drops; "rearmed, ready for tasking" after the cooldown; mark removed. (This kills T3's APC and its jammer emitter: do P15 first) | ☐ |
| P6.2 | Repeat with SHEAF TYPE PARALLEL, BOX, CREEPING; INTERVAL; DELAY 30 s; REPEAT 1 | Impact pattern changes per sheaf; DELAY pushes the first round back; REPEAT fires a second volley a cooldown apart | ☐ |
| P6.3 | COORDINATE = WITH NEARBY on T3 | Verdict says `+ NEARBY`; STEEL and FOX fire too (same shell, within 1 km). RTB (CHECK FIRE, double confirm) stops all three | ☐ |
| P6.4 | THUNDER smoke and illumination on T2 | Smoke screen / flares over T2 | ☐ |
| P6.5 | STEEL (retired, no guns) | Row listed, 4 GUNS, 40 HE + 16 smoke, fires virtually from its module. **[DIAG]** dump: `jmfsb_moduleFiresArtillery 'STEEL' ... synced []` | ☐ |
| P6.6 | FOX (retired, 2 Scorchers synced) | 2 GUNS, rounds from the Scorchers' magazines, battery at their centre; the Scorchers never turn, load or fire and are never crewed. **[DIAG]** `FOX: 2 x ... synced` and its magazines | ☐ |
| P6.7 | STEEL on T5 | Accepted (no maximum set on the retired module) - while THUNDER refuses T5 | ☐ |
| P6.8 | SITREP on an artillery row | Answers (was hidden for type arty before) | ☐ |
| P6.9 | TRIDENT STRIKE on T4, MISSILES 2 | TIME TO TARGET verdict; missiles launch at the module, terrain-follow, pop up and dive; SPLASH call; T1 refused (inside 1 km) | ☐ |
| P6.10 | GHOST HUNT on T2 | Munitions fly out, orbit, pick a crewed vehicle or infantry at T2 and dive; the empty LSV at T1 is never picked; out of loiter time = self-destruct. (Kills T2's MRAP and the enemy net node: do P15 / P16.3 first) | ☐ |

### P7. CAS

| # | Do | Should happen | P/F |
|---|---|---|---|
| P7.1 | HOG, SAD on T2 with an INGRESS and an EGRESS point | Jet appears ~6 km out on the ingress bearing, orbits no tighter than 1 km at normal speed and **does not crash after ~90 s** (the 2026-10-20 fix), strikes, leaves on the egress bearing and is deleted there. Row goes to cooldown **at the request** | ☐ |
| P7.2 | [TEST] Teleport 600 m short of T2, lase T2, HOG ATTACK RUN, PASSES 2 | Release on the laser; ORDNANCE stepper works on SAD too | ☐ |
| P7.3 | HOG point within 150 m of yourself | DANGER CLOSE ring on the map; the release is held and said once | ☐ |
| P7.4 | LOITER, then a new SAD while on station | Weapons tight orbit; the new task moves the orbit; one-minute warning before time on station ends | ☐ |
| P7.5 | VIPER (synced AH-99) SAD on T2 | Takes off from its stand (crewed at launch - it stands empty), flies to the ingress point first, strikes, lands back on its stand repaired / refuelled / re-armed; cooldown starts **at the end** | ☐ |
| P7.6 | HAWK (CAS drone) on T2 | Strikes; at the end flies off the map before it is deleted (not a few km past the target) | ☐ |
| P7.7 | [TEST] Destroy VIPER's helicopter (idle on its stand) | Row reads lost; 60 s later a new AH-99 stands on the stand. Destroy HOG's jet mid-sortie: REPLACING until 60 s | ☐ |

### P8. Transport

| # | Do | Should happen | P/F |
|---|---|---|---|
| P8.1 | RAVEN, PICKUP > LZ, no pickup point, LZ on LZ ROOMBA | Lands on you engine running, PASSENGERS lists the cabin; once your group is in it flies to the LZ and puts you out; plan markers (PICKUP, LZ) joined by a line from the airframe | ☐ |
| P8.2 | Same with two VIA clicks and an APPROACH bearing | Flies via both legs, lands on the given bearing | ☐ |
| P8.3 | LZ SIGNAL on; throw blue smoke near the LZ | Lands on the smoke (IR strobe / flare at night) | ☐ |
| P8.4 | LOITER, then HOVER | Orbits at the radius; holds a hover | ☐ |
| P8.5 | FASTROPE on a rope point, you aboard | Hovers with ACE ropes out until the cabin is empty or the wait is up. The ropes are **stocked by support_air now** (2 x `ACE_rope36` at module read, on a replacement, at launch, when a FASTROPE task arrives) although `ace_fastroping_requireRopeItems` stays forced on. **[DIAG]** dump `ropes: RAVEN ... carries 2 x ACE_rope36`. Players in the cabin: P18 | ☐ |
| P8.6 | HELOCAST on open sea north of the airbase | Comes down to the water, drifts while the cabin goes out, climbs back to a hover. Over land the VERDICT refuses it first | ☐ |
| P8.7 | PARADROP, JUMP HEIGHT 250 | Crosses the drop zone, the whole cabin goes out on static lines (you on your own machine), returns to base | ☐ |
| P8.8 | SLINGLOAD: LOAD point on the cargo net beside RAVEN's stand, SET DOWN 300 m away | Hooks the net, carries it, lowers it at SET DOWN | ☐ |
| P8.9 | BISON (class Huron), LAND near you | Appears at its module already flying; RTB: removed once no player is aboard; cooldown **at the request** | ☐ |
| P8.10 | RTB on an idle transport | Refused: "at base - nothing to recall" | ☐ |
| P8.11 | [TEST] Destroy RAVEN's helicopter on its stand | Rebuilt on its stand after 60 s. **[DIAG]** a dump after it: the new airframe carries 2 ropes again | ☐ |

### P9. Logistics and QRF

| # | Do | Should happen | P/F |
|---|---|---|---|
| P9.1 | MULE SUPPLY DROP near the base | Aircraft from MULE's module, crate out under a chute over the point, blue smoke on landing. With `sync = "off"` there are no PAC arsenal lists, so the crate carries `B_supplyCrate_F`'s own contents (RPT says so) | ☐ |
| P9.2 | MULE again, CRATE SIGNAL stepper to IR / chemlight / flare / none | The landed crate shows what was picked | ☐ |
| P9.3 | PORTER SUPPLY DROP | Huron brings a crate on the hook and sets it down on the point; IR strobe | ☐ |
| P9.4 | REACH STATIC LINE on a field near T2 | Huron low slow pass, the squad's chutes open, squad defends the point | ☐ |
| P9.5 | REACH AIR ASSAULT | Lands (or fast-ropes) the squad and leaves; a third request after two squads is refused / EXPENDED | ☐ |

### P10. ECOTI, BFT rings, TAC//MEDIC

| # | Do | Should happen | P/F |
|---|---|---|---|
| P10.1 | Goggles on, N to NVG mode | ECOTI boxes on the squad and the AiTR compass across the top | ☐ |
| P10.2 | Open the map, the tablet, the inventory | Boxes and compass **gone** while each is up (not frozen on screen), back when closed | ☐ |
| P10.3 | Push-to-talk on TEAM, then on DIRECT; watch the tablet / phone map. **[2P]** the second player does the same while you watch | Your member icon gets the voice ring while you talk: red on a radio net, magenta on DIRECT (VOX); his icon the same for him (and his squad-list row TX / VOX). SETTINGS > DEVICES member voice rings off: no rings. **[DIAG]** no `Type Object` errors from drawMembers / overlaySquad in the RPT | ☐ |
| P10.4 | [TEST] Wound a squadmate (heavy bleed) | MEDIC tile counts him and turns to the alert block | ☐ |
| P10.5 | Open TAC//MEDIC | Squad worst first; patient page with vitals as "last hand check" (none yet) or live only under an ACM monitor; without ACM the ACM-only lines say ACM NOT LOADED; SHOW ON MAP works. ACE Check Pulse on him: the line shows the check, its age and you. Be quick - the AI medic treats him | ☐ |
| P10.6 | TAC//MEDIC list with one man OK, one wounded, one unconscious (user, 2026-11-01; built, not seen in game) | Each row's state colour is a full-height block on its left edge, about 16 px wide (was a 4 px bar): green, yellow, accent; the names and the column headers start clear of it, still lined up | ☐ |
| P10.7 | On the tablet (Display mode Tablet), open his page, SHOW ON MAP (BFT member markers: Own squad) | The app closes, the tablet's map pans to him, and the squad's member icons (circle, number, name) are on it round him - you included when map content is off. Press SHOW ON MAP again: no doubled icons. Member markers Off: the map only pans | ☐ |
| P10.8 | Same on the vanilla map (Display mode Native) | Member icons as before, not doubled | ☐ |

### P11. Vehicle tablet and VEHICLE STATUS

| # | Do | Should happen | P/F |
|---|---|---|---|
| P11.1 | Get in the Marshall beside the stands (driver or commander); ACE self > Vehicle tablet | Vehicle frame; bar reads VEHICLE . <name>; ON BOARD (name, CMDR / DRV / GNR / PAX, n / seats) instead of the squad rail; the net row now has a **VEH** cell | ☐ |
| P11.2 | Open VEHICLE STATUS | Three columns: DAMAGE + FUEL (range MEASURING until you have driven), AMMUNITION + COUNTERMEASURES, APS + RF SET + CREW (the voice nets aboard, no rack); the VEHICLE tile | ☐ |
| P11.3 | Drive 1 km; shoot a wheel | Range figure appears; WHEELS group worsens | ☐ |
| P11.4 | Get out | The vehicle tablet closes; the large tablet has no VEHICLE STATUS app; the VEH net cell is gone | ☐ |

### P12. Game voice (VON)

Voice is Arma 3's VON through `jmfsb_voice` (nets, calls, sounds) and
`jmfsb_adapter_von` (the VON commands). RF decides who hears whom: every
second each listener's client sets each speaker's VON volume from the mesh
quality on the speaker's net (`getPlayerVoNVolume` in the voice dump). The
nets with no PAC plan: TEAM (Group channel, one per Arma group, VHF), C2 (a
custom channel, VHF), A2G (custom, UHF), CALL 1-8 (custom, on DATA = UHF),
VEH (Vehicle, crew only), DIRECT (Direct, 3D, never meshed). On clear ground a
handheld reaches ~22 km on VHF and ~2.8 km on UHF (addons/rf README), so on
Tanoa distance fades A2G, DATA and the calls; TEAM and C2 fade only behind
terrain or under a jammer.

**Self test** - the five "Tests to run first" of docs/DESIGN_VOICE.md.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P12.1 | [TEST] Voice: self test, then press push-to-talk 3-4 times in the next 15 s | **[DIAG]** RPT, at once: `(voice) INFO: selfTest: voice active true ...`, `selfTest: adapter von, <n> players`, `selfTest: RF nodes [...]`, one `selfTest: net [...]` per net, `selfTest: active <net>, radio silence false`, `selfTest: cut-off level 0 ...`, `selfTest: slots [...]`; `(adapter_von) INFO: VON T1 setPlayerVoNVolume: SKIPPED, needs a second player` (alone); `VON T2 enableChannel: Group voice off for 15 s ...`; `VON T3 getPlayerChannel: press your push-to-talk ...`; `VON T4 custom channel: server takes you off C2 (custom <n>) and back on after 3 s`; `VON T5 Vehicle channel: in vehicle false, crew false, channelEnabled 4 = ..., setCurrentChannel 4 = ...`. After 15 s: `VON T2 ... Group voice restored. Group talkers seen while it was off: []`; `VON T3 ... own [ms, frames, channel] per press: [[..],..]` - **one entry per press, ms small (under ~100) and the channel your current one**; `VON T3 ... remote channel changes seen: 0` and `VON T3 pushed key events received ...: 0` (alone); `VON T4 custom channel: server removed you ... / server added you ...` about 3000 ms apart, and `membership seen here [ms since start, member]: [[0,true],[..,false],[..,true]]` - the false and the true each within ~1 s of the server's lines | ☐ |
| P12.2 | **[2P]** He takes `jmsbt_medic` (your group). Run the self test again; while it runs he talks on TEAM (Group) twice | **[DIAG]** `VON T1 setPlayerVoNVolume <his name>: was 1, set 0.5, read 0.5` - **PASS when read = set**. `VON T2 ... Group talkers seen while it was off: [<his name>]` - **write down whether you heard him** (yes = listen-only is possible on VON; that is a finding, not a failure). `VON T3 pushed key events received` above 0 while he talked (his key-down / key-up reach you); `VON T3 ... remote channel changes seen:` 0 or more - 0 means getPlayerChannel does not report remote players (the pushed events cover it; paste the line either way) | ☐ |
| P12.3 | Get in the Marshall as driver, run the self test; then as a passenger (cargo seat), run it again | **[DIAG]** `VON T5 ... in vehicle true, crew true, ...` then `crew false`; paste both T5 lines (what `channelEnabled 4` and `setCurrentChannel 4` say is the finding) | ☐ |

**Nets and push-to-talk**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P12.4 | Tablet > RADIO (numpad 6 with the tablet up) > NETS | One row per net you are on: TEAM WEST <callsign> (VON channel Group), C2 and A2G (their custom channels), DIRECT (Direct); link, ear L / B / R, MUTE, state, who is talking. No frequency anywhere. In the Marshall a VEH row appears (crew seats only), out of it it goes. **[DIAG]** [TEST] Voice: dump state - `netState` the same nets | ☐ |
| P12.5 | Inventory: take the MPU5 out of the radio slot; wait 3 s; put it back | Without a set only DIRECT (and VEH in a vehicle) is left on the net row and in NETS; with it back TEAM / C2 / A2G return within ~2 s. **[DIAG]** voice dump `sets carried: []` in between | ☐ |
| P12.6 | Numpad 0 / . round the nets; the game's own Previous / Next channel keys too | The active net steps TEAM -> C2 -> A2G -> DIRECT with a net-switch click; the game's channel indicator (bottom left) follows: Group, the C2 channel, the A2G channel, Direct. The game's channel keys move the active net too. Side and Command may still come up in the game's cycle for text chat, but push-to-talk does not key them | ☐ |
| P12.7 | Push-to-talk on each net, alone | The game's own radio click when you key and the roger click when you let go on TEAM / C2 / A2G (with Pitch per net on: C2 low, TEAM mid, A2G high); none on DIRECT. Your phone talking box and squad row show you TX (red) on radio nets, VOX (magenta) on DIRECT | ☐ |
| P12.8 | **[2P]** He on `jmsbt_hq` (own group HQ) 50 m away. You talk on TEAM, C2, A2G, DIRECT in turn; then he does | TEAM: he does **not** hear you (his TEAM is TEAM WEST HQ) - and you not him. C2 and A2G: both hear, with squelch open / tail around each transmission. DIRECT: heard only nearby, in 3D, no beeps. The listener's phone talking box shows the speaker, `on <NET>` and the net's ear. **[DIAG]** each player's voice dump: `speaker <name>: getPlayerVoNVolume 1, getPlayerChannel <ch>` while he talks | ☐ |
| P12.9 | **[2P]** He moves to `jmsbt_medic` (your group). You talk on TEAM; then you use the game's per-channel "Push To Talk - Group" / "- Direct" keys with the active net on C2 | TEAM heard. A per-channel key sends on its own channel whatever the active net is | ☐ |
| P12.10 | Try to talk on Global, Side and Command. **[2P]** he tries Global | Side / Command: no voice (the game will not key them). Global: you can (host / admin); he cannot unless logged in as admin. **[DIAG]** voice dump `channelEnabled ... 1 Side [true,false], 2 Command [true,false]` | ☐ |
| P12.11 | Bind the game's "Voice Over Net (toggle)" key (Controls > Multiplayer) if it has none; press it | The VOICE note once, top right: "Voice Over Net (toggle) is blocked. Bind Push To Talk instead ..."; you are **not** left transmitting (no TX on your row; voice dump `getPlayerChannel -1`). **[2P]** he hears no open mic | ☐ |
| P12.12 | Ear and mute: on TEAM press Ctrl + numpad 2 (ear) three times, Ctrl + numpad 3 (mute) twice | Ear tag L -> B -> R on the net cell and in NETS; the beeps and static of that net come from that side (voice itself is not panned - VON cannot). Mute: name dim, **[2P]** you no longer hear him on that net (his volume 0 in your dump), unmute brings him back | ☐ |
| P12.13 | Addon Options > Voice: radio beeps off, call beeps off, pitch per net off, static by quality off; then the beep volume slider | Each takes effect on the next transmission; RADIO > NETS > SOUNDS shows the same values. Put them back | ☐ |

**Quality fade, static, cut-offs** (all **[2P]**: he stays at base and talks; you listen, then swap)

| # | Do | Should happen | P/F |
|---|---|---|---|
| P12.14 | [TEST] Teleport: mesh 1 - LZ ROOMBA (~2.8 km). He talks on A2G, then TEAM / C2 | A2G quieter (down to the "Volume at the weakest link" floor, 0.3) with static under it, louder static as quality drops; TEAM / C2 still full. RADIO > NETS link bar for A2G lower. **[DIAG]** your voice dump: `getPlayerVoNVolume` between 0.3 and 1 while he talks on A2G | ☐ |
| P12.15 | [TEST] Teleport: mesh 2 (~4 km), then mesh 3 (~9 km) | A2G fades further, then is **gone** (volume 0); if it drops while he is talking, a cut tone; the A2G cell gets a **red outline** (out of reach, never hidden), NETS says NO ROUTE. The last quality is held 3 s (grace) before it goes to 0. TEAM / C2: note what you hear (VHF reaches; terrain may cut it) | ☐ |
| P12.16 | Back to base | Everything back to full within a few seconds | ☐ |
| P12.17 | You: TAC//EW > EP, set your set to EMCON 3 (SILENT); key TEAM / C2 / A2G, then DIRECT | Radio silence: the blocked tone on the radio nets and he hears nothing of them; DIRECT still works. **[DIAG]** voice dump `block level [1,"Radio silence (EMCON 3)."]`. Set EMCON 0 again | ☐ |
| P12.18 | [TEST] Voice: unconscious for 20 s; try to key TEAM and DIRECT while out (and the Marshall's VEH if you are crew) | "Unconscious: no radio." - he hears nothing of you on TEAM / C2 / A2G / VEH; **DIRECT still carries**. **[DIAG]** a dump taken while out (have him watch, or run it from the debug console): `lifeState INCAPACITATED`, `block level [2,...]` | ☐ |
| P12.19 | [TEST] Teleport: under water (3 m down); key TEAM and DIRECT; surface | "No air: you cannot talk." - nothing at all, Direct included, while you cannot breathe; back as soon as you surface. **[DIAG]** dump under water: `underwater true`, `block level [3,...]`, `isAbleToBreathe false` | ☐ |

**Calls** (all **[2P]** unless marked; RADIO > CALLS on the tablet, or numpad 6 on the phone then 7 / 8 to CALLS)

| # | Do | Should happen | P/F |
|---|---|---|---|
| P12.20 | You: CALLS > CONTACTS > CALL on him | You: dial tone, ringback, LIVE CALL "outgoing". Him: ring, phone notify line `CALL from <you> - F1 accept - F4 decline`, a RING cell on his net row, talking box RINGING <you>; on his phone RADIO app F1 / F4 read ACCEPT / DECLINE on every tab. VON CHANNEL SLOTS show CALL 1 ringing | ☐ |
| P12.21 | He presses Ctrl + numpad 1 | Connect tone on both; a CALL 1 net cell on both rows and it becomes the active net (VON channel = its custom channel); you talk to each other on it; LIVE CALL shows slot, clock, people, priority ROUTINE, size 2. **[DIAG]** voice dump `calls: 1`, `... live ROUTINE | owner <you> | members [you, him]`, `callSlots [[1,"CALL 1",2],...]` | ☐ |
| P12.22 | He presses Ctrl + numpad 4 | Hang-up tone; the call ends (one member left); CALL 1 goes from both rows; the active net goes back to what it was before. LIVE CALL shows the last word (ended) | ☐ |
| P12.23 | Call him again; he declines (Ctrl + numpad 4) | You: busy tone, "declined", CALL BACK offered on his contact | ☐ |
| P12.24 | Call him again; he does nothing for 20 s | "no answer" after the ring time; CALL BACK available | ☐ |
| P12.25 | Owner only: you call him, he accepts. He looks at CALLS and presses numpad 2 on the walking view; you press numpad 2 | **He** (not the owner): contacts read OWNER ADDS instead of + ADD, no RECENT add chips, his phone app's ADD / CALL / GROUP + soft keys disabled, his numpad 2 stays the ear toggle. **You** (owner): + ADD on contacts, numpad 2 opens the quick-add list on your notify line (recent, your group, anyone in reach), 0 / . move, 1 adds, 4 closes | ☐ |
| P12.26 | **[3P]** As owner, + ADD the third player; then you hang up while the two others stay | He rings until he accepts (join chime for the others); when you leave, the call goes on and the longest-standing member is owner (voice dump `owner`); only he now sees + ADD | ☐ |
| P12.27 | FLASH: look at CALLS > NEXT: FLASH as host, and **[2P]** as `jmsbt_hq` and as `jmsbt_medic` | Offered to RTOs, HQ and admins: you (the host should count as admin - if it is not offered to you, note it) and the HQ RTO (manpack, "HQ RTO" role); the medic slot only if the board counts him admin (this mission sets `everyoneAdmin`, a panel flag - note what it shows). **[DIAG]** voice dump `roles: [...] / FLASH allowed: ...`. The bump itself needs all 8 call slots taken (16 players): **N/A here** | ☐ |
| P12.28 | Callback: he teleports mesh 3 (out of DATA reach). You CALL him | Refused at once: "no route" and CALL BACK available. Press CALL BACK: CALLBACKS shows him waiting with its age, both notify lines `CALLBACK pending - <name>`. **[DIAG]** voice dump `callbacks [[you, him, <s>, "waiting"]]` | ☐ |
| P12.29 | He teleports back to base | When you reach each other on DATA both phones ring; accept: a normal live call | ☐ |
| P12.30 | Callback limits: with him out of reach press CALL BACK on him twice | One per pair: the second is refused (3 per player is the other limit - needs more contacts) | ☐ |
| P12.31 | In a live call, he teleports mesh 3 | Dropped after ~10 s with no DATA route: "dropped", busy tone; the call ends | ☐ |
| P12.32 | You set EMCON 3 with a callback pending; then EMCON 0 | The callback is held while you are silent, rings when you are back | ☐ |

**RTO skill and RTO nets** (the RTO is the PAC skill `rto` since 2026-10-22 - `tools/pac_skill_rto.py`; the nets are made from RADIO > MANAGE on the tablet; **[2P]** throughout)

| # | Do | Should happen | P/F |
|---|---|---|---|
| P12.33 | PAC admin (tablet > PAC, or the website): give yourself the RTO skill; wait for the skill republish, or respawn. Then take it away again | With it: your tag reads **RTO** (squad panel, contacts, BFT label), CALLS offers FLASH, RADIO > **MANAGE** opens with the RTO NETS block (NEW NET and the list). Without it, and no RTO / RADIO / JTAC / FAC in the slot name: no RTO tag, no FLASH, no RTO NETS block | ☐ |
| P12.34 | As the RTO: MANAGE > NEW NET, name `raven`, tick his squad and tick one more player by name (or him again); CREATE | Within a second the chip **RAVEN** (upper-cased) is on the net row, the walking view and NETS of everyone ticked - by squad and by name alike - and in the numpad 0 / . cycle; NETS shows a custom channel of its own; you talk on it, they hear you with the squelch clicks; the phone's **NET %** drops by one (one custom channel gone for the mission). **[DIAG]** SERVER EXEC `jmfsb_voice_customPub` -> `[["RAVEN","RAVEN",["<his callsign>"],["<uid>"],"<your uid>","<you>"]]` | ☐ |
| P12.35 | As a rifleman with no RTO skill, not logged in as admin: local exec `player setVariable ["jmfsb_common_isAdmin", true]`; MANAGE > NEW NET `bogus`; CREATE; then set the variable back to `false` | The block opens (the client gate is display only) but the server refuses: a refusal on the notify line (reason `notRto`), no chip anywhere, `jmfsb_voice_customPub` unchanged. The same while logged in as admin (`#login`) is accepted | ☐ |
| P12.36 | As the RTO: MANAGE, REMOVE on RAVEN | The chip goes for everyone within a second, NETS and the cycle drop it, whoever had it active falls back to the net he had before; NET % does **not** come back (VON keeps the channel) | ☐ |
| P12.37 | NEW NET `raven` again, the same members | The same chip and the **same custom channel** in NETS as before (reused by name); NET % unchanged | ☐ |
| P12.38 | Addon Options > Voice: "RTO nets at once" 2 (default). NEW NET `ALPHA`, `BRAVO`, then `CHARLIE`; REMOVE ALPHA; `CHARLIE` again. Then try `C2`, `TEAM X`, `A`, `BOGUS-NAME-12` and `BRAVO` | CHARLIE refused the first time (reason `full`), no chip; made after the remove. `C2` and `TEAM X` reserved, `A` too short, `BOGUS-NAME-12` too long (over 10): all `badName`; `BRAVO` again: `taken`. Nothing of the refused ones in `jmfsb_voice_customPub` | ☐ |
| P12.39 | A TFAR (or ACRE) night, as the RTO: RADIO > MANAGE | The RTO NETS block is read-only - the list only, no NEW NET / REMOVE / member editing - under the stand-down note NETS shows | ☐ |
| P12.40 | Field Manual (2026-10-23): pause menu > Field Manual | A **1st JMSB** category with four topics - Radio voice, Staging zone, Map and tablet, Ammunition - 25 entries; each opens with its sign board as the picture and the board's words as the text, colours and line breaks intact (nothing shows as raw `<t ...>` tags) | ☐ |
| P12.41 | Field Manual: Radio voice > The tablet | The tablet board with its 13 numbered callouts; the text lists 1-13 in order and matches the board | ☐ |
| P2.2i | Tablet corners (2026-10-23): open the tablet, look at all four corners of the dark recess band | Each corner is slightly round - the frame's olive fills the corner outside the arc, no square dark corner, no gap; the left corners' rubber lobes sit over the screen as before | ☐ |
| P2.2j | STABILIZE (2026-10-31), an ACM night with Require antibiotics on: **[2P]** he is down and bleeding, no Ertapenem in him; select him in the console, press **STABILIZE** (the medical block, above WAKE UP; TAC//PAC beside the three buttons at their height) | Notification "<name>: bleeding stopped, Ertapenem 1 g IV given" in green; his bleeding stops, he stays unconscious, his triage card reads Ertapenem IV (1g); a medic's Convert Casualty action is offered within 5 s (his side met: medic skill, place, tickets). Press again: "already meets what ACM's conversion needs of him". On a conscious man the note ends "conscious, and ACM converts unconscious casualties only"; without ACM loaded: "ACM is not loaded" in red | ☐ |

### P13. Numpad keys

All CBA keybinds in Configure Addons > JMSB (rebindable). Check each in each
context; a key that does something it should not, or nothing where it should,
is a fail - paste which.

| # | Key | Walking view (phone / side) | Tablet open | RADIO app open on the phone / side | A text box focused | P/F |
|---|---|---|---|---|---|---|
| P13.1 | 1 2 3 4 | F1 accept call / F2 ear (quick add in a call, owner) / F3 mute / F4 decline or hang up | the frame's F1-F4 apps | the soft keys shown | typed into the box | ☐ |
| P13.2 | 0 . | net page left / right (quick-add cursor while the list is up) | live tiles page (one page: scroll) | cursor | typed | ☐ |
| P13.3 | 5 | opens the tablet | closes it | opens the tablet | typed | ☐ |
| P13.4 | 6 | opens / closes the RADIO app on the device | opens the tablet's RADIO app | closes it | typed | ☐ |
| P13.5 | 7 8 | - | RADIO's tabs while it is open | previous / next tab | typed | ☐ |
| P13.6 | 9 | Troops In Contact sent (notify / TAC//MSG) | the same | the same | typed | ☐ |
| P13.7 | Keyboard F1-F4, arrows | the game's own (nothing of ours) | nothing of ours | nothing of ours | arrows move the cursor | ☐ |
| P13.8 | Ctrl+End | Toggle Device: hides / shows the walking view | - | - | - | ☐ |

### P14. Map tools (jmfsb_maptools)

Run every tool twice: on the **vanilla map** with Display mode = **Native**
(the MAP TOOLS strip is on the map), and on the **tablet** with Display mode
= **Tablet** (strip > TOOLS). Nothing comes from PLP any more.

| # | Do | Should happen (both hosts) | P/F |
|---|---|---|---|
| P14.1 | Open the strip | CENTRE, RULER, PROTRACTOR, ROUTE, MARK, GRID, VIEWSHED, CLEAR; the running tool lit; CANCEL on the title bar stops it | ☐ |
| P14.2 | Pan away, CENTRE | The map back on you (on your vehicle when in one) at the zoom you left; a running tool keeps running | ☐ |
| P14.3 | RULER: press and drag; then press, move, press | Line with distance and bearing at its middle; between two presses a rubber band follows the cursor. If a drag pans the map instead, the two-press ruler is the way (note it: README "Not verified") | ☐ |
| P14.4 | PROTRACTOR: press, move, press, press | A rose (tick every 10 deg, long every 30, N E S W) a fixed size at any zoom; the arm follows with bearing and distance, the next press locks it, the one after places a new rose | ☐ |
| P14.5 | ROUTE: press four waypoints | Each leg its own distance and bearing, the last waypoint the total; the next leg follows the cursor. Starting ROUTE again starts a new route | ☐ |
| P14.6 | MARK: press twice | Markers labelled with the ten-digit grid and the time; the cursor previews the grid. Local: **[2P]** he does not see them; Addon Options > Map Tools > Share marks with group on, mark again: he does | ☐ |
| P14.7 | GRID | The ten-digit grid under the cursor; its leading digits match the map's own grid | ☐ |
| P14.8 | VIEWSHED on a hill near the base | Shading grows out from the point with a percentage at the centre; accent where a standing man can be seen, ink where not; no frame stall. (Needs `drawTriangle` in your game build: if nothing shades, paste the RPT) | ☐ |
| P14.9 | Addon Options > Map Tools > Bearing units: mils, then both | Every reading changes unit | ☐ |
| P14.10 | Lay a ruler on the tablet; close the tablet, open the vanilla map (M) | The same ruler on the paper map (world positions); a tool stops when its map closes but what it drew stays | ☐ |
| P14.11 | With TAC//SUPPORT open, click the map | The click sets SUPPORT's point, never a tool press; the press that closes an app is not a tool press either. Shift / Ctrl / Alt clicks stay the game's | Withdrawn 2026-11-01: TAC//SUPPORT app removed |
| P14.12 | CLEAR | Everything the tools drew and your local marks gone; a shared mark stays (the group's) | ☐ |

### P15. EW and TAC//EW

The enemy emitters are on from the start (P0.1): an enemy net node on T2's
MRAP and an enemy jammer on T3's APC. Your MPU5 is the DF sensor; the EW
Receiver makes it the 2 deg all-band set. Run this section before the fires
and CAS steps destroy T2 / T3.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P15.1 | Tablet tiles: the EW tile; open TAC//EW | Tile reads ON AIR / OFF / NO DATA (not stuck on WAITING FOR THE SERVER after ~10 s). App tabs OVERVIEW / ES / EA / EP. OVERVIEW: SIDE, ISR NO, RECEIVER yes, PACK none, VEHICLE no, your SETS, TRACKS, FIXES, JAMMERS, GPS GOOD, THREAT WARNINGS | ☐ |
| P15.2 | Wait 10-20 s at base; ES tab and the map | Two tracks: T2's (VHF, class **UNKNOWN** - non-ISR players see only JAM / SPOOF / VIDEO named) and T3's (**JAM**), with SIGNAL dBm, CONF, AGE and a bearing. A **JAMMER** threat warning on the notify rail and in OVERVIEW. On the map (tablet, and the vanilla map in Native mode): DF lines from where you stood toward T2 and T3 with a narrow error wedge (2 deg). **[DIAG]** dump: `EW slice: ... 2 tracks`, a `track ...` line each | ☐ |
| P15.3 | [TEST] ISR flag on; ES | T2's track now reads **COMMS** (it carries traffic). Not named (you do not hold OPFOR's key) | ☐ |
| P15.4 | [TEST] Teleport: DF baseline; wait 10 s | A **fix** on each: an error circle and label at T2 / T3 on the map, FIX / BEARING in ES, a NEW FIX warning; CONF rises. **[DIAG]** dump `track ... fix <grid near T2 / T3> err <m>` | ☐ |
| P15.5 | Drop the EW Receiver (inventory, on the ground); wait 10 s; pick it up | New cuts get the handheld's wider wedge (15 deg, 10 as ISR); OVERVIEW RECEIVER no, then yes again | ☐ |
| P15.6 | [TEST] EW: enemy emitters off | No new cuts; the tracks age out after the track lifetime (300 s). On again afterwards | ☐ |
| P15.7 | [TEST] EW: get in the jammer vehicle (the Marshall, EW Jammer Module in its cargo); EA tab | JAMMER CONTROL: header **GJ-01  STANDBY**; VEHICLE names the Marshall; JAM MODE, TARGET (VHF / UHF / SAT / VIDEO), FILTER, PATTERN, TX POWER (1 / 5 / 20 / 50 W), DUTY, OPERATION, the switch; POWER SYSTEM and BATTERY / HEAT bars. P15.8-P15.13, P15.17 and P15.23-P15.30 are run from this seat | ☐ |
| P15.8 | Barrage VHF, 20 W, TRANSMIT | OVERVIEW JAMMER on; your jammer on the map; ES SPECTRUM HERE shows VHF noise far above the floor. **[2P]** he stands 300 m away: his TEAM / C2 links to you and to anyone through you drop - static, quieter, lower link bars in his NETS. STOP TRANSMITTING: back | ☐ |
| P15.9 | Sweep | The bands come up in turn, 5 s each (SPECTRUM HERE) | ☐ |
| P15.10 | Spot: ISR on, TARGET = T2's track, TRANSMIT | Only that net is jammed (+10 dB on it); your own nets and spectrum otherwise unchanged. ISR off: spot is refused / not offered; with no ES track: NO ES TRACK | ☐ |
| P15.11 | GPS mode at each power | A GPS denial zone on you, 200-1000 m by power: the GPS cell on your phone (and **[2P]** his, inside the radius) reads jammed | ☐ |
| P15.12 | **[2P]** Spoof (ISR) near him; he first without, then with an EW Receiver | Without: his GPS drifts - his TAC//EW OVERVIEW GPS SPOOFED, his dump `EW gpsState` offset growing (about 3 m/s up to the drift setting). With the receiver: SUSPECT, no drift. (What follows the false fix: P15.18) | ☐ |
| P15.13 | ISR on; EA > PLACE DECOY three times | Two antennas (`OmniDirectionalAntenna_01_olive_F`) appear by you; the third is refused (two per man); OVERVIEW / dump `decoys out 2`; they go after the decoy battery setting. ISR off: "DECOYS ARE FOR ISR OPERATORS" | ☐ |
| P15.14 | EP tab | Each of your sets with EMCON 0-3 and how far it is heard; SILENT = RECEIVE ONLY (and voice radio silence, P12.17). Back to 0 | ☐ |
| P15.15 | Get out of the Marshall; EA. Then put the EW Jammer Module on your back from its cargo; EA | On foot: NO JAMMER, "CREW A VEHICLE WITH AN EW JAMMER MODULE IN ITS CARGO". Worn: still NO JAMMER - no man packs. Put it back in the cargo | ☐ |
| P15.16 | ISR off again (dump `isISR false`) | Before P5.7 / P16.3 as written | ☐ |
| P15.17 | GPS denial (2026-10-20 GPS readers). In the Marshall; EA **GPS** mode, any power, TRANSMIT (the zone sits on the vehicle) | Rail: the jamming addon's "GPS NONET" once. OVERVIEW GPS **NO FIX**. Map (map content off, as the test preset): your own BFT dot is gone, your men's stay. Map tools GRID: under the cursor's grid a line **GPS NO FIX**. CENTRE: the map does not move, rail "NO GPS FIX - THE RECEIVER HAS NO LOCK...". A report card's CUR LOC: nothing filled, same rail line; compose CURRENT LOC: no pin; reader + GRID: nothing added. TIC key: "No GPS fix - send the TIC from the card with your grid". STOP TRANSMITTING: all back (dot, GRID line `GPS <ten digits>`) | ☐ |
| P15.18 | **[2P]** Spoof him as P15.12 (no receiver), let it drift 100 m+; he checks; then with the EW Receiver | Without: his own BFT dot (and the dot of him on YOUR map, about every 3 s, 10 m steps) walks off where he stands; his GRID line and CENTRE give the false spot; his CUR LOC / + GRID / TIC carry the false grid; his EW OVERVIEW GPS SPOOFED. With the receiver: dot back on him reading "- GPS SUSPECT", GRID line ends SUSPECT, CUR LOC fills with a rail warning "GPS SUSPECT...". Out of the field: walks back, GOOD | ☐ |
| P15.19 | Enemy AI EW BASIC (setting "Enemy AI EW skill", default BASIC; Reaction module placed). [TEST] Teleport within ~1 km of T2 / T3; hold the PTT on TEAM for 10 s, twice, 20 s apart; stay put | Notify rail **DF ON YOU** "EAST CUT ON YOUR VHF SET" (the T2 / T3 crews carry radios = handheld DF sets). Once two crews 50 m+ apart have cut you inside 30 s: RPT `AI EAST (BASIC) answers fix T<n> at <grid near you>`; the crews within 50 m of a cutting crew, or with a radio link to one, go AWARE and turn toward you for 60 s; `#jmfsbreact` shows you flagged (silent) - a second fix while flagged = MAJOR ("COMPROMISED") | ☐ |
| P15.20 | Same, EMCON 3 SILENT on your sets; then the setting OFF | SILENT: no cuts, no DF ON YOU. OFF: only T2's own RF node still cuts you (it is an EAST set, a sensor without the setting) - one sensor, so no EAST fix and no `answers fix` line | ☐ |
| P15.21 | Comms gate. Marshall (P15.15) beside T2, barrage VHF 50 W over the crews; with a crew more than 50 m from the cutting one, transmit from 1 km as P15.19 | Fewer or no `answers fix` lines than P15.19 - the reports ride VHF handhelds (~0.5 km) that your jammer drowns. Within 50 m of each other the crews still tell each other (voice) | ☐ |
| P15.22 | [optional] ACTIVE, then SMART (a mission with a drone patrol module / ALiVE commanders) | ACTIVE: a drone comes to look at the fix (`jmfsb_uas`, inside its ceiling), at most every 300 s. SMART: also a QRF toward the fix | ☐ |
| P15.23 | Device ID (2026-10-21). **[2P]** he crews a second jammer vehicle of your side; both open EA | Yours **GJ-01**, his **GJ-02** in the header and the footer. Your NETWORK footer names `GJ-02 BARRAGE STBY` (then ON when he transmits); not yourself. Map: your side's jammers on the air labelled `GJ-0n MODE`. He gets out and back in: still GJ-02 (a new jammer if the old one was dropped, the lowest free number) | ☐ |
| P15.24 | Battery. Engine OFF; barrage VHF, 50 W, DUTY 100%, CONTINUOUS, switch on | POWER SYSTEM: SOURCE **BATTERY**, IN / OUT `0 W / 125 W`, NET `-125 W DRAINING`; BATTERY bar falls (150 Wh lasts about 72 min - lower the "Jammer battery" setting to 20 Wh to see it flat in about 10 min). At 0: header **BATTERY FLAT**, warning `GJ-01 BATTERY FLAT - TRANSMITTER OFF THE AIR`; SPECTRUM HERE drops back to the floor | ☐ |
| P15.25 | Generator. Start the engine | SOURCE **GENERATOR**, GEN FUEL = the Marshall's fuel %, IN / OUT `425 W / 125 W`, NET `+300 W CHARGING`; the battery climbs; a flat jammer comes back on the air. Battery full: NET `0 W - FULL` | ☐ |
| P15.26 | Heat. 50 W, 100% duty for about 4 min (setting "Jammer heating" up to 2 to hurry it) | HEAT bar rises (green, amber from 80% = COOLING **HOT**). At 100%: **THERMAL CUTOUT**, COOLING **CUTOUT**, warning naming 60%; off the air (no noise). It cools; at 60% `COOLED - TRANSMITTER BACK ON THE AIR` and it transmits again. At 5 W / 50% duty it never cuts out | ☐ |
| P15.27 | Pattern. **[2P]** he stands 300 m north of you; barrage VHF 20 W; PATTERN SECTOR 120, AZIMUTH stepped to 000, then to 180 | TRANSMITTER PATTERN `SECTOR 000 +3 DB`. Azimuth 000: his VHF nets are jammed (net row amber / red) a little harder than OMNI. Azimuth 180: not jammed at all (he is outside +-60 deg). The arrows step 15 deg and wrap 345 -> 000 | ☐ |
| P15.28 | MHz. ES tracks up (P15.2); EA | DETECTED rows read `T<n>  VHF 47.325  ...` with a MHz in the band's range (VHF 30-88, UHF 225-400, SAT 7250-7750, VIDEO 2400-2483 / 5725-5850); the same MHz on every client and after a restart for the same nets. SPECTRUM HERE: each band's MHz range under it and a tick per heard emitter along its bar | ☐ |
| P15.29 | Targeted. ISR off: FILTER TARGETED is dim. ISR on: barrage, FILTER TARGETED; TUNED arrows onto T2's MHz; switch on | Sub line `BARRAGE - VHF 47.325 MHZ`; a red tick at that MHz on the VHF bar; T2's row red. Only T2's net (and any net within +-0.5 MHz) is jammed; **[2P]** his own VHF nets on other frequencies are not. A press on a DETECTED row tunes to it. Stepping TARGET to another band: `TUNE A FREQUENCY`, nothing jammed until tuned | ☐ |
| P15.30 | Auto. OPERATION AUTO, switch on, no hostile drone or track in reach | Header **AUTO STANDBY**, OPERATION `STANDBY - NOTHING HOSTILE`; no noise, no battery draw, HEAT falls. [TEST] put up an EAST UAV within 3 km: within 15 s **TRANSMITTING**, `ENGAGED - HOSTILE DRONE`. UAV gone: back to STANDBY within 15 s. With T2's track fresh and within reach on the barrage band: `ENGAGED - TRACK T<n>` (T2's track id) | ☐ |

### P16. RADIO, DRONES and HACK boards (tablet)

| # | Do | Should happen | P/F |
|---|---|---|---|
| P16.1 | RADIO: NETS, CALLS, MANAGE tabs (numpad 7 / 8 step them) | NETS as P12.4 plus SOUNDS (the voice settings) and KEYS (your numpad bindings as bound). CALLS: + MY TEAM / + SQUAD LEADERS / + RTOs / + MEDICS / + HQ, NEXT: FLASH (P12.27), FIND by name or callsign, VON CHANNEL SLOTS (C2, A2G, CALL 1-8), CONTACTS with ON CALL / + ADD / CALL / CALL BACK, LIVE CALL, CALLBACKS. MANAGE: your nets with VON channel, kind and state, TEAM / CALL members with reach, WHO CAN. What is not built (per-net beep volume, MAKE FLASH, callback cancel, HOPS, temp nets, patches, rekey, ...) is said in words, never a dead button. The RADIO tile: the active net, its kind, who is talking | ☐ |
| P16.2 | DRONES: [TEST] put up a UAV; open DRONES (tile) | FLEET: the Greyhawk with link word, quality, battery (fuel), task. Pick it, FEED: its gunner optic rendered inside the app with a HUD - name, altitude, speed, heading, target grid and range, link. MARK TARGET (a local marker where the optic looks) and CONNECT live; TAKE CONTROL, ORBIT, GO TO, LASE, RTB live once connected (P16.8-P16.12). ENEMY tab: enemy drones the scanner hears (none expected) | ☐ |
| P16.3 | No UAV terminal anywhere (2026-10-20). UAV operator trait OFF: CONNECT. Trait ON: CONNECT, TAKE CONTROL; look and fire from the gunner seat; scroll menu **Release drone control**; TAKE CONTROL again, then numpad 5; TAKE CONTROL, then debug console `jmsbt_uav setDamage 1`; DISCONNECT | Trait off: CONNECT dead, "Only the UAV operator flies drones." under the buttons. Trait on: the row reads LINKED - YOU; TAKE CONTROL closes the tablet and puts you in the gunner optic (row: MANUAL - YOU). The release action and numpad 5 each put the camera back on you in the view you left in, link kept. Drone destroyed: "Drone link dropped. That drone is gone.", camera back on you, no black screen. **If CONNECT says "No DATA link"** while you are alone, that is RF's DATA link to nobody: repeat **[2P]** with him at base and paste the result | ☐ |
| P16.4 | Close the app, change tab, change pick; destroy the UAV (debug console `jmsbt_uav setDamage 1`) | The feed camera stops each time; the dead drone: "That drone is gone." | ☐ |
| P16.5 | HACK at base, ISR off | The HACK tile says you are not cleared before you press it (hacking requires ISR, forced) | ☐ |
| P16.6 | [TEST] ISR flag on; [TEST] Teleport: HACK tower; HACK | Tile: a target in range. NODES IN REACH: the COMM TOWER, and T2's enemy net node with its RF quality marked **NO ACCESS** (remote unit hack is off). ACTION: target + grid, DISABLE / SPOOF / TAP (SPOOF dead on a tower), product, progress with time left, risk, needs, START / ABORT. START on the tower: progress runs; LOG lists the steps; ABORT stops it | ☐ |
| P16.7 | ISR off | Before P5.7 | ☐ |
| P16.8 | HACK SPOOF (2026-10-20). ISR on; CBA setting "Remote Unit Hack" on; within reach of T2 (P16.6), HACK | T2's MRAP is now a suite row (NET - its crew's group) instead of NO ACCESS. ACTIONS: TAP filled, SPOOF live (outlined); press SPOOF: SPOOF filled, PRODUCT replaced by EFFECT "THEIR GPS WALKS UP TO 300 M OFF TRUE FOR 300 S". START: runs and rolls as a TAP (it may fail / be detected). Done: rail "GPS spoof injected - <group>'s sets are walking off their true position.", RPT `GPS of <group> (EAST) spoofed by <you>`, the row goes (net broken). Then P15.19 against T2: its cuts start from where its GPS says, so EAST's fix on you lands off you (RPT grid). A tower or drone row: SPOOF dead | ☐ |
| P16.8 | DRONES GO TO: UAV operator trait on, [TEST] put up a UAV, CONNECT it; GO TO; left-click the map about 1 km away. Again: GO TO, right-click. Again: GO TO and wait 30 s. Again on the vanilla map (tablet put away, DRONES opened from the map's tile) | The app closes and "GO TO: click the map for the point. Right click cancels."; the click does not draw map tools or close anything; "Flying to <grid>, then loitering.", the board comes back, the fleet task reads MOVE, then LOITER over the point at the height it had. Right click: "GO TO cancelled.", board back. Waiting: "GO TO timed out - no point picked." and a map click closes apps again. Same on the vanilla map | ☐ |
| P16.9 | DRONES LASE on the Greyhawk (it carries a designator): pick a spot in the FEED, LASE; then LASE OFF. Then a drone with no designator (AR-2 Darter), LASE | Greyhawk: "Lasing <grid>.", the optic slews onto the point, the designator comes on within about a second, the HUD target line reads `LASE <grid> - <n> M`, the button reads LASE OFF in the red fill; **[DIAG]** `laserTarget jmsbt_uav` not null. LASE OFF: "Laser off.", the spot goes. Darter: "This airframe has no laser designator." | ☐ |
| P16.10 | DRONES RTB: the Greyhawk put up in the air; then a Darter linked while it sits on the ground, flown off with GO TO, then RTB | Greyhawk: "RTB to STAGING (<grid>), will loiter." (or a patrol base's name, or OPERATOR with neither) and it flies there and circles. Darter: "RTB to LAUNCH POINT (<grid>), will land." and it sets down where it was linked | ☐ |
| P16.11 | Drone40 modes (GX Drones loaded): fire a Drone40 Relay round as the UAV operator; DRONES, pick it; JAMMER; OFF; RELAY | A MODE row RELAY / DECOY / JAMMER / OFF over the buttons, RELAY filled. JAMMER: "Drone40 mode: JAMMER.", JAMMER filled, nearby VHF/UHF links lose quality and EW ES hears a JAMMER; OFF: no node, no noise; RELAY: relays again. Without the trait the row is dead | ☐ |
| P16.12 | **[2P]** dedicated server: the client connects a server-spawned UAV and gives GO TO, LASE, RTB | Each order runs (the crew is the server's: the orders go by `jmfsb_devices_uavOrder` to it); no errors in either RPT | ☐ |

### P17. Air verdicts and map shapes on TAC//SUPPORT

Withdrawn 2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P17.1 | CAS > HOG, SAD, point on T2 | VERDICT `ETA <n> MIN - ON STATION <n> MIN - <n> SORTIES LEFT`; map: HOG's base / stand point, and once tasked the leg out, the INGRESS / EGRESS legs and the 150 m FRIENDLY RANGE ring round the point (no ring on LOITER). **[DIAG]** matches P0.3 | ☐ |
| P17.2 | Danger close: point within 150 m of you, DANGER parameter on | The verdict ends `- DANGER CLOSE` | ☐ |
| P17.3 | HOG on station: a new SAD; then ATTACK RUN | SAD: `REPOSITION - ETA <n> S`; ATTACK RUN on an aircraft already on station: refused (false) | ☐ |
| P17.4 | HAWK (CAS drone) SAD, then LOITER | `ETA ... - <n> AIRFRAMES LEFT`; LOITER `ON STATION IN ...`. While out: INGRESS / EGRESS legs and the search ring (strike) or orbit ring (loiter); no home point | ☐ |
| P17.5 | RAVEN: LAND on LZ ROOMBA; PICKUP with no point; change SPEED | `ETA <n> MIN <n> S TO LZ`; PICKUP without a grid `... ON YOU`; the ETA changes with SPEED. While out the leg home from the plan's last point is drawn | ☐ |
| P17.6 | RAVEN: HELOCAST on land; PICKUP > LZ without the LZ; SLINGLOAD on empty ground | HELOCAST over land refused; PICKUP > LZ without its second point refused; SLINGLOAD with nothing within 80 m: **true** but `NOTHING LIFTABLE WITHIN 80 M` | ☐ |
| P17.7 | MULE / PORTER DROP; REACH STATIC | `ETA ... - LAST DROP` / `... DROPS LEFT`; `ETA ... - <n> SQUADS LEFT` | ☐ |
| P17.8 | Any air asset busy or launching | VERDICT false with the reason (busy / launching / turning round / replacing / spent) and CONFIRM held | ☐ |

### P18. Fast-rope with players in the cabin

| # | Do | Should happen | P/F |
|---|---|---|---|
| P18.1 | Dump at start | **[DIAG]** `ropes: RAVEN ... carries 2 x ACE_rope36` - stocked at module read, no [TEST] action used | ☐ |
| P18.2 | **[2P]** Both players and the AI squad board RAVEN; RAVEN FASTROPE on open ground near LZ ROOMBA | Hovers at the point with ACE ropes out; each player gets ACE's fast-rope action and slides down on his own machine; the AI squad ropes down; RAVEN holds until the cabin is empty (or the wait is up), then holds the hover | ☐ |
| P18.3 | Alone: the same with you and the AI | You rope down; the AI follow | ☐ |
| P18.4 | Dump after; then FASTROPE again | Note the rope count after a sortie; when the next FASTROPE task arrives RAVEN is topped up to 2 again | ☐ |
| P18.5 | BISON (class Huron) FASTROPE | Ropes stocked at launch; same as P18.2 (if the Huron can rope - ACE decides) | ☐ |
| P18.6 | [TEST] Destroy RAVEN's helicopter; after the rebuild, dump | The replacement carries 2 ropes (stocked on adoption) | ☐ |

### P19. Base stations - staging zone uplink, patrol base relay, no manpack

Built 2026-10-20 (docs/DESIGN_RF.md "The satellite link", "Base stations").
Server commands go in the debug console with **SERVER EXEC**. Nobody wears a
manpack in this section: MPU5 handhelds only. The handheld's own 25 mW is the
weak leg: handheld to base station is about 0.6 km on flat, clear ground, so
"near the patrol base" below means within ~0.5 km (or meshed to it through
other MPU5s); the patrol base itself can be 3-5 km (or any distance) from the
staging zone.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P19.1 | Start; read the server RPT. If the mission has no staging zone marker (`respawn_west`, `zone_staging`, ...), add one: `[getPosATL player, 12] call jmfsb_mission_fnc_addStagingZone` (local exec) | RPT `base station base_1 up for WEST (jmfsb_mission)`, once per zone however many players report it. SERVER EXEC `["base_1"] call jmfsb_rf_fnc_nodeInfo`: profile `base`, nets = every plan net + `DATA` + `C2`, relay true, tx true, no holder | ☐ |
| P19.2 | [TEST] or Zeus: drop 4 patrol base kits 3-5 km from the staging zone, in the open; Establish Patrol Base | RPT `base station base_2 up for WEST (jmfsb_patrol_base)`. SERVER EXEC `["base_1", "base_2", "C2"] call jmfsb_rf_fnc_link` -> `[0.9, 1, ""]` (clear sky, one hop through the satellite; lower if it is raining) | ☐ |
| P19.3 | **[2P]** He stands at the staging zone; you within ~0.5 km of the patrol base. Talk on your C2 net, then he does | Each hears the other on C2 (static only as your own handheld leg weakens). RADIO > NETS: C2 reachable, hops 3 (you - patrol base - staging zone - him). Neither of you wears a manpack | ☐ |
| P19.4 | Walk away from the patrol base (no other MPU5 between you), keep talking on C2 | C2 to him fades and is gone at about 0.6 km from the base (the handheld's 25 mW uplink); back when you return. With a second player as an MPU5 relay half way, it reaches further | ☐ |
| P19.5 | SERVER EXEC `0 setOvercast 1; 0 setRain 1; forceWeatherChange`; after ~5 s the P19.2 link again | Quality falls to about 0.6 (6 dB rain fade at the default "SAT rain fade"); C2 still carries, with more static. Clear the weather afterwards | ☐ |
| P19.6 | Zeus: move the patrol base mast into a building or hangar (under a roof); wait 5-10 s; P19.2 link again | `[0, 0, ""]` (no sky, and 3-5 km is far beyond the ground link): your C2 to the staging zone is gone while the local relay still works round the base. Move it back into the open: back within 5-10 s | ☐ |
| P19.7 | ISR on; TAC//EW ES near the patrol base; then from the Marshall's jammer (P15.15: SAT is a vehicle band) EA barrage on **SAT** beside the mast | The base station is an ES track (VHF / UHF / SAT emitter). While you jam SAT, the P19.2 link quality drops (jammed at the mast end); STOP TRANSMITTING: back | ☐ |
| P19.8 | Destroy the base: SERVER EXEC `((jmfsb_patrol_base_bases select 0) select 0) setDamage 1` (or delete the mast in Zeus; or Unbuild on a second base) | RPT `base station base_2 down`; P19.2 link `[0, 0, ""]`; your C2 to the staging zone goes (unless you are within handheld reach of him) | ☐ |
| P19.9 | Addon options: "Patrol base radio relay" off, build a base; restart with "Staging zone satellite uplink" off | No base station on the new base; no `base station ... up` line for the staging zone | ☐ |
| P19.10 | RTO: a slot with no RTO role description and no RTO skill; CALLS contacts and MANAGE | You are **not** the RTO (no RTO tag, no FLASH). A slot named "RTO" (or the PAC RTO skill) is | ☐ |

---

### P20. Echo test (voice over LiveKit)

Built 2026-10-29 (docs/DESIGN_VOICE_LIVEKIT.md "Echo test",
addons/adapter_livekit). Needs the LiveKit voice server (the Pelican egg) up
with Echo test true, and the server's CBA settings JMSB - Voice (Built-in) >
Voice server (LiveKit) set: `ws://VOICE-SERVER:7880` (or `wss://game9001.ghostsofbattle.com:7880`
with the egg's Encryption on: run P20.2-P20.5 once each way), the egg's key and secret. Windows
client; the mod's `jmsb_voice_x64.dll` loads with it. A headset, so the
playback does not reach your mic.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P20.1 | Start; read your client RPT | `jmsb_voice extension 0.1.0`. (On a client without the DLL: `jmsb_voice extension not loaded - no echo test`, and no ECHO TEST row anywhere) | ☐ |
| P20.2 | Phone RADIO app, CALLS tab | First row ECHO TEST, VOICE SERVER, READY, CALL | ☐ |
| P20.3 | Cursor on ECHO TEST, F2 | Notification "Calling the voice server..."; row CALLING, then within ~2 s LIVE and the notification "Talk, then pause: you hear it back". Header ECHO TEST - LIVE; F4 reads HANG UP. Voice server console: `echo: answered echo-<your UID>` | ☐ |
| P20.4 | Say a sentence, then stop | About 1 s after you stop, you hear the sentence back. Voice server console: `recording <UID>`, `playing N s back to <UID>` | ☐ |
| P20.5 | F4 | Notification "Ended."; row READY. Voice server console: `left echo-<UID>` | ☐ |
| P20.6 | Tablet RADIO page, CONTACTS: ECHO TEST CALL; talk; HANG UP | Same as P20.3-P20.5 on the tablet's row | ☐ |
| P20.7 | **[2P]** Both run the echo test at the same time | Each hears only his own words back | ☐ |
| P20.8 | Voice server egg: Echo test false (restart it); call ECHO TEST | After 15 s: "No answer: the voice server, or its echo test, is off." Row READY | ☐ |
| P20.9 | Admin: clear the API secret setting (server); call ECHO TEST | "...the voice server's address, key or secret is not set..." at once. Set it back | ☐ |
| P20.10 | Start the echo test, leave it LIVE, Escape and abort the mission | Voice server console: `left echo-<UID>` within a few seconds (the mic closes with the mission) | ☐ |

---

### P21. Holiday crests on the loading screen

Built 2026-10-30 (addons/loading `CfgLoadingScreen.hpp` Holidays,
`fnc_holiday`, `fnc_holidayDate`). The crest beside the mission box is a
holiday's from 7 days before its day through the day (New Year's: Dec 26 to
Jan 2), the unit's otherwise. The picker takes a date, so the rest is the
debug console on any day - no clock changes.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P21.1 | Load any mission between Oct 24 and Oct 31 | The pumpkin crest (halloween) where the unit crest stands, 512 px square, top on the mission box's top; the unit crest on Nov 1 | ☐ |
| P21.2 | Debug console: `configName ([[2026, 12, 25]] call jmfsb_loading_fnc_holiday)` | `"christmas"` | ☐ |
| P21.3 | The same with `[2026, 12, 26]`, `[2027, 1, 2]`, `[2027, 1, 3]`, `[2026, 12, 17]` | `"newYearsDay"`, `"newYearsDay"`, `""`, `""` | ☐ |
| P21.4 | The same with `[2026, 11, 19]`, `[2026, 11, 27]`, `[2026, 5, 18]`, `[2026, 10, 5]`, `[2027, 3, 21]` | `"thanksgiving"` (Nov 26), `""`, `"memorialDay"` (May 25), `"indigenousPeoplesDay"` (Oct 12), `"easter"` (Mar 28) | ☐ |
| P21.5 | `([configFile >> "jmfsb_loading_CfgLoadingScreen" >> "Holidays" >> "thanksgiving", 2026] call jmfsb_loading_fnc_holidayDate) - ([2026, 11, 1] call jmfsb_common_fnc_daysFromCivil) + 1` | `26` | ☐ |
| P21.6 | A mission with a database boot (the TAC//PAC INITIALISING THE UNIT overlay shows), inside a holiday window | The overlay's mark is the holiday's crest, square, where the unit crest stood; outside a window the unit crest | ☐ |
| P21.7 | Start the game inside a holiday window; look at the main menu | The crest above the three server buttons is the holiday's; outside a window the unit crest. Client RPT with debug on: `Main menu crest` names the holiday | ☐ |

---

### P22. Voice over the voice server (LiveKit is the VON)

Built 2026-10-31 (addons/adapter_livekit, docs/DESIGN_VOICE_LIVEKIT.md).
Needs the LiveKit egg up and the server's JMSB - Voice (Built-in) > Voice
server (LiveKit) settings set, as P20. Two Windows clients with the mod's
`jmsb_voice_x64.dll`. Headsets. Game VON must carry nothing.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P22.1 | Start; read the client RPT | `voice: livekit carries the voice`, `voice adapter in use: livekit`, then `voice server: in the room mission-...`; notification VOICE "On the voice server." | ☐ |
| P22.2 | Esc > chat channel list; try Arma's Push To Talk on every channel | No channel carries voice (the speaker icon stays off); text still works on all | ☐ |
| P22.3 | **[2P]** Both on the same TEAM net; hold Caps Lock, talk | The other hears you; the net chip reads TX on your side, your name on his talking chip. Release: silence | ☐ |
| P22.4 | **[2P]** Set net 2's ear to L on the RADIO app; the other talks on it | Heard in the left ear only | ☐ |
| P22.5 | **[2P]** The other walks 100 m off and holds Shift + Caps Lock (talk local) | Nothing. At 40 m faint, beside you full; from your right in the right ear | ☐ |
| P22.6 | **[2P]** Both in one vehicle; talk local | Full volume whatever the seats | ☐ |
| P22.7 | **[2P]** Mute net 1 (Ctrl + numpad 1); the other talks on it | Silence; unmute: heard | ☐ |
| P22.8 | Call the ECHO TEST (P20), hang up | Works; RPT: the room left, then `in the room` again within a second | ☐ |
| P22.9 | Kill the LiveKit egg; wait; start it again | Notification "The voice server dropped you ... Rejoining."; within 10 s of the egg being back: "On the voice server." | ☐ |
| P22.10 | Server: clear the API secret, restart the mission | One notification "No voice: the voice server's address, key or secret is not set"; RPT `voice server: the server cannot sign us in` every 60 s. Set it back | ☐ |
| P22.11 | Rename `jmsb_voice_x64.dll` away on one client, start | That client's RPT: `jmsb_voice extension not loaded - no voice server`; `voice: von carries the voice`; Group / Vehicle / Direct carry voice for him. Put it back | ☐ |
| P22.12 | Settings untouched (Speakers and Microphone empty); call the ECHO TEST | The echo plays in the headset: `%LOCALAPPDATA%\Arma 3\jmsb_voice.log` says `speakers: Windows' communications device 'Headset Earphone (...)'` and `microphone: ...`. If Windows has no communications device set, the default device, and then: Addon Options > JMSB - Voice (Built-in) > Speakers = part of the headset's name (the RPT lists the names after `voice devices`); the log says `reopened` | ☐ |
| P22.13 | End the mission, exit the game from the main menu | No crash on exit (2026-10-31's two runs crashed there). The log's last line: `process exit with the voice runtime up: ending the process here`. The RPT may end before the `Extensions:` list - that is the DLL ending the process after the engine's own shutdown | ☐ |
| P22.14 | Tablet SETTINGS, the walking view | No NET cell on the phone's status line; the status facts in one line of one size, each cell as wide as its text; the first net chip a gutter in from the screen's edge; the tablet bar's facts on one line either side of the clock; two-letter tile badges (RF, UP) on one line; the reader's ALL and GHOST tabs whole; no white hairline down the tablet frame's outer edges | ☐ |

### P23. Code review fixes (2026-10-31)

From docs/REVIEW_CODE_2026-10-31.json. Nothing below was run before this list
was written. A dedicated server, two clients and, where it says so, a headless
client. **[CHEAT]** rows use a client's debug console (local exec) to play a
client that lies; each must be refused, with a WARNING in the server RPT.

**Admin and trust (S1-S7)**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.1 | Join, not logged in, not on any admin list; `#jmfsb admin.me` | Nothing (the surface is silent). Then `#login`: within 5 s the console opens for you and `#jmfsb admin.me` says "server says admin: true (... #login: true)" | ☐ |
| P23.2 | **[CHEAT]** As a non-admin: `player setVariable ["jmfsb_common_isAdmin", true, true]`, then open the console and press SET TIME, GRANT ADMIN, ZEUS, RANK | The console may open (screens trust the flag) but nothing happens on the server; each refused in the server RPT | ☐ |
| P23.3 | **[CHEAT]** As a non-admin: `["hint 'pwned'", clientOwner] remoteExec ["admp_fnc_compileAndExec", 2]` | No hint anywhere; server RPT "compileAndExec refused: machine N is not an admin" | ☐ |
| P23.4 | **[CHEAT]** As a non-admin: `admp_authorisedIDs pushBack getPlayerUID player; publicVariable "admp_authorisedIDs"`; then any PAC admin page action | Refused; the server's list is unchanged (`#jmfsb admin.list` from a real admin) | ☐ |
| P23.5 | **[CHEAT]** As a non-admin, pass an admin's unit: `[<adminUnit>, getPlayerUID player, "rankId", "COL"] remoteExec ["jmfsb_pac_fnc_adminSet", 2]` | Refused - the caller is not the sender | ☐ |
| P23.6 | Admin: code box REMOTE on the other client: `hint str clientOwner` | The hint shows on his screen; the return line comes back to your console | ☐ |
| P23.7 | Admin: GRANT ADMIN on the other player, then revoke; then try to revoke a TAC//PAC admin the same way | He gets access, then loses it; the PAC admin: "is an admin by the mod's list or TAC//PAC's admins, not by a grant here" | ☐ |
| P23.8 | Admin: TIME / WEATHER SET on both; STABILIZE a bleeding casualty | Time, weather (both clients' overcast) and the casualty change as before (P2.2j) | ☐ |
| P23.9 | Add a Steam id on the PAC admins page; that player reopens the console | He is an admin at once (server list follows the section); remove it - he is not | ☐ |
| P23.10 | Mission `cba_settings.sqf` with `jmfsb_adminpanel_everyoneAdmin = true` | Everyone passes; **[CHEAT]** on a mission without it, publishing the variable true changes nothing | ☐ |
| P23.11 | A player types `#jmfsb state` as an admin, with two other clients connected | The reply comes once, to him only; other clients see nothing and do not run it | ☐ |
| P23.11a | Normal use, dedicated: task support_air (CAS, transport, drop, QRF) and RTB; a support_fires FFE and CHECK FIRE; CAS drone SAD / LOITER / RTB; artillery carrier pre-deploy, deploy, pack, clear spot; a medic evac; a tower hack and an intel deposit (3 items, deposit pressed twice); a free-text to HQ; Zeus Call Endex; ZEN respawn; drop kits and build a patrol base; UAV GO TO / ORBIT / RTB / LASE | All work as before. The deposit banks 3 once; a tower hacked again while cooling says "Tower cooling down" and runs no bar | ☐ |
| P23.11b | **[CHEAT]** Other side: `[jmfsb_support_air_entities select 0, "SAD", getPosATL player, []] remoteExecCall ["jmfsb_support_air_fnc_order", 2]`; same idea for `jmfsb_support_fires_fnc_request` / `fnc_abort` and `jmfsb_cas_fnc_request` / `fnc_abort` | Nothing flies or fires, the other side's mission continues; RPT "refused" | ☐ |
| P23.11c | **[CHEAT]** `[someDownedPlayer] remoteExecCall ["jmfsb_evac_fnc_evacServer", 2]` from 500 m | No heal, no clone; "Failed."; RPT "evacServer: refused" | ☐ |
| P23.11d | **[CHEAT]** `[cursorObject, "drone", "none"] remoteExecCall ["jmfsb_hacking_fnc_srvHackComplete", 2]` with no hack run | Nothing deleted; "Intrusion refused" | ☐ |
| P23.11e | **[CHEAT]** `[playerB, "x1", "freetext", [["Text.A","fake"]], ["B:HQ"], "", "", "", [], []] remoteExecCall ["jmfsb_messaging_fnc_srvSubmit", 2]`; `[playerB, "T0001"] remoteExecCall ["jmfsb_messaging_fnc_srvRequestThread", 2]` | Nothing filed in B's name; B's thread not sent; RPT refusals | ☐ |
| P23.11f | **[CHEAT]** `[player] remoteExecCall ["jmfsb_curator_fnc_zeusAssign", 2]`; `[sideUnknown, {diag_log "PWNED"; true}] call jmfsb_respawn_fnc_forceRespawn`; `[player, "x", west] remoteExecCall ["jmfsb_teleport_fnc_addPoint", 2]`; `["X"] remoteExecCall ["jmfsb_patrol_base_fnc_serverBuild", 2]` with no kits | No Zeus, no "PWNED" in the server RPT, no point, no base; RPT refusals | ☐ |
| P23.11g | **[CHEAT]** Without the drone: `["rtb", uav, [getPosATL player, 300]] remoteExecCall ["jmfsb_devices_fnc_uavOrder", 2]`; and `[false,true,false,true] remoteExecCall ["jmfsb_zenmodules_fnc_endexRequest", 2]` as a non-Zeus | The drone ignores it; nobody healed, AI unchanged | ☐ |
| P23.11h | Kill an enemy AI owned by a headless client | The body yields intel | ☐ |

**PAC store and roster (B1-B4, P4)**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.12 | `sync = "service"`, slow or blocked database: join while the boot overlay is up, then restart the server | The profile still holds the full roster; RPT "N connect(s) / disconnect(s) held during the boot, applied now"; you have an open session | ☐ |
| P23.13 | End the mission before the boot finishes | RPT "mission ended before the store was loaded - nothing written"; profile unchanged | ☐ |
| P23.14 | Kill the server process with a player on; restart | His session is closed at its last heartbeat time | ☐ |
| P23.15 | Admin starts a manual op window; restart the server | The window is still open; new joins are filed under it | ☐ |
| P23.16 | A takes a kept loadout, changes gear; B joins | A's gear does not change | ☐ |
| P23.17 | Admin changes A's rank or skills mid-mission | Rank and skills update at once; gear and slot do not | ☐ |
| P23.18 | Two players open their PAC application or ticket list at the same moment | Each sees only his own; RPT shows the requests answered one after the other | ☐ |
| P23.19 | Two admin edits within 30 s, wait 70 s, kill the server | Both edits are in the profile after restart | ☐ |
| P23.20 | Dedicated server with a headless client; TAC//PAC Roster | The HC has no record and no session | ☐ |
| P23.21 | PAC player page KICK not logged in; then after `#login` | "Log in as the server's admin (#login) to kick."; then he is kicked and the log shows it | ☐ |
| P23.22 | currentOpord set; two admins spawn together | One OPORD message in C2 | ☐ |

**Voice (B14, B15, V1-V8; LiveKit egg up)**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.23 | Two players on different nets; A talks on his | B hears nothing; B joins A's net: B hears A at once, in that net's ear | ☐ |
| P23.24 | B leaves a net while A is talking on it | A's voice stops for B within a second | ☐ |
| P23.25 | A walks in from 100 m talking local | B hears him come in at the local range, no lost first words | ☐ |
| P23.26 | Respawn, or a voice-server reconnect, while someone talks | His volume stays as it was, never full | ☐ |
| P23.27 | Microphone disabled in Windows privacy; join | One "No microphone" notice; he still hears the nets | ☐ |
| P23.28 | Plain Caps Lock under LiveKit, check every game channel, again after respawn | Arma's VON never transmits | ☐ |
| P23.29 | Server chose LiveKit; a client without the DLL joins | One VOICE UNAVAILABLE notice; text works; the RADIO app shows NONE: NO NET | ☐ |
| P23.30 | Listener on EMCON 3, then unconscious, while a squad mate talks; then dead | Hears in the first two, cannot talk; dead hears nothing | ☐ |
| P23.31 | Server key and secret settings EMPTY, `JMSB_LIVEKIT_KEY` / `JMSB_LIVEKIT_SECRET` set in the server's environment (the egg's variables); join and ECHO TEST | Join works; the echo is heard. Unset them: one "not set" notice | ☐ |
| P23.32 | Game VON server, client with the DLL | The client runs game VON; no voice-server join | ☐ |
| P23.33 | Under game VON, PTT 2 set to a net you are not on; hold it | "PTT 2: you are not on ... yet - nothing sent", once per press | ☐ |

**Will-break bugs and the rest**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.34 | ACRE night, dedicated: wait 30 s, get in one of our trucks | Two 117F racks; no "Suspending not allowed" in the server RPT | ☐ |
| P23.35 | Two clients: one fires a 40 mm PAB, a 30 mm PROX burst and a Mk380 relay near a drone | One flash, one frag event, one relay each - not one per client | ☐ |
| P23.36 | Mission without ALiVE, QRF module and a `jmfsb_qrf_test` marker | RPT "ALiVE is not loaded - QRF watches jmfsb_qrf markers only"; QRF arms | ☐ |
| P23.37 | Tablet Intel app, recover a file; Support map with no task point | The file pane shows its text; no getDir errors | ☐ |
| P23.38 | Zeus Call Endex unticked with no endex running; then ticked, with a headless client | Only a log line; then players healed and safe, AI on server and HC careless | ☐ |
| P23.39 | Ten players at a boarding point, two trucks of six | Six and four; nobody told he was seated when he was not | ☐ |
| P23.40 | Call a CAS drone that comes out crewless; then a pylon-only airframe | It flies its waypoints and fires; if the store does not fire, the RPT shows the fallback warning | ☐ |
| P23.41 | A player on a deployed mortar while the driver packs | "Pack refused - a player is still on the gun" | ☐ |
| P23.42 | APS setting OFF, RPG at a fitted tank; then ON, RPG and Titan from another client | No intercept; then each dies about 30 m out and is gone on the shooter's screen | ☐ |
| P23.43 | Respawn without ACM | No undefined-variable errors | ☐ |
| P23.44 | `#attendance` as admin on dedicated | Names, not uids, in the server's and the admin's RPT | ☐ |
| P23.45 | Run without the messaging addon, open TAC//MSG | "Messaging is not loaded"; no script error | ☐ |
| P23.46 | Two Boo Boo Bag unpacks pressed quickly; two medics take one casualty's bag at once | One bag used, contents once; exactly one medic gets the bag | ☐ |
| P23.47 | Fire a drone40 relay; the launcher disconnects | Within 5 s the relay is back on DATA, held by nobody | ☐ |
| P23.48 | Zeus supply crate; a player joins in progress | Host and joiner can drag and carry it | ☐ |
| P23.49 | Logged-in admin on dedicated: `#jmfsbreact`, `#jmfsbqrf`, `#jmfsbleaders`; a non-admin the same | Admin gets one line each, alone; the non-admin gets nothing | ☐ |

**TFAR and ACRE removed (DEC1)**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.49a | Server profile or `cba_settings` with the voice system set to `"tfar"`, then `"acre"` | No error; voice runs as Automatic; RPT says it was reset | ☐ |
| P23.49b | Server on LiveKit, a client without the DLL | Net row, HUD radio widget and all three RADIO tabs read VOICE UNAVAILABLE | ☐ |
| P23.49c | A calls B, B accepts, B hangs up; A dials someone out of DATA reach; a callback request expires | Rings, connects, ends; "No route on DATA..."; "A callback request expired." | ☐ |
| P23.49d | **[CHEAT]** `[_otherCallId, B, true] remoteExecCall ["jmfsb_voice_fnc_srvAnswer", 2]` naming another player | Nothing happens | ☐ |
| P23.49e | Vehicle spawn, ZEN Rekit Vehicle, respawn, Back to Game, arsenal; grep the RPT for `adapter_tfar`, `acre_`, `radio_mesh` | No script errors; no radio racks; no Radios arsenal button; no hits | ☐ |
| P23.49f | Field Manual > Radio voice and Radios | No TFAR or ACRE text; "No man packs: the handhelds carry every net" | ☐ |

**Performance (P1-P10)** - with `#jmfsb` diag on, 20+ players or AI with radios

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.50 | Everyone stands still for a minute, then moves | No frame-time spike every 5 s on the server (edge casts staggered, at most 150 a tick); RF links as before | ☐ |
| P23.51 | Ten fitted AI tanks idle, engines on | Server FPS steady; fire an RPG at one: intercepted as before | ☐ |
| P23.52 | Viewshed at 3000 m radius, 20 m resolution | Fills with coarser cells; map stays smooth | ☐ |
| P23.53 | Stand in a heal area unhurt; then get hurt | No banner or heal while unhurt; healed when hurt | ☐ |
| P23.54 | QRF captures twice | No server hitch on the second | ☐ |
| P23.55 | Any load test, Log tick timings on (default) | Once a minute the server RPT has `perf rf.tick: ... avg ... worst ... budget 8 ms, over N` and `perf aps.watch: ...`; note the numbers at 10, 20 and 40 players | ☐ |

**Screens built once (P5, P6)** - each must look exactly as before

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.61 | HUD SQUAD left, SCANNER right, 30 s; cycle every readout (Alt+[ / ]), slots off and on (Shift+[ / ]); move and resize a slot in Layout; change scheme, scales, opacity; a squadmate wounded then healed; open and close the admin console | Same look, no flicker, values change in place; OFF leaves no box; APS tile only in a vehicle; layout and theme changes apply at once; the HUD hides under the console and comes back current | ☐ |
| P23.62 | A live call with the tablet open, then the phone shown; open and close an app; step the corner (numpad 0 / .) | The call window does not flicker, its caption follows the talker, it stays on top in every corner | ☐ |
| P23.63 | Phone / side rows: key a net, mute one, take a ring; change device opacity and side; RADIO app cursor, tabs, group mode | TX red at once; everything reacts as before; no flicker when idle | ☐ |
| P23.64 | TIMER: arm 1 and 2 minute alarms, start the stopwatch, rest the pointer on the page; DEL, START/STOP, RESET with slow presses; let an alarm ring | Clocks tick every second (they used to pause under the pointer); every press lands; RINGING - SILENCE within a second | ☐ |
| P23.65 | EW SCANNER with a drone near; tile band on map and tablet: TIMER tile running, a tile going stale, paging, drag and resize, theme change | Values update in place every 2 s; rows change when a drone enters or leaves 2 km; tiles open on press; outlines switch dashed / solid; redraws correct | ☐ |
| P23.66 | Reader: press nets and fold squads in the rail; TO line, CC @-completion, picker | As before, same targets | ☐ |

**The last event paths (S7, P8)**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.67 | Transport LAND with AI aboard; PARADROP with players and AI; QRF paradrop | AI get out; one man jumps per tick, each on a canopy | ☐ |
| P23.68 | Zeus places a unit; respawn setting off and on, delay changed while dead; ISR LOITER; Zeus teleport point; artillery, cruise missile, loitering munition with a JIP player | Second Zeus can edit it; timers stop and resume and adjust; gunner and notice; point works and goes with its object; shot / splash and the marker for your side only, also for the JIP player | ☐ |
| P23.69 | Two players hack one tower; A closes at 60 %, B resumes | B from 50 %, A from where he was; progress goes out at 25 / 50 / 75 % only | ☐ |
| P23.70 | **[CHEAT]** `jmfsb_teleport_list = [[player,"X",west]]; publicVariable "jmfsb_teleport_list"`; `jmfsb_Mission_Endex = true; publicVariable "jmfsb_Mission_Endex"`; `jmfsb_hacking_banked = 999; publicVariable "jmfsb_hacking_banked"`; `["jmfsb_respawn_disable"] call CBA_fnc_globalEvent`; `[[cursorObject]] remoteExecCall ["jmfsb_curator_fnc_editableAdd",2]` on an object you do not own | The server's values come back; respawn unchanged; nothing added to Zeus | ☐ |
| P23.71 | **[CHECK]** On a client: `<enemy AI> getVariable "jmfsb_ew_gps"` | nil (AI spoof offsets are no longer public) | ☐ |
| P23.72 | Hack a pop, leader product; deliver a cuffed leader to a `jmfsb_prison` marker | Orange SAFE HOUSE circle, then the INTERROGATION icon - your side's map only | ☐ |
| P23.73 | TIMER as the host of a hosted game: arm 1 min, DEL it; as a dedicated client arm 5 min and ALARM AT | Host's DEL removes it, nothing rings; the client's alarms show on every scanner and DEL removes them for all | ☐ |
| P23.74 | Send a FLASH; TIC with TIC broadcast on; a tacpad countdown expires | Banner for the recipient only; your side's red TIC popup; "TIMER Countdown expired" still shows | ☐ |
| P23.75 | WITHDRAWN 2026-11-02 - the JUMPMASTER app is gone; the jump by message is P55 | - | - |
| P23.76 | Disconnect and reconnect (Back to Game); `#jmfsbfire` as non-admin then after `#login` | Teleport dialog, confirm puts you back; nothing, then it runs | ☐ |
| P23.77 | **[CHEAT]** `["jmfsb_messaging_received",[createHashMap,createHashMapFromArray [["priority","high"]]]] call CBA_fnc_globalEvent`; the same with `jmfsb_common_alert`, `jmfsb_cas_offStation`, `jmfsb_jumpmaster_jumpOut`, `jmfsb_support_air_say`, `jmfsb_back_to_game_teleportPlayer`, `jmfsb_qrf_captured`, `jmfsb_hacking_product`; `["X","fake","",2,60] remoteExecCall ["jmfsb_common_fnc_onAlert",0]`; `[otherPlayer] remoteExecCall ["jmfsb_jumpmaster_fnc_srvLaunch",2]` | None has any effect; RPT refusals | ☐ |

**Every client request checked (R1, the rest)**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.78 | Normal play: admin panel heal / Zeus / STABILIZE on another player; artillery deploy and pack; role grant; Heal All at a crate; fire during endex; ALiVE spotting, counter-battery and FRONT lines; spectator on death; radio battery swap and respawn; EW jammer and decoy; chestpack on and off; a jammer disabled by an engineer; `#jmfsbjam` as admin; a failed hack | Every line, effect and screen as before, to the same people | ☐ |
| P23.79 | **[CHEAT]** Raise `jmfsb_notify_post`, `jmfsb_spectator_start`, `jmfsb_adapter_alive_ready`, `jmfsb_reaction_event`, `jmfsb_ew_aiAlert` and the boc `clearAllCargo` event; remoteExec `jmfsb_notify_fnc_notify` to everyone; remoteExec `jmfsb_rf_fnc_srvRequest` "unregister" on another player's node | Nothing happens anywhere; RPT refusals | ☐ |
| P23.80 | **[CHEAT]** `jmfsb_common_debugCommands = createHashMap; publicVariable "jmfsb_common_debugCommands"`, then an admin types `#jmfsb help` | The admin gets the real list; nothing the cheater sent runs | ☐ |
| P23.81 | **[CHEAT]** `[otherPlayer, [0,0], "rifleman"] remoteExecCall ["jmfsb_groups_fnc_assignPlayer", 2]`; `["fake", objNull] remoteExec ["jmfsb_common_fnc_debugReply", otherPlayer]` | He is not moved; no "[jmfsb] fake" line in his chat | ☐ |

**Secrets entered in game (R4)**

| # | Do | Should happen | P/F |
|---|---|---|---|
| P23.56 | `#login`, then `#jmfsb secrets` | A dialog over the console (or the tablet): four rows, each NOT SET or SET ...last four | ☐ |
| P23.57 | LiveKit key and secret settings empty, no environment variables; type the key and secret in the dialog, SET each; ECHO TEST | Rows turn SET ...xxxx, the fields empty; the echo works without a restart | ☐ |
| P23.58 | An empty field, SET | That row NOT SET | ☐ |
| P23.59 | **[CHEAT]** Not logged in: `["livekitSecret", "x"] remoteExecCall ["jmfsb_common_fnc_secretSet", 2]`; `[] remoteExecCall ["jmfsb_common_fnc_secretStatus", 2]` | Refused in the server RPT; no status comes back | ☐ |
| P23.60 | Database string entered in the dialog, settings empty, restart the mission | PAC boots from the database | ☐ |

### P24. Voice without libwebrtc: LiveKit or Mumble (2026-11-01)

The DLL no longer carries Google's WebRTC library: LiveKit runs over pure Rust
WebRTC, and Mumble is built in (extensions/jmsb_voice README). JMSB - Voice >
**Voice system** picks one ("Type" below; Automatic is Mumble). Two Windows
clients with the new `jmsb_voice_x64.dll`, headsets. For Mumble, a Mumble
server (1.4 or later) and Voice server (Mumble) address and password set.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P24.1 | Type LiveKit; run P22.1-P22.6 | Same results as P22 | ☐ |
| P24.2 | Type LiveKit; ECHO TEST | The echo bot plays your words back | ☐ |
| P24.3 | Type Mumble, address and password set; start, read the client RPT and `%LOCALAPPDATA%\Arma 3\jmsb_voice.log` | VOICE "On the voice server."; the log shows `mumble: signed in` and the server certificate's SHA-256 | ☐ |
| P24.4 | Mumble: two players on one net, one talks | The other hears him with the radio effect; a third player off the net hears nothing | ☐ |
| P24.5 | Mumble: local voice, walk apart | Full beside him, fading to nothing at the local range; panned to his side | ☐ |
| P24.6 | Mumble: a phone call between two players | Both hear each other; nobody else does | ☐ |
| P24.7 | Mumble: ECHO TEST | Your words come back (the server's loopback); hanging up ends it | ☐ |
| P24.8 | Mumble: a wrong password | VOICE "Voice: mumble: refused: Invalid server password. Trying again." once | ☐ |
| P24.9 | Mumble: open the Mumble server in the Mumble app as an admin | One channel `mission-...` holding every player, by UID; it is gone when the mission ends | ☐ |
| P24.10 | Mumble: restart the Mumble server mid-mission | VOICE "The voice server dropped you"; voice comes back on its own | ☐ |
| P24.11 | Either type: talk with a fan or keyboard noise near the mic | The noise is mostly gone on the other end (RNNoise) | ☐ |
| P24.12 | Scan the new DLL on VirusTotal | Fewer engines than the old build's (Jiangmin); record the result | ☐ |
| P24.13 | Quit the game after a mission with voice, both types (the DLL pinned, 2026-11-01) | No crash on exit; no new "jmsb_voice_x64.dll_unloaded" Application Error in Event Viewer | ☐ |
| P24.14 | Server with the new `ghostd_pacdb_x64.so` (Linux) or `.dll` (Windows), Database set to the Atlas `mongodb+srv://` string; start, read the server RPT | `pacdb extension: ok 0.7.0 -> mongodb+srv://...@... (direct)`; `service: config ADOPTED` with the counts | ☐ |
| P24.15 | Change a player in PAC, end the mission, start again | The change is still there; the site shows the document with its fields | ☐ |
| P24.16 | Scan the new `ghostd_pacdb_x64.dll` on VirusTotal | No ClamAV or Gridinsoft hit; record the result | ☐ |

### P25. TAC//SUPPORT v2 report deck (2026-11-01)

The support cards are built in (docs/DESIGN_SUPPORT_V2.md sections 8 and 12).
Since 2026-11-02 the mod's own card always wins: nothing is run against the
database (P64 tests the rule). The 9-line rows went with the card
(`nineline` retired, 2026-11-02).

| # | Do | Should happen | P/F |
|---|---|---|---|
| P25.5 | Start a mission, read the server RPT | No "registered twice" and no "has no REMARKS line" for bda, hlz or airdrop | ☐ |
| P25.6 | TAC//MSG > NEW | BATTLE DAMAGE ASSESSMENT in the list; no CAS 9-LINE | ☐ |
| P25.7 | Open LIFT REQUEST (HLZ) and PARADROP | LIFT REQUEST has WIND and OBSTACLES above REMARKS; PARADROP has LOAD | ☐ |
| P25.8 | File a CALL FOR FIRE to yourself, `#jmfsb msg.reply <id>` until it is ACCEPTED (or reply WILCO), then open its reply list | ADJUST FIRE, FIRE FOR EFFECT, REPEAT, CHECK FIRE, CLEARED HOT offered; ADJUST refuses without a direction and a distance | ☐ |
| P25.9 | Reply ADJUST (LEFT 50), then REPEAT, then FFE | `#jmfsb msg.threads`: the thread stays ACCEPTED after ADJUST and REPEAT, IN_PROGRESS after FFE; the three replies on the spine in order | ☐ |
| P25.10 | On a thread still ISSUED, open the reply list | CHECK FIRE offered; ADJUST, FFE, REPEAT and CLEARED HOT not | ☐ |
| P25.11 | PAC admin > Templates > Report deck > CALL FOR FIRE | "Danger close (m, 0 = none)" reads 600; set 500, SAVE, reopen: 500 | ☐ |

### P26. Support reach (2026-11-01)

`jmfsb_support_fnc_reach` (docs/DESIGN_SUPPORT_V2.md section 6). Mission with
one Virtual Artillery battery (note its Maximum Range), one CAS drone module
and one support_air Transport module, all on the player's side. Markers `near`
(inside the battery's range, outside its minimum) and `far` (beyond its
maximum). Debug console, local exec, result in the watch line.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P26.1 | `[getMarkerPos "near", []] call jmfsb_support_fnc_reach` | One row per asset TAC//SUPPORT lists; each `[id, true, eta, "", effect, tasks]`; the battery's effect like `4 GUNS - HE 24 RDS - ...`, tasks `["FFE"]`; rows in ETA order, smallest first | ☐ |
| P26.2 | `[getMarkerPos "far", []] call jmfsb_support_fnc_reach` | The battery row `[id, false, -1, "OUT OF RANGE x/y KM", effect, []]` with y its maximum; it is last, after the air rows that can | ☐ |
| P26.3 | `[getMarkerPos "near", ["arty"]] call jmfsb_support_fnc_reach` | Only the battery row | ☐ |
| P26.4 | Fire a mission with the battery, run P26.1 while it fires | Battery row `false`, why `TASKED`, after every row that can | ☐ |
| P26.5 | Run P26.1 while the battery rearms after the mission | Battery row why `COOLDOWN n S`, n counting down between calls | ☐ |
| P26.6 | Transport row with HELOCAST allowed: a point on land, then one on water | HELOCAST missing from tasks on land, present on water; the ETA grows with distance from the helipad | ☐ |
| P26.7 | With ALiVE combat support placed, P26.1 | ALiVE rows: can true when idle, eta -1, all their tasks, after the rows with an ETA; busy ones `TASKED` | Withdrawn 2026-11-02: ALiVE support provider removed |
| P26.8 | `[[], []] call jmfsb_support_fnc_reach` | `[]`, no RPT error | ☐ |

### P27. Support threads: the asset answers (2026-11-01)

Step 2 of docs/DESIGN_SUPPORT_V2.md (section 9, decision D6). Mission with one
Virtual Artillery battery, one CAS drone module and one support_air CAS
module, all on the player's side; the report deck from P25. Find the asset ids
with `[] call jmfsb_support_fnc_assets` (debug console, local exec) - field 0
of each row, e.g. `fires:1`. Server RPT open.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P27.1 | TAC//MSG > NEW > CALL FOR FIRE, addressed to `B:SUPPORT:fires:1` (or debug console: `["callforfire", <answers>, ["B:SUPPORT:fires:1"]] call jmfsb_messaging_fnc_submit`) | The thread appears; within a frame a ROGER-equivalent reply arrives in it, unread with a notification, from the battery's call sign; `#jmfsb msg.threads` shows it RECEIPT; RPT `thread T....: fires:1's open thread` | ☐ |
| P27.2 | Task the battery on TAC//SUPPORT (the current screen) | WILCO-equivalent arrives as the battery (its text field carries the verdict line, if the card has one), then ON TASK; `msg.threads`: ACCEPTED, then IN_PROGRESS | Withdrawn 2026-11-01: TAC//SUPPORT app removed |
| P27.3 | Wait for the mission to finish | CLOSE arrives as the battery with "rounds complete, over" in its text field; the thread is CLOSED | ☐ |
| P27.4 | File a new thread to the battery, task it, then RTB (CHECK FIRE) at once | ROGER, WILCO, ON TASK, then CLOSE with "check fire - rounds in the air will still land" | ☐ |
| P27.5 | File to the battery, then task it on a point out of range | ROGER, then a CANTCO-equivalent with the refusal ("out of range ...") as the battery; the thread is DECLINED | ☐ |
| P27.6 | File to `B:SUPPORT:cas:<n>` (CAS drone), task a strike | ROGER, WILCO when the server takes it, ON TASK "in hot - <grid>" at the release, CLOSE "run complete" after egress | ☐ |
| P27.7 | Same, but RTB the drone before it releases | CANTCO "off task - leaving the area" (it never flew the task) | ☐ |
| P27.8 | File to the support_air CAS asset, task it | ROGER, WILCO, ON TASK at launch ("airborne"), CLOSE when the sortie is over | ☐ |
| P27.9 | Same, and shoot the aircraft down in flight | CLOSE with "is down at <grid> - ..." and no second CLOSE when the sortie ends | ☐ |
| P27.10 | Task an asset nobody filed a thread to | Nothing filed anywhere; no RPT line about threads | ☐ |
| P27.11 | File a plain message (FREE TEXT) to `B:SUPPORT:fires:1` | No ROGER (a plain message is OPEN, no RECEIPT card is allowed from it); RPT `not filed - no RECEIPT card may be sent while the thread is OPEN` | ☐ |
| P27.12 | File to `B:SUPPORT:nosuch:1` | No reply; RPT `no support provider answers for that id` | ☐ |
| P27.13 | Dedicated server: a client files to the battery and tasks it | The replies arrive under the battery's call sign, not `FIRES:1` | ☐ |
| P27.14 | Dedicated server: client A files to the battery, client B tasks it | Known limit: what the server says inside B's request (ON TASK) is held to B's own threads - RPT `srvReply: fires:1 IN_PROGRESS refused - <B's uid> did not issue that thread`; CLOSE still arrives in A's thread at the end | ☐ |
| P27.15 | support_air transport (class, e.g. the Tanoa Ghost Hawk) on an ORBIT; let it fly the whole orbit (fix 2026-11-01, built, not seen in game) | It orbits until the next order; no `cannot fly` line in the RPT | ☐ |
| P27.16 | Same, then shoot its tail rotor or kill the pilot (Zeus) | RPT `RAVEN transport cannot fly - <test> (<damage, hit points, fuel, engine, height, speed, crew, last hit by ...>) - written off in 10 s unless it recovers`, then 10 s later `sortie written off: ...` and `lost '<class>' to '<what hit it>'`; the thread CLOSED with "is down at <grid>" | ☐ |
| P27.17 | Same, but heal / repair it (Zeus) inside the 10 s | RPT `RAVEN transport can fly again - not written off`; the sortie goes on | ☐ |

### P28. Tablet review: the shell (2026-11-01)

docs/DESIGN_TABLET_REVIEW.md 2.2, 2.5, 2.6, 2.7, 3.2. Display mode TABLET,
large tablet open (numpad Enter), JMSB Night. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P28.1 | Addon Options: Panel opacity 0.3. Open WEATHER, TIMER, JAMMER, then every other tile's app | No map, contour or label shows through any app body; the panels (squad rail, reader) are still see-through at 0.3 | ☐ |
| P28.2 | Look at the frame keys, then hover each (R3 changed by the user, 2026-11-01) | No caps: the frame's printed F1-F4 and arrows show. Hover names the bind - "F1 (NUM 6): ..." .. "F4 (NUM 9): ...", the arrows "... (NUM 0)" / "... (NUM .)" by default | ☐ |
| P28.3 | Configure Addons: rebind Device button F1 to Ctrl + numpad 1, reopen the tablet | Key 1's tooltip reads "F1 (CTRL+NUM 1): ..."; the printed F1 is unchanged; clicking the key still opens its app | ☐ |
| P28.4 | Same with the UAV tablet, the vehicle tablet and the RDC frame | Every frame's six keys show their art and the bind on hover; nothing drawn over the keys | ☐ |
| P28.5 | Addon Options > JMSB - Tablet & Map > Devices | The four soft-key settings read "Device key 1 opens" .. "Device key 4 opens" | ☐ |
| P28.6 | Leave every voice net (or a mission with no comm plan net) | Net row the same height and place as with nets: six cells, the first dim reading NO NET, the rest dim outlines; join a net - the row does not change shape | ☐ |
| P28.7 | Client with `jmfsb_voice_system` "none" | Net row reads VOICE UNAVAILABLE across it, as before | ☐ |
| P28.8 | With a hacking scanner, bring a drone inside 1 km | DRONES tile kicker reads DRONES whole; the tile is the accent block (the accent fill, words in the ground colour, the KM badge ground with accent text) - no fixed red on JMSB Night | ☐ |
| P28.9 | Make another tile alert (TIMER expiry, unread FLASH) | Same accent block; amber warn and green ok tiles unchanged | ☐ |
| P28.10 | Display mode Native: PAC tile on the map's band with no OPORD | Kicker the same size as the other tiles'; detail reads NO OPORD with no trailing " -" | ☐ |
| P28.11 | Device grid digits 10; artillery team with a radar fix; a LOG entry with a position in the docked reader | ARTY tile value and the LOG entry's grid both 10 figures, like the header | ☐ |
| P28.12 | Off every net, RADIO tile; docked reader with one net; a thread with one reply | "0 NETS" / "1 NET", header "1 NET", row "1 REPLY" - plural only when the count is not one | ☐ |
| P28.13 | Squad rail with one man, then eight, then twelve (user, 2026-11-01) | One man: the rail is already eight rows tall + legend + REFRESH; at eight the rows fill it; past eight it grows a row per man, never past its fixed place; no scrollbar, the rows run the full width; the vanilla map's rail keeps its placed height | ☐ |
| P28.14 | MAP TOOLS at rest (R5 reversed by the user, 2026-11-01) | The full grid of buttons: CENTRE RULER PROTRACTOR ROUTE / MARK GRID VIEWSHED RINGS / LOS CLEAR, GRID REF box, GO TO GRID - on the tablet and the vanilla map; no one-row strip | ☐ |
| P28.15 | Press RULER, then CANCEL; type in the grid box | RULER fills while it runs, CANCEL RULER on the title bar stops it; the box is outlined like its neighbours and reads GRID REF until something is typed - no empty cell | ☐ |
| P28.16 | Walking view on the phone, then a side device (user, 2026-11-01) | Status strip: MESH, JAM, BATT, DRONES, MSG - no GPS cell; on the phone's one row the five words are evenly spaced across the strip, the same air between each and at both ends | ☐ |
| P28.17 | Tablet tile row; then MENU (user, 2026-11-01) | No SUPPORT tile and no PAC tile; SETTINGS > LIVE TILES offers neither. MENU still lists SUPPORT and PAC, and each opens its app | ☐ |
| P28.18 | Tablet top bar; press PAC | Reads ... UAV TABLET (or TABLET)  MENU  PAC  ESC CLOSES - the device name and MENU moved left, PAC in the accent between MENU and ESC CLOSES, nothing overlapping or wrapping. PAC opens the PAC app the old tile opened; MENU still opens the menu | ☐ |
| P28.19 | Display mode Native, open the map | The band has no SUPPORT tile; the PAC tile is still there and opens the PAC app | ☐ |
| P28.20 | Mute net 2 (Ctrl + numpad 2), then make it the active net, then unmute | The C2 chip in the tablet's net row gets a red diagonal line from bottom left to top right and its name dims - also while it is the active (light) cell; unmuted, the line goes and the name is back | ☐ |
| P28.21 | A mission with a database boot (the TAC//PAC INITIALISING THE UNIT overlay) | The document grid runs wider than the step list above it, near the screen's edges, three rows of ten; "arsenal versions 8/8" and "roles 36/36" each on one line; the "documents landed" line starts under the grid's left edge | ☐ |

### P29. Tablet review: key/values, WEATHER, DRONES, JAMMER, TIMER (2026-11-01)

docs/DESIGN_TABLET_REVIEW.md 2.4, 3.3-3.7; decisions R1, R2, R6, R7. Large
tablet, JMSB Night, text size 1. A UAV operator with a drone up on his side
(one with a designator) and, on the same side, a NASAMS (or any AD vehicle
jmfsb_adsite registers) and a radar with no weapon. A scanner in the kit; an
enemy drone 1.5 km out. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P29.1 | Open WEATHER | Hero: glyph, condition word, a DAY or NIGHT chip beside the word, the detail line untracked; ROTARY and THERMAL straight under it; then two columns - CLOUD COVER, RAIN, FOG, WIND, WIND STATE, VISIBILITY left; LOCAL TIME, FIRST LIGHT, LAST LIGHT, MOON, DATE right | ☐ |
| P29.2 | Read LOCAL TIME against the game clock | HH:MM (e.g. 14:05), never DAY or NIGHT; FIRST and LAST LIGHT also HH:MM | ☐ |
| P29.3 | Every key/value list (WEATHER both columns and the verdicts, DRONES > ENEMY, JAMMER's TRANSMITTER / POWER SYSTEM) | Each value starts within 40 px of its own label's end, the shortest label included (labels are right-aligned against the value column); values in the monospace, no smaller than a tile's detail line | ☐ |
| P29.4 | WEATHER at text size 2.4, then the opacity setting at its lowest | The page grows to fit; no list row clipped or smaller than at 1; no map through the page | ☐ |
| P29.5 | DRONES > FLEET (R6 reversed by the user, 2026-11-01) | The drone, the NASAMS / AD vehicle and the radar are all listed - every live UAV-crewed vehicle of the side | ☐ |
| P29.6 | Stand out of RF reach of every drone (or turn the RF core off) | One line "No drone in data link range"; rows show DRONE and BATT only, with the task line; no NO RF / empty bar / dash columns | ☐ |
| P29.7 | Back in reach | LINK, QUALITY and BATT columns return | ☐ |
| P29.8 | Pick a row | The picked row is an ink fill with ground-coloured text; its quality bar and number still read | ☐ |
| P29.9 | As a man without the UAV operator trait | CONNECT drawn dead; under the button row, at body size: "Only the UAV operator flies drones."; nothing written over the picture's bottom strip | ☐ |
| P29.10 | Look at the tab row and the FEED header | "CONTROL NEEDS DATA LINK" only in the FEED header | ☐ |
| P29.11 | DRONES > ENEMY with the contact up | Scope: you as a square in the centre, N above, a dotted ring at 1 KM and 2 KM, the cross; the contact at its bearing and range in amber (red inside 1 km) with its airframe beside it, on the side away from the edge; BEARING, RANGE, GRID, AIRFRAME beside the scope | ☐ |
| P29.12 | Device grid digits 8, then 10 | ENEMY's GRID 8 figures, then 10 | ☐ |
| P29.13 | ENEMY with nothing up | Scope with rings and you, "Nothing unmanned and hostile heard." beside it | ☐ |
| P29.14 | JAMMER as a man with no jammer (EW loaded) | "NO JAMMER" once, in the title area, with "Crew a vehicle with an EW jammer module in its cargo" under it; no NETWORK line when the side has none; no footer | ☐ |
| P29.15 | JAMMER, spectrum | The chart spans the right column's full width, about twice its old height; the legend is one row of four under it | ☐ |
| P29.16 | JAMMER crewing a jammer vehicle | TRANSMITTER and POWER SYSTEM as two key/value lists; the footer with device id and figures, untracked; "DECOYS - n OF 2 OUT" untracked | ☐ |
| P29.17 | Open TIMER (the old timer, cleaner - user, 2026-11-01) | Three headings: ARMED ALARMS, SET AN ALARM, STOPWATCH, a rule between each; labels right-aligned in one column, values and keys from one column beside it; no IN / AT toggle; every key the same height; values and key words not spaced out | ☐ |
| P29.18 | Press ARM IN 5 MIN | One alarm armed for 05:00 at once, soonest-first in the roster with DEL #n; the quick keys are filled, the -/+ keys outlined | ☐ |
| P29.19 | CUSTOM: press -1, +10, +60 from 15:00 | CUSTOM reads 14:00, 24:00, 1:24:00; never under 01:00; nothing armed until ARM IN 1:24:00 is pressed, which arms it | ☐ |
| P29.20 | ALARM AT: step to a time 2 h of game time ahead on a 6x mission; -1H, +1H across midnight | The key reads "ARM AT hh:mm - IN 0:20:00"-ish, counting down while the page is open; 23:50 +10 is 00:00; the key arms that | ☐ |
| P29.21 | Arm three alarms; let one ring | Rows soonest first, countdown right-aligned in the label column, "#n hh:mm NAME" beside it; red inside 30 s, amber inside 2 min; RINGING - SILENCE on the ARMED ALARMS line silences it | ☐ |
| P29.22 | Stopwatch START, wait, STOP, RESET | READY / RUNNING / HELD beside the big readout; START reads STOP while running; the readout runs, holds, returns to 00:00 | ☐ |

### P30. Tablet review: developer text, tracking, TAC//MSG, RADIO (2026-11-01)

docs/DESIGN_TABLET_REVIEW.md 2.1, 2.3, 3.1, 3.8-3.10; decisions R1, R8. Large
tablet, JMSB Night, text size 1. A squad leader with a long call sign
(BANSHEE 1-1 VANILLA), a radio in the radio slot, a mission whose nets
include FIRES with cas / arty / trans sub-nets. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P30.1 | Open TAC//MSG | Under TAC//MSG the group call sign only, not spaced out, no " - TASK_FOR..." | ☐ |
| P30.2 | Look at the net list | No three-letter code column; FIRES then cas, arty, trans indented under it | ☐ |
| P30.3 | Pick a net with no traffic | List: "No traffic on <net>"; right pane empty (no NOTHING ON THIS NET, no composer) | ☐ |
| P30.4 | Pick ALL with traffic | Conversation drawn; no SEND TO / REPLY ON row, no quick replies, no + TEMPLATE / + MESSAGE | ☐ |
| P30.5 | Pick a net with an open thread | REPLY ON <net> and only the quick replies that thread takes; no + TEMPLATE / + MESSAGE; NEW at the top still opens compose | ☐ |
| P30.6 | Open a CLOSED thread, then an OPEN one | Closed: no quick tiles; open: only the tiles it takes, none dim; + TEMPLATE under the thread | ☐ |
| P30.7 | + GRID with device grid digits 8, then 10 | 8, then 10 figures in the box | ☐ |
| P30.8 | Compose; look at the TAG chips and the sender lines, times and counts in the list and thread | Call signs, times and counts not letter-spaced; "1 REPLY", "1 MESSAGE" | ☐ |
| P30.9 | Voice system Game VON (fallback); RADIO > CALLS | Strip CALL 1-8 only; FIXED NETS C2 on custom 1 · A2G on custom 2 under it; header "n / 8 IN USE"; tab note "8 CALLS AT ONCE, UP TO 8 PEOPLE EACH"; footer and CALLBACKS lines with no "not built" | ☐ |
| P30.9a | Voice system Mumble (then LiveKit), extension loaded; RADIO > CALLS with no call (user, 2026-11-01: no limit to the number of calls) | No strip and no FIXED NETS line; ALL CALLS panel, header "0 CALLS", "No calls on the server."; tab note "ANY NUMBER OF CALLS, UP TO 8 PEOPLE EACH" | ☐ |
| P30.9b | Same, one call ringing, then answered; then a second call | "1 CALL", row CALL 1 · RINGING · 1 MEMBER, then LIVE · 2 MEMBERS; then "2 CALLS", two rows | ☐ |
| P30.9c | Same, 10 pairs of players (or a 20-player test session) each dial at once | Every call rings and goes live, CALL 9 and CALL 10 too - none BUSY; RPT `call slot 9 added`, `call slot 10 added`; "10 CALLS", the list scrolls; scrolled down, it stays put while the calls tick | ☐ |
| P30.9d | Same, a callback pending with 8+ calls up, both then in reach | Both phones ring - no wait for a slot | ☐ |
| P30.10 | RADIO > NETS with no radio | "You carry no radio set." and what to do | ☐ |
| P30.11 | Unbind Troops In Contact in Configure Addons; RADIO > NETS | Top line "TROOPS IN CONTACT has no key · bind it in Configure Addons" in the accent | ☐ |
| P30.12 | NETS right column: press KEYS, then SOUNDS | Each takes the whole column; KEYS shows every row and the walking-view keys, none cut off; no NOT BUILT row in SOUNDS | ☐ |
| P30.13 | RADIO > MANAGE as SL | WHO CAN: every cell an ink square or a dash; MEMBERS reads "Pick a net on the left to see and edit its members." until a net is pressed | ☐ |
| P30.14 | MANAGE as RTO, ADD NET | Squad chips untracked, each sized to its call sign, none overflowing | ☐ |
| P30.15 | Save a loadout in TAC//PAC | Notice "Loadout kept for <role name> (n of m)", not the class name | ☐ |
| P30.16 | Small device RADIO > MANAGE; VAD key with no game voice adapter | No NOT BUILT header; notice names no addon | ☐ |
| P30.17 | Docked reader on the tablet map, nets ALL and your squad (user, 2026-11-01: "kind of squished") | Chips read ALL and GHOST 1, not letter-spaced, each as wide as its word, with air round them and under the strip; a thread entry's three lines (chip + type + time, subject, reply count) each a full row, none overlapping the rule under the chips; time and counts not letter-spaced; a quiet net reads "No traffic on <net>" ("No traffic on any net" on ALL) in the dim tone; the panel's place unchanged | ☐ |

### P31. Logistics: catalog, airdrop, sling (2026-11-01)

`addons/support_logistics` (README). Mission: one JMSB - Logistics module
(blank class: the side's Huron-type heavy helicopter; Capacity 4; Spawn
Distance 0; Response Delay 10; PAC Arsenal Lists `magazines`), synced to one
JMSB - Logistics Catalog whose area holds an empty Hunter, a quad bike and a
`B_supplyCrate_F` emptied in Eden and given 5 first aid kits. A second
mission: one old JMSB - Logistics Drop saved before this build. Server RPT
open; asset ids from `[] call jmfsb_support_fnc_assets` (field 0, `logi:0`).

Rows that order on TAC//SUPPORT (P31.2-P31.10, P31.16, the LOGISTICS tab in P31.19): withdrawn 2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING (P44 orders resupply by message).

| # | Do | Should happen | P/F |
|---|---|---|---|
| P31.1 | Start; read the server RPT; look at the catalog area | `catalog at ...: 3 items from 3 objects`; `logistics asset 'MULE' on the board ... ["AIRDROP","SLING"], 4 items`; the three objects are gone from the area | ☐ |
| P31.2 | TAC//SUPPORT, LOGISTICS tab | MULE listed; tasks AIRDROP and SLING LOAD; ITEM steps through the four names (HUNTER, QUAD BIKE, the crate, CRATE - MAGAZINES); COUNT 1-4 | ☐ |
| P31.3 | SLING LOAD picked, step ITEM | Only what the hook lifts (the Hunter is skipped if it is heavier than the helicopter's sling rating) | ☐ |
| P31.4 | AIRDROP, ITEM the crate, COUNT 1, click a point | Verdict `ETA ... - 1 x <CRATE> (1/4) - 2 DELIVERIES LEFT`; CONFIRM; after the delay the helicopter comes from the module, the crate leaves under a chute short of the point, blue smoke on landing; the crate holds exactly the 5 first aid kits | ☐ |
| P31.5 | AIRDROP, ITEM HUNTER, COUNT 2 | Two Hunters out a second apart under chutes, land upright and drivable, painted as placed | ☐ |
| P31.6 | Set Chute Opens At 150; airdrop the quad bike from DROP HEIGHT 400 M | It falls free and its chute opens near 150 m | ☐ |
| P31.7 | SLING LOAD, ITEM QUAD BIKE, COUNT 2 | Two helicopters side by side, each with a quad on the hook; each comes down to 12 m over its own spot 60 m apart and lets go; both marked | ☐ |
| P31.8 | SLING LOAD of the Hunter (an airframe that can lift it, e.g. `B_Heli_Transport_03_F`) | It arrives on the hook and is set down undamaged | ☐ |
| P31.9 | Touch any stepper, then put a cart of 5 in slot 49 (debug console: `jmfsb_tacpad_apps_supportParams set [49, [[0, 3], [1, 2]]]`) and redraw | Verdict refused: `MULE TAKES 4 AT MOST - 5 ORDERED`; CONFIRM held | ☐ |
| P31.10 | Sling Fulfillment "One helicopter": SLING LOAD | COUNT stops at 1 | ☐ |
| P31.11 | Order, then RTB before the delay is up | `stood down`; the delivery is given back (sitrep count unchanged) | ☐ |
| P31.12 | Airdrop 3 crates, RTB as the first leaves | `recalled - leaving with what is still aboard`; the asset says `delivered 1 of 3 ... - recalled` | ☐ |
| P31.13 | Shoot the sling helicopter down on the way in | Its load is not delivered; `is down at ... - replacement in 300 sec`; the row reads REPLACING, then idle | ☐ |
| P31.14 | After a delivery of 2 items | Cooldown = Cooldown + 2 x Item Cooldown (sitrep `turning round - n s`) | ☐ |
| P31.15 | Spawn Distance 5000: an airdrop | The aircraft appears ~5 km out on the module's side, flies straight over and is removed ~5 km past; the reach card ETA counts the 5 km leg | ☐ |
| P31.16 | File `["resupply", <answers>, ["B:SUPPORT:logi:0"]] call jmfsb_messaging_fnc_submit` (deck from P25 with the resupply card), then order on TAC//SUPPORT | ROGER; WILCO; ON TASK `airborne with ..., inbound <grid>`; CLOSE `delivered ... at <grid>` when the last item is down; the thread CLOSED | ☐ |
| P31.17 | Same, but RTB before launch | CANTCO `stood down`; the thread DECLINED | ☐ |
| P31.18 | Same, and shoot the airdrop aircraft down before the point | CLOSE `nothing delivered - aircraft lost at <grid>` | ☐ |
| P31.19 | Old mission with JMSB - Logistics Drop (Method Parachute, Drops 3) | Loads with no missing-class error; RPT `... is an old Logistics Drop - read as JMSB - Logistics`; LOGISTICS tab lists it as `logi:<n>` with AIRDROP only, COUNT 1, ITEM over its PAC loads; a drop flies from the module as before | ☐ |
| P31.20 | Old module set to Sling with a fixed-wing class | RPT `has no cargo hook - SLING LOAD not offered` and `can fly none of the methods ticked - it airdrops`; AIRDROP offered | ☐ |
| P31.21 | Eden: Systems > Modules > JMSB Modules | JMSB - Logistics and JMSB - Logistics Catalog listed; JMSB - Logistics Drop is not; an old placed one still opens its attributes | ☐ |
| P31.22 | TAC//MSG > NEW | RESUPPLY REQUEST: Item 1-4 (Item 1 and its count required), DELIVERY POINT (map click, required), METHOD AIRDROP/SLING (required), MARKING, REMARKS | ☐ |

### P32. TAC//SUPPORT v2: the map-first board (2026-11-01)

Withdrawn 2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING.

docs/DESIGN_SUPPORT_V2.md sections 3 and 11, build step 4. Mission: a
support_fires battery, a support_air transport (helicopter) and CAS, a CAS
drone module, the P31 logistics module, a friendly AI squad placed 400 m from
a target area. The built-in cards (callforfire with dangerClose 600, bda,
resupply). Native host first, then the
tablet. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P32.1 | Open TAC//SUPPORT | The board: header with the input legend and CLOSE, chips ALL n and one per type with its count, IN FLIGHT / QUEUED / READY on the left, the map, the order bar "Click the map for a target" | ☐ |
| P32.2 | Addon Options > TAC//SUPPORT > Support screen: Form; reopen | The old form opens; set back to Board, reopen: the board | ☐ |
| P32.3 | Click a point on the map | Target marked with its grid; the reach card beside it lists every asset; the first that can is tagged BEST FIT, each with ETA, kind, effect and task buttons; out-of-range assets one dim line each with the reason (e.g. OUT OF RANGE 14/12 KM) | ☐ |
| P32.4 | RPT while clicking, panning and hovering | One `supportBoard: map target` line per click; reach is not asked on hover, pan or redraw | ☐ |
| P32.5 | Press chip ARTILLERY, then ALL | Card, READY and IN FLIGHT show only artillery, then everything; the board stays one board | ☐ |
| P32.6 | Pointer over a READY battery row | Its range rings on the map; pointer off, they go | ☐ |
| P32.7 | Shift-click two points | QUEUED 2; numbered outline diamonds 1 and 2 on the map; press row 2: it becomes the target (card asks again), the old target takes slot 2 | ☐ |
| P32.8 | On the card press a transport's LIFT | Card closes; bar "RAVEN will PICKUP > LZ on <grid>", steppers, status "LZ - RIGHT-CLICK THE MAP", SEND dim | ☐ |
| P32.9 | Alt-click twice, right-click once | VIA legs drawn into the target; the LZ arrow out of it; status shows the verdict; SEND live | ☐ |
| P32.10 | SEND | `#jmfsb msg.threads` shows a thread with template hlz in box B:SUPPORT:air:n, Line1.A the target; the aircraft is tasked; IN FLIGHT card: call sign, ISSUED/ROGER, task, grid, SITREP line | ☐ |
| P32.11 | Wait | IN FLIGHT moves to WILCO, ON TASK, then CLOSED (one line + BDA) with the thread's replies | ☐ |
| P32.12 | On the card press a battery's task (callforfire needs a description) | The old form opens on that battery, task and target, with "<battery> <task> - confirm tasking here" | ☐ |
| P32.13 | CAS task on the card | The form opens likewise (cas needs a target description) | ☐ |
| P32.14 | Logistics: a deck whose resupply makes only the location and method required, AIRDROP on the card, SEND | Thread `resupply` with Location.A the target and Method.A AIRDROP | ☐ |
| P32.15 | Target 200 m from the friendly squad, a task that sends from the bar on an asset whose card has dangerClose (or arty / CAS) | Status line red: DANGER CLOSE · <NAME> <n> M; SEND reads SEND · DANGER CLOSE; first press: CONFIRM · DANGER CLOSE and nothing sent; second within 5 s sends; waiting 5 s puts the label back | ☐ |
| P32.16 | ABORT (RTB) on an IN FLIGHT card | First press: CONFIRM RTB; second within 3 s: RTB ordered | ☐ |
| P32.17 | BDA on a finished mission with a CAS drone idle | `#jmfsb msg.threads`: a bda thread in B:SUPPORT:cas:n, Target.A the mission's point; with no drone on the mission the button is dead and reads NO DRONE | ☐ |
| P32.18 | Press READY on an asset with no target set | Bar: "<asset> - pick a task" with its tasks as buttons; press one: "<asset> will <task> - click the map for the target"; click: the sentence takes the grid | ☐ |
| P32.19 | Tablet: open support, click the map several times | Each click moves the target; the board never closes; ESC closes the board and leaves the tablet up | ☐ |
| P32.20 | Native: ESC | The board's dialog closes; the map is back with its panels | ☐ |
| P32.21 | Open the form from the board (P32.12), CLOSE, reopen | The board again | ☐ |
| P32.22 | Transport out on an ORBIT; IN FLIGHT ABORT (RTB) twice within 3 s, pressing the label and then the button's edge on separate runs (fix 2026-11-01, built, not seen in game) | Second press: "RTB ordered."; RPT `request: asset 'air:n' task 'rtb'`, `order: RAVEN rtb`, `say: RAVEN returning to base`; the helicopter flies home and lands | ☐ |
| P32.23 | Repeat P32.22 for the support_air CAS, the CAS drone, a battery firing (check fire), the logistics drop in flight (the ALiVE CAS withdrawn 2026-11-02: ALiVE support provider removed) | Each: RPT `request: ... task 'rtb'` and that provider's recall line (`off station`, `recalled`, `check fire`, `abort`) | ☐ |
| P32.24 | ABORT once, then press anywhere else on the board (or wait 3 s) | Label back to ABORT (RTB); nothing sent | ☐ |
| P32.25 | CAS screen ABORT twice (P33) | As P32.22 for the CAS asset | ☐ |

### P33. TAC//SUPPORT v2: the CAS screen (2026-11-01)

Withdrawn 2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING.

docs/DESIGN_SUPPORT_V2.md sections 4, 4.1, 7 and 11, build step 5. Mission: the
P32 mission (support_air CAS and a CAS drone module, a friendly AI squad
placed 250 m from a target area), two player markers near the target, the
built-in cards (`clearedhot`; `nineline` retired 2026-11-02). Native
host first, then the tablet. P32.13 now opens the CAS screen, not the form.
Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P33.1 | Click the target, press a CAS asset's task on the reach card | The CAS screen: header CAS · CARD CAS · THREAD -, BACK, CLOSE; steps DRAFT lit; the card's rows Line 1 to Remarks; the map on the right; the order bar with SEND dim | ☐ |
| P33.2 | Look at Line 1 | The target's grid, FROM MAP, no accent edge | ☐ |
| P33.3 | Look at Line 2 and Line 6 | Line 2 offers the nearest marker `NAME (MARKER)` with USE; Line 6 offers `250 M (BFT)` with USE and DANGER CLOSE (BFT) outlined in the accent; both have the accent edge; nothing of them is in the card yet | ☐ |
| P33.4 | Alt-click twice | Line 3 then Line 4 fill (MAP); ingress and egress legs drawn into and out of the target | ☐ |
| P33.5 | SEND with Line 5 empty | Nothing sent; status names `LINE 5 TARGET DESCRIPTION - TYPE IT` (or the first offer still open) | ☐ |
| P33.6 | Type a description into Line 5; wait 5 s while typing | Focus stays in the box; no redraw takes it | ☐ |
| P33.7 | USE on Line 2 and Line 6, press DANGER CLOSE | Values in the rows, FROM MARKER / BFT; accent edges gone | ☐ |
| P33.8 | Press DANGER CLOSE again | Stays ticked; status `Danger close stays ticked - type a distance outside it` | ☐ |
| P33.9 | Type 800 in Line 6's box | DANGER CLOSE can be cleared now | ☐ |
| P33.10 | Line 7: press LASER while a squad mate lases the target with an ACE designator (code 1688) | The code row offers `1688 (BFT)`; the map draws a line from him to the spot labelled LASE 1688 | ☐ |
| P33.11 | Optional: press a store button | The store's name in the row, FROM STORES; pressed again clears | ☐ |
| P33.12 | Map | Target diamond, L1 grid under it, L2 marker over it; ring DANGER CLOSE <n> M naming the friendly; a line to the friendly with L6 <NAME> <n> M | ☐ |
| P33.13 | SEND (two presses when danger close) | `#jmfsb msg.threads`: a `cas` thread in B:SUPPORT:<id> with Line1.A the target, Line2.A the marker, Line5.A the text, Line6.A the number, Line6.B true; the asset is tasked; the header shows THREAD Txxxx; rows read only; bar `<call sign> · CAS REQUEST · Txxxx · ROGER` | ☐ |
| P33.14 | Wait for the replies | Steps move ISSUED, WILCO, ON TASK; the thread log under the rows lists ROGER, WILCO, ON TASK with call sign and time | ☐ |
| P33.15 | CLEARED HOT before WILCO | Dead, line `Cleared hot once the asset says WILCO` | ☐ |
| P33.16 | CLEARED HOT after WILCO | A CLEARED HOT message in the log; the thread keeps its state | ☐ |
| P33.17 | ABORT (RTB) | First press CONFIRM RTB, second within 3 s: RTB ordered | ☐ |
| P33.18 | CLOSE on another filed CAS thread | A CLOSE message; steps CLOSED; the three buttons dead | ☐ |
| P33.19 | A run the asset refuses (CANTCO) | The last step reads CANTCO in the accent; the reason under its log line | ☐ |
| P33.20 | Fill half the card, BACK, press the same task again | The screen comes back with what was typed; another asset's task starts a fresh draft | ☐ |
| P33.21 | File a `checkin` to B:SUPPORT:<id> (`["checkin", <answers>, ["B:SUPPORT:<id>"]] call jmfsb_messaging_fnc_submit`), open the screen for that asset | The strip above the rows: CHECK-IN, call sign and time, then type, position, altitude, ordnance, time on station, abort code | ☐ |
| P33.22 | A player in the pilot's seat of the asset's airframe, open its CAS task | The switch CAS REQUEST / 9-LINE shows, 9-LINE picked; rows Line 1 IP / BP to Line 9 EGRESS and Remarks; alt-click an ingress: IP / BP offers the nearest marker to it, HEADING and DISTANCE offered (MAP), ELEVATION offered, Line 8 direction and range (BFT) | ☐ |
| P33.23 | Switch to CAS REQUEST and SEND | A `cas` thread, not `nineline` | ☐ |
| P33.24 | Tablet: open, click the map, type, ESC | Clicks move the target; typing works in the tablet; ESC closes the board and leaves the tablet up | ☐ |
| P33.25 | A call for fire task on the reach card | The old form still opens (no ARTY screen yet) | ☐ |

### P34. TAC//SUPPORT v2: the ARTY screen and the adjust pad (2026-11-01)

Withdrawn 2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING.

docs/DESIGN_SUPPORT_V2.md sections 4.2, 7, 8 (T1, T2, T4, T5) and 11, build
step 6. Mission: a **JMSB - Virtual Artillery** module in range of a target
area (Response Time 5-10 s), a friendly AI squad 400 m from the target, the v2
built-in cards (`adjust`, `ffe`, `repeat`, `checkfire`, callforfire
`dangerClose` 600). Native host first, then the tablet. P33.25 now
opens this screen. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P34.1 | Click the target, press the battery's FIRE MISSION on the reach card | The ARTY screen: header ARTILLERY · CARD CALLFORFIRE; the rows Observer (your call sign), Warno 1 choice row, Warno 2, Warno 3 TARGET LOCATION with GRID / POLAR / SHIFT (GRID on, the target's grid, FROM MAP), Description, Engagement shells and NUMBER OF ROUNDS under them, Danger Close, Control A-F, Remarks; no TOT, no Target 2 / 3 rows | ☐ |
| P34.2 | Press POLAR, then SHIFT, then GRID | POLAR shows the POLAR (FROM OBSERVER) row under the switch; SHIFT swaps it for SHIFT FROM A KNOWN POINT; GRID shows neither; only one of the three is ever on | ☐ |
| P34.3 | Press Control TIME ON TARGET, then FIRE WHEN READY | TOT appears under Control, then goes | ☐ |
| P34.4 | Look at Danger Close | The squad is inside 600 m: DANGER CLOSE (BFT) offered in the accent and `400 M (BFT)` with USE; the accent edge; SEND names it | ☐ |
| P34.5 | Warno 1 ADJUST FIRE, type a description, take the offers, SEND (two presses) | `#jmfsb msg.threads`: a `callforfire` thread in B:SUPPORT:fires:<n> with Warno1.A true, Warno3A.A the target, DangerClose.A true; the battery fires ONE round (notify rail: shot, splash) and does not say rounds complete | ☐ |
| P34.6 | Look under the rows and over the map | BATTERY with its newest reply; ROUNDS `1 · IN FLIGHT · SPLASH m:ss` counting down, then `1 · SPLASH · <grid>`; the adjust pad top right of the map with OT <mils> MILS; on the map the OT line, the ring with `1 · SPLASH m:ss`, then a point `1` where it landed | ☐ |
| P34.7 | While the round is in the air | SEND CORRECTION, FIRE FOR EFFECT and REPEAT dead, `Rounds in the air - wait for the splash` | ☐ |
| P34.8 | After the splash: press ADD, step 100 | Middle reads `100 M`; SEND CORRECTION · ADD 100 filled; map NEXT · ADD 100 from the aim, away from you along the OT line | ☐ |
| P34.9 | Click the map 180 m right of the last splash | The pad switches to RIGHT 200 (step 100) and the flash says to press SEND CORRECTION; nothing fired | ☐ |
| P34.10 | SEND CORRECTION three times (any three corrections, each after the splash) | Each: an ADJUST message in the thread with direction and distance, one round at the corrected point, a new ROUNDS row `n · <correction> · IN FLIGHT ...` | ☐ |
| P34.11 | FIRE FOR EFFECT · n (n = rounds per gun x guns as sent) | An FFE message; the whole order lands round the last aim; the round log row reads `5 · FFE · SPLASH · <n> ROUNDS · <grid>`; the battery says rounds complete and keeps holding | ☐ |
| P34.12 | `#jmfsb msg.threads` / the thread in TAC//MSG | Section 11: the observer's five messages in order - CALL FOR FIRE, ADJUST, ADJUST, ADJUST, FFE - with the battery's ROGER / WILCO / ON TASK between them | ☐ |
| P34.13 | REPEAT | A REPEAT message; the same FFE again on the same aim | ☐ |
| P34.14 | EOM | A CLOSE message first; steps CLOSED; the battery says end of mission and starts its cooldown; the pad goes | ☐ |
| P34.15 | New adjust mission; CHECK FIRE while the round is in the air | A CHECK FIRE message; the battery checks fire (the round in the air still lands), the thread CLOSED | ☐ |
| P34.16 | New adjust mission; do nothing for 5 minutes after the splash | The battery ends the mission itself (`end of mission - no call from the observer`), the thread CLOSED | ☐ |
| P34.17 | Second player: while the battery holds for you, task it from his board | Refused, `<call sign> is adjusting for another observer` | ☐ |
| P34.18 | A FIRE FOR EFFECT mission (Warno 1 B) | Fires the whole order as before and closes the thread at rounds complete; the pad's corrections dead, `Corrections follow an ADJUST FIRE mission`; ROUNDS rows read SENT (an ordinary mission publishes no rounds) | ☐ |
| P34.19 | After the screen's SEND, order the battery from the old form | The order carries no adjust call: an ordinary mission | ☐ |
| P34.20 | Tablet: P34.5 to P34.10 | Same; map clicks on the screen set corrections while the pad is up, and never close the board | ☐ |

### P35. TAC//SUPPORT v2: the TRANSPORT and LOGISTICS screens (2026-11-01)

Withdrawn 2026-11-01: TAC//SUPPORT app removed - support by message, DESIGN_SUPPORT_MESSAGING.

docs/DESIGN_SUPPORT_V2.md sections 4.3, 4.4, 7 and 11, build step 7. Mission:
a **JMSB - Transport** module (PICKUP > LZ and LAND allowed), a **JMSB -
Logistics** module (AIRDROP and SLING, Capacity 4, Spawn Distance 0) synced to
a **JMSB - Logistics Catalog** with two vehicles and a crate, two friendly
squads 200 m from a clearing, a map marker near the LZ, the built-in cards
(`hlz` Wind / Obstacles, `airdrop` Contents, `resupply`). Native host first, then the tablet. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P35.1 | Click the clearing, press the transport's PICKUP > LZ on the reach card | The board's bar: the order, and BRIEF on the status line | ☐ |
| P35.2 | Press BRIEF | The TRANSPORT screen: header TRANSPORT · CARD HLZ; switch HLZ / CASEVAC / AIRDROP; ROUTE with the base line, the leg to PICKUP with a distance and a time, the boxed PICKUP, THEN HOLD, the legend; MANIFEST 0 with an empty seat bar, `0 OF n SEATS` | ☐ |
| P35.3 | Shift-click twice between base and pickup | VIA 1, VIA 2 on the strip, each leg timed; the map arrows chain into the pickup; nothing is queued on the board | ☐ |
| P35.4 | Right-click near the marker | LZ boxed on the strip with the marker's name; Line 1 HLZ LOCATION = the LZ's grid, FROM STRIP; Line 2 offers the marker name with USE; WHEELS DOWN m:ss on the strip and in the sentence | ☐ |
| P35.5 | + MY SQUAD | A row: your squad, its men, `n M OUT` or AT PICKUP; the seat bar fills one segment; Line 3 reads `n - <SQUAD> (n)`, FROM MANIFEST; + MY SQUAD goes dead | ☐ |
| P35.6 | + SQUAD AT PICKUP, press the other squad, then + CARGO twice | The list shows the squad within 400 m; pressed, it joins; CARGO `2 SEATS`; Line 3's count equals the manifest's total (section 11) | ☐ |
| P35.7 | REMOVE the cargo | Its segment goes, Line 3's count drops by 2 | ☐ |
| P35.8 | Line 4: press GREEN, then RED | One line of three buttons; RED clears GREEN; the LZ box goes thick accent with RED; status `HOT LZ · CONFIRM TWICE`; SEND reads `LAUNCH · HOT LZ` | ☐ |
| P35.9 | Line 5 SMOKE | The bar's LZ SIGNAL stepper reads SMOKE | ☐ |
| P35.10 | Leave Line 6 alone | Line 6 = VIA 2's grid, FROM STRIP; alt-click: Line 6 = the click, FROM MAP | ☐ |
| P35.11 | LAUNCH once, wait 6 s | `CONFIRM · HOT LZ` then back to `LAUNCH · HOT LZ`; nothing filed | ☐ |
| P35.12 | LAUNCH twice | `#jmfsb msg.threads`: an `hlz` thread in B:SUPPORT:air:<n>, Line1.A the LZ, Line3.A the manifest text, RED true; the helicopter flies the vias, lands at the pickup, then the LZ; the steps move ISSUED > WILCO > ON TASK | ☐ |
| P35.13 | GREEN LZ order | LAUNCH sends on one press | ☐ |
| P35.14 | Switch to CASEVAC, then AIRDROP | CASEVAC: Line 1 the pickup (the task's point); AIRDROP: Line 1 the task's point, CONTENTS from the manifest | ☐ |
| P35.15 | A LAND order (no LZ point) | The strip ends at the LZ (the task's point); no FROM in the sentence; no RIGHT-CLICK in the legend | ☐ |
| P35.16 | Click a point, press the logistics' AIRDROP | The LOGISTICS screen: CART 0, `0 OF 4 ITEMS`, + ITEM, METHOD AIRDROP (filled) / SLING LOAD; no ITEM / COUNT steppers on the bar; Item 1 says PRESS + ITEM | ☐ |
| P35.17 | + ITEM, press a vehicle twice, the crate once | Rows with - 2 + / - 1 +; `3 OF 4 ITEMS`; Item 1 / Item 2 lines from the cart, FROM CART, no boxes; the sentence `<CALLSIGN> DROPS 2 <VEHICLE>, 1 <CRATE> ON <grid>` | ☐ |
| P35.18 | + on the crate | `4 OF 4 ITEMS · FULL`; every + and + ITEM dead | ☐ |
| P35.19 | METHOD SLING LOAD | Items the hook cannot lift leave the cart with a line saying how many; the map shows a set-down mark per item, 60 m apart across the leg in from the base | ☐ |
| P35.20 | Marking SMOKE, SEND | A `resupply` thread, Item lines as the cart; the asset delivers exactly the cart; the MARKING stepper read SMOKE; after SEND, `jmfsb_tacpad_apps_supportParams select 49` in the debug console is `[]` | ☐ |
| P35.21 | Tablet: P35.2 to P35.8, P35.16 to P35.18 | Same; shift-clicks add vias and never close the board | ☐ |

### P36. CAS units as message receivers (2026-11-01)

docs/DESIGN_SUPPORT_MESSAGING.md build step 2 (CAS). Mission: one **JMSB -
CAS** drone module (call sign HOG), one **JMSB - Air** module of kind CAS
(the ALiVE CAS asset withdrawn 2026-11-02: ALiVE support provider removed); a JMSB - Artillery battery to show
it is not listed; Support tasking tag empty. Native host first, then the
tablet. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P36.1 | TAC//MSG, NEW, CHANGE | Under the nets, squads and men: SUPPORT, `n ASSETS` (`1 ASSET` for one), one row per CAS asset - call sign, then `CAS - IDLE - ETA m:ss`. No artillery row (superseded by P40.1: every type is listed since 2026-11-01) | ☐ |
| P36.2 | Wait 10 s with the picker open, scrolled down | The ETA and state lines update every 2 s in place; the list does not jump back to the top | ☐ |
| P36.3 | Task HOG from TAC//SUPPORT, then open the picker again | HOG's row dim, `CAS - TASKED`; still pressable | Withdrawn 2026-11-01: TAC//SUPPORT app removed (task HOG by message instead) |
| P36.4 | HOG back home and rearming | `CAS - REARMING - COOLDOWN n S`, dim, counting down | ☐ |
| P36.5 | EW: deny the GPS, open the picker | Rows show state, no ETA | ☐ |
| P36.6 | Press HOG | The picker closes; TO reads HOG; the line above reads `SEND TO HOG` (not `ON ... NET`) | ☐ |
| P36.7 | + TEMPLATE, CAS, fill it, SEND | `#jmfsb msg.threads`: a `cas` thread in B:SUPPORT:cas:<n>; a ROGER arrives from HOG (not `CAS:<n>`) | ☐ |
| P36.8 | Look at the rail, the thread header, the list filter | The rail's net reads HOG; the header `TO HOG`; typing HOG in the filter finds the thread | ☐ |
| P36.9 | NEW, + TEMPLATE, CAS, then CHANGE | SUPPORT comes first, CAS rows only, then the nets, squads and men | ☐ |
| P36.10 | Set the Support tasking tag to JTAC; a non-JTAC player opens the picker | No SUPPORT group | ☐ |
| P36.11 | Docked reader on the map | The net chip of the thread reads HOG | ☐ |
| P36.12 | Tablet: P36.1, P36.2, P36.6, P36.9 | Same | ☐ |

### P37. Support aircraft fly tactically (2026-11-01)

Night mission (23:00, no moon). Modules: a **JMSB - CAS** with a jet class, a
second **JMSB - CAS** with an attack-helicopter class, a **JMSB - Transport**
(class, offers PARADROP and SLINGLOAD; a liftable crate near the load point),
a **JMSB - QRF Insertion** (helicopter), a **JMSB - Logistics** (Spawn
Distance 0, a helicopter, both methods), a **JMSB - CAS Drone**. Watch each aircraft from the
ground and through the Zeus / spectator camera. Lights: on within 1500 m of
where it started, off beyond. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P37.1 | TAC//SUPPORT: look at the transport's tasks, the CAS steppers, the Eden attributes | No LIGHTS, HEIGHT or ALTITUDE stepper; no Altitude / Flight Height / Attack Altitude / Sling Flight Height attribute. A mission that had them set loads without an error | ☐ (the TAC//SUPPORT part withdrawn 2026-11-01: app removed; the Eden part stands) |
| P37.2 | Transport PICKUP 5 km out; watch it lift off the module | Collision lights on over the module; about 1.5 km out they go off, landing light and searchlight off. It flies about 30 m above the ground the whole way | ☐ |
| P37.3 | Watch it for a minute in the field (CARELESS, night) | Lights stay off; the crew does not switch them back on | ☐ |
| P37.4 | RTB | 30 m home; inside 1.5 km of the module the collision lights come back on | ☐ |
| P37.5 | Transport SLINGLOAD on the crate, set down 3 km away | Hooks at its hover; carries the crate higher than 30 m (about 30 + rope + crate + 10); comes down to 12 m at the set-down; after the cut, back to 30 m. Lights off throughout once clear of the module | ☐ |
| P37.6 | Transport PARADROP, jump height 250, 6 km out | 30 m until about 1.1 km short; climbs to 250 m over the drop zone; the stick goes; home at 30 m, dark until over the module | ☐ |
| P37.7 | QRF AIR ASSAULT | Out at 30 m, dark once clear of the module, fast-ropes or lands as before, home at 30 m | ☐ |
| P37.8 | Jet CAS ATTACK RUN | Appears in the air on the ingress, no lights at any time; runs in at about 4000 m above the ground; releases; leaves dark | ☐ |
| P37.9 | Jet CAS LOITER on a grid | The order bar has no RADIUS; the map draws the leg to HOLD. The jet appears about 8 km outside the map edge nearest the grid at 4000 m and orbits there, not over the grid; "on station off the map" | ☐ |
| P37.10 | Jet CAS SAD on a grid; after a minute put a laser on a target inside the radius | It holds off the map until the laser; then runs in at 4000 m, strikes, goes back to the hold | ☐ |
| P37.11 | Helicopter CAS SAD | Flies 30 m, orbits the grid at 30 m (not off the map), strikes as before; dark once clear of the module | ☐ |
| P37.12 | Logistics SLING LOAD (two items) | Each helicopter carries its item higher than 30 m (rope + load + 10), drops to the Unload Height 200 m out, back to 30 m once cut; lights on over the module only | ☐ |
| P37.13 | Logistics AIRDROP, drop height 250, 6 km out | 30 m, climbing to 250 m from about 1.1 km out; items out; back to 30 m and home | ☐ |
| P37.14 | Logistics with Spawn Distance 4000, AIRDROP | Appears at a distance, dark throughout | ☐ |
| P37.15 | CAS Drone strike, then LOITER | Strike at about 4000 m, no lights ever. LOITER orbits over the grid at about 4000 m (drones are exempt from the off-map hold, 2026-11-01); the ISR seat is handed over there | ☐ |
| P37.16 | ALiVE CAS and transport (with ALiVE) | Within 30 s the parked aircraft are on the watch: lights on at their pad, off once 1.5 km clear; the transport is told 30 m, the CAS jet 4000 m. ALiVE's loiter is over the point (not reached) | Withdrawn 2026-11-02: ALiVE support provider removed |
| P37.17 | A player takes the pilot seat of a synced transport | His lights are his own; the watch does not touch them | ☐ |
| P37.18 | RPT | No error from `jmfsb_support_fnc_tactical*`, `flightHeight`, `flyAt`, `holdPoint` | ☐ |

### P38. The CAS asset acts on its thread; on station first (2026-11-01)

DESIGN_SUPPORT_MESSAGING steps 3-4 and 1.1. The built-in `onstation` and
`clearedhot` cards.
Modules: **JMSB - CAS** jet (HOG), **JMSB - CAS** attack helicopter (SNAKE),
**JMSB - CAS Drone** (REAPER); a Support Darter / Switchblade module. A second player (or AI squad of your
side) to stand near targets. Night. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P38.1 | `cas` to HOG (not on station) | ROGER, then CANTCO `NOT ON STATION` | ☐ |
| P38.2 | `onstation` to HOG: 20 min, an area grid | ROGER, WILCO `ETA m:ss - ON STATION 20 MIN` (no more than the module's Time on Station) | ☐ |
| P38.3 | Watch HOG | Dark throughout; holds about 8 km off the map edge nearest the area at 4000 m; the row reads ON STATION | ☐ |
| P38.4 | At the hold | A CHECK-IN from HOG in the thread: Line 1 HOG (not your call sign), the airframe, the stores, 20 MIN, a four-figure abort code | ☐ |
| P38.5 | `cas` to HOG, Line 1 typed as an 8-figure grid with a space, Line 5 "BMP in treeline" | ROGER, WILCO `ETA m:ss - BMP in treeline` within a few seconds; HOG stays at the hold | ☐ |
| P38.6 | Wait 60 s | HOG does not leave the hold, releases nothing | ☐ |
| P38.7 | CLEARED HOT in the `cas` thread | Only offered after WILCO. ON TASK; HOG comes in at about 4000 m, releases on the grid, goes back to the hold; CLOSE `back at the hold` | ☐ |
| P38.8 | `cas` with Line 3 / Line 4 picked | It runs in by the ingress point and leaves by the egress point before the hold | ☐ |
| P38.9 | `cas` with a friendly at 250 m from the target, DC not ticked | CANTCO `DANGER CLOSE NOT ACKNOWLEDGED`; same with the tick: WILCO | ☐ |
| P38.10 | `cas` with Line 7 LASER, code 1688, to an airframe with no laser-guided store | CANTCO `CANNOT LASE 1688`; with SMOKE: WILCO | ☐ |
| P38.11 | `cas` with no Line 1 grid (or a grid off the map) | CANTCO `NO TARGET LOCATION` | ☐ |
| P38.12 | Second `cas` to HOG while the first is waiting | CANTCO `TASKED`; the first thread still answered | ☐ |
| P38.13 | CLOSE the `onstation` thread | HOG goes home; the open strike thread (if any) closes `RTB` | ☐ |
| P38.14 | New `onstation`, let the time run out | Both threads close `BINGO`; it goes home | ☐ |
| P38.15 | `cas` to SNAKE (helicopter) | WILCO with an ETA; it orbits the run-in distance short of the target until CLEARED HOT, then attacks; CLOSE when the sortie is over | ☐ |
| P38.16 | `cas` to REAPER | WILCO; it orbits OVER the grid at 4000 m, dark, until CLEARED HOT; then in through the target, ON TASK at the release, CLOSE `run complete` | ☐ |
| P38.17 | `onstation` to REAPER | It loiters over the area (not off the map); the ISR seat is offered there | ☐ |
| P38.18 | Darter / Switchblade mission at night | Dark from launch; flies as before | ☐ |
| P38.19 | ALiVE CAS and the ATO (with ALiVE): `cas` | WILCO `... ON CLEARED HOT`; nothing flies until CLEARED HOT; then the ATO request / ATTACK GROUND goes, ON TASK | Withdrawn 2026-11-02: ALiVE support provider removed |
| P38.20 | Same `cas` to a player pilot's box | No AI acts; the player sees the thread and answers by hand | ☐ |
| P38.21 | TAC//SUPPORT board: task HOG, SNAKE and REAPER as before | Works as before, no CLEARED HOT needed | Withdrawn 2026-11-01: TAC//SUPPORT app removed |
| P38.22 | RPT | No error from `jmfsb_support_fnc_srvFiled`, `srvFollowUp`, `readOrder`, `jmfsb_cas_fnc_srvThread`, `jmfsb_support_air_fnc_srvThread` / `casJob` / `checkIn` | ☐ |

### P39. Drone escorts for support aircraft (2026-11-01)

DESIGN_SUPPORT_MESSAGING 1.2. Night. Modules, each with **Drone Escorts** on:
**JMSB - CAS** jet (HOG; Fixed-Wing Escort Class `B_UAV_02_dynamicLoadout_F`),
**JMSB - Transport** class helicopter (RAVEN; Rotary Escort Class an armed
rotary drone class of the mod set loaded), **JMSB - Logistics** plane, AIRDROP
(Fixed-Wing Escort Class set). A **JMSB - CAS** with Drone Escorts on and both
classes empty (EMPTY). An enemy AA site (a MANPADS team or a Tigris) near the
transport's LZ, one on the jet's way in. Deck with `onstation`, `cas`,
`clearedhot` and `hlz`. Watch from Zeus / spectator. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P39.1 | Eden: open each module | Drone Escorts (off by default); CAS, QRF and Logistics have Fixed-Wing and Rotary Escort Class, Transport only Rotary; the class pickers list drones only | ☐ |
| P39.2 | `onstation` to HOG (20 min) | Two fixed-wing drones appear beside HOG, one each side, and fly with it to the hold 8 km off the map at about 4000 m, dark throughout | ☐ |
| P39.3 | At the hold | The drones orbit with HOG at the hold, at about 4000 m; the check-in comes as before | ☐ |
| P39.4 | `cas` to HOG, CLEARED HOT | The drones come in with HOG at 4000 m, engage threats round HOG and the target, go back to the hold with it | ☐ |
| P39.5 | Let the AA on the way in fire at HOG | When the missile is fired: both drones (and HOG) put out flares; the drones turn on the shooter; RPT `under missile fire ... aircraft flared` | ☐ |
| P39.6 | RTB HOG | The drones fly home with HOG and are removed with it at its exit (or recovered on its stand, a synced HOG) | ☐ |
| P39.7 | Board TRANSPORT screen: PICKUP, `hlz` Line 4 GREEN | RAVEN flies with no escort; RPT `LZ security GREEN - no escort` | ☐ |
| P39.8 | Same, Line 4 YELLOW | About 5 s after launch two rotary drones join RAVEN: nap of the earth (about 30 m), dark, on its route; they orbit the LZ while it is down; RPT `LZ security YELLOW - escorted` | ☐ |
| P39.9 | Same, Line 4 RED (HOT LZ) | Two rotary drones as P39.8; they engage the enemy round the LZ, never further than about 2 km from RAVEN | ☐ |
| P39.10 | A helicopter CAS with escorts on, tasked by a `cas` card (no LZ line) | Two rotary drones; RPT `no LZ security on the request - escorted by the module option` | ☐ |
| P39.11 | Shoot down one escort, then the second | Not replaced; the lead flies on. With both gone the watch stops quietly | ☐ |
| P39.12 | Shoot down RAVEN with its escorts up | The escorts fly back to where they were made and are removed there (or after 10 min) | ☐ |
| P39.13 | Logistics AIRDROP with escorts | Two fixed-wing drones with the plane on every delivery; removed with it at its exit | ☐ |
| P39.14 | Task EMPTY (jet) twice | No escort; one RPT warning `drone escorts are on, but escortPlane '' is not a Plane class` - only once | ☐ |
| P39.15 | Set EMPTY's Fixed-Wing Escort Class to a helicopter class | No escort, one warning naming the class | ☐ |
| P39.16 | CAS Drone module (addons/cas) | No escorts ever - drones fly alone | ☐ |
| P39.17 | With ALiVE | Escorts are not virtualised by ALiVE (profileIgnore) | ☐ |
| P39.18 | RPT | No error from `jmfsb_support_fnc_escort*`, `lzSecurity`, `jmfsb_support_air_fnc_escortLaunch` | ☐ |

### P40. @ mentions of support assets in the composer (2026-11-01)

DESIGN_SUPPORT_MESSAGING 6.1. Mission: a **JMSB - CAS** jet module (HOG), a
**JMSB - CAS** helicopter module (SPARROW), a CAS drone module (REAPER), a
**JMSB - Artillery** battery (THUNDER), a **JMSB - Transport** helicopter
(RAVEN), a **JMSB - Logistics** module (MULE), a **JMSB - QRF** module
(WOLF); Support tasking tag empty. Deck with `cas`, `onstation`,
`callforfire`, `hlz` and `resupply`, and NO `qrf` card. A squad or net named
HOGAN for P40.6. Native host first, then the tablet. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P40.1 | TAC//MSG, NEW, CHANGE | SUPPORT lists every asset: `CAS`, `ARTY`, `TRANS`, `LOGI`, `QRF` rows, each call sign then `TYPE - state - ETA m:ss` | ☐ |
| P40.2 | NEW, type `@` on the CC line | The drop lists the support assets first (call sign, then `TYPE - state - ETA`, untracked), then nets, squads and men; six rows at most | ☐ |
| P40.3 | Type a sentence in MESSAGE, then `@THU` on CC and pick THUNDER | CC line loses `@THU`; TO reads `<net>, THUNDER`; the card is CALL FOR FIRE; the sentence is in its REMARKS line if the card has one, else SWITCH / KEEP asks (P40.8) | ☐ |
| P40.4 | NEW, type `@RAVEN,` | Taken without picking: TO adds RAVEN, the card is HLZ; the keyboard stays on the CC line | ☐ |
| P40.5 | NEW, type `@MULE` (no comma) | Taken at the last letter (nothing else begins with MULE): TO adds MULE, the card is RESUPPLY | ☐ |
| P40.6 | NEW, type `@HOG` | Not taken yet (HOGAN also begins with HOG); `@HOG,` takes HOG | ☐ |
| P40.7 | HOG idle at base: `@HOG,` | The card is REQUEST ON STATION (`onstation`), not `cas` | ☐ |
| P40.8 | On that card fill Line 1 and Remarks, then `@SPARROW,` | Under the CC line: `SPARROW TAKES THE CAS CARD - 1 TYPED FIELD IS NOT ON IT` (or `FIELDS ARE` for more than one), SWITCH and KEEP; TO already has SPARROW | ☐ |
| P40.9 | KEEP | The ON STATION card stays, filled as it was; the row goes | ☐ |
| P40.10 | Repeat P40.8, SWITCH | The CAS card; Remarks kept; Line 1 (minutes) is not in the CAS grid line | ☐ |
| P40.11 | Send the ON STATION to HOG; when the check-in arrives, NEW, `@HOG,` | The card is `cas` (HOG's row reads ON STATION) | ☐ |
| P40.12 | NEW, `@REAPER,` and `@SPARROW,` | `cas` - a drone and a helicopter are never asked on station | ☐ |
| P40.13 | NEW, `@WOLF,` | TO adds WOLF; the card stays as it was; beside SEND `THE DECK HAS NO QRF CARD - CARD KEPT` | ☐ |
| P40.14 | Fill the CAS card for SPARROW from P40.10, SEND | `#jmfsb msg.threads`: the thread in B:SUPPORT:air:<n>; ROGER, then WILCO from SPARROW | ☐ |
| P40.15 | NEW, type a sentence, press CURRENT LOC, SEND | The sentence survives the redraw and is sent (the plain box is harvested now) | ☐ |
| P40.16 | Support tasking tag JTAC; a non-JTAC types `@` | No support assets in the drop; `@HOG,` stays a CC name and is dropped at the send | ☐ |
| P40.17 | Tablet: P40.2, P40.3, P40.8 | Same | ☐ |
| P40.18 | RPT | No error from `jmfsb_tacpad_fnc_composeMention*`, `composeCcDrop`, `jmfsb_support_fnc_mailboxes` | ☐ |

### P41. Map markers on the tablet's map (2026-11-01)

Two players on one side in different groups (A, B), multiplayer. Tablet
display mode, the large tablet. Addon Options > JMSB - Tablet & Map > Map
Tools > **Map marker system**. Runs 1-14 without ACE and ALiVE, 15-18 with ACE,
19-21 with ALiVE and its Advanced Markers module. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P41.1 | Addon Options, Map marker system (no ACE, no ALiVE) | One choice: Built-in | ☐ |
| P41.2 | A: tablet open, no app, no tool; double-click the map | The marker card opens beside the point (2026-11-02): an ink band with MARK and the grid; one row of tabs BASIC MIL BLU OPF IND CIV FLAG JMSB, the tab holding the last icon open; a page of square icon cells, six a row, the picked one filled; the page readout; square colour swatches, nine a row; S M L and `< 000° >`; TEXT box, channels, PLACE filled / CANCEL outlined - all on one column, no text cut or overlapping; a dot icon on the map at the point | ☐ |
| P41.3 | Pick OPF, `o_inf`, red, type `ENEMY`, channel GROUP, PLACE | The card closes; a red enemy infantry marker `ENEMY` at the point on the tablet and on A's vanilla map; B (other group) does not see it | ☐ |
| P41.4 | Double-click again, channel SIDE, type text, press Enter | Placed on Enter; B sees it | ☐ |
| P41.5 | Double-click, MY MAP, PLACE; MAP TOOLS > CLEAR | Only A sees it; CLEAR removes it | ☐ |
| P41.6 | Close the tablet, open the vanilla map, hover the P41.3 marker, Delete | Deleted for A's group, as any marker | ☐ |
| P41.7 | Tablet: double-click on your P41.4 marker | EDIT MARK with its icon (its tab open on its page), colour, size, direction, text, SIDE; DELETE shown. Change the text, PLACE: the marker is replaced. Again, DELETE: gone for B too | ☐ |
| P41.8 | MAP TOOLS > MARK; press the map | The card opens with the grid and time as text, on MY MAP (Share marks with group off) / GROUP (on) | ☐ |
| P41.9 | MARK running: press on one of your own markers | Deleted; no card | ☐ |
| P41.10 | MARK running: press on B's marker | No delete; the card opens | ☐ |
| P41.11 | Open an app (SUPPORT); double-click the map | The first press closes the app; no card | ☐ |
| P41.12 | SUPPORT picking a point on the map (claim held); double-click | The pick is SUPPORT's; no card | ☐ |
| P41.13 | RULER running; double-click | Two ruler presses; no card | ☐ |
| P41.14 | TOOLS on the strip off (MAP TOOLS hidden), reopen the tablet, double-click after a second | The card opens | ☐ |
| P41.15 | With ACE: Map marker system lists Built-in and ACE; pick ACE; tablet double-click | ACE's marker dialog (shape, colour, angle, scale, channel); its preview icon at the point on the tablet's map | ☐ |
| P41.16 | Pick a shape, colour, angle 45, scale 1.5, a channel, text, OK | One marker with those, at the double-clicked point, seen by that channel; RPT may say ACE could not find it - nothing else | ☐ |
| P41.17 | ACE: double-click on your own marker | ACE edits it; OK replaces it in place | ☐ |
| P41.18 | ACE: close and reopen the tablet; double-click | ACE's preview still draws | ☐ |
| P41.19 | With ALiVE + Advanced Markers module: pick ALiVE; tablet double-click | ALiVE's Advanced Marker dialog over the tablet; OK makes the ALiVE marker at the point | ☐ |
| P41.20 | MARK press on that ALiVE marker | Removed (it is yours); B's ALiVE marker is not | ☐ |
| P41.21 | ALiVE loaded, no Advanced Markers module | Built-in card opens instead | ☐ |
| P41.22 | Native display mode: vanilla map double-click; MARK press | The game's own dialog (ACE's with ACE); MARK opens the chosen system | ☐ |
| P41.23 | RPT | No error from `jmfsb_maptools_fnc_marker*`, `mapDblClick`, `mark`, `jmfsb_adapter_alive_fnc_markerOpen` / `markerRemove` | ☐ |
| P41.24 | Card open (2026-11-02): press each tab; hover icons | Each tab shows its set: BASIC the hand-drawn marks (dot, objective, flag, warning, destroy, pickup first), MIL the military marks, BLU / OPF / IND the NATO symbols of that side, CIV civilian, unknown installation and places (ruin, bunker, transmitter, hospital ...), FLAG the flags, JMSB this mod's (CAS points, LZs, DZ, dive points, downed aircrew ...). Hover names each icon; tab hover names the tab. No system marks (empty, select, waypoint, group sizes, respawn) | ☐ |
| P41.25 | CIV or FLAG: press `>` until it wraps, then `<` | Pages turn `1 / 2`, `2 / 2`, back to `1 / 2`; `<` from 1 goes to the last; a one-page tab shows `1 / 1` without keys | ☐ |
| P41.26 | Pick a flag and Default colour, PLACE | The flag in its own colours on the map; the card's FLAG / JMSB icons are drawn in their own colours, every other icon in the ink | ☐ |
| P41.27 | Colours: count the swatches; hover | Every marker colour with scope (Default, Black, Grey, Red, Brown, Orange, Yellow, Khaki, Green, Blue, Pink, White, BLUFOR, OPFOR, Independent, Civilian, the side-unknown yellow, JMSB) in rows of nine; hover names each; Default's swatch is the picked icon's own colour (an OPF icon: OPFOR red) | ☐ |
| P41.28 | `mil_arrow`, L, `>` three times, SIDE, PLACE | The preview grows and turns 15° a press; the marker is large and points 045°, for B too | ☐ |
| P41.29 | Smallest tablet; double-click near the bottom of the map | The card stays inside the map; the icon grid shows fewer rows and the pager turns the rest | ☐ |
| P41.30 | Change the colour scheme (LIGHT / DARK), reopen the card | Header band, cell outlines, filled picks and buttons follow the theme | ☐ |

### P42. Artillery called by message in TAC//MSG (2026-11-01)

DESIGN_SUPPORT_MESSAGING step 6. Dedicated server, three players on one side:
A (JTAC, group ALPHA 1-1), B (group BRAVO 1-1), C (any). A **JMSB - Virtual
Artillery** battery THUNDER (HE, SMOKE; response 10-20 s), friendlies placed
for P42.6. Deck: `callforfire` (with `dangerClose` 600), `adjust`, `ffe`
(with ROUNDS), `repeat`, `checkfire`, `confirm`, `shot`, `splash`, `prompt`,
`bda` as a reply, `close` - all built in. Shared mailboxes include
`FIRES`. Support tasking tag empty. Built, not seen in game. P42.25-P42.33
(cruise missiles and loitering munitions by message, 2026-11-01) add a **JMSB
- Cruise Missiles** TRIDENT (6 missiles, salvo 2, response 10-20 s) and a
**JMSB - Loitering Munitions** GHOST (6, launch 2), and an enemy crewed
vehicle at the target.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P42.1 | A: CALL FOR FIRE to THUNDER - Warno 1 A ADJUST, grid 3 km out, Engagement HE, SEND | One thread: ROGER, then WILCO `ETA m:ss - ADJUST - 1 RD HE - TOF n S - <description>`, then ON TASK | ☐ |
| P42.2 | Wait | `SHOT` (`TOF n`), `SPLASH` about 5 s before the round lands, then `ADJUST?` (answers adjust, ffe, close); one round on the grid | ☐ |
| P42.3 | A: `adjust` ADD 50 | `SHOT`, `SPLASH`, `ADJUST?`; the round lands 50 m further along A's line to the target | ☐ |
| P42.4 | A: `ffe` (ROUNDS 2) | `SHOT`, `SPLASH`, `ROUNDS COMPLETE - REQUEST BDA` (bda, repeat, close); every gun fires 2 rounds on the adjusted point | ☐ |
| P42.5 | A: `close` (EOM) | The thread CLOSED; THUNDER idle after its cooldown. The whole thread reads in order: ROGER, WILCO, ON TASK, SHOT, SPLASH, ADJUST?, ADJUST, SHOT, SPLASH, ADJUST?, FFE, SHOT, SPLASH, ROUNDS COMPLETE, CLOSE | ☐ |
| P42.6 | CFF FFE on a grid 300 m from a friendly, Danger Close not ticked | CANTCO `DANGER CLOSE NOT ACKNOWLEDGED`; nothing fired. Ticked: WILCO with `DANGER CLOSE` | ☐ |
| P42.7 | CFF on a grid beyond the battery's max range | CANTCO `OUT OF RANGE n/max KM` | ☐ |
| P42.8 | CFF with Engagement D Cluster (THUNDER has none) | CANTCO `NO STORES CLUSTER` | ☐ |
| P42.9 | CFF with no grid, no polar, no shift | CANTCO `NO TARGET LOCATION` | ☐ |
| P42.10 | A second CFF to THUNDER while P42.1's runs | CANTCO `TASKED`; the first thread carries on | ☐ |
| P42.11 | CFF, Warno 3B polar ticked, Target 2 090 / 1500 | The round lands 1.5 km due east of A | ☐ |
| P42.12 | CFF, Warno 3C shift ticked, grid = a known point, Target 3 `R 200` / `ADD 400` | The round lands 400 m beyond and 200 m right of the point on A's line | ☐ |
| P42.13 | CFF FFE, Control B AT MY COMMAND | WILCO `AT MY COMMAND - ...`, prompt `READY - AT MY COMMAND` (confirm, close); nothing fires. `confirm`: SHOT within the least response time | ☐ |
| P42.14 | CFF FFE, Control C TOT 3 min ahead (HHMM) | WILCO `TOT hhmm`; the first round lands at that minute. A TOT 10 s ahead: CANTCO `CANNOT MAKE TOT`; TOT empty: `NO TOT` | ☐ |
| P42.15 | CFF FFE with several rounds; `checkfire` after the SHOT | Rounds not yet fired are not fired; `CHECK FIRE - HOLDING`; `repeat` fires the salvo again | ☐ |
| P42.16 | After a FFE splash: `bda` | `END OF MISSION?` (close, repeat) | ☐ |
| P42.17 | Leave a prompt unanswered | 3 min: `NO RESPONSE - HOLDING`; 5 min: CLOSED `NO RESPONSE - END OF MISSION`, THUNDER idle | ☐ |
| P42.18 | CFF with Observer line `BRAVO 1-1`, adjust; B sends `adjust` LEFT 100 | Taken from B (the observer); the correction is on B's line to the target | ☐ |
| P42.19 | C (not the observer) sends `adjust` | FIRES readable by all (no role nets): taken. With role nets on and C's role without FIRES: RPT `not the issuer, the observer or on the FIRES net`, nothing fires | ☐ |
| P42.20 | A player of another side files `adjust` in the thread | Not passed on | ☐ |
| P42.21 | During a thread mission, the TAC//SUPPORT ARTY screen | THUNDER busy; its rounds in the round log; the adjust pad works for A as before | Withdrawn 2026-11-01: TAC//SUPPORT app removed |
| P42.22 | ALiVE combat-support battery: CFF FFE HE, 3 rounds | WILCO `FFE - n x HE - ...`, ON TASK when the FSM takes it, CLOSED `ROUNDS COMPLETE` when it is done. CFF ADJUST: CANTCO `ADJUST NOT AVAILABLE`; Control B: `FIRE WHEN READY ONLY` | Withdrawn 2026-11-02: ALiVE support provider removed |
| P42.23 | CAS: CLEARED HOT and EOM still work on a `cas` thread (P38) | As P38 | ☐ |
| P42.24 | RPT | No error from `jmfsb_support_fires_fnc_srvThread`, `thread*`, `jmfsb_support_fnc_srvFollowUp`, `readOrder`, `observer` | ☐ |
| P42.25 | A: @TRIDENT, CALL FOR FIRE - Warno 1 B FFE, grid 5 km out, Engagement rounds 2, SEND | One thread: ROGER, WILCO `ETA m:ss - FFE - 2 MISSILES - TOF n S - <description>`, ON TASK; `SHOT` (`TOF n`) as the first missile leaves; `SPLASH` about 5 s before the first lands; two missiles on the grid; then `ROUNDS COMPLETE - REQUEST BDA` (bda, repeat, close). TRIDENT reads TASKED meanwhile | ☐ |
| P42.26 | A: `repeat`, then `bda`, then `close` | 2 more missiles (SHOT, SPLASH, ROUNDS COMPLETE again); `END OF MISSION?` (close, repeat); CLOSED `END OF MISSION`, TRIDENT idle after its cooldown with 2 left | ☐ |
| P42.27 | CFF to TRIDENT: Warno 1 A ADJUST; then Warno 1 none ticked; then rounds 5 | CANTCO `ADJUST NOT AVAILABLE`; none ticked: WILCO `... FFE - 1 MISSILE ...`; 5: as many as the salvo size (2) | ☐ |
| P42.28 | CFF to TRIDENT: Control C TOT 3 min ahead; Control B AT MY COMMAND | TOT: WILCO `TOT hhmm`, the first missile lands at that minute (`CANNOT MAKE TOT` for 10 s ahead). AT MY COMMAND: `READY - AT MY COMMAND` (confirm, close), nothing launches until `confirm` | ☐ |
| P42.29 | CFF to TRIDENT: Engagement B SMOKE; a grid 0.5 km away; a grid beyond its reach; a friendly 300 m from the grid, DC not ticked | `NO STORES SMOKE`; `TOO CLOSE n/1 KM`; `OUT OF RANGE n/max KM`; `DANGER CLOSE NOT ACKNOWLEDGED` | ☐ |
| P42.30 | A: @GHOST, CALL FOR FIRE - FFE, grid of the enemy vehicle, rounds 2 | WILCO `ETA m:ss - FFE - 2 MUNITIONS - TRANSIT n S`, ON TASK, `SHOT` (`TRANSIT n S`); no SPLASH; the munitions hunt round the grid and dive; when both are gone `ROUNDS COMPLETE - REQUEST BDA` | ☐ |
| P42.31 | CFF to GHOST with Control C TOT; then a GHOST CFF and `close` while the munitions are on station | CANTCO `TOT NOT AVAILABLE`. CLOSE: the thread CLOSED `END OF MISSION`, the munitions in the air blow up where they are | ☐ |
| P42.32 | Leave TRIDENT's ROUNDS COMPLETE unanswered | 3 min: `NO RESPONSE - HOLDING`; 5 min: CLOSED `NO RESPONSE - END OF MISSION`, TRIDENT idle | ☐ |
| P42.33 | RPT | No error from `jmfsb_support_fires_fnc_threadStrike`, `threadLaunch`, `threadTot`, `flyCruise`, `loiterOne`, `loiterTick`, `sortieDone` | ☐ |

### P43. Support quick replies and player crews in TAC//MSG (2026-11-01)

DESIGN_SUPPORT_MESSAGING 6.2, 7 and D8. The P42 setup (A the JTAC, battery
THUNDER, the same deck), plus a **JMSB - CAS** aircraft HOG, and player D of
A's side. A Little Bird / AH-6 and an Mk6 mortar, empty, near D. Built, not
seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P43.1 | A: CALL FOR FIRE to THUNDER (ADJUST), open the thread; wait for `ADJUST?` | The spine shows `ADJUST?` large on the accent, no ANSWERS line. Quick reply tiles: ADD, DROP, LEFT, RIGHT, FFE, EOM - nothing else | ☐ |
| P43.2 | A: press ADD | The row becomes 25, 50, 100, 200, 400, BACK; the label reads `ADJUST ADD` | ☐ |
| P43.3 | A: press 100 | One `adjust` reply ADD 100 on the thread (subject `ADJUST ADD 100`), no composer opened; the row is back to normal; the next round lands 100 m further (P42.3) | ☐ |
| P43.4 | A: ADD, then BACK | The row is back to normal; nothing filed | ☐ |
| P43.5 | After a FFE splash (`ROUNDS COMPLETE - REQUEST BDA`): press BDA | The composer opens the BDA card on this thread (Target is required) | ☐ |
| P43.6 | A reply after a prompt (e.g. after A's ADJUST, before SHOT) | The tiles are the callforfire row: ADD, DROP, LEFT, RIGHT, FFE, REPEAT, CHECK FIRE, EOM - on two rows, VOICE MSG at the end of the first; only those the thread's state takes (REPEAT, FFE and ADJUST need ACCEPTED / IN_PROGRESS) | ☐ |
| P43.7 | A: EOM | The thread CLOSED, with no outcome; no tiles | ☐ |
| P43.8 | B opens A's CFF thread | No EOM (only the issuer may close); no callforfire row - B gets the one-tap replies and the prompt's answers the server takes from him | ☐ |
| P43.9 | A: `cas` to HOG; after WILCO | Tiles CLEARED HOT, ABORT, RTB, CLOSE (CLEARED HOT and ABORT only once ACCEPTED). CLEARED HOT files in one press | ☐ |
| P43.10 | A deck without `rtb` (or not run): a `cas` thread | RTB is simply not on the row | ☐ |
| P43.11 | A SITREP thread in ACCEPTED | ROGER / WILCO / ON TASK and the phrases as before - no CLEARED HOT, ABORT, REPEAT | ☐ |
| P43.12 | D gets into the AH-6 as pilot; A: NEW, CHANGE | The SUPPORT group lists D after the assets: D's name, `CAS - PLAYER - AH-6M PAWNEE` (the vehicle's own name); no ETA | ☐ |
| P43.13 | D as a passenger of a transport heli, then as its pilot | Passenger: not listed. Pilot: `TRANS - PLAYER - <heli>` | ☐ |
| P43.14 | D as the mortar's gunner | `ARTY - PLAYER - MK6 MORTAR` | ☐ |
| P43.15 | A: `@` on the CC line | D's crew row is on the @ list with the assets; picking it puts D on TO and opens `cas` (or `callforfire` from the mortar) | ☐ |
| P43.16 | A sends the `cas` to D | D gets the thread as a man does; no AI ROGER; D's tiles are ROGER / WILCO (not the cas row) | ☐ |
| P43.17 | D gets out | Within 2 s D's crew row is gone from the open picker | ☐ |
| P43.18 | RPT | No error from `jmfsb_tacpad_fnc_readerQuick`, `readerQuickTiles`, `readerReplies`, `jmfsb_support_fnc_mailboxes` | ☐ |

### P44. Transport, casevac, airdrop, resupply and QRF called by message (2026-11-01)

DESIGN_SUPPORT_MESSAGING step 7. Dedicated server, players A (JTAC, group
ALPHA 1-1) and B on one side, A's squad on foot. A **JMSB - Transport** RAVEN
(class helicopter, PARADROP on, Extract Wait 2 min), a **JMSB - QRF
Insertion** REACT (AIR ASSAULT and STATIC LINE), a **JMSB - Logistics** MULE
(AIRDROP and SLING, a catalog with a HUNTER and a crate), a JMSB field
hospital crate placed 3 km away. The built-in cards (step 7 cards; `hlz`
with Pickup). Support tasking tag empty. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P44.1 | A: `hlz` to RAVEN - Pickup on A's squad, Line 1 an LZ 3 km off, Line 3 `ALPHA`, Line 4 GREEN, SEND | One thread: ONE message `ROGER, WILCO - ETA m:ss - ALPHA` (not ROGER then WILCO - 2026-11-01), then at launch WHEELS UP `INBOUND - ETA m:ss` and ON TASK | ☐ |
| P44.1a | Wait while RAVEN flies to the pickup | Every minute INBOUND `ETA m:ss - <RAVEN's grid>` (2026-11-01) | ☐ |
| P44.1b | Wait until about 1 min out from the pickup | `1 MIN OUT - POP SMOKE` in the thread, FLASH; on A's screen, upper right, the popup `RAVEN 1 MIN OUT - POP SMOKE`. Line 5 IR STROBE: `POP IR` (2026-11-01) | ☐ |
| P44.2 | Wait | RAVEN lands at the pickup engine running; lifts when A's squad is aboard (or 2 min); WHEELS UP `TO <grid>` | ☐ |
| P44.3 | Wait | INBOUND every minute; about 1 min out: ONE FLASH message `1 MIN OUT - POP SMOKE - LZ STATUS?` (cold, hot) and A's popup; unanswered, RAVEN orbits 1 km short of the LZ, side rail "holding short" | ☐ |
| P44.4 | A: COLD | RAVEN goes in and lands; WHEELS DOWN `<grid>`, then `WHEELS DOWN - PAX OFF?` (paxoff, hold); AI passengers out | ☐ |
| P44.5 | A: HOLD | `HOLDING - PAX OFF?` (paxoff, rtb); RAVEN stays | ☐ |
| P44.6 | A: PAX OFF | `HOLD, RTB OR NEXT LIFT?` (hold, rtb, hlz) | ☐ |
| P44.7 | A: a new `hlz` in the thread (Pickup here, LZ elsewhere) | WILCO again with the ETA from the LZ; ON TASK; WHEELS UP `TO <grid>`; flies it | ☐ |
| P44.8 | A: RTB | RAVEN goes home (by Line 7's egress when given); CLOSED `RTB` | ☐ |
| P44.9 | `hlz` with Line 4 RED | One message `ROGER, WILCO - HOT LZ - REPLY CONFIRM TO LAUNCH - ETA ...`; the quick replies show CONFIRM; RAVEN does not launch. CONFIRM: it launches (2026-11-01) | ☐ |
| P44.10 | `hlz` RED, then RTB instead of CONFIRM | CANTCO `HOT LZ NOT ACKNOWLEDGED`; nothing launched | ☐ |
| P44.11 | At 1 MIN - LZ STATUS? answer HOT | `HOT LZ - CONFIRM` (confirm, rtb); it holds short until CONFIRM, then goes in | ☐ |
| P44.12 | Leave a prompt unanswered | 3 min: `NO RESPONSE - HOLDING`; 5 min: RAVEN RTB, CLOSED `NO RESPONSE - RTB` | ☐ |
| P44.13 | `hlz` without Line 1 | CANTCO `NO TARGET LOCATION` | ☐ |
| P44.14 | `casevac` to RAVEN - pickup grid, 2 patients | WILCO `ETA - 2 PATIENTS`; lands, WHEELS DOWN; 2 aboard (or 2 min): `PATIENTS ABOARD - DESTINATION?` (destination, freetext) | ☐ |
| P44.15 | A: `destination` empty (DEFAULT) | WHEELS UP `TO FIELD HOSPITAL <grid>`; lands by the hospital crate; `WHEELS DOWN - PAX OFF?`. No hospital anywhere: a terrain HOSPITAL, else `TO BASE` | ☐ |
| P44.16 | A: a free-text reply with a grid at DESTINATION? | Flies to that grid | ☐ |
| P44.17 | `airdrop` to RAVEN with B aboard, Line 1 a DZ | PARADROP: B jumps on a static line; going home `PACKAGE AWAY - CONFIRM RECEIPT`. RECEIVED: CLOSED `RECEIVED` | ☐ |
| P44.18 | `qrf` to REACT - Line 2 a link-up 2 km off, Line 1 `REACT TO ALPHA`, Line 5 `JOIN` | WILCO `ETA - AIR ASSAULT - REACT TO ALPHA`; WHEELS UP, ON TASK; WHEELS DOWN at the landing; `SQUAD DOWN AT <grid> - n MEN - YOURS - LINKED UP?`; the squad joins A. RECEIVED: CLOSED `LINKED UP - ...`, also when REACT is home already | ☐ |
| P44.19 | `qrf` with Line 3 `STATIC LINE`, Line 5 `HOLD` | STATIC LINE; the squad holds the link-up; `... - HOLDING - LINKED UP?` | ☐ |
| P44.20 | `resupply` to MULE - Item 1 `hunter` x 1, AIRDROP, SMOKE RED | WILCO `ETA - 1 x HUNTER - AIRDROP`; ON TASK; the HUNTER lands under a chute with red smoke; `PACKAGE AWAY - CONFIRM RECEIPT` | ☐ |
| P44.21 | A: NOT FOUND | The item pops smoke again; CLOSED `NOT FOUND - LANDED AT <grid>` | ☐ |
| P44.22 | `resupply` Item 1 `TANK` | CANTCO `NO STORES TANK` | ☐ |
| P44.23 | `resupply` SLING of an item the hook cannot lift | CANTCO with the check's reason (`... CANNOT GO ON A HOOK` / `... TOO HEAVY ...`) | ☐ |
| P44.24 | `airdrop` to MULE, Contents `2 x crate`, Line 5 `270/10` | WILCO `ETA - 2 x CRATE ... - AIRDROP - WIND 270/10`; two crates dropped | ☐ |
| P44.25 | The TAC//SUPPORT board: a TRANSPORT PICKUP to RAVEN and a LOGISTICS AIRDROP to MULE | As before: the board's card is filed, its order flies; RPT `the board's own card`; no second sortie | Withdrawn 2026-11-01: TAC//SUPPORT app removed |
| P44.26 | ALiVE combat-support transport: `hlz` | WILCO `ETA - TO PICKUP <grid>`; it lands at the pickup; WHEELS DOWN; `WHEELS DOWN AT PICKUP - CONFIRM FOR THE LZ`; CONFIRM: it flies to the LZ; WHEELS DOWN, CLOSED `WHEELS DOWN AT <grid>` | Withdrawn 2026-11-02: ALiVE support provider removed |
| P44.27 | ALiVE transport: `casevac`, DESTINATION? answered DEFAULT | Lands at the field hospital (or CLOSED `NO MEDICAL FACILITY - RTB`) | Withdrawn 2026-11-02: ALiVE support provider removed |
| P44.28 | A second `hlz` to RAVEN while it flies one | CANTCO `TASKED` | ☐ |
| P44.29 | RPT | No error from `jmfsb_support_air_fnc_lift*`, `qrfThread`, `qrfReply`, `thread*`, `jmfsb_support_logistics_fnc_srvThread`, `threadReply`, `jmfsb_support_fnc_prompt`, `readOrder`, `medicalNearest`, `jmfsb_support_fnc_inbound`, `srvReply`, `jmfsb_messaging_fnc_registerBuiltins`, `jmfsb_support_logistics_fnc_inbound` | ☐ |
| P44.30 | A deck WITHOUT the support cards (the 2026-11-01 RPT's case): `hlz` RED to RAVEN, then CONFIRM | RPT at start `built-in cards (support): ...`; the WILCO says REPLY CONFIRM TO LAUNCH, CONFIRM is offered and works, 3 min silent gives `NO RESPONSE - HOLDING` (no `no such template 'prompt'`); the whole P44.1-P44.8 run works the same (2026-11-01) | ☐ |
| P44.31 | The same with a deck that has them | RPT `report deck: <n> card(s) skipped - the mod carries them: ...`; behaviour the same, the mod's own cards used (2026-11-02) | ☐ |
| P44.32 | `qrf` to REACT, `resupply` to MULE | Each: one `ROGER, WILCO - ...`; WHEELS UP `INBOUND - ETA m:ss`; INBOUND every minute; `1 MIN OUT - POP SMOKE` with A's popup (2026-11-01) | ☐ |
| P44.33 | A card RAVEN does not fly (a `cas` card to its box) | ROGER alone, about 2 s after SEND; the thread stays at RECEIPT (an asset slower than 2 s: ROGER, then its WILCO) | ☐ |
| P44.34 | Circle, don't land (user, 2026-11-02): P44.1, RAVEN reaches the pickup | RAVEN circles the pickup about 200 m out, 50 m up, and does not land; side rail `circling <grid>, looking for your smoke`. The same at the LZ after COLD (P44.4), at a casevac's pickup and its destination. P44.2 / P44.4 land only after P44.37 | ☐ |
| P44.35 | A throws a red smoke within 150 m of the pickup | Within a few seconds `I SEE RED SMOKE`, FLASH, quick replies CORRECT / WRONG. A white `SmokeShell`: `I SEE WHITE SMOKE`; a green 40 mm: `I SEE GREEN SMOKE`. Line 5 IR STROBE and an IR grenade: `I SEE IR STROBE`; a chemlight with Line 5 SMOKE is not seen | ☐ |
| P44.36 | A: WRONG | RAVEN keeps circling; that smoke is not called again; a second smoke of another colour: `I SEE <its colour> SMOKE` | ☐ |
| P44.37 | A: CORRECT | `READY TO LAND - CLEARED?`, FLASH, quick replies CLEARED TO LAND / HOLD / ABORT. A: CLEARED TO LAND - RAVEN lands at the smoke (a clear spot near it), side rail `cleared to land, landing at <grid>`; WHEELS DOWN as before | ☐ |
| P44.38 | No smoke: RAVEN circles 45 s | `CIRCLING - NO SMOKE SEEN - POP SMOKE` (routine, once), quick reply NO SMOKE. A: NO SMOKE - `READY TO LAND - CLEARED?`; CLEARED TO LAND: it lands on the grid | ☐ |
| P44.39 | At READY TO LAND - CLEARED?: A: HOLD | RAVEN keeps circling; about 30 s later `READY TO LAND - CLEARED?` again | ☐ |
| P44.40 | At READY TO LAND - CLEARED?: A: ABORT | RAVEN goes home; CLOSED `RTB` | ☐ |
| P44.41 | `hlz` Line 4 RED | CONFIRM to launch as before, then at the pickup the circle and `READY TO LAND - CLEARED?` too - it never lands on CONFIRM alone | ☐ |
| P44.42 | Circling, A silent | 3 min after the last prompt `NO RESPONSE - HOLDING` (same quick replies); 5 min: home, CLOSED `NO RESPONSE - RTB` | ☐ |
| P44.43 | `qrf` AIR ASSAULT to REACT | REACT circles the link-up; the same smoke / clearance prompts; CLEARED TO LAND: it ropes or lands. Silent 5 min: the insertion is off, home, CLOSED `NO RESPONSE - RTB` | ☐ |
| P44.44 | ALiVE transport: `hlz` | It flies ALiVE's CIRCLE over the pickup, then the same prompts; CLEARED TO LAND: it lands (ALiVE picks the spot), WHEELS DOWN AT PICKUP - CONFIRM FOR THE LZ; at the LZ the circle and the clearance again | Withdrawn 2026-11-02: ALiVE support provider removed |
| P44.45 | RPT | No error from `jmfsb_support_fnc_lzClear*`, `lzMarks`, `markColour`, `popWord`, `jmfsb_support_air_fnc_liftCleared`; lines `circling ... looking for`, `landing told 'correct'`, `cleared to land at` | ☐ |
| P44.46 | Rotor clear spot (2026-11-02, the RPT 07:37:53 write-off): the P44.1 run with A standing by the hangars and trees near RAVEN's module | RAVEN is not written off `canMove false ... hithrotor 1.00 ... never hit`. Where its start or a landing pad had something in the rotor's way the RPT says `... blocked for the rotor by <what> - moved n m`; it lands clear of trees and buildings | ☐ |
| P44.47 | Rotor safety net: in the debug console, `RAVEN`'s helicopter on the ground near base during a sortie, `_heli setHitPointDamage ["hithrotor", 1]` | RPT `... hithrotor wrecked at <grid> before it left its airfield, nothing hit it - repaired once, not written off`; it flies on. Done twice in one sortie: written off as before | ☐ |

### P45. Support thread map pins (2026-11-01)

DESIGN_SUPPORT_MESSAGING 6.3, build step 8. The P42 / P44 setup: dedicated
server, A (JTAC) and B on one side, battery THUNDER, CAS HOG, transport RAVEN,
the step 7 deck. BFT on. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P45.1 | A: `cas` to HOG - Line 1 a grid 2 km off, Line 2 `OBJ RAVEN`, Line 3 / 4 an ingress and an egress grid; SEND. Open the game map, then the tablet's map | Both maps: a black `mil_destroy` `HOG TARGET OBJ RAVEN` on the grid, a line from the ingress to it with `IN` at its end, a line from it to the egress with `OUT`. Within 2 s of SEND | ☐ |
| P45.2 | B (not addressed): look at the map; then open the thread | Nothing before; the same shapes within 2 s of opening | ☐ |
| P45.3 | `cas` with Line 1 250 m from A, DC ticked | A red ring of 300 m round the target, `DANGER CLOSE 300 M - FRIENDLY 250 M` (about) at its top. A walks out past 300 m: the ring goes within 2 s | ☐ |
| P45.4 | CLEARED HOT, the run goes IN_PROGRESS | HOG's overlay too: its search ring with `SEARCH n M`, the legs; HOG's route from the airframe through its plan, moving every 2 s | ☐ |
| P45.5 | The run ends (CLOSED) | Every shape of the thread is gone within 2 s; a pin A set with CURRENT LOC / MAP PIN on the thread stays | ☐ |
| P45.6 | CALL FOR FIRE to THUNDER, 600 m from A's squad, DC ticked | `THUNDER TARGET` on the grid; a red 600 m ring naming the nearest friendly | ☐ |
| P45.7 | FFE, rounds in the air | A red filled ring round the impact, `THUNDER - SPLASH 0:nn`, counting down in 2 s steps; THUNDER's point and MIN / MAX rings in black | ☐ |
| P45.8 | The salvo lands | The ring becomes a red dot per round, the first numbered with its salvo | ☐ |
| P45.9 | `hlz` to RAVEN - Pickup, Line 1 LZ, Line 2 `LZ CROW`, Line 6 / 7 | `RAVEN LZ LZ CROW` and `RAVEN PICKUP` (`mil_pickup`); IN and OUT legs into the LZ. In flight: the route from RAVEN through its plan | ☐ |
| P45.10 | A NEXT LIFT `hlz` in the same thread, a new LZ | The LZ moves to the new card's within 2 s | ☐ |
| P45.11 | `casevac`, `airdrop` (Line 3 `DZ HAWK`), `resupply`, `qrf`, `onstation` | PICKUP; `DZ DZ HAWK` (`mil_end`); DELIVERY; LINK-UP; STATION | ☐ |
| P45.12 | `cas` to a player crew D (P43.12) | The card's shapes, no call sign in front, no overlay | ☐ |
| P45.13 | A disconnects and rejoins | No shapes until A opens the thread; then back | ☐ |
| P45.14 | RPT | No error from `jmfsb_support_fnc_pinTick`, `pinRoot`, `pinCard`, `pinLive`, `pinMarker`, `readOrder` on a client | ☐ |

### P46. TAC//SUPPORT removed (2026-11-01)

docs/DESIGN_SUPPORT_MESSAGING.md step 9. The P38 / P42 / P44 mission. Built,
not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P46.1 | Tablet bar MENU | No SUPPORT row; PAC and SETTINGS still there | ☐ |
| P46.2 | SETTINGS > DEVICE KEYS, a tablet key and a walking button | No Support / Tablet on Support choice. A fresh profile: device key 4 opens SETTINGS | ☐ |
| P46.3 | Addon Options, JMSB - Tablet & Map | No TAC//SUPPORT category, no Danger close distance setting | ☐ |
| P46.4 | `cas` to HOG with a friendly 250 m from the target, DC not ticked | CANTCO `DANGER CLOSE NOT ACKNOWLEDGED` (the card's own threshold) | ☐ |
| P46.5 | TAC//MSG NEW, CHANGE: the SUPPORT group | Every asset with its state and ETA, as P36 | ☐ |
| P46.6 | Any order an asset takes or refuses | A SUPPORT line on the notify rail with the asset's words | ☐ |
| P46.7 | RPT, a whole mission | No error naming a `jmfsb_tacpad_apps` support function, dialog or variable | ☐ |

### P47. CAS prompts and BDA (2026-11-01)

docs/DESIGN_SUPPORT_MESSAGING.md step 5 (5.4, D9). The P38 mission: HOG
(jet), SNAKE (attack helicopter), REAPER (CAS drone). The built-in cards:
`in`, `off`, the `bda` COUNT / RE-ATTACK lines.
Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P47.1 | `cas` to REAPER, no CLEARED HOT for 60 s | `AWAITING CLEARED HOT` from REAPER, FLASH (banner, accent row); quick replies CLEARED HOT, ABORT | ☐ |
| P47.2 | Stay silent 3 min more | `NO RESPONSE - HOLDING` (routine, not FLASH), same quick replies | ☐ |
| P47.3 | Stay silent 2 min more | REAPER leaves; thread CLOSED `NO RESPONSE - RTB` | ☐ |
| P47.4 | New `cas` to REAPER, CLEARED HOT within 60 s | No AWAITING prompt; ON TASK and `IN` as it runs in; after the release `OFF`, then `REQUEST BDA` (quick reply BDA) | ☐ |
| P47.5 | Watch REAPER after the release | It does not fly off the map: back over the grid at 4000 m, dark; the row reads ON STATION | ☐ |
| P47.6 | BDA: Result DAMAGED, a TARGET grid 200 m from the first, RE-ATTACK ticked | The BDA shows in the thread; `RE-ATTACK? <n> <store> LEFT` with the rounds really left; quick replies CLEARED HOT, NO | ☐ |
| P47.7 | CLEARED HOT | `IN`, it attacks the BDA's grid (not the first), `OFF`, `REQUEST BDA` again | ☐ |
| P47.8 | BDA with RE-ATTACK ticked, then NO | `<n> MIN ON STATION - FURTHER TASKING?`; quick replies CAS, RTB, CLOSE | ☐ |
| P47.8a | Another strike, BDA with RE-ATTACK not ticked (stores left) | No RE-ATTACK?: straight to `<n> MIN ON STATION - FURTHER TASKING?` | ☐ |
| P47.9 | CAS: a new `cas` card in the thread on another grid | WILCO with an ETA from where it is; held over the new grid; `AWAITING CLEARED HOT` after 60 s | ☐ |
| P47.10 | A `cas` card in the thread with no grid | `NO TARGET LOCATION - <n> MIN ON STATION - FURTHER TASKING?` | ☐ |
| P47.11 | RTB | REAPER leaves; thread closes | ☐ |
| P47.12 | REAPER with one store, strike, BDA | No RE-ATTACK?: it leaves, CLOSED `WINCHESTER` | ☐ |
| P47.13 | REAPER on a thread strike, wait out its 30 min | `BINGO IN 2 MIN` (FLASH) at 28 min, quick replies RTB, CLOSE; it leaves 2 min later, CLOSED `BINGO` | ☐ |
| P47.14 | HOG on station, `cas` from station, CLEARED HOT | `IN` from the hold, `OFF` + `REQUEST BDA` at the release; back at the hold the strike thread stays open | ☐ |
| P47.15 | BDA with RE-ATTACK ticked, CLEARED HOT | In from the hold again on the BDA's grid | ☐ |
| P47.16 | BDA without the RE-ATTACK tick (FURTHER TASKING? at once), then CLOSE in the strike thread | The strike thread closes; HOG stays at the hold, the on-station thread open | ☐ |
| P47.17 | Another strike, BDA, NO, then RTB in the strike thread | HOG goes home; both threads close `RTB` | ☐ |
| P47.18 | HOG on station with 5 min asked | `BINGO IN 2 MIN` (FLASH) in the on-station thread (and an open strike thread) at 3 min; home at 5, `BINGO` | ☐ |
| P47.19 | `cas` to SNAKE, CLEARED HOT | `IN`, one pass, `OFF` + `REQUEST BDA`; it holds the run-in distance short again, does not go home | ☐ |
| P47.20 | BDA ticked, CLEARED HOT; then BDA not ticked, a new `cas` in the thread | Re-attack from short; then WILCO for the new grid, holds short of it until CLEARED HOT | ☐ |
| P47.21 | SNAKE: let its Time on Station run from the first pass | `BINGO IN 2 MIN` 2 min before it; home | ☐ |
| P47.22 | ALiVE NEO CAS: `cas`, CLEARED HOT | ON TASK and `IN` when ALiVE takes it; `OFF` + `REQUEST BDA` about 15 s after its first rounds go | Withdrawn 2026-11-02: ALiVE support provider removed |
| P47.23 | BDA DESTROYED, COUNT 2 | ALiVE C2ISTAR has a sitrep at the BDA grid (enemy = the card's Line 5, 2 KIA, BDA in remarks) with an enemy marker; RE-ATTACK ticked and rounds left - `RE-ATTACK?`, not ticked - `FURTHER TASKING?` | Withdrawn 2026-11-02: ALiVE support provider removed |
| P47.24 | ALiVE: NO | `FURTHER TASKING?` (no minutes) | Withdrawn 2026-11-02: ALiVE support provider removed |
| P47.25 | ATO `cas`, CLEARED HOT, then a BDA in its thread | The sitrep reaches ALiVE; no prompts after it | Withdrawn 2026-11-02: ALiVE support provider removed |
| P47.26 | Messaging's ALiVE forwarding off, a BDA in an ALiVE thread | No sitrep | Withdrawn 2026-11-02: ALiVE support provider removed |
| P47.27 | A player pilot's box, the same flow by hand | No AI prompt; the pilot can file `in`, `off` by hand | ☐ |
| P47.28 | RPT | No error from `jmfsb_support_fnc_promptCleared` / `casPrompt` / `threadBda`, `jmfsb_cas_fnc_request` / `threadReply`, `jmfsb_support_air_fnc_casTick` / `casJob` / `casRetask` / `threadReply` | ☐ |

### P48. Point Man on the phone and side devices (2026-11-01)

User: "navagation app does not show on the phone or side devices" - "no line
no direction no distance". Tablet mode, phone in the GPS slot. POINT MAN: ADD
three grids 300-800 m apart, USE - NAVIGATE, close the tablet. Built, not
seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P48.1 | Read the phone's status row | It leads with `PM 1 420M 045°` (waypoint, distance, bearing) before MESH; the row's type is about the size it was without PM, every cell readable | ☐ |
| P48.2 | Look at the phone's map | The three numbered dots and the legs between them in ink; the leg from you to WP 1 and its dot in the accent | ☐ |
| P48.3 | Walk 100 m toward WP 1 | The PM cell's distance drops and its bearing follows; the accent leg stays on you | ☐ |
| P48.4 | Side Device in the GPS slot instead (left edge, then right) | The PM cell first in the 3 x 3 status grid, same reading, the grid's type readable; the route and the accent leg on its map | ☐ |
| P48.5 | Configure Addons > Map Tools > Bearing units: Mils | The cell reads `PM 1 420M 0800 MIL`; Degrees and Both read `045°` | ☐ |
| P48.6 | Open the tablet | The bar's right block reads `PM WP1 420M 045°` in full, not wrapped, beside BATT; PAC still between MENU and ESC CLOSES | ☐ |
| P48.7 | Reach WP 1 (inside 25 m) | "WP 1 reached" note; the cell reads `PM 2 ...`, the accent moves to the leg to WP 2 | ☐ |
| P48.8 | STOP on the page (or reach the last waypoint) | The PM cell goes from the phone and the side device; the dots and legs stay in ink, no accent leg; the tablet bar loses its PM fact | ☐ |
| P48.9 | [TEST] EW: GPS denied while navigating | The cell reads `PM 1 NO FIX` on red; no accent leg from you; the bar `PM WP1 NO FIX` | ☐ |
| P48.10 | RPT | No error from `jmfsb_pointman_fnc_cell` / `legText` / `navText` / `draw` / `attach`, `jmfsb_devices_fnc_overlayOpen` / `overlayDraw` | ☐ |

### P49. TAC//MSG: a filed card reads in one column (2026-11-02)

User: "the 2 column view in the message history is hard to read". Tablet
mode, TAC//MSG open. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P49.1 | `#jmfsb msg.flash`, open the thread | The card under the ink header bar is one column: each filled line's label (muted, not spaced out) in a column as wide as the longest label, its value right after it; no second column, no rule down the middle | ☐ |
| P49.2 | File a 6-LINE CASEVAC (the 9-line MEDEVAC is retired, 2026-11-02) with Line 1, 3, 4 and REMARKS filled, the rest empty; open it | Four rows only; Line 4 reads its tick word; the grid bold in the accent at your grid digits (8, then 10 with Device grid digits 10) | ☐ |
| P49.3 | REMARKS a sentence of 30+ words | The label on its own line at the left edge, the sentence under it across the full card width, wrapped; the row under it starts below the last line | ☐ |
| P49.4 | A card whose labels carry no number (SALUTE, SITREP) | Labels read `1. SIZE`, `2. ACTIVITY` ... by the card's own line order | ☐ |
| P49.5 | An hlz with Line 4 SECURITY ticked RED | The row reads SECURITY ... RED | ☐ |
| P49.6 | In a `callforfire` thread, ADD then 100 | The ADJUST reply on the spine reads CORRECTION ADD / DISTANCE (M) 100 as two key/value rows, a thin rule under it before the next reply | ☐ |
| P49.7 | A typed reply and the asset's `prompt` question | Read as before: the words alone; the question at the title size in the accent | ☐ |
| P49.8 | Text size 2.4, then UI size 80% | Rows grow, labels and values never overlap the row under them; values never smaller than a tile's detail line | ☐ |
| P49.9 | RPT | No error from `jmfsb_tacpad_fnc_readerCard` / `readerKv` / `readerKvRows` / `readerReplies` | ☐ |

### P50. ON STATION is an order to get in the air; a CFF that went nowhere says so (2026-11-02)

User: "arty never replied, and on station is not a fire mission its just an
order to get in the air". A CAS drone (HAWK), a support_air CAS module (a jet
and a helicopter), a virtual battery (FOX 1-1), a cruise or loitering launcher.
Tablet mode, TAC//MSG, NEW MESSAGE. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P50.1 | + TEMPLATE - REQUEST ON STATION, then `@HAWK` on the CC line | HAWK on the TO line; the card stays REQUEST ON STATION (not CAS REQUEST) | ☐ |
| P50.2 | SEND it with Line 2 empty, standing among friendlies | One reply `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss`; no DANGER CLOSE, no NO TARGET LOCATION; the drone orbits over you, dark, and fires nothing | ☐ |
| P50.3 | CAS REQUEST being written, then `@HAWK` | The card stays CAS REQUEST; a plain message then `@HAWK` opens CAS REQUEST as before | ☐ |
| P50.4 | REQUEST ON STATION to the jet's module | `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss`; it flies to its off-map hold and checks in. A jet with nothing on its pylons is not refused NO STORES | ☐ |
| P50.5 | REQUEST ON STATION to the helicopter's module | The same WILCO; it loiters over the area (you when Line 2 is empty), dark, weapons tight | ☐ |
| P50.6 | REQUEST ON STATION written, then `@FOX 1-1`; then a REQUEST ON STATION with `B:SUPPORT:fires:0` typed in full on the CC line | The mention switches the card to CALL FOR FIRE. The typed box: one CANTCO `NOT AN AIR ASSET`, no ROGER left hanging; the same from a cruise or loitering launcher | ☐ |
| P50.7 | CALL FOR FIRE to `@FOX 1-1`, TARGET - POLAR direction 6400 (mils), SEND (TARGET DESCRIPTION is optional since 2026-11-02) | Nothing sent: `NOT SENT - ... MUST BE BETWEEN 0 AND 360` beside SEND; a `NOT SENT` popup upper right; RPT `(messaging) INFO: not sent 'callforfire' - ...` | ☐ |
| P50.8 | Clear the polar line, give a grid, SEND | One reply at once: `ROGER, WILCO - ETA m:ss - ...`; RPT `sent 'callforfire' to [...,"B:SUPPORT:fires:0"]`; then SHOT, SPLASH | ☐ |
| P50.9 | CALL FOR FIRE on the FIRES net (or your squad), no asset on TO | It is filed on the net; popup `NO ASSET ADDRESSED - CFF sent - no support asset on TO, no AI answers it. @ the asset.`; RPT line `'callforfire' sent to [...] - no support asset addressed` | ☐ |
| P50.10 | A plain message on a net | No NO ASSET popup | ☐ |
| P50.11 | RPT | No error from `jmfsb_messaging_fnc_submit`, `jmfsb_tacpad_fnc_composeSend` / `composeMention`, `jmfsb_support_fnc_mailboxes` / `stationWilco` / `etaText`, `jmfsb_cas_fnc_srvThread`, `jmfsb_support_air_fnc_srvThread`, `jmfsb_support_fires_fnc_srvThread` | ☐ |

### P51. The report-card review applied (2026-11-02)

User decisions 2026-11-02 on `docs/REVIEW_REPORT_CARDS_2026-11-02.md`, in the
mod's built-in cards (the mod's own card always wins - nothing is run against
the database). Tablet mode, TAC//MSG. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P51.1 | Start with the live deck, read the RPT | `report deck: <n> card(s) skipped - the mod carries them: ... - retired: accepted, nineline, ontask` (once) | ☐ |
| P51.2 | `#jmfsb msg.flash` | A FLASH `CASEVAC <grid>` arrives from DOC RILEY - the 6-LINE CASEVAC, no refusal | ☐ |
| P51.3 | `seedTest` on (Seed test traffic), restart | Three threads arrive: CASEVAC, SITREP (no CALL SIGN line), CONTACTREP (the original full SALUTE); RPT has no `unknown field` line | ☐ |
| P51.4 | + TEMPLATE: the picker | TROOPS IN CONTACT (the plain quick card: only LOCATION required), SALUTE (the CONTACTREP card, every line as before), MIST unchanged, LIFT REQUEST (HLZ), PARADROP by those names (no CAS 9-LINE since 2026-11-02 - P54); no WILCO WITH DETAIL / ON TASK WITH DETAIL | ☐ |
| P51.5 | A TIC with only its location, SEND | Sent; subject `TIC <grid>` with no dangling dash | ☐ |
| P51.6 | Another player (or `msg.inbound` then a TIC from a second client) opens it | Quick replies ROGER and CLOSE (issuer only); ROGER is accepted and the thread reads RECEIPT; the same on a SITREP, DEFREP, CHECK-IN, METT-TC; on the unchanged CONTACTREP and MIST, ROGER is accepted too (their own reply list) | ☐ |
| P51.7 | A CAS REQUEST: the card | TARGET LOCATION first, then TARGET DESCRIPTION; no CUR LOC beside the target grid (MARKER only); no MAP REFERENCE line; the tick reads `Under 300 m - tick to acknowledge` | ☐ |
| P51.8 | A CALL FOR FIRE: TARGET - GRID typed by hand (`034 127`), nothing else, to `@FOX 1-1` | Sent (no required line left); the thread's map anchor and the pin are on the typed grid, not on you; one adjusting round (the label says empty = ADJUST FIRE) | ☐ |
| P51.9 | CALL FOR FIRE with only TARGET - SHIFT range `ADD 200` and a grid | Superseded (2026-11-02): the shift is its own card, CFF SHIFT - P54.4 | ☐ |
| P51.10 | In an adjust mission, open ADJUST FIRE from + TEMPLATE: RIGHT 50, and the other axis ADD 100 | One message; the next round lands right 50 and add 100 of the last | ☐ |
| P51.11 | CAS 9-LINE | Retired (2026-11-02: one CAS card) - P54.6 | ☐ |
| P51.12 | CAS 9-LINE DANGER CLOSE | Retired (2026-11-02) - CAS REQUEST's tick is P51.7 | ☐ |
| P51.13 | REQUEST BDA from a CAS asset, answer with the BDA card | TARGET LOCATION already holds the thread's point (AUTO); only RESULT is required | ☐ |
| P51.14 | In a damaged vehicle with half a tank, + TEMPLATE - VEHICLE REPORT | VEHICLE reads `<call sign> - <type>`; DAMAGE and FUEL ticked from the vehicle; tick another DAMAGE - it stays; on foot nothing is filled | ☐ |
| P51.15 | Squad app: a man reports A AMBER, another is unconscious; open a SITREP | STATUS AMMO AMBER, CAS RED; change them by hand and they stay | ☐ |
| P51.16 | LIFT REQUEST (HLZ) | PICKUP first and optional (empty = you), DROP-OFF LZ required, WIND filled `FROM ddd - n M/S` (or CALM) | ☐ |
| P51.17 | PARADROP to a transport module that flies a paradrop | ROGER, WILCO with the LOAD; the 1 MIN OUT alert asks for the card's MARKING | ☐ |
| P51.18 | The TO picker on a LOGI row; a PARADROP typed to a LOGI box | The picker offers RESUPPLY only; the typed one gets CANTCO `PARADROP IS A TRANSPORT CARD - SEND RESUPPLY` | ☐ |
| P51.19 | RESUPPLY with ITEM 1 named, no COUNT, no METHOD | Accepted: one of it, the module's first method | ☐ |
| P51.20 | QRF LINK-UP: ACTION ON ARRIVAL REINFORCE | The squad joins you on landing (as JOIN); RECOGNITION SIGNALS read on the card | ☐ |
| P51.21 | A fixed-wing on station checks in | The CHECK-IN's TIME ON STATION is a number of minutes | ☐ |
| P51.22 | A task thread to a player (a CASEVAC to a player crew) | Quick replies include WILCO and ON TASK again (one tap, DETAIL left empty) | ☐ |
| P51.23 | An asset's WILCO with an ETA after the script ran | The deck's WILCO carries `ROGER, WILCO - ETA m:ss ...` in its DETAIL | ☐ |
| P51.24 | SITREP to a box with ALiVE reports on | ALiVE's sitrep carries your group id as the call sign | ☐ |
| P51.25 | RPT | No error from `jmfsb_tacpad_fnc_composeAutoFill` / `autoValue` / `autoVehicle` / `autoDamage` / `autoFuel` / `autoWind` / `autoSquadAce` / `autoAnchor`, `jmfsb_messaging_fnc_fieldPos` / `srvThreadFor` / `subject`, `jmfsb_support_fnc_readOrder`, `jmfsb_support_fires_fnc_threadReply`, `jmfsb_support_logistics_fnc_srvThread` | ☐ |

### P52. Every support aircraft checks in on station (2026-11-02)

User: "in the support system an aircraft when it arrives on station needs to
send an AIRFRAME CHECK-IN". A support_air CAS module with a jet (HOG) and one
with a helicopter (VIPER) and a CAS drone (HAWK). Tablet mode, TAC//MSG. The
built-in CHECK-IN card (with CAPABILITIES and LASER CODE). Built, not seen in
game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P52.1 | REQUEST ON STATION to HOG, 20 min | At the off-map hold, one AIRFRAME CHECK-IN from HOG in the thread: Line 1 HOG, `1x <airframe>`, the hold and about 4000 m, the rounds left (`GBU-12 x2, ...`), 20 (a number), a four-figure abort code, `HOLDING OFF THE MAP, DARK` | ☐ |
| P52.2 | The same after the review deck | CAPABILITIES ticked from the airframe (a jet with a targeting pod: FMV, LASER and IR/NVG where its pod has them), LASER CODE 1111 - or the code set in ACE on the jet | ☐ |
| P52.3 | A `cas` card to HOG on station, CLEARED HOT, back at the hold; then a SAD/LOITER that moves it | No second check-in | ☐ |
| P52.4 | REQUEST ON STATION to VIPER | Over the area: one check-in from VIPER, `OVER THE GRID, DARK`, the station height | ☐ |
| P52.5 | A `cas` card to VIPER (not on station) | Where it holds short for CLEARED HOT: one check-in, `HOLDING SHORT FOR CLEARED HOT`, minutes no more than the module's Time on Station; the re-attack's hold does not check in again. CLEARED HOT before it gets there: one check-in where it holds short after the pass | ☐ |
| P52.6 | REQUEST ON STATION to HAWK | Over the grid: one check-in from HAWK, `OVER THE GRID, DARK`, under 60 min left, FMV ticked | ☐ |
| P52.7 | A `cas` card to HAWK, wait for it over the grid | One check-in, `OVER THE GRID, HOLDING FOR CLEARED HOT`; CLEARED HOT before it arrives: none on the way in, one when it is back over the grid after the pass | ☐ |
| P52.8 | An order with no thread (`jmfsb_support_fnc_request` from the debug console) to any of them | No check-in anywhere | ☐ |
| P52.9 | ALiVE: a `cas` card to NEO, CLEARED HOT | Within 2 km of the point: one check-in from NEO's call sign, no TIME ON STATION, `AT THE TARGET AREA, CLEARED HOT`; a re-attack or a new `cas` card in the thread: no second one. To the ATO: none | Withdrawn 2026-11-02: ALiVE support provider removed |
| P52.10 | RPT | One `checks in on thread` INFO line per check-in; no `unknown field` line; no error from `jmfsb_support_fnc_checkIn` / `airframeCaps` / `ordnanceLeft`, `jmfsb_support_air_fnc_checkIn` / `casTick`, `jmfsb_cas_fnc_request` | ☐ |

### P53. After contact, a SITREP (2026-11-02)

User: "after contact a sitrep should be sent". A squad of AI under you, an
enemy group in range, a command net in Shared mailboxes. Tablet mode,
TAC//MSG. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P53.1 | TIC key, then open the TIC thread | SEND SITREP is the first quick tile, before ROGER / CLOSE | ☐ |
| P53.2 | Press SEND SITREP | The composer opens on SITREP inside the TIC thread (REPLY IN THREAD); LOCATION holds the TIC's grid; STATUS AMMO and CAS filled from the Squad app's ACE state (AUTO) | ☐ |
| P53.3 | SEND it | Filed as a reply on the TIC thread's spine, not a new thread | ☐ |
| P53.4 | A second player (not the squad leader, not in your group) opens your TIC | No SEND SITREP tile. Your squad leader (a second client, in your group): SEND SITREP shown | ☐ |
| P53.5 | New TIC, fight, then stop firing; nobody shoots for 3 minutes | `CONTACT OVER? SEND SITREP` upper right, once; the TIC thread's row label reads it in the accent over SEND SITREP | ☐ |
| P53.6 | After the prompt, fire one shot (or be shot at) | The label goes back to QUICK REPLY; 3 quiet minutes later the prompt comes once more | ☐ |
| P53.7 | Keep firing every minute for 5 minutes | No prompt until 3 minutes after the last shot | ☐ |
| P53.8 | A man of your group files his own TIC from his position during the quiet time | The 3 minutes start again | ☐ |
| P53.9 | After the prompt, send the SITREP | No further prompt for that TIC; the label is QUICK REPLY | ☐ |
| P53.10 | New TIC, CLOSE the thread before 3 minutes | No prompt | ☐ |
| P53.11 | Skip since 2026-11-02 - the built-in SITREP is `both` and always wins. (Was: a SITREP that is still a root card: SEND SITREP) | A new SITREP on the TIC's net; LOCATION the TIC's grid, REMARKS `SITREP AFTER TIC <grid> - THREAD <id>`; beside SEND `THE DECK'S SITREP OPENS ITS OWN THREAD - THE TIC IS IN REMARKS`; sending it ends the watch | ☐ |
| P53.12 | RPT | No error from `jmfsb_tacpad_fnc_sitrepAfterTic` / `contactArm` / `contactAgain` / `contactCheck` / `contactDrop` / `contactTraffic` / `readerQuickTiles` / `readerQuick` | ☐ |

### P54. Report cards: CFF in three, one CAS card, ON STATION marker, EXTRACTION, crate picks (2026-11-02)

User decisions 2026-11-02 (review doc section 7, "Later the same day"), in
the mod's built-in cards. A battery (FOX 1-1), a transport (RAVEN) that offers
PICKUP > LZ and EXTRACT, a logistics module with a catalog of two or more
crates, a fixed-wing CAS (HOG) and a helicopter CAS (VIPER), two player-placed
map markers. Tablet mode, TAC//MSG. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P54.1 | + TEMPLATE: the picker | CALL FOR FIRE - GRID (CFF GRID), CALL FOR FIRE - POLAR, CALL FOR FIRE - SHIFT, EXTRACTION (HLZ) and LIFT REQUEST (HLZ); no CAS 9-LINE | ☐ |
| P54.2 | `@FOX 1-1` with nothing written; then write CFF POLAR first and `@FOX 1-1` | The first opens CFF GRID; the second keeps CFF POLAR | ☐ |
| P54.3 | CFF POLAR: direction 90, distance 800, no observer grid, ADJUST, to FOX 1-1 | WILCO; the round lands about 800 m east of you; the pin's TARGET is there. Give OBSERVER a marker 1 km north and send again - 800 m east of that marker | ☐ |
| P54.4 | CFF SHIFT: KNOWN POINT a marker, RIGHT 100, ADD 200, FFE | Fired 200 m beyond and 100 m right of the marker as seen from you; UP / DOWN changes nothing | ☐ |
| P54.5 | CFF GRID with nothing ticked under TYPE OF MISSION, SEND | Refused `TYPE OF MISSION is required - tick one`; the line head reads `REQ - TICK ONE` once and one red frame goes round the four ticks (not one per tick); tick ADJUST - the frame goes | ☐ |
| P54.6 | `@` a player flying a jet; RPT after the deck loads | The mention opens CAS REQUEST; no `nineline` in the deck (the review script removed it) and none built in | ☐ |
| P54.7 | REQUEST ON STATION: the AREA field | MARKER only (no CUR LOC), MARKER and REQ in its meta. SEND empty: `PICK A MAP MARKER FOR THE AREA`. Type a grid, SEND: the same, the field framed red | ☐ |
| P54.8 | REQUEST ON STATION, AREA a marker, to HOG; the same to VIPER | HOG holds off the map edge nearest the marker and checks in; VIPER loiters over the marker | ☐ |
| P54.9 | EXTRACTION to RAVEN: pickup a map marker away from you, SECURITY RED, SMOKE, 4 passengers, no destination | WILCO `HOT LZ - REPLY CONFIRM TO LAUNCH - ETA m:ss - 4 PAX`; CONFIRM; a minute out `1 MIN OUT - POP SMOKE - LZ STATUS?` for the pickup; COLD; it circles the pickup, `I SEE ... SMOKE` - CORRECT - `READY TO LAND - CLEARED?` - CLEARED TO LAND; it lands, loads every man of your side within 150 m, lifts, flies home, lands and unloads, thread CLOSED | ☐ |
| P54.10 | EXTRACTION with a DESTINATION marker | After the pickup: WHEELS UP `TO <grid>`, INBOUND, `1 MIN OUT - POP SMOKE` at the destination, circles, the smoke check and CLEARED TO LAND there, then `WHEELS DOWN - PAX OFF?` | ☐ |
| P54.11 | The pin of an EXTRACTION with a destination | PICKUP and DEST drawn | ☐ |
| P54.12 | With ALiVE: EXTRACTION to an ALiVE transport, no destination; then with one | First: CANTCO `NO DESTINATION - GIVE A GRID OR MARKER`; then flown as a lift, circling and cleared at both | Withdrawn 2026-11-02: ALiVE support provider removed |
| P54.13 | RESUPPLY with the logistics box on TO: ITEM 1 | A drop-down cell `PICK ONE` with REQ; press - the box's crates listed; pick one - the cell reads it; ITEM 2 lists NONE first | ☐ |
| P54.14 | RESUPPLY with nobody on TO | The items list every logistics asset's crates of your side | ☐ |
| P54.15 | Send RESUPPLY to the logistics box, ITEM 1 a crate, COUNT 2 | WILCO `ETA m:ss - 2 x <CRATE> - AIRDROP`; delivered | ☐ |
| P54.16 | A deck without the logistics addon loaded (or no logistics module) | ITEM 1 is a typed box as before | ☐ |
| P54.17 | TAC//MSG > NEW with the live deck | CFF GRID, CFF POLAR, CFF SHIFT and EXTRACTION (HLZ) as listed above - the built-in cards, whatever the deck holds | ☐ |
| P54.18 | RPT | No error from `jmfsb_support_fnc_readOrder` / `builtinCards`, `jmfsb_messaging_fnc_validate` / `registerTemplate`, `jmfsb_tacpad_fnc_composeCard` / `composeDrop` / `composeChoices` / `composeSend` / `autoValue`, `jmfsb_support_logistics_fnc_catalogNames`, `jmfsb_support_air_fnc_liftThread` / `liftLegs` / `liftJob` / `liftTick` | ☐ |

### P55. The jump by message: JUMP REQUEST to SKYTRAIN (2026-11-02)

User: "also want to change the halo/haho/static app in to a message based
one" ... "it also needs a work flow". The JUMPMASTER app is gone (P23.75
withdrawn). The workflow: `addons/jumpmaster/README.md`. A squad leader slot
(SL in its role) with four men, a second player in a rifleman slot of
another group; every man a parachute (`B_Parachute`), HALO masks on all but
one. Two map markers 3 km apart. No JMSB - Jump Aircraft module (the side's
own SKYTRAIN; the module is P58). Tablet mode, TAC//MSG. The built-in cards
(`jump`, `redlight`, `greenlight`, `stickout`, `go`). Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P55.1 | Tablet bar MENU; the tiles; SETTINGS > DEVICE KEYS, a walking button | No JUMPMASTER page, tile or `Tablet on Jumpmaster` choice | ☐ |
| P55.2 | As the SL: NEW, CHANGE, the SUPPORT group; then `@` | SKYTRAIN, JUMP, IDLE, the Blackfish's name, an ETA. `@SKYTRAIN` opens JUMP REQUEST | ☐ |
| P55.3 | As the rifleman: the SUPPORT group and `@` | No SKYTRAIN | ☐ |
| P55.4 | JUMP REQUEST, nothing ticked under TYPE, SEND | Refused: TYPE is required - tick one. RED LIGHT and GREEN LIGHT empty: refused, required | ☐ |
| P55.5 | HALO, RED and GREEN on the markers, the man without a mask in the squad, SEND to SKYTRAIN | One message: CANTCO `1 MAN WITHOUT A MASK`. Drop a man's parachute: `1 MAN WITHOUT A PARACHUTE - 1 MAN WITHOUT A MASK` | ☐ |
| P55.6 | Masks on everyone; the same card, PASSES 2, EXIT AUTO | One message `ROGER, WILCO - HALO 6000 M - 5 MEN - 2 PASSES - AUTO EXIT - RED LIGHT IN m:ss` (and `SHIFTED n M FOR WIND` in wind); then WHEELS UP `5 ABOARD - RED LIGHT IN m:ss`, the thread ON TASK; the squad in the Blackfish's seats at 6000 m | ☐ |
| P55.7 | The map while ON TASK | The pin's GREEN LIGHT, RED LIGHT (PICKUP when given); a line from the aircraft through RUN-IN, RED, GREEN | ☐ |
| P55.8 | Wait for the lights | RED LIGHT (FLASH) `PASS 1 OF 2 - STAND BY`; GREEN LIGHT - GO (FLASH) `PASS 1 OF 2 - 3 OUT ON THE LIGHT`; three men out 0.7 s apart; STICK OUT `3 OUT - 2 ABOARD - CIRCLING FOR PASS 2`; INBOUND `PASS 2 OF 2 - RED LIGHT IN m:ss`; the second pass; STICK OUT `5 OUT - 0 ABOARD`; CLOSE `STICK OUT - LEAVING THE DZ`; the aircraft gone | ☐ |
| P55.9 | STATIC, EXIT MANUAL, PASSES 1; stay aboard with one man past the window | RED LIGHT `STAND UP, HOOK UP`; GREEN LIGHT `JUMP FROM THE ACTION MENU`; JUMP in the action menu; STICK OUT `n OUT - 1 ABOARD`; the ask `MEN STILL ABOARD - HOLDING OVER THE DZ` (GO, ABORT); the aircraft orbits the green light | ☐ |
| P55.10 | Answer GO | GREEN LIGHT - GO `1 OUT OVER THE DZ`; he goes out on a static line; CLOSE `CABIN EMPTY - LEAVING THE DZ` | ☐ |
| P55.11 | Again to the hold; answer nothing | `NO RESPONSE - HOLDING` at 3 min; at 5 min GREEN LIGHT - GO `NO RESPONSE - 1 OUT OVER THE DZ` and out | ☐ |
| P55.12 | A new run; ABORT before the red light | It turns to orbit the green light; `ABORTED - HOLDING OVER THE DZ - 5 ABOARD - JUMP WHEN READY` (GO offered), nothing more asked; jump one by one with JUMP - CLOSE when the cabin is empty | ☐ |
| P55.13 | While a run is up, a second JUMP REQUEST from the SL | CANTCO `TASKED`; the row reads TASKED until the first one closes | ☐ |
| P55.14 | PICKUP a marker 1 km away from the squad | CANTCO `NOBODY AT THE PICKUP`. Two men walk to it, file again: WILCO `2 MEN ... - 3 NOT AT THE PICKUP`, the two boarded | ☐ |
| P55.15 | The rifleman files a JUMP REQUEST to `B:SUPPORT:jump:west` by hand | CANTCO `SQUAD LEADERS ONLY` (he does not lead his group) | ☐ |
| P55.16 | HAHO with the ALT readout | From the exit the phone's status row leads with ALT, height and sink rate; off on the ground | ☐ |
| P55.17 | `["jump:west", "jump", [], []] call jmfsb_support_fnc_request` | `[false, "BY MESSAGE - FILE A JUMP REQUEST"]` | ☐ |
| P55.18 | RPT | No error from `jmfsb_jumpmaster_fnc_*`, `jmfsb_support_fnc_readOrder` / `builtinCards` / `pinCard`; no `srvThread` / `srvLaunch` refusal in a normal run | ☐ |

### P56. A new task in the asset's thread; every support card has its row (2026-11-02)

Found while writing docs/WORKFLOWS.md. A CAS module (helicopter), a CAS module
(fixed-wing, AI), a Transport, a Logistics and a QRF Insertion module on the
players' side, Drone Escorts on with both escort classes set; a second
player on the FIRES net. Tablet mode, TAC//MSG. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P56.1 | CAS REQUEST to the helicopter; CLEARED HOT; at `OFF - RETURNING TO STATION - REQUEST BDA` (P57 since 2026-11-02) | Tiles BDA, CAS | ☐ |
| P56.2 | Press CAS | The composer on CAS REQUEST, REPLY, `IN THREAD <id> - A NEW TASK FOR <CALLSIGN>` beside SEND. Fill a new target, SEND | ☐ |
| P56.3 | Watch the thread | The CAS REQUEST in the same thread; `ROGER, WILCO - ETA m:ss - ...` (or WILCO) from where it is; it holds short; AWAITING CLEARED HOT after 60 s; CLEARED HOT runs it in on the new target | ☐ |
| P56.4 | Same, a CAS REQUEST it cannot fly (no store, or DANGER CLOSE unticked near friendlies) | FURTHER TASKING? again with the reason in front; the thread open | ☐ |
| P56.5 | The fixed-wing: REQUEST ON STATION, then a CAS REQUEST; at REQUEST BDA press CAS | The next strike in the strike thread, flown from the hold | ☐ |
| P56.6 | EXTRACTION with a destination to the transport; fly it to PAX OFF there (an insertion's PAX OFF egresses home since 2026-11-02, P57.19) | `HOLD, RTB OR NEXT LIFT?` with HOLD, RTB, HLZ | ☐ |
| P56.7 | Press HLZ, fill a new drop-off, SEND | LIFT REQUEST in the same thread; a fresh `ROGER, WILCO - ETA m:ss - <LOAD>`; WHEELS UP and the lift flown. RED on line 4: CONFIRM asked first | ☐ |
| P56.8 | In the lift thread, + TEMPLATE | LIFT REQUEST, EXTRACTION, CASEVAC and PARADROP among the cards; in a CAS strike thread, CAS REQUEST; in a call-for-fire thread, none of the root cards | ☐ |
| P56.9 | As the FIRES-net player in the CAS thread, + TEMPLATE | No CAS REQUEST. Filed by hand (debug console, `jmfsb_messaging_fnc_submit` with the thread id): `only the issuer may send CAS into this thread` | ☐ |
| P56.10 | By hand, file a SALUTE into a TIC thread with its thread id | `SALUTE opens its own thread` | ☐ |
| P56.11 | REQUEST ON STATION to the fixed-wing; open its thread as the sender | Row ABORT, RTB, CLOSE - no ON TASK, no WILCO, no ROGER; ACK sends the word ROGER as a message, not the ROGER card (the state does not move) | ☐ |
| P56.12 | RESUPPLY to the logistics asset; open its thread | Row ABORT, CLOSE; after the drop the prompt's RECEIVED, NOT FOUND | ☐ |
| P56.13 | REACT/QRF LINK-UP to the QRF; open its thread | Row ABORT, RTB, CLOSE; no ON TASK. The asset's own WHEELS UP and ON TASK arrive and the thread reads IN_PROGRESS from them | ☐ |
| P56.14 | By hand, the sender files `inprogress` into his QRF thread | `ON TASK is the asset's to send` (the short as the deck has it) | ☐ |
| P56.15 | A CALL FOR FIRE, ADJUST; the FIRES-net player presses FFE | FFE goes in (not refused as the asset's) and the battery fires for effect | ☐ |
| P56.16 | A CAS REQUEST to a player pilot; as the sender, open the thread | No WILCO / ON TASK tiles. As the pilot: WILCO, ON TASK offered and filed | ☐ |
| P56.17 | A LIFT REQUEST with line 4 GREEN; another with YELLOW | GREEN: no escort drones; YELLOW: two rotary drones with the helicopter. The thread says nothing about them | ☐ |
| P56.18 | RPT | `a new 'cas' for air:<n> taken into the thread`; refusals as INFO `refused ... the asset's to send`; no error from `srvThreadFor`, `srvThreadCard`, `threadLegal`, `taskInThread`; no `BOARD_GRACE` / board's own card line | ☐ |

### P57. The CAS, HLZ insertion and extraction flows (2026-11-02)

User, 2026-11-02: "cas: 1) on station request 2) cas call 3) bda while
returning to on station 4) reattack or egress (reattack back to 3) rinse and
repeat. hlz insertion: 1) pick up site (always safe) 2) troop load, all in
(need an ace interaction while in heli for all in) 3) flight path 4)
insertion 5) egress. extraction: 1) on station 2) extraction 3) troop load,
all in 4) egress." A CAS module (helicopter), a CAS module (fixed-wing, AI), a
CAS drone module (`addons/cas`) and a Transport module on the players' side;
two players in one squad, the second its leader. ACE loaded. Tablet mode,
TAC//MSG. The built-in cards. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P57.1 | NEW > BDA (any thread) | Lines TARGET, RESULT (REQ), COUNT, DECISION (REQ): RE-ATTACK, EGRESS - one tick only; SEND with neither: `DECISION is required - tick one` | ☐ |
| P57.2 | CAS REQUEST to the helicopter with an EGRESS point (line 4); CLEARED HOT; watch the release | One message after the release: `OFF - RETURNING TO STATION - REQUEST BDA`, tiles BDA, CAS. No separate OFF card | ☐ |
| P57.3 | BDA, DECISION RE-ATTACK | `RE-ATTACK - <n> <STORE> LEFT - AWAITING CLEARED HOT` (FLASH), tiles CLEARED HOT, CAS, ABORT | ☐ |
| P57.4 | CLEARED HOT | IN; it runs in again (the BDA's grid if given); after the release `OFF - RETURNING TO STATION - REQUEST BDA` again | ☐ |
| P57.5 | BDA, DECISION EGRESS | Thread CLOSED `EGRESS - RTB`; the helicopter flies to the line-4 egress point first, then home (row reads RTB); no egress point - straight home | ☐ |
| P57.6 | Fixed-wing: REQUEST ON STATION, CAS REQUEST, CLEARED HOT, BDA RE-ATTACK, CLEARED HOT, BDA EGRESS | Re-attack flown from the hold; at EGRESS both threads CLOSED `EGRESS - RTB`; it flies the egress point, then leaves | ☐ |
| P57.7 | Drone: CAS REQUEST, CLEARED HOT, BDA RE-ATTACK, CLEARED HOT, BDA EGRESS | Same prompts; at EGRESS it leaves on its egress line off the map, CLOSED `EGRESS - RTB` | ☐ |
| P57.8 | At `OFF - RETURNING TO STATION - REQUEST BDA`, press CAS, fill a new target, SEND | Re-tasked in the thread: WILCO from where it is, held for CLEARED HOT | ☐ |
| P57.9 | BDA, DECISION RE-ATTACK, with nothing left aboard | Home, CLOSED `WINCHESTER` | ☐ |
| P57.10 | NEW > LIFT REQUEST (HLZ) | Lines in order: PICKUP - ALWAYS SAFE, ROUTE TO THE LZ (4 grids), DROP-OFF LZ, SECURITY, MARKING, PAX / LOAD, EGRESS AFTER THE DROP (4 grids), WIND, OBSTACLES, REMARKS; route and egress fields have MARKER, no CUR LOC | ☐ |
| P57.11 | LIFT REQUEST with a pickup, 2 route points, the LZ, 2 egress points; open the thread map | The pin draws PICKUP - RTE 1 - RTE 2 - LZ - EGR 1 - EGR 2 as one line | ☐ |
| P57.12 | Send it; watch the way to the pickup | WILCO, WHEELS UP INBOUND, ON TASK. No INBOUND updates, no 1 MIN OUT, no circle, no READY TO LAND at the pickup; it lands | ☐ |
| P57.13 | At the pickup | `WHEELS DOWN AT PICKUP <grid>`, then `TROOP LOAD - ALL IN?` with ALL IN, ABORT. No NO RESPONSE after 3 min | ☐ |
| P57.14 | The sender gets in; ACE self-interaction | **ALL IN** offered (to him; to the squad leader too when he is aboard; not to a squad member who is neither). Press it | ☐ |
| P57.15 | Watch | It lifts at once (`all in by <name>, lifting` on the rail); `WHEELS UP TO <LZ grid>`; it flies RTE 1, RTE 2, then the LZ; the ACE action is gone once it lifts | ☐ |
| P57.16 | Repeat P57.12-13; press the ALL IN tile instead | It lifts | ☐ |
| P57.17 | Repeat; neither | It lifts when everyone of the side on foot within 150 m at touchdown is aboard, or at the module's Extract Wait | ☐ |
| P57.18 | On to the LZ | `1 MIN OUT - POP SMOKE - LZ STATUS?`, circle, I SEE, READY TO LAND - CLEARED?, CLEARED TO LAND, WHEELS DOWN, `WHEELS DOWN - PAX OFF?` - as before | ☐ |
| P57.19 | PAX OFF | CLOSED `EGRESS - RTB`; it flies EGR 1, EGR 2, then home. No HOLD, RTB OR NEXT LIFT? | ☐ |
| P57.20 | Debug console on a client: `[vehicle player] remoteExecCall ["jmfsb_support_air_fnc_srvAllIn", 2]` as a squad member who is not the leader, aboard while it loads | Refused (RPT WARNING `not the issuer or a group leader`); it does not lift | ☐ |
| P57.21 | NEW > EXTRACTION (HLZ) | Lines: STATION (marker only), PICKUP HLZ (REQ), LZ SECURITY, MARKING, PASSENGERS, EGRESS (4 grids), DESTINATION, WIND, OBSTACLES, REMARKS | ☐ |
| P57.22 | EXTRACTION with a STATION marker 2 km from the HLZ, 1 egress point, a destination | `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss - <n> PAX`; WHEELS UP, ON TASK; it flies to the STATION and orbits there | ☐ |
| P57.23 | At the station | `ON STATION - READY FOR EXTRACTION` with EXTRACT, ABORT; it waits past 5 min, no NO RESPONSE | ☐ |
| P57.24 | Press EXTRACT | To the HLZ: INBOUND, `1 MIN OUT - POP SMOKE - LZ STATUS?`, circle, mark, READY TO LAND - CLEARED?, CLEARED TO LAND | ☐ |
| P57.25 | At the HLZ | `WHEELS DOWN AT PICKUP <grid>`, `TROOP LOAD - ALL IN?`; ALL IN (tile or ACE action) lifts it | ☐ |
| P57.26 | Watch | It flies EGR 1, then the destination: WHEELS UP, 1 MIN OUT - POP SMOKE, circle, CLEARED TO LAND, PAX OFF?, HOLD, RTB OR NEXT LIFT? | ☐ |
| P57.27 | EXTRACTION with no STATION and no destination | It holds 1 km short of the HLZ on its side; after the load, the egress points then home, landed and unloaded, CLOSED | ☐ |
| P57.28 | ABORT at ON STATION - READY FOR EXTRACTION | Home direct, CLOSED `RTB` | ☐ |
| P57.29 | Open LIFT REQUEST (HLZ), BDA and EXTRACTION (HLZ) in the composer | LIFT REQUEST: PICKUP, ROUTE, DROP-OFF LZ, SECURITY, MARKING, PAX / LOAD, EGRESS, WIND, OBSTACLES, REMARKS; BDA: DECISION (RE-ATTACK / EGRESS); EXTRACTION: STATION first, EGRESS before DESTINATION | ☐ |
| P57.30 | RPT | `srvAllIn: <callsign> all in by <name>`; no error from `liftTick`, `liftJob`, `liftReply`, `casTick`, `threadReply`, `readOrder`, `pinCard` | ☐ |

### P58. JMSB - Jump Aircraft module (2026-11-02)

User: "Jump aircraft module" - class, call sign, altitudes, side; several
jump aircraft per side. The set-up of P55 (an SL with four men, parachutes
and masks, a rifleman of another group, two markers 3 km apart), plus in
Eden two JMSB - Jump Aircraft modules synced to nobody: one Callsign
SKYTRAIN with defaults, one Callsign HERKY, Aircraft Class a CUP or vanilla
cargo helicopter, HALO Altitude 4000, Static Line Altitude 300, Response
Delay 10, Cooldown 60, Sorties 1. A third module synced to an OPFOR unit.
Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P58.1 | Eden: Systems > Modules > JMSB; place the module; open it | JMSB - Jump Aircraft with the attributes; Aircraft Class opens the class picker (crewed planes and helicopters with seats) | ☐ |
| P58.2 | As the SL: NEW, the SUPPORT group; then `@` | SKYTRAIN and HERKY, JUMP, IDLE, each with its own aircraft's name and an ETA (HERKY's counts its 10 s); no third (OPFOR) row; no second SKYTRAIN for the side's own | ☐ |
| P58.3 | As the rifleman | Neither row | ☐ |
| P58.4 | JUMP REQUEST to HERKY: STATIC, the markers, PASSES empty, EXIT unticked | `ROGER, WILCO - STATIC 300 M - 5 MEN - 1 PASS - AUTO EXIT - RED LIGHT IN m:ss`, signed HERKY; 10 s later WHEELS UP and the squad in the helicopter at 300 m; every card after it signed HERKY | ☐ |
| P58.5 | During the run: the SUPPORT group | HERKY TASKED; SKYTRAIN IDLE but dim, `TASKED` (the squad has a run) | ☐ |
| P58.6 | After CLOSE | HERKY LOST (Sorties 1 flown); a card to it: CANTCO `SPENT` | ☐ |
| P58.7 | HERKY with Sorties 2: file, then ABORT within the 10 s | CLOSE `STOOD DOWN BEFORE WHEELS UP`, nothing flies; HERKY IDLE with 2 sorties left | ☐ |
| P58.8 | HERKY again right after a flown run | REARMING; a card: CANTCO `COOLDOWN n S`; IDLE after 60 s | ☐ |
| P58.9 | HALO to HERKY | `HALO 4000 M` in the WILCO; the aircraft at 4000 m | ☐ |
| P58.10 | An OPFOR SL on the third module's side: the SUPPORT group | Only the OPFOR module's row | ☐ |
| P58.11 | Delete every module of BLUFOR (or a mission with none) | The side's own SKYTRAIN again, as P55 | ☐ |
| P58.12 | Zeus: place JMSB - Jump Aircraft | A new row SKYTRAIN with the defaults (6000 / 6000 / 150 m, 60 s delay) | ☐ |
| P58.13 | A module with Aircraft Class `NotAClass` | No row; RPT `Jump Aircraft module names 'NotAClass', which is not a class in this mission - no asset placed` | ☐ |
| P58.14 | CBA settings, Jumpmaster | No Jump aircraft (class) setting; the altitudes, passes, exit and bay say they fly a side with no module | ☐ |
| P58.15 | RPT | `jump aircraft 'HERKY' in TAC//MSG for WEST flying <class>`; no error from `jmfsb_jumpmaster_fnc_moduleJump` / `asset` / `assets` / `reach` / `srvThread` / `srvRelease` | ☐ |

### P59. Runs with or without ALiVE (2026-11-02)

User: "works with or without" - "if alive is present we integrate - but not
the support". The table is docs/ALIVE_OPTIONAL.md. Built, not seen in game.

Set-up, WITHOUT ALiVE: `hemtt launch` (the `default` profile has no ALiVE).
A mission with BLUFOR player slots, some OPFOR infantry and a town or two
away from the players' start, and the modules: Air Defence, AA Base, Leader
Chain, QRF (and a `jmfsb_qrf_1` area marker on a town), Enemy Reaction,
Jamming, a Jammer Site, a Drone Patrol Zone over OPFOR ground, Anti-Ship on a
coast. Run once with no markers, once with an area marker `jmfsb_taor_east`
over the OPFOR half. CBA setting UAS "Patrol ALiVE objectives" on. Then the
same mission WITH ALiVE: `hemtt launch alive`, OPCOMs and placements as
before.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P59.1 | Without ALiVE: start; open the RPT | No script error from any jmfsb addon; one line each: `Air defence: ALiVE not loaded - ...`, `Leader chain: ...`, `QRF: ...`, `Spotted warning: ...`, `Objective jammers: ... off`, `UAS objective zones: ... off`, `Anti-ship: ...`, `Body intel: ...` - each once | ☐ |
| P59.2 | No markers: `#jmfsb aa` | Batteries for EAST over towns, none within 3 km of the players' start; RPT `no ALiVE - air defence for [EAST] ... (whole map: true)` | ☐ |
| P59.3 | With `jmfsb_taor_east`: `#jmfsb aa` | Batteries only inside the marker | ☐ |
| P59.4 | AA Base module | Radar, launchers, guns, crews; guards stay live; RPT `AA base: no ALiVE adapter - n guard group(s) stay live`; no `profileIgnore` error | ☐ |
| P59.5 | `#jmfsb leaders` | `side=EAST houses=n` with three leaders up in towns (inside `jmfsb_taor_east` when drawn), in the OPFOR infantry's faction; RPT `no ALiVE - the chain is EAST's` | ☐ |
| P59.6 | Leader Chain synced to an independent unit | The chain is GUER's, in that unit's faction | ☐ |
| P59.7 | `#jmfsb qrf`, then hold the `jmfsb_qrf_1` town for the hold time | The marker is on the watch list; `QRF: EAST () answers ...`; squads spawn 3-6 km out (inside OPFOR ground when drawn) and walk in; no shells, one RPT line `QRF artillery: ... no shells` | ☐ |
| P59.8 | Trigger a MAJOR (fail a hack) | Fallback barrage, a drone comes looking, COMPROMISED | ☐ |
| P59.9 | Stand where OPFOR has seen you a while | SPOTTED `EAST has your position.`, then quiet for 5 min | ☐ |
| P59.10 | Hack a terminal: the product list | Package / anti-ship / radar / jammer / leader hunts as the mission has them; no LOCATE AA / ARTILLERY / CAMP / LOGISTICS / INSTALLATION | ☐ |
| P59.11 | Kill OPFOR men; search the bodies | Documents by chance; deposit counts up | ☐ |
| P59.12 | Jammer Site; Drone Patrol Zone | Jams; drones fly and resupply from caches; no adapter error | ☐ |
| P59.13 | Anti-Ship | Battery in the module's area within a minute of start, not after 5 min | ☐ |
| P59.14 | File a CONTACTREP | Sent as normal; RPT `Report forwarding: ALiVE not loaded - ...` once, not per report | ☐ |
| P59.15 | Tablet: BFT, map marker system setting | No virtual layer, no error; marker system lists Built-in (ACE if loaded), not ALiVE | ☐ |
| P59.16 | Zeus: place a drone; call CAS (loiter) | No `profileIgnore` error | ☐ |
| P59.17 | WITH ALiVE: start, wait for `ALiVE up after ...` | No `ALiVE not loaded` line anywhere; air defence, leaders, QRF start on ALiVE ready as before | ☐ |
| P59.18 | With ALiVE: `#jmfsbreads`, `#jmfsb aa`, `#jmfsb leaders`, `#jmfsb qrf` | Commanders' TAORs; batteries on commanders' objectives; the asymmetric commander's chain; commanders' objectives on the watch list - as before | ☐ |
| P59.19 | With ALiVE: hold an objective; fail a hack; get spotted | QRF answers with the commander's guns and profiled squads; reaction asks the commander's guns; SPOTTED names ALiVE's reporter - as before | ☐ |
| P59.20 | With ALiVE: the hack list, CONTACTREP, BFT virtual layer | ALiVE hunts offered; report posted to C2ISTAR; virtual friendlies drawn - as before | ☐ |
| P59.21 | ALiVE LOADED, NO COMMANDERS (user, 2026-11-02: "same as not loaded"): `hemtt launch alive`, the P59 mission with no OPCOM module placed; wait 5 min | RPT `waiting on ALiVE init` each minute, then once `WARNING ... no ALiVE commander after 300s - ALiVE treated as not loaded for this mission`; no more waiting lines | ☐ |
| P59.22 | Same run, after the warning: the RPT | One line each, as P59.1 but reading `ALiVE loaded with no commanders - treated as not loaded - ...`: Air defence, Leader chain, QRF, Objective jammers, UAS objective zones, Anti-ship, Body intel; Spotted warning on its first tick | ☐ |
| P59.23 | Same run: repeat P59.2-P59.13 | The same results as without ALiVE (batteries over towns or in `jmfsb_taor_east`, the chain in towns, QRF on markers with live squads, fallback barrage, SPOTTED from knowsAbout, no ALiVE hunts, documents by chance, anti-ship in the module's area) - only started at the give-up, not at mission start; no script error | ☐ |
| P59.24 | With OPCOMs placed (normal ALiVE mission), a slow start | No give-up: `ALiVE up after ...` whenever the commanders finish, even past 300 s; everything as P59.17-P59.20 | ☐ |

### P60. Artillery by message: shape, method of fire, recorded targets, stock, TOT (2026-11-02)

User, 2026-11-02 (ideas from the Tun Firesupport review). The set-up of P42
(A the JTAC, THUNDER a JMSB - Virtual Artillery, 4 guns, HE 96, SMOKE 24,
ILLUM 12, response 10-20 s), plus: THUNDER's Max Sheaf Length 500; a second
Virtual Artillery STEEL, Sheaf Types `CONVERGED`, Max Continuous Fire 0; an
Eden marker named `TH1001` (Variable Name) on an open field; an OPFOR player
D. The built-in cards. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P60.1 | A: CFF GRID - the card | Lines TARGET SHAPE (Point, Area, Linear, Creeping, Size), LINEAR / CREEPING - FAR END OR ATTITUDE, METHOD OF FIRE (INT, VOL, CONT); TOT label `HHMM, HHMMSS OR +MIN`. The same on CFF POLAR and CFF SHIFT | ☐ |
| P60.2 | TO picker, SUPPORT group | THUNDER `ARTY - IDLE - 96 HE, 24 SMOKE, 12 ILLUM - ETA m:ss` | ☐ |
| P60.3 | CFF GRID FFE to THUNDER, Area, size 150 | WILCO `... FFE - 4 GUNS x n HE - AREA 150 M - TOF n S`; rounds spread inside 150 m of the grid | ☐ |
| P60.4 | CFF FFE, Linear, size 400, attitude 90 | WILCO `LINEAR 400 M ATT 090`; the rounds land along an east-west line 400 m long centred on the grid, each gun on its own stretch | ☐ |
| P60.5 | CFF FFE, Linear, far end a second grid 300 m away | The line runs from the grid to the far end; WILCO `LINEAR 300 M ATT <dir>` | ☐ |
| P60.6 | CFF FFE, Linear, size 800 | WILCO `LINEAR 500 M ...` (Max Sheaf Length 500) | ☐ |
| P60.7 | CFF FFE, Creeping, size 300, no attitude, 3 rounds, VOL 2 | `CREEPING 300 M DIR <gun-target bearing>`; each gun's rounds land further from the guns, volley 2 carrying on from where volley 1 stopped, the last 300 m from the grid | ☐ |
| P60.8 | CFF to STEEL: Linear; Creeping; Area | `SHEAF NOT AVAILABLE` twice; Area fires (CONVERGED) | ☐ |
| P60.9 | CFF FFE, Linear, far end 300 m from a friendly, grid 900 m away, DC not ticked | CANTCO `DANGER CLOSE NOT ACKNOWLEDGED` | ☐ |
| P60.10 | CFF FFE, 3 rounds, INT 20, VOL 3 | WILCO `4 GUNS x 3 HE - INTERVAL 20 S - 3 VOLLEYS`; each gun's rounds about 28 s apart (reload 8 + 20), never exactly; the volleys follow on without a pause (superseded 2026-11-05: P75.1) | ☐ |
| P60.11 | CFF FFE, ILLUM, GUNS 1, INT 22, CONT 3 | WILCO `1 GUNS x 7 ILLUM - INTERVAL 22 S - CONTINUOUS 3 MIN`; a flare about every 30 s for 3 min; `ROUNDS COMPLETE` only after the last flare | ☐ |
| P60.12 | CFF to STEEL with CONT 3 | CANTCO `CONTINUOUS FIRE NOT AVAILABLE` | ☐ |
| P60.13 | After an FFE: the prompt | `ROUNDS COMPLETE - <n> HE, 24 SMOKE, 12 ILLUM LEFT - REQUEST BDA`; tiles BDA, RECORD, REPEAT, EOM | ☐ |
| P60.14 | BDA | `<n> HE, ... LEFT - END OF MISSION?`; tiles EOM, RECORD, REPEAT | ☐ |
| P60.15 | Adjust mission: ADD 100, FFE, then RECORD | `RECORDED AS TARGET TH1002` (TH1001 is the Eden marker - skipped); a red `TH1002` marker on the adjusted point, not the first grid; the question again without RECORD | ☐ |
| P60.16 | RECORD again | `RECORDED AS TARGET TH1002` again, no second marker | ☐ |
| P60.17 | CHECK FIRE during an FFE | `CHECK FIRE - HOLDING`; tiles include RECORD | ☐ |
| P60.18 | EOM; new CFF GRID with TARGET - GRID `TH1002` | Fires on the recorded point. `TH1001` (pre-planned): fires on the Eden marker. CFF SHIFT, known point `TH1002`, ADD 200: 200 m beyond it | ☐ |
| P60.19 | D (OPFOR) and a JIP BLUFOR player: the map | D: no `TH1002`; the JIP player sees it | ☐ |
| P60.20 | STEEL records a target | Named `ST1001` (or the next pair when another battery has ST); RPT at start lists THUNDER's pre-planned `TH1001` | ☐ |
| P60.21 | Module Target Prefix `AB` on THUNDER | Recorded targets `AB1001` ... | ☐ |
| P60.22 | TOT: `1430`-style 3 min ahead; `HHMMSS` 3 min ahead; `+3` | WILCO `TOT hhmm`; `TOT hhmmss`, the first round within a second or two of it; `TOT hhmmss` 3 game minutes from now. `+90`: `CANNOT MAKE TOT`; `abc`: `NO TOT` | ☐ |
| P60.23 | TRIDENT (cruise): CFF with Linear, VOL 3, TOT `+3` | Shape and method ignored - one launch; the TOT read as for a battery | ☐ |
| P60.24 | RPT | No error from `jmfsb_support_fires_fnc_srvThread`, `threadShape`, `threadMethod`, `threadTot`, `threadVolley`, `threadReply`, `record`, `targetLocal`, `targetPrefix`, `stockWords`, `fireVirtual`, `aimPoint`, `jmfsb_support_fnc_readOrder`, `mailboxes` | ☐ |

### P61. Artillery, second build: preview before SEND, airburst, aiming error, dispersion, magazines, cues (2026-11-02)

User, 2026-11-02 (the rest of the Tun Firesupport review). The set-up of P60,
plus: THUNDER's Aiming Error 200, Dispersion 40; a third Virtual Artillery
MAG whose HE Shell Class is `32Rnd_155mm_Mo_shells` and Smoke Shell Class
`NoSuchMag`; a BLUFOR AI squad 400 m from grid T. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P61.1 | A: + TEMPLATE > CFF GRID, TO THUNDER, TARGET - GRID T (no tick yet) | Beside SEND: `IN RANGE n KM (MIN 2 KM, MAX 24 KM) - TOF n S`, muted; on the map an orange `THUNDER TOF n S` on T and an ellipse round it, long along the THUNDER-T line (about 240 x 96 m) | ☐ |
| P61.2 | Type the grid digit by digit | The line and the markers follow each change; no stutter, the box keeps focus | ☐ |
| P61.3 | Shape Area 150; then Linear 400 att 90; then Creeping 300 | An orange circle of 150 m; then an east-west line 400 m long centred on T; then a line from T away from the guns to a `WALK END` dot. The line adds `AREA 150 M` / `LINEAR 400 M ATT 090` / `CREEPING 300 M DIR nnn` | ☐ |
| P61.4 | The squad 400 m from T, DC not ticked | In the accent `CANTCO - DANGER CLOSE NOT ACKNOWLEDGED - FRIENDLY ~400 M`; markers red, a red 600 m ring with `DANGER CLOSE - FRIENDLY ~400 M`. Tick DC: muted again, the line ends `DANGER CLOSE - FRIENDLY ~400 M` | ☐ |
| P61.5 | TARGET - GRID beyond 24 km; Engagement Cluster | `CANTCO - OUT OF RANGE n/24 KM`; `CANTCO - NO STORES CLUSTER` | ☐ |
| P61.6 | TO STEEL with Linear | `CANTCO - SHEAF NOT AVAILABLE` | ☐ |
| P61.7 | SEND an out-of-range card anyway | The server still answers CANTCO `OUT OF RANGE ...`; the markers are gone within a second of the send | ☐ |
| P61.8 | CANCEL a card with markers up; REMOVE the template; switch TO to a CAS asset | Markers gone each time | ☐ |
| P61.9 | CFF FFE to THUNDER, Engagement Airburst, 2 rounds | WILCO `... 4 GUNS x 2 HE AIRBURST ...`; the rounds burst in the air (about 7-12 m), no craters | ☐ |
| P61.10 | CFF ADJUST, Airburst; then FFE | The adjusting rounds burst on the ground; the FFE bursts in the air | ☐ |
| P61.11 | CFF ADJUST on a marked point, then ADD 25 three times, then FFE (each round against the point it was aimed at) | Round 1 up to ~200 m off, mostly along the gun-target line; round 2 within ~100 m of its point; round 3 ~50 m; round 4 and the FFE within the dispersion only | ☐ |
| P61.12 | CFF FFE (no adjust), then REPEAT | Both salvos off by the full error, each its own way; REPEAT does not reduce it | ☐ |
| P61.13 | THUNDER with Aiming Error 0, Dispersion 40, a point FFE of 12 rounds | Impacts in an ellipse about 80 m long along the line of fire and 32 m wide, never a circle | ☐ |
| P61.14 | MAG at start (RPT) | `Artillery 'MAG': HE magazine '32Rnd_155mm_Mo_shells' fires 'Sh_155mm_AMOS'`; a WARNING naming `NoSuchMag`; MAG's row lists HE and no smoke; HE fires | ☐ |
| P61.15 | Any CFF to THUNDER: listen as A (issuer) and B (named observer); C on the FIRES net | A and B hear a beep at SHOT and a tone at SPLASH (5 s before impact), once each; C hears nothing | ☐ |
| P61.16 | CFF to TRIDENT (cruise) being written | No line beside SEND, no markers | ☐ |
| P61.17 | RPT | No error from `jmfsb_support_fires_fnc_cardPreview`, `aimError`, `scatter`, `virtualShot`, `virtualRound`, `fireVirtual`, `adjustNext`, `cue`, `cueLocal`, `stockFromTable`, `jmfsb_support_fnc_cardPreview`, `pinMarker`, `jmfsb_tacpad_fnc_composeFire`, `composeFireTick` | ☐ |

### P62. Support aircraft virtual until tasked; BOARD; the respawn count; escorts (2026-11-02)

User, 2026-11-02: "all support aircraft needs to be virtual till tasked, then
they spawn in at alt over the support module location and drone escorts is
based on lz security for helos and always for fix wings" (it replaced the same
day's "on station from the start"); "have team leader send a board message
then move the team to cargo"; "static 2000 then move to jump alt, halo haho
6k"; "rtb via egress"; "make sure there is a respawn count for each support,
default no respawns". Built, not seen in game.

Set-up: A a JTAC, L a squad leader with 3 AI (parachutes; masks for HALO).
Modules on one side, none synced: HOG (JMSB - CAS, A-164, Respawns 1, Respawn
Delay 120, Time On Station 600) in the middle of the map; VIPER (JMSB - CAS,
AH-99 class); RAVEN (JMSB - Transport, Respawns 0); REACH (JMSB - QRF
Insertion, Respawns 1, delay 120); HAWK (JMSB - CAS Drone, Respawns 1, delay
120); SKYTRAIN (JMSB - Jump Aircraft, Respawns 0); SUPPLY (JMSB - Logistics,
Respawns 0). A second transport CROW synced to a parked helicopter. No escort
class set on any module, except VIPER's Rotary Escort Class (a rotary drone
of the mission, e.g. `B_T_UAV_03_dynamicLoadout_F` with Apex).

| # | Do | Should happen | P/F |
|---|---|---|---|
| P62.1 | Start; Zeus camera over each module | No support aircraft anywhere (no HOG, VIPER, RAVEN, REACH, HAWK, SKYTRAIN, SUPPLY). CROW on its stand | ☐ |
| P62.2 | TO picker, SUPPORT group | Every row IDLE with its ETA from the module; sitrep / reach lines `1 SPARE AIRFRAME` / `LAST AIRFRAME` | ☐ |
| P62.3 | A: REQUEST ON STATION to HOG (marker anywhere) | `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss` (module to hold at cruise). HOG appears **directly over its module at 4000 m**, engines on, flying - no drop, no stall - dark, with two fixed-wing escorts beside it (the side's UCAV, the class being empty). It flies to its hold 8 km off the map edge nearest the marker; AIRFRAME CHECK-IN `HOLDING OFF THE MAP, DARK` there | ☐ |
| P62.4 | A: CAS REQUEST to HOG; CLEARED HOT; BDA EGRESS | Strike from the hold as P47; EGRESS: it flies the card's egress point, then home to its module; both threads CLOSED `EGRESS - RTB`; within 600 m of the module HOG and its escorts vanish - no wreck, no crew left. Row IDLE after the cooldown; no respawn used (`1 SPARE AIRFRAME` still) | ☐ |
| P62.5 | A: REQUEST ON STATION again | A fresh HOG over the module, full fuel and stores (Zeus: `fuel` 1, magazines full) | ☐ |
| P62.6 | A: RTB in that REQUEST ON STATION thread | CLOSED `RTB`; HOG flies home and is removed over the module | ☐ |
| P62.7 | A: CAS REQUEST to VIPER (helicopter) | WILCO with an ETA from the module; VIPER appears over its module at 30 m, engines on; no escorts (a CAS REQUEST has no LZ security); it holds the run-in distance short of the target, checks in `HOLDING SHORT FOR CLEARED HOT`; CLEARED HOT, strikes, holds short for the BDA; RTB: home, removed over the module | ☐ |
| P62.8 | Two modules on one spot: task both at once | The second aircraft is made 150 m or more from the first (or higher); the RPT says `made n m from <grid> - another aircraft was there` | ☐ |
| P62.9 | HOG out; shoot it down | `is down at <grid> - replacement in 120 sec`; row REPLACING; a REQUEST ON STATION now: `CANTCO - REPLACING`; after 120 s it is IDLE; the next REQUEST ON STATION makes a new HOG over the module | ☐ |
| P62.10 | Shoot the second HOG down | `is down at <grid> - no replacement`; HOG leaves the SUPPORT list; a card to its box (an open thread, or the box id) gets `CANTCO - UNABLE - NO AIRFRAME` | ☐ |
| P62.11 | A helicopter out on a task: kill its pilot (Zeus) | 10 s later the RPT `cannot fly - sortie written off`; a respawn is used as for a wreck | ☐ |
| P62.12 | L: LIFT REQUEST to RAVEN, line 4 GREEN | WILCO with ETA from the module; RAVEN appears over its module at 30 m, `WHEELS UP INBOUND`, ON TASK; no escorts; pickup, ALL IN, route, LZ, PAX OFF as P57. After PAX OFF: the egress points, it lands at the module, unloads, is removed. RAVEN stays on the list (Respawns 0 is only for losses) | ☐ |
| P62.13 | LIFT REQUEST to VIPER-class transport with line 4 YELLOW (a transport with a Rotary Escort Class) | Two rotary drones made beside it about 5 s after it appears; they fly with it and vanish with it at the module | ☐ |
| P62.14 | EXTRACTION to a transport | `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss - n PAX`; made over the module, flies to the station; after PAX OFF: CLOSED `EGRESS - RTB`; home, removed | ☐ |
| P62.15 | LIFT REQUEST to CROW (synced) | As before: takes off from its stand at once, parks back there, not removed | ☐ |
| P62.16 | QRF to REACH | REACH appears over its module with the squad aboard; insertion as P44; then it flies to the module and is removed; a second QRF request makes a fresh REACH and squad | ☐ |
| P62.17 | CAS REQUEST to HAWK; BDA RE-ATTACK until Winchester | HAWK appears over its module at 4000 m; strike as P47; after Winchester it flies home to its module and is removed; no respawn used | ☐ |
| P62.18 | L: JUMP REQUEST HALO to SKYTRAIN | WILCO `... BOARD TO RED LIGHT m:ss`; SKYTRAIN appears over its module at 2000 m, a plane with two escort drones, and orbits it; `ON STATION - SEND BOARD WHEN READY` [BOARD] [ABORT] | ☐ |
| P62.19 | One man drops his parachute; L: BOARD | `1 MAN WITHOUT A PARACHUTE - SEND BOARD WHEN READY`; nobody is moved | ☐ |
| P62.20 | Pick it up; BOARD | The 4 men are moved aboard; ON TASK `STICK ABOARD - 4 MEN - RED LIGHT IN m:ss`; SKYTRAIN climbs from 2000 m to 6000 m on its way to the run-in; INBOUND, RED LIGHT, GREEN LIGHT, STICK OUT, CLOSED as P55; then home at 2000 m (row RTB), removed over the module with its escorts; REARMING, then IDLE | ☐ |
| P62.21 | STATIC request; BOARD | It comes down to the module's static-line altitude (150 m) for the run | ☐ |
| P62.22 | ABORT before BOARD | CLOSED `NOT BOARDED - STOOD DOWN`; SKYTRAIN flies home and is removed | ☐ |
| P62.23 | Shoot SKYTRAIN down (Respawns 0) | Its row leaves the list; a JUMP REQUEST to it: `UNABLE - NO AIRFRAME`; the side's own SKYTRAIN does not come back | ☐ |
| P62.24 | RESUPPLY to SUPPLY, then a second one | Each delivery's aircraft appears over the module, delivers, flies home and is removed; SUPPLY stays on the list (a delivery uses no respawn) | ☐ |
| P62.25 | Eden: the modules' attributes | No Response Delay on CAS, Transport, QRF, CAS Drone, Logistics; no Ingress Distance on CAS; no Spawn Distance on Logistics; no Drone Escorts checkbox anywhere; Fixed-Wing / Rotary Escort Class on CAS, QRF, Logistics and Jump Aircraft (Transport rotary only); Respawns tooltips say only a loss uses one. A mission saved with the old attributes still loads | ☐ |
| P62.26 | RPT | No error from `jmfsb_support_fnc_spawnAirborne`; `jmfsb_support_air_fnc_spawnAircraft`, `casLaunch`, `casTick`, `transportLaunch`, `qrfLaunch`, `homeTick`, `writeOff`, `finish`, `lost`, `replace`, `escortLaunch`; `jmfsb_cas_fnc_spawnDrone`, `launch`, `runTick`, `recover`, `gone`; `jmfsb_jumpmaster_fnc_airUp`, `airTick`, `airHome`, `airLost`, `srvAskBoard`, `srvBoard`; `jmfsb_support_logistics_fnc_spawnAircraft`, `launch` | ☐ |

### P63. LZs and DZs highlighted in AiTR (2026-11-02)

User, 2026-11-02: "in AiTR lz and drop zones need to be highlighted". Built,
not seen in game.

Set-up: as P62, dedicated server. L a squad leader with an AiTR goggle (NVG
mode, or an AiTR goggle in day mode), the TAC//PAD loaded; E a player on the
other side with an AiTR goggle; J a third player of L's side who joins after
the requests are sent.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P63.1 | L: LIFT REQUEST to RAVEN, pickup 300 m away, LZ 2 km away | At the WILCO: a ring of dots on the ground round the pickup and round the LZ, in the TAC//PAD accent; under each `LZ \| PICKUP \| RAVEN \| 300 m`, `LZ \| INSERT \| RAVEN \| 2 km`. The LZ shows through hills and buildings | ☐ |
| P63.2 | Turn away; then look at the LZ through the round window | Nothing off screen; dots and label only inside the window. A JMSB full-screen goggle with NVG full screen on: anywhere on screen | ☐ |
| P63.3 | Open the map, the tablet, Zeus; switch to thermal; Ctrl + Shift + N | The rings go with the boxes each time and come back after | ☐ |
| P63.4 | Board; ALL IN | The PICKUP ring goes when it lifts; the INSERT ring stays | ☐ |
| P63.5 | At the LZ: PAX OFF | The INSERT ring goes | ☐ |
| P63.6 | E looks at the same points | E never sees L's side's rings | ☐ |
| P63.7 | EXTRACTION with a destination; EXTRACT; ALL IN | `LZ \| EXTRACT` and `LZ \| DEST` from the WILCO; EXTRACT goes when it lifts; DEST goes at PAX OFF | ☐ |
| P63.8 | CASEVAC; patients aboard; DEST DEFAULT | `LZ \| CASEVAC` until the destination is given, then `LZ \| DEST` at the hospital (or base) | ☐ |
| P63.9 | PARADROP | `DZ \| PARA` from the WILCO until RECEIVED / NOT FOUND | ☐ |
| P63.10 | QRF air assault; then a static-line QRF | `LZ \| QRF` until the squad is down; `DZ \| QRF` the same | ☐ |
| P63.11 | L: JUMP REQUEST HALO with wind; BOARD; jump | `DZ \| HALO \| SKYTRAIN` on the green light and `DZ \| RELEASE` from the WILCO; after `STICK OUT - LEAVING THE DZ` both stay while anyone of the stick is in the air, and go a few seconds after the last man lands | ☐ |
| P63.12 | JUMP REQUEST; ABORT before BOARD | The rings go within a few seconds of `NOT BOARDED - STOOD DOWN` | ☐ |
| P63.13 | RESUPPLY AIRDROP; then SLING | `DROP \| RESUPPLY` / `DROP \| SLING` from the WILCO until the thread closes | ☐ |
| P63.14 | RTB or CLOSE in any of these threads | Its rings go | ☐ |
| P63.15 | J joins while two requests are open | J sees both requests' rings once in the game | ☐ |
| P63.16 | Addon Options > AiTR (ECOTI): AiTR LZ / DZ highlight off | No rings; boxes and compass as before. On again: back | ☐ |
| P63.17 | Seven zones open at once | The nearest six drawn | ☐ |
| P63.18 | RPT, both machines | No error from `jmfsb_support_fnc_zones`, `zonesHold`, `zonesPublish`, `zonesLocal`; `jmfsb_support_air_fnc_liftZones`; `jmfsb_ecoti_fnc_updateZones`, `drawZones`, `rangeText` | ☐ |

### P64. The mod's own card always wins (2026-11-02)

User: card changes must reach the game without running Python. Every card
the mod defines is built in (messaging `builtinCards`, support `builtinCards`
/ `builtinFires` / `builtinReplies`, PAC `registerTemplates`); the TAC//PAC
deck adds only ids the mod does not have. Dedicated server with the live
deck, one client. Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P64.1 | Server RPT at start | `built-in cards (messaging): 12 - ...`, `built-in cards (support): 50 - ...` (`allattack` since 2026-11-02), `built-in cards (pac): 2 - opord, mettc`; then `report deck: <n> card(s) skipped - the mod carries them: ... - retired: accepted, nineline, ontask` | ☐ |
| P64.2 | Client RPT after it takes the server's structure | The same `report deck` line once; a later publish with the same deck adds no second line | ☐ |
| P64.3 | TAC//MSG > NEW | SALUTE, TROOPS IN CONTACT, 6-LINE CASEVAC, CALL FOR FIRE - GRID / POLAR / SHIFT, LIFT REQUEST (HLZ), EXTRACTION (HLZ), PARADROP, JUMP REQUEST - no CAS 9-LINE, no 9-LINE MEDEVAC, whatever the deck holds | ☐ |
| P64.4 | A unit card in the deck with an id the mod does not have (PAC site, Templates page) | It is in the picker after the next publish; `report deck: 1 template(s) registered` | ☐ |
| P64.5 | Edit the deck's `tic` on the PAC site (title TEST), publish | The picker still says TROOPS IN CONTACT - the mod's card is used | ☐ |
| P64.6 | Reply WILCO with text to a task | `wilco` carries DETAIL; no `accepted` / `ontask` card anywhere | ☐ |
| P64.7 | RPT | No `registered twice`; no error from `jmfsb_messaging_fnc_registerBuiltins` / `builtinCards` / `registerTemplate`, `jmfsb_support_fnc_builtinCards` / `builtinFires` / `builtinReplies`, `jmfsb_pac_fnc_templatesApply` / `registerTemplates` | ☐ |

### P65. ALL ATTACK - a fixed-wing flight's escorts attack the target area (2026-11-02)

User, 2026-11-02: "add an all attack for the fixed flight where the drones
also attack the target or targets in the area". Built, not seen in game.

Set-up as P62: A a JTAC; HOG (JMSB - CAS, A-164) with the Fixed-Wing Escort
Class empty (the side's UCAV); VIPER (helicopter); HAWK (CAS drone). Enemy at
a target: two vehicles and a section of men inside 300 m, one more vehicle 600
m off; a friendly section 80 m from one vehicle (HOG's Friendly Range 100).

| # | Do | Should happen | P/F |
|---|---|---|---|
| P65.1 | A: REQUEST ON STATION to HOG, then a CAS REQUEST on the target | The WILCO's quick replies: CLEARED HOT, ALL ATTACK, ABORT, RTB, CLOSE; 60 s later `AWAITING CLEARED HOT` with [CLEARED HOT] [ALL ATTACK] [ABORT] | ☐ |
| P65.2 | A: ALL ATTACK | `ON TASK - ALL ATTACK - FLIGHT IN HOT`, then IN; the jet runs its strike as for CLEARED HOT; both drones break off for the target area | ☐ |
| P65.3 | Watch the drones | Each on its own target, vehicles first, then men; the vehicle 600 m off is not attacked; the vehicle with the friendlies 80 m off is not attacked | ☐ |
| P65.4 | Repeat with DANGER CLOSE ticked on the card | That vehicle is attacked too | ☐ |
| P65.5 | After the jet's release | The OFF waits until the drones are done (area clear, Winchester, at most 2 min), then `OFF - RETURNING TO STATION - DRONES DESTROYED <n> - REQUEST BDA`, n what the drones destroyed | ☐ |
| P65.6 | Drones done | They rejoin the jet's wing slots and fly back to the hold with it | ☐ |
| P65.7 | BDA RE-ATTACK | `RE-ATTACK - ... - AWAITING CLEARED HOT` with [CLEARED HOT] [ALL ATTACK] [CAS] [ABORT] | ☐ |
| P65.8 | BDA EGRESS while the drones still attack | They break off, rejoin and go home with the jet; all removed over the module | ☐ |
| P65.9 | Shoot both escorts down; send ALL ATTACK on the next strike | `NO ESCORTS - USE CLEARED HOT` (FLASH) [CLEARED HOT] [ABORT]; nothing flies until CLEARED HOT | ☐ |
| P65.10 | ALL ATTACK in VIPER's thread (+ TEMPLATE), and in HAWK's | `NO ESCORTS - USE CLEARED HOT` in each; the helicopter and the drone hold | ☐ |
| P65.11 | ALL ATTACK from a man who is not the issuer, observer or on FIRES | Not passed on (the RPT says so), as CLEARED HOT | ☐ |
| P65.12 | RPT | No error from `jmfsb_support_fnc_escortAttack`, `escortStrike`, `escortAttackEnd`, `escortTick`, `casPrompt`, `promptCleared`; `jmfsb_support_air_fnc_allAttack`, `canAllAttack`, `threadReply`, `casJob`; `jmfsb_cas_fnc_threadReply` | ☐ |

### P66. CFF SHIFT UP / DOWN lays the guns for the height (2026-11-05)

Built, not seen in game. The guns are laid for the known point's height plus
UP / DOWN; a target at another height is missed along the line of fire by the
difference over the tangent of the descent (long laid high, short laid low).

Set-up: a virtual battery (JMSB - Virtual Artillery), Aiming Error 0,
Dispersion 0. A known point on a hilltop; a target in a valley about 100 m
lower, 300 m from it. An observer with line of sight to both.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P66.1 | CFF SHIFT, FFE, from the hilltop known point to the valley target, UP / DOWN empty | The rounds land long of the target, on the gun-target line; RPT `... laid for the known point's height: lands <n> m long` | ☐ |
| P66.2 | Same, Vertical DOWN 100 | The rounds land on the target; no `laid for` RPT line | ☐ |
| P66.3 | Known point in the valley, target on the hilltop, UP / DOWN empty | The rounds land short; RPT says `short` | ☐ |
| P66.4 | ADJUST mission as P66.1, then ADD / DROP corrections | The corrections walk the rounds onto the target from where they landed | ☐ |
| P66.5 | CFF GRID and CFF POLAR on the valley target | On target; no `laid for` RPT line | ☐ |
| P66.6 | RPT | No error from `jmfsb_support_fires_fnc_layHeight` or `srvThread` | ☐ |

### P67. Receive-only R and drone marks on the walking view (2026-11-05)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P67.1 | Phone in the GPS slot, on TEAM and C2. Tablet TAC//EW > EP: one set to 3 SILENT | Within a second or two a grey R at the left end of the TEAM and C2 cells on the phone; the ear tag still at the right | ☐ |
| P67.2 | Same, open the tablet | The tablet net row shows the same grey R at the left of each radio net cell; the label does not overlap it | ☐ |
| P67.3 | Get in a vehicle while SILENT | The VEH cell has no R; the radio nets keep theirs | ☐ |
| P67.4 | EP: the set back to 0 | The R gone from every cell, phone and tablet | ☐ |
| P67.5 | A mission without jmfsb_ew | Net rows as before, no R, no script error | ☐ |
| P67.6 | Phone up, a friendly UAV (Darter) in the map's view | An accent circle on the drone with the FLEET board's name beside it; it moves with the drone | ☐ |
| P67.7 | Stand where a squad member is under the drone | The member icon drawn over the drone mark | ☐ |
| P67.8 | An enemy UAV nearby; then destroy the friendly one | The enemy drone not marked; the destroyed one's mark gone at once | ☐ |

### P68. Tablet apps: SQUAD member page, WEATHER forecast, SETTINGS display (2026-11-05)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P68.1 | Open SQUAD in a squad with fire teams set | Each row starts with the BFT icon in the team colour, the same number as his map mark | ☐ |
| P68.2 | Same with jmfsb_bft not loaded | A team-coloured square with his place in the group; no script error | ☐ |
| P68.3 | LINK for a linked player, a cut player, an AI and yourself | Swatch + %, NONE, `-`, `-` | ☐ |
| P68.4 | Press a man's row | The rail becomes MEMBER: icon, rank and name, role and team, STATE, WOUNDS, BLOOD, AMMO, RADIO, LINK, DIST with bearing | ☐ |
| P68.5 | Wound a man (ACE), open his MEMBER page | WOUNDS names the parts (e.g. `L LEG 2`), TQ count if any; BLOOD `nn% - x.x L`; bleeding in the accent | ☐ |
| P68.6 | Same without ACE medical | WOUNDS `NO ACE MEDICAL`, BLOOD `--`; no error | ☐ |
| P68.7 | SHOW ON MAP | The app closes, the map pans to him | ☐ |
| P68.8 | CALL on a reachable player | The call rings as from RADIO > CONTACTS; no CALL in the table foot | ☐ |
| P68.9 | MEMBER for yourself, an AI, a dead man | CALL dead; DIST `YOU` for yourself | ☐ |
| P68.10 | < BACK | The rail returns to STRENGTH, DISPERSION, MY ACE REPORT | ☐ |
| P68.11 | Press a man on the map's squad rail | SQUAD opens on his MEMBER page | ☐ |
| P68.12 | WEATHER; debug `3600 setOvercast 0.9` | FORECAST: NEXT CHANGE `BY <now+1h>`, CLOUD COVER `x > 90%`, ROTARY / CAS MARGINAL | ☐ |
| P68.13 | No pending change | NEXT CHANGE NONE SCHEDULED; trends now > now | ☐ |
| P68.14 | `36000 setFog 0.5` | `BY hh:mm - PAST 8 H`; THERMAL / DRONES DEGRADED | ☐ |
| P68.15 | Time multiplier x4, `3600 setOvercast 0.9` | Note whether `BY hh:mm` matches when the change lands (the forecast assumes game seconds) | ☐ |
| P68.16 | RAIN, WIND row | NOT FORECAST | ☐ |
| P68.17 | TEXT SIZE max, WEATHER | The forecast rows fit in the frame | ☐ |
| P68.18 | SETTINGS > DISPLAY, DISPLAY MODE | NATIVE / TABLET toggles, the screen closes, the suite rebuilds on the other display; Addon Options agrees | ☐ |
| P68.19 | HUD READOUTS, then HUD IN TABLET MODE | Each flips ON / OFF and the HUD follows | ☐ |
| P68.20 | NOTIFICATIONS CORNER < / > | Cycles the four corners; the next popup appears there | ☐ |
| P68.21 | Force `jmfsb_notify_corner` in server settings | The row reads `<corner>  LOCKED` | ☐ |
| P68.22 | Without jmfsb_hud | No HUD rows; no error | ☐ |

### P69. The buddy, picked by ACE interaction (2026-11-05)

Built, not seen in game. Two players A and B in one group, C in another.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P69.1 | A: ACE interact on B | `Buddy up` with a star icon; not on C (other group) | ☐ |
| P69.2 | A: Buddy up | A's phone squad list: a yellow star after B's name; B's: after A's. On every map a yellow star over the upper left of the buddy's circle, the same distance off at every zoom | ☐ |
| P69.3 | A: ACE interact on B again | `End buddy pair`, no `Buddy up` | ☐ |
| P69.4 | A pairs with a third man D in the group | B's star gone on A's devices; B's devices show no buddy | ☐ |
| P69.5 | End buddy pair | Both stars gone | ☐ |
| P69.6 | Pair A-B, then B joins another group, or dies | The star gone on A's devices | ☐ |
| P69.7 | Look at the star on the phone list | Drawn as a star, not a box or blank (texture, not a glyph) | ☐ |
| P69.8 | RPT | No error from `jmfsb_bft_fnc_buddyAdd`, `buddySet`, `buddyOf`, `drawMembers`, `jmfsb_devices_fnc_overlaySquad` | ☐ |

### P70. Voice by default; artillery on a dedicated server (2026-11-05)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P70.1 | Dedicated server, Voice system Automatic, no Mumble or LiveKit address | Server RPT `voice: livekit has no voice server set ... the game VON carries the voice`; two players hear each other on game VON; no `No voice` notice | ☐ |
| P70.2 | Mumble address set (Automatic) | Players join Mumble: RPT `voice server: in the room ...`; jmsb_voice.log `mumble: signed in` | ☐ |
| P70.3 | Only the LiveKit address set (Automatic), key and secret in the server's environment | Players join LiveKit (jmsb_voice.log `livekit: joined`) | ☐ |
| P70.4 | Address set to a host that does not answer | One notice `Voice: the voice server does not answer ...`; RPT `no answer in 40 s - asking again` every 40 s; an error from the extension (if any) is shown, not lost | ☐ |
| P70.5 | `[] call jmfsb_voice_fnc_selfTest` on a client | `VOICE SERVER extension ..., room ...`, join state, mic, receiving n of m | ☐ |
| P70.6 | Two players, one net, both on the voice server | Each hears the other on PTT (the test never run yet) | ☐ |
| P70.7 | CFF GRID to THUNDER, then read the client RPT | `sent 'callforfire' to ["B:SUPPORT:fires:0"]` - if it names a net or a man, the card was not addressed to the battery | ☐ |
| P70.8 | CFF GRID to THUNDER: grid + FFE | WILCO, SHOT, SPLASH, rounds land | ☐ |
| P70.9 | Retired Artillery Battery with HE and smoke magazines (synced guns or the Ammunition field), CFF with SMOKE ticked | Smoke fires; no `NO STORES SMOKE` | ☐ |
| P70.10 | LIFT REQUEST (HLZ) with a ROUTE point 500 m short of the LZ; COLD at LZ STATUS | It goes in, circles for the smoke and lands - not hanging at the hold-short point | ☐ |
| P70.11 | Module Time On Station 60 s; CLEARED HOT so the run in starts near the end | The strike is flown and released, then BINGO / off station | ☐ |
| P70.12 | CAS REQUEST to HOG while it flies out to its hold | `CANTCO - NOT ON STATION` | ☐ |

### P71. You and your team on the tablet's map (2026-11-05)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P71.1 | Open the tablet (default Member markers: Own squad) | Your icon in your team colour with your number, and every member of your group with theirs | ☐ |
| P71.2 | Move and turn | Your icon follows and turns with you | ☐ |
| P71.3 | Open the vanilla map (M) | You once, not twice | ☐ |
| P71.4 | Member markers: All tracked | Other tracked groups' members too | ☐ |

### P72. TAC//MSG: the card keeps its scroll (2026-11-05)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P72.1 | NEW, a long card (CFF GRID), scroll to the bottom, tick a box there | The card stays where it was; the tick shows | ☐ |
| P72.2 | Same, pick a MARKER and a drop-down at the bottom | Stays put each time | ☐ |
| P72.3 | Close the composer, open the same card again | Opens at the top | ☐ |
| P72.4 | Switch to another card while scrolled | The new card opens at the top | ☐ |
| P72.5 | Tick a box near the bottom and watch | No visible jump to the top and back (one frame at most) | ☐ |

### P73. Transport leaves at once; escorts stacked, never across (2026-11-05)

Built, not seen in game. Watch air:0 (the UH-80 with the escorts, module at
034139), not the second RAVEN beside the pickup.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P73.1 | LIFT REQUEST to the escorted RAVEN, LZ security RED; CONFIRM | The helicopter made over its module heads for the pickup at once; RPT `transportPlan: RAVEN LIFT to <grid>` and `moveTo: ... to <pickup grid>` at the launch | ☐ |
| P73.2 | Watch the escorts after launch | Two drones 150 m out each side, 100 m back, above the helicopter and at different heights from each other (about 70 and 110 m) | ☐ |
| P73.3 | Let it land at the pickup (or hold it with Zeus) | The escorts orbit about 300 m out, the same way round, never through the middle or over the helicopter; no collision | ☐ |
| P73.4 | It lifts off again after the load | Each escort takes the slot on its own side; none crosses over the lead | ☐ |
| P73.5 | If it hovers again | Superseded the same day by P74.2 (the stall watch became `heliOrderTick`) | ☐ |
| P73.6 | An extraction or hot-LZ lift that holds short | RPT `liftTick: RAVEN holds the watch - holding short for the LZ status` once; no stall lines while it holds | ☐ |

### P75. Artillery on Simplex's method: volleys, numbered SHOT / SPLASH, the arc through the height, the dropped call (2026-11-05)

Built, not seen in game. The set-up of P60 (THUNDER: 4 guns, reload 8,
cooldown 60, response 10-20 s). Replaces P60.10's "each after the last landed
and the cooldown".

| # | Do | Should happen | P/F |
|---|---|---|---|
| P75.1 | CFF GRID FFE, 2 rounds, VOL 3, no interval | WILCO `4 GUNS x 2 HE - 3 VOLLEYS`; each gun fires 6 rounds about 8 s apart with no longer pause anywhere; the cooldown (COOLDOWN n S on the row) starts only after the last round lands | ☐ |
| P75.2 | The thread of P75.1 | `SHOT VOLLEY 1 OF 3 - TOF n`, `SHOT VOLLEY 2 OF 3 ...`, `SHOT VOLLEY 3 OF 3 ...`, then `SPLASH VOLLEY 1 OF 3` ... `SPLASH VOLLEY 3 OF 3` (SHOTs may all come before the first SPLASH); a single-volley CFF still reads `SHOT TOF n` and plain `SPLASH` | ☐ |
| P75.3 | RPT at P75.1 | `THUNDER salvo 1: 3 volleys x 2 rounds x 4 guns, gap 8 s, rise n m, last round lands in n s` | ☐ |
| P75.4 | CFF FFE, ILLUM, GUNS 1, CONT 2 | `ROUNDS COMPLETE - ... - REQUEST BDA` arrives about 5 s before the LAST flare ignites, not 10-20 s after | ☐ |
| P75.5 | Battery on a hill, target in a valley 200 m lower, 6 km; then the reverse | WILCO's `TOF n S` and the preview's TOF differ by a few seconds between the two (shorter firing down); the rounds still land on the grid; `laid for` lines only on a CFF SHIFT | ☐ |
| P75.6 | Flat ground, any CFF | WILCO TOF, the preview TOF and the impact time match the previous build's to the second | ☐ |
| P75.7 | CFF FFE, CONT 5; after 20 s send ADD 100 (adjust reply) | RPT `THUNDER: 'adjust' waits for the splash`; after 120 s the thread gets `ROUNDS IN THE AIR - CALL AGAIN AFTER SPLASH` (tiles CHECK FIRE, EOM); the battery keeps firing - no `NO RESPONSE - HOLDING`, no stand-down from that prompt; RPT `told to call again after the splash` | ☐ |
| P75.8 | P75.7, then CHECK FIRE | Taken at once: `CHECK FIRE - HOLDING`; rounds already in the air land | ☐ |
| P75.9 | RPT | No error from `jmfsb_support_fires_fnc_ballistics`, `fireVirtual`, `threadVolley`, `threadReply`, `inRange`, `reach`, `preview`, `cardPreview`, `layHeight`, `srvThread` | ☐ |

### P74. Transport flown Simplex's way: vehicle orders and a scripted landing (2026-11-05)

Built, not seen in game. Watch the RPT for `heliTake` / `heliRelease` /
`heliOrderTick` lines. Supersedes P73.5 (the stall watch is gone).

| # | Do | Should happen | P/F |
|---|---|---|---|
| P74.1 | LIFT REQUEST (HLZ) to RAVEN, CONFIRM | It leaves its module for the pickup within a few seconds of WHEELS UP; no waypoint is shown on it (none is given); RPT `moveTo: ... MOVE NORMAL to <pickup>` | ☐ |
| P74.2 | If it hovers after WHEELS UP: wait 10 s, then 15 s | RPT `heliOrderTick: '<class>' idle N m short of <grid> - ordered again (<speed>, <height>, engine, behaviour, in the air)` and it sets off; after five without progress `- climbing to N m`. Send me those lines | ☐ |
| P74.3 | Watch the pickup landing (always safe, no circle) | RPT `heliTake: ... takes the airframe N m from <grid> - landing, engine on after 10 m over it - landing to get in`; it slows, descends onto a clear spot, settles; `heliRelease: ... hands the airframe back ... on the ground`; WHEELS DOWN AT PICKUP, TROOP LOAD - ALL IN? as before | ☐ |
| P74.4 | Sit in the back through the landing | No jump or teleport, no damage; it stays on the ground, engine running, until ALL IN | ☐ |
| P74.5 | ALL IN | It lifts off and flies the ROUTE; WHEELS UP TO <LZ>, INBOUND lines as before | ☐ |
| P74.6 | At the LZ: pop smoke, CORRECT, CLEARED TO LAND | It circles 200 m out, 50 m up (ring points, no waypoint), lands on the mark: `heliTake ... landing to get out`, WHEELS DOWN, PAX OFF? as before | ☐ |
| P74.7 | PAX OFF | EGRESS points, then home; at the module it lands (engine off), unloads, is removed; thread CLOSED EGRESS - RTB | ☐ |
| P74.8 | A FASTROPE insertion (airframe with FRIES) | `heliTake ... a hover 18 m over it - the rope hover`; ropes out while it holds still; cabin out, ropes cut, "holding a hover", `heliRelease ... a new order ... in the air` | ☐ |
| P74.9 | A HELOCAST over water | Down to 3 m over the water under the controller, AI out, a slow forward drift (`heliTake ... the cast drift`), a climb to a hover after | ☐ |
| P74.10 | A SLINGLOAD on a crate | A hover 14 m over the load (`the hook`), hooks it, then the AI carries it at the sling height and lowers it; load set down, no rope break | ☐ |
| P74.11 | A QRF AIR ASSAULT by message | Circle, CLEARED TO LAND, then ropes (rope hover) or a landing by the controller; squad out; it lifts for base | ☐ |
| P74.12 | A fixed-wing CAS sortie and a jumpmaster plane | Unchanged: group waypoints, same lines; no `heli*` RPT lines for a plane | ☐ |
| P74.13 | Take the controls as a player copilot while it is under the controller | `heliRelease ... lost the airframe`; you have it; no fight from the script | ☐ |

### P76. Logistics on Simplex's method: the stick on the point, the scripted set-down, the carried-home load (2026-11-05)

Built, not seen in game. Watch the RPT for `airdrop:` / `sling:` /
`heliTake` / `heliRelease` lines.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P76.1 | RESUPPLY, METHOD SLING, one crate, to MULE; CONFIRM | ROGER, WILCO - ETA - 1 x CRATE - SLING; helicopter made over the module with the crate hanging; WHEELS UP INBOUND, INBOUND lines, 1 MIN OUT - POP SMOKE as before | ☐ |
| P76.2 | Watch it 200 m from the point | RPT `sling: MULE '<class>' 200 m from <grid> - to a hover with 'CRATE ...' 12 m over the point, then lowered to the ground` and `heliTake: ... a hover N m over it - the unload hover`; it slows, no AI circling | ☐ |
| P76.3 | Watch the hover | The load hangs about 12 m over the point; RPT `sling: MULE in the hover at <grid> after N s - lowering ...` and `heliTake ... the set-down`; it comes straight down | ☐ |
| P76.4 | Watch the set-down | The crate rests on the ground before the hook lets go (rope slack, no drop); RPT `sling: MULE sets 'CRATE ...' down at <grid>, N s after the take - hook let go`; smoke on the crate; PACKAGE AWAY - CONFIRM RECEIPT | ☐ |
| P76.5 | After the cut | RPT `moveTo ... to <module>` then `heliRelease ... a new order ... in the air`; it climbs to 30 m and flies home; removed over the module; the thread closes on RECEIVED | ☐ |
| P76.6 | Set-down point on a roof or a pier | Hover and set-down measured from the roof / deck, the load put on it | ☐ |
| P76.7 | Block the point (Zeus: a tall object where the load would go) | After 90 s `sling: MULE could not settle ... - let go N m up` (WARNING); the crate comes down undamaged; delivered | ☐ |
| P76.8 | SLING order of 3 items | Three helicopters 60 m apart; each takes its own set-down 60 m from the next; the first on the point | ☐ |
| P76.9 | ABORT while a sling helicopter is inbound or in the hover | `recalled - X not delivered`; the crate stays on the hook, flies home with it, both vanish over the module; RPT `sling: MULE recalled - 'X' carried home on the hook` and `removed with 'X' still on the hook` | ☐ |
| P76.10 | RESUPPLY, METHOD AIRDROP, 4 crates from a plane | RPT `airdrop: MULE '<class>' releases the first of 4 N m short of <grid> at M m/s` and `... the stick is S m long`; the four chutes straddle the point - the middle of the stick on it, not all short | ☐ |
| P76.11 | Same with 1 crate | Release 2 s + 80 m short, lands on or just short of the point | ☐ |
| P76.12 | Airdrop by a helicopter; hold it (Zeus) in transit | If the controller climbs it (`heliOrderTick ... climbing to N m`), the climb holds - the watch does not set 30 m back every tick; it comes onto the Drop Height on the slope as before | ☐ |
| P76.13 | Zeus: damage a delivery helicopter so it autorotates and lands alive | Within a second of it being down and unable to move: RPT `... is down at <grid> and cannot move - counted lost, left where it is`; `MULE is down at ... - no replacement` (or replacement in N s); load not delivered; the thread closes with `aircraft lost at`; escorts recovered; not counted twice if then destroyed | ☐ |
| P76.14 | Delivery crew under fire on the run-in | No break-off, no combat mode; it keeps the line | ☐ |
| P76.15 | Every said line and card of 3.9 RESUPPLY | Unchanged | ☐ |

### P77. CAS on Simplex's method: the pass (2026-11-05)

Built, not seen in game. Watch the RPT for `pass: '<class>' ...` lines. A jet
at 4000 m, a helicopter, a CAS drone; targets a vehicle on open ground.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P77.1 | ATTACK RUN, jet, unguided bombs, no INGRESS | RPT `pass: ... line up by n m, dive from n m`, `lining up - sent to the aim (on the line)`, `commits n m out, n m up`, `on the solution`, `releases <mag> 1 of 2`, `2 of 2`, `bomb '<class>' steered n m onto the aim` (n under 100), `pass: ... fired - salvo complete`; both bombs land within ~30 m of the grid; it pulls out and turns out | ☐ |
| P77.2 | The same with the gun (ORDNANCE = the cannon) | A visible dive, a 2 s burst into the grid, no per-round RPT lines, `fired - burst complete` | ☐ |
| P77.3 | GBU / Scalpel on a laser spot | `takes the laser at <grid> on the way in` if lit late, one round, it guides onto the spot | ☐ |
| P77.4 | Fixed-wing REQUEST ON STATION, CAS REQUEST, CLEARED HOT | IN as it leaves the hold; it lines up on the hold's bearing (or your INGRESS point), dives from 4000 m, releases; `OFF - RETURNING TO STATION - REQUEST BDA` arrives after the pull-out, not while over the target; back at the hold | ☐ |
| P77.5 | Helicopter CAS REQUEST, CLEARED HOT | It climbs to about 150 m for the run (RPT `commits`), fires rockets / gun from about 1 km, OFF, holds short again at NOE 30 m; `moveTo` / `heliOrderTick` lines resume after the pass, no hover over the target | ☐ |
| P77.6 | Helicopter SAD over enemies | Every ~20 s a pass from the orbit at a target, then back to the orbit (`SAD pass over - fired`); no hovering, no idle airframe | ☐ |
| P77.7 | Drone CAS REQUEST, CLEARED HOT | `cleared hot - pass on <grid>`, the drone dives (no waypoint on it during the pass), releases, then flies to its egress point and back over the grid for the BDA | ☐ |
| P77.8 | ABORT (or RTB) during a dive | `pass: ... aborted - recalled` at once, the airframe pulls out and goes home; no fight between the script and the AI | ☐ |
| P77.9 | Let the time on station run out while a pass is in its dive | The pass finishes (OFF said), then `off station, returning to base` | ☐ |
| P77.10 | A pass with nothing to fire (store empty before the run) | `no release, coming round` on the rail (run) or CANTCO `NO RELEASE` (strike from station); no hover, the sortie carries on | ☐ |
| P77.11 | Disable a drone on the ground (damage, no kill) | RPT `is down and cannot move ... lost`, thread CLOSED `disabled`, a respawn used, the drone removed | ☐ |
| P77.12 | Friendlies inside the Friendly Range, no DANGER CLOSE | `holding - friendlies within n m ...` once; no pass begun; with DANGER CLOSE ticked the pass flies | ☐ |
| P77.13 | RPT | No error from `jmfsb_cas_fnc_pass*`, `bombDrop`, `pickStore`, `fireAt`, `runTick`, `jmfsb_support_air_fnc_casRun`, `casStrike`, `casJob`, `casTick` | ☐ |

### P78. A marker's name with its grid (2026-11-05)

Built, not seen in game. A marker `LZ RAVEN` on the map.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P78.1 | NEW, LIFT REQUEST (HLZ), LZ line: MARKER, pick LZ RAVEN; SEND | The message reads `... 041117 (LZ RAVEN)` on that line; the thread row's subject carries `(LZ RAVEN)`; the reader's row for the line shows the same | ☐ |
| P78.2 | Same, then type over the grid before SEND | The name is gone: the grid alone | ☐ |
| P78.3 | Same, then CUR LOC on the line | The grid alone, no name | ☐ |
| P78.4 | REQUEST ON STATION, AREA from the marker list | `AREA 041117 (LZ RAVEN)`; the asset still takes it (the position is unchanged) | ☐ |
| P78.5 | A card forwarded to a net (a TIC to the FIRES net) with a marker-picked grid | The forwarded text shows `041117 (LZ RAVEN)` | ☐ |
| P78.6 | Open an older thread filed before this build | Grids as before, no error | ☐ |

### P79. What happens to an aircraft is said in its thread (2026-11-05)

Built, not seen in game. A LIFT REQUEST flying with escorts; enemy air or AA
on its route.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P79.1 | A missile fired at the helicopter or an escort | FLASH message from RAVEN in the thread `MISSILE - FLARES OUT`, the popup upper right; not again within 15 s | ☐ |
| P79.2 | Hits on the helicopter (gunfire) | `TAKING FIRE AT <grid>` once, then not again for 30 s | ☐ |
| P79.3 | An escort shot down | `ESCORT DOWN - 1 LEFT`, then `ESCORT DOWN - 0 LEFT` | ☐ |
| P79.4 | The helicopter shot down | FLASH `DOWN AT <grid> - AIRFRAME LOST - NO REPLACEMENT` (or `REPLACEMENT IN n S`) in the thread, then the thread's CLOSED line as before | ☐ |
| P79.5 | A rotor or engine fault that grounds it | `CANNOT FLY - <fault> - AT <grid>` at once | ☐ |
| P79.6 | A CAS drone and a logistics aircraft hit | The same `TAKING FIRE` line in their threads | ☐ |
| P79.7 | RPT | `thread T...: air:0 - MISSILE - FLARES OUT` lines; no error from `jmfsb_support_fnc_threadEvent` | ☐ |

### P80. The landing's surface scan (2026-11-05)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P80.1 | LIFT REQUEST, watch the pickup | From `heliTake` on, the helicopter comes down to a 10 m hover over the pad and lands; no climb | ☐ |
| P80.2 | RPT during the approach | `heliFrame: ... approach - n m out, n m over the terrain, goal 10 m, floor n m, vz n m/s, hit '...'` every 5 s; the height over the terrain falls toward 10, `hit` is a terrain / building object or empty - never a man or the airframe's class | ☐ |
| P80.3 | If it still climbs | Send the `heliFrame:` lines: they say whether the floor or the goal is what it is chasing | ☐ |

### P81. The dive's remains (2026-11-06)

Built, not seen in game. Zeus: a *JMSB - Drone Swarm*, Impact, 4 x
`jmfsb_faction_china_O_SwitchBlade_600`, on a squad in the open and again
against a two-storey building.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P81.1 | Let all four arrive | Four bursts, each at the aim or on the first wall / roof / man in the way; after each, nothing of the airframe remains - no wreck lying there, nothing moving on the ground, no second explosion | ☐ |
| P81.2 | Shoot one down on the way in | No bang from ours (on a hosted game the Switchblade mod's own airburst may go off where it was hit); the airframe vanishes there, nothing falls or slides on | ☐ |
| P81.3 | Stand a unit 20 m short of the aim on the approach bearing | The drone bursts on it (the surface look-ahead) rather than flying through it to the aim | ☐ |
| P81.4 | Low frame rate (a busy map) | Still one burst per drone at the aim - a drone carried past it by a long frame bursts on overshoot or on the ground instead of ramming it | ☐ |
| P81.5 | *JMSB - Ambient Kamikaze Drones*, wait for a run | Same end: one burst on the building, nothing left of the quad | ☐ |
| P81.6 | A DDT-flown FPV (IED Pelican, Switchblade) dies on a player | The wreck stops dead where it was killed and is gone next frame; nothing of it slides on | ☐ |

### P82. The landing, placed by the wheels (2026-11-06)

Built, not seen in game. P80's lines are the readout.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P82.1 | LIFT REQUEST, watch the pickup | From `heliTake` on it descends and slows; `heliFrame: ... n m over the terrain` falls every 5 s toward `goal`, never climbs; a 10 m hover, then down (P83 for what follows) | ☐ |
| P82.2 | Sit in the back through it | A smooth ride, no jump, no damage (P74.4) | ☐ |
| P82.3 | CAS REQUEST, CLEARED HOT (plane, then a helicopter) | The dive comes down the line to the aim and fires; it does not climb away during the dive, no `pulled out` or `the dive went vertical` unless the aim really was unreachable | ☐ |
| P82.4 | A bomb pass | The bomb falls on the aim, not above it | ☐ |

### P83. Gear down, held down; escorts on the wing (2026-11-06)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P83.1 | LIFT REQUEST, watch the last 150 m of the pickup | The gear comes down before the touchdown and stays down | ☐ |
| P83.2 | After the touchdown, wait 30 s before boarding | It stays on the ground, engine running; RPT `heliFrame: '<class>' down at <grid> - engine running, held on the ground until the next order`; no climb back to a hover | ☐ |
| P83.3 | ALL IN | It lifts off and flies the route; RPT `heliRelease ... a new order ... on the ground` | ☐ |
| P83.4 | At the LZ, PAX OFF | Same at the drop: gear down, down, held, engine running until the egress order | ☐ |
| P83.5 | A LIFT with LZ security YELLOW or RED, watch the two drone wingmen in transit | Each holds beside and a little behind the lead - about 80 m out, 50 m back, stacked above it - and keeps pace; one that falls behind closes up within a few seconds rather than trailing | ☐ |
| P83.6 | The lead lands | The wingmen orbit it about 200 m out | ☐ |
| P83.7 | A threat near the lead | The wingman breaks off at full speed to engage, not held to the lead's pace | ☐ |
| P83.8 | A logistics plane with its fixed-wing escorts | About 250 m out, 150 m back, keeping pace; no stall, no wingman falling out of the sky | ☐ |

### P84. The pickup holds for ALL IN (2026-11-06)

Built, not seen in game. A LIFT REQUEST by message.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P84.1 | Let it land at the pickup | Thread `on the ground at <grid>, holding for ALL IN` and `TROOP LOAD - ALL IN?` | ☐ |
| P84.2 | Everyone boards; say nothing for 3 minutes | It stays down, engine running, gear down; it does not lift with everyone aboard, nor when the module's Extract Wait runs out | ☐ |
| P84.3 | Aboard, as the issuer or a group leader: scroll menu | `ALL IN` with the get-in icon at the top of the menu; not shown on foot, not shown to a man who is neither issuer nor leader, not shown once it has lifted | ☐ |
| P84.4 | Use it | `all in by <name>, lifting`; it lifts and flies the route | ☐ |
| P84.5 | Again, ALL IN by the `allin` reply in the thread instead | Lifts the same | ☐ |
| P84.6 | Again, ALL IN by the ACE self action | Lifts the same | ☐ |
| P84.7 | Respawn, then a new lift | The scroll action is there on the new unit, once (not twice) | ☐ |
| P84.8 | An EXTRACTION, at the HLZ | Holds the same way until ALL IN | ☐ |

### P85. Quick answers on numpad 6-9 (2026-11-06)

Built, not seen in game. Phone or side device up, tablet closed. Numpad 6-9 are the device keys F1-F4, numpad 0 / . the arrows.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P85.1 | LIFT REQUEST by message; let it reach the LZ | Above the call strip: `RAVEN I SEE RED SMOKE` (red name, FLASH), then `NUM 6 CORRECT   NUM 7 WRONG` | ☐ |
| P85.2 | Press numpad 6 | `SENT CORRECT`; CORRECT is filed in the thread; the next question (`READY TO LAND - CLEARED?`) takes the strip | ☐ |
| P85.3 | Answer CLEARED TO LAND on numpad 6 | It lands; the strip goes until `TROOP LOAD - ALL IN?` | ☐ |
| P85.4 | Answer a question from the tablet instead | The strip goes when the answer comes back | ☐ |
| P85.5 | CFF GRID with ADJUST FIRE; at `ADJUST?` press the key for ADD | The strip shows ADD 25 ... ADD 400 and BACK, two pages (`NUM 0/. 1/2`); a distance files ADJUST ADD <m> | ☐ |
| P85.6 | `ROUNDS COMPLETE - REQUEST BDA` | BDA opens the tablet composer on the BDA card in the thread (it has a required line); RECORD / REPEAT / CLOSE file at once | ☐ |
| P85.7 | Two questions at once (a transport and a battery) | FLASH first, `1 OF 2`; answering one shows the other | ☐ |
| P85.8 | CFF whose Observer line names another player's group | That player's strip shows the battery's question too; his answer is taken; it goes off both strips | ☐ |
| P85.9 | Nothing waiting | Numpad 6-9 do the player's own device keys again (accept call, mute, ...); 0 / . step the active net | ☐ |
| P85.10 | RADIO app open on the phone | 6-9 are the RADIO app's; the strip comes back when it closes | ☐ |
| P85.11 | A player pilot sent a LIFT REQUEST (his P: box) | His strip: `ASK <requester>` and POP SMOKE / LZ STATUS? / SMOKE OK? / CLEARED? (page 2: ALL IN? / PAX OFF?) | ☐ |
| P85.12 | The pilot presses CLEARED? | The requester's strip shows `READY TO LAND - CLEARED?` with CLEARED TO LAND / HOLD / ABORT (answers need the thread ON TASK - the crew sends ON TASK first) | ☐ |
| P85.13 | The thread closes | Every strip for it goes | ☐ |

### P86. AiTR building marks (2026-11-06)

Built, not seen in game. Wear an AiTR goggle, ECOTI on.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P86.1 | Eden: JMSB - AiTR Building Mark on a house, Colour Blue, Label OBJ ALPHA | In game a blue box round the house with `OBJ ALPHA \| <range>`, through walls, out to 2 km; fades with range | ☐ |
| P86.2 | Eden: the module with two buildings synced | Both marked; the nearest-building rule is not used | ☐ |
| P86.3 | Eden: the module 40 m from any building | RPT `moduleMark: no building within 25 m` | ☐ |
| P86.4 | Zeus with ZEN: AiTR building mark on a building | Dialog Colour / Label; the box appears for every player; CLEAR takes it off | ☐ |
| P86.5 | Zeus: the Eden module placed from the Zeus list | Marks the nearest building red, label MARK | ☐ |
| P86.6 | Bind AiTR - mark building; look at a house with the phone up; press | Strip `MARK <HOUSE> - COLOUR?`, RED BLUE GREEN YELLOW on 6-9, page 2 WHITE ORANGE PURPLE | ☐ |
| P86.7 | Pick one | Hint `MARK <colour>`; every player's AiTR shows it | ☐ |
| P86.8 | Press on a marked house | CLEAR is on page 2; it takes the mark off | ☐ |
| P86.9 | No device up; press three times | Red, blue, green in turn; after purple, no mark | ☐ |
| P86.10 | Look at the sky; press | Hint `MARK - NO BUILDING UNDER THE CROSSHAIR` | ☐ |
| P86.11 | The house is destroyed | Its box goes | ☐ |

### P87. TAC//MSG reply tags readable (2026-11-06)

Built, not seen in game.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P87.1 | Open a support thread with the asset's replies | BOXCAR's replies tag the card (WILCO, INBOUND, ON TASK), not YOU | ☐ |
| P87.2 | Your own reply | Tagged YOU, the whole word in its chip | ☐ |
| P87.3 | A long call sign (GHOST 1 YONV) | The tag starts after the name; nothing overlaps | ☐ |

### P88. Teleport list loop (2026-11-06)

| # | Do | Should happen | P/F |
|---|---|---|---|
| P88.1 | Dedicated server, players join | No `teleport list overwritten by a client` lines repeating in the server RPT | ☐ |
| P88.2 | Teleport menu | Lists the mission's points | ☐ |
| P88.3 | A client keeps overwriting the list | At most one `teleport list overwritten by a client <n> time(s)` line a minute; the list is put back within a second | ☐ |

### P89. Net buttons - three pages of four (2026-11-07)

Built, not seen in game. Needs a player on five or more nets (a TL: TEAM, C2,
plus VEH in a vehicle and an RTO net) or nets set on page 2 / 3.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P89.1 | Phone up, on three nets | Four cells, three chips numbered 1-3, one dim cell; no page marker | ☐ |
| P89.2 | Tablet RADIO > NETS > BUTTONS: set PAGE 2 · 1 to C2 | The phone row shows `2/2` at its right end; C2 is gone from page 1, the others close up | ☐ |
| P89.3 | Numpad . then 0 on the walking view | The row turns to page 2 (C2 reads `1 C2`), then back; numpad 1 on page 2 makes C2 active | ☐ |
| P89.4 | Ctrl + numpad 1 on page 2 | C2 mutes (struck red), the active net does not change | ☐ |
| P89.5 | Side device | 2 x 2 chips, `2/2` in the row under them; 0 / . turn the page | ☐ |
| P89.6 | Tablet open | Four cells, `< 2/2 >` left of GLOBAL; < and > turn the page at once; numpad 0 / . still turn the live tiles | ☐ |
| P89.7 | BUTTONS: set QUICK 1 to a net you are not on | That button reads `(NOT ON IT)`; chip 1 is a dim cell, chips 2-4 keep their nets | ☐ |
| P89.8 | Set a net on QUICK 2 that already sits on PAGE 2 · 1 | PAGE 2 · 1 goes back to AUTO; the net is on one button only | ☐ |
| P89.9 | Get a call while page 2 is shown | A RING cell on page 2 (first empty cell, else the last); * answers | ☐ |
| P89.10 | Rejoin / next mission | The BUTTONS settings are still there (profile); the row starts on page 1 | ☐ |

### P90. TAC//MSG message templates (2026-11-09)

Built, not seen in game. From `docs/DESIGN_MESSAGE_TEMPLATES.md` and
`DESIGN_MESSAGE_TREES.html`.

| # | Do | Should happen | P/F |
|---|---|---|---|
| P90.1 | Open INSERTION (HLZ) | REAL WORLD view, 11 lines; REQ on DROP-OFF LZ's line head; SIMPLE tags on DROP-OFF LZ and INSERTION | ☐ |
| P90.2 | Press SIMPLE on the card head | Only DROP-OFF LZ and INSERTION; what was typed elsewhere is still sent | ☐ |
| P90.3 | TAC//PAC > Templates > REPORT DECK: press TEMPLATES: REAL WORLD | Turns to TEMPLATES: SIMPLE; the next card opens SIMPLE for players on UNIT (TAC//PAC) | ☐ |
| P90.4 | Settings: composer default REAL WORLD with PAC on SIMPLE | Cards open REAL WORLD | ☐ |
| P90.5 | CAS REQUEST: pick an IP and a target | Lines 2, 3, 4 and 8 fill (heading, distance, elevation, direction and distance to you) | ☐ |
| P90.6 | CAS to an aircraft | WILCO, then READBACK - TARGET grid; CORRECT: IP INBOUND, IN asks CLEARED HOT / CONTINUE / ABORT | ☐ |
| P90.7 | CAS with TYPE 3 ticked | CLEARED TO ENGAGE offered; after the pass ATTACK COMPLETE - REQUEST BDA | ☐ |
| P90.8 | ABORT on the run | No release; STATE INTENTIONS with MOVE / HOLD / FRAGO / RTB / CAS | ☐ |
| P90.9 | BDA: BACK TO STATION | FURTHER TASKING?; RTB flies the egress home | ☐ |
| P90.10 | FRAGO on an INSERTION before lift: change the LZ | Card shows only DROP-OFF LZ old -> new; the transport flies the new LZ | ☐ |
| P90.11 | FRAGO on CAS after IP INBOUND | ABORT FIRST - not taken | ☐ |
| P90.12 | STATUS in any asset thread | STATUS REPLY: position, task, time left, fuel, ammo, pax | ☐ |
| P90.13 | ESCORT in a transport thread before launch, GREEN LZ | ESCORTS WILL LAUNCH WITH THE AIRCRAFT; drones launch with it | ☐ |
| P90.14 | ESCORT with the aircraft airborne | ESCORTS LAUNCHING; pressed again: ESCORTS ALREADY UP | ☐ |
| P90.15 | Landing: READY TO LAND - CLEARED? answered CONTINUE APPROACH / GO AROUND | Asked again later / circles, looks for the mark, asks again | ☐ |
| P90.16 | MOVE in a transport thread: point, LAND | Flies there, circles for the mark, lands and shuts down | ☐ |
| P90.17 | 9-line CASEVAC, line 6 X | Escorts launch (X reads RED); WILCO names litters and equipment | ☐ |
| P90.18 | TIC thread: file a CAS REQUEST into it to an aircraft | The aircraft answers in the TIC thread; the TIC grid was prefilled | ☐ |
| P90.19 | PARADROP: NO DROP at STAND BY | Another pass, asked again; second NO DROP asks STATE INTENTIONS | ☐ |
| P90.20 | RTB with LAND AT set, players aboard | RTB - LANDING AT grid FOR PAX FIRST; lands, PAX OFF?, then home | ☐ |
| P90.21 | RTB with LAND AT set, nobody aboard | Straight home | ☐ |
| P90.22 | Jump aircraft: NO DROP on the run-in | No green light, another pass | ☐ |
| P90.23 | CFF: a second call for fire in the thread | WILCO, the guns re-lay; ROUNDS COMPLETE card after the FFE | ☐ |
| P90.24 | Tablet MENU | LOG row opens the notices log; a LOG tile can be put on the band | ☐ |
| P90.25 | Medical HUD monitor | EKG and pleth traces 1 px | ☐ |
