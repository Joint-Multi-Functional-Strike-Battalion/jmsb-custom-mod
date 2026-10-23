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
| Open SUPPORT with tasking held by another tag — a blank screen is not the result; the strip is there and closes out | ☐ | the gate refused before its dialog opened |
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
| P1.2 | Look at the screen rows | Device bar (TAC//APP, time, GRID, callsign . group, TABLET, ESC CLOSES), notification line, live tiles, map area with the squad rail and the TOOLS / SETTINGS / ADMIN / HIDE strip, net row at the foot (one cell per voice net you are on, never a frequency) | ☐ |
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
| P2.2a | Net state colours: walk away from your squad until TEAM weakens, then out of reach; mute a net (Ctrl + numpad 3); EW barrage on its band (P15.8) | TEAM's outline goes green -> amber (weak or jammed) -> red (no route); a muted net's outline and name dim. The tablet's net row shows the same colours | ☐ |
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
| P4.7 | The PAC tile app | Opens as a tablet app, closes cleanly | ☐ |
| P4.8 | Addon Options > Display mode = Native | The tablet closes; the map (M) carries the suite as before; ADMIN / SUPPORT / MSG open as their native dialogs. Back to Tablet | ☐ |
| P4.9 | **[2P]** Open a thread he wrote in (TAC//MSG); press **CALL** in the action row under QUICK REPLY (next to + MARKER) | His phone rings; accept and you are on a CALL net together, as with the roster's CALL. A thread where nobody else is in game: CALL is dim and does nothing. Without game voice (TFAR / ACRE loaded) there is no CALL button | ☐ |

### P5. TAC//SUPPORT inside the tablet

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

### P13. Numpad keys

All CBA keybinds in Configure Addons > JMSB (rebindable). Check each in each
context; a key that does something it should not, or nothing where it should,
is a fail - paste which.

| # | Key | Walking view (phone / side) | Tablet open | RADIO app open on the phone / side | A text box focused | P/F |
|---|---|---|---|---|---|---|
| P13.1 | 1 2 3 4 | F1 accept call / F2 ear (quick add in a call, owner) / F3 mute / F4 decline or hang up | the frame's F1-F4 apps | the soft keys shown | typed into the box | ☐ |
| P13.2 | 0 . | active net left / right (quick-add cursor while the list is up) | active net left / right | cursor | typed | ☐ |
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
| P14.11 | With TAC//SUPPORT open, click the map | The click sets SUPPORT's point, never a tool press; the press that closes an app is not a tool press either. Shift / Ctrl / Alt clicks stay the game's | ☐ |
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
