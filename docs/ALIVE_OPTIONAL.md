# Running with or without ALiVE

User, 2026-11-02: "we should run without alive" - "works with or without" -
"but if alive is present we integrate" - "but not the support". Built, not
seen in game.

Not a generated file. Edit it by hand when a feature's answer changes.

## How it works

- `addons/adapter_alive` requires `ALiVE_main` and carries
  `skipWhenMissingDependencies`. Without the ALiVE mod its PBO is skipped:
  every `jmfsb_adapter_alive_fnc_*` is nil, every `jmfsb_adapter_alive_*`
  variable undefined, `whenReady` / `onCapture` hooks never run.
- Nothing else requires ALiVE or the adapter in `requiredAddons` (checked
  2026-11-02), so every other PBO loads either way.
- Every call into the adapter is guarded where it is made:
  `if (isNil QEFUNC(adapter_alive,<fn>)) ...` (coding guidelines R6). The
  string-literal spellings (`isNil "jmfsb_adapter_alive_fnc_x"`) were all
  turned into the macros.
- A feature's decision and its one RPT line go through
  `jmfsb_common_fnc_aliveLoaded [feature, what instead]`, and `<feature>:
  ALiVE not loaded - <what instead>` is written once per feature, not once
  per call.
- ALiVE is its own main PBOs (user, 2026-11-02: "use the alive main pbo
  names"): loaded = every CfgPatches class in `PATCHES_ALIVE`
  (`ALiVE_main`, `ALiVE_x_lib`, in addons/common/script_component.hpp) AND
  the adapter's own class, so a yes always means the adapter's functions
  exist. The adapter's `requiredAddons` carries the same names as literals
  (config needs them) with a comment pointing at the define - keep the two
  in step. The adapter's `jmfsb_patches_usesAlive` is the same test, asked
  at preInit.
- Support is not touched: it is the mod's own providers with or without
  ALiVE (see the support README, "Without ALiVE"). Only their
  `profileIgnore` calls were checked.

## The mission's own answers (addons/common)

| Function | With ALiVE | Without ALiVE |
|---|---|---|
| `groundFor [side]` | the adapter's `taorFor` | area markers whose names start `jmfsb_taor_west` / `jmfsb_taor_east` / `jmfsb_taor_guer` (anything may follow, case does not matter); `jmfsb_black_<side>` kept out; none = whole map |
| `settlements` | ALiVE's settlement clusters | the map's capital, city and village locations, at least 150 m |
| `hostileCommander [side]` | first ALiVE commander hostile to the side | the mission's enemy (`enemySide`) when hostile, faction from `sideFaction`, no control type |
| `sideFaction [side, unit]` | - | the named unit's faction, else the most common faction among the side's AI |

WHERE stays out of CBA settings: the fallback ground is map markers, the
fallback identity is the mission's own units and side relations.

## Feature by feature

| Addon | Feature | With ALiVE | Without ALiVE | Where |
|---|---|---|---|---|
| common | Pre-spawn gate (`taorGate`) | ALiVE TAORs | `jmfsb_taor_<side>` markers; none = whole map minus others' ground (fallback) | common/functions/fnc_taorGate.sqf:71 |
| airdefence | Air Defence module | commanders, TAORs, objectives from ALiVE | sides with a module TAOR field or `jmfsb_taor` markers get batteries over their towns; none drawn = the enemy, towns 3 km clear of player-side men (fallback) | airdefence/functions/fnc_moduleController.sqf:94, fnc_plan.sqf:46 |
| airdefence | Battery / MANPAD / security crews kept out of ALiVE | `profileIgnore` | skipped (were unguarded - a script error from an AA Base without ALiVE) | fnc_crewSite.sqf:95, fnc_buildTeam.sqf:97, fnc_buildSecurity.sqf:54 |
| airdefence | AA Base guards profiled | once ALiVE is up | stay live, one RPT line per base | fnc_profileGuards.sqf:31 |
| leaders | Leader chain | the asymmetric commander, its TAOR, faction, ALiVE settlements | the enemy (or the side of a man synced to the module, his faction), module TAOR / `jmfsb_taor` markers, map towns (fallback) | leaders/functions/fnc_moduleController.sqf:62, fnc_start.sqf:30, fnc_safeHouses.sqf:40, fnc_placePops.sqf:51, fnc_spawnLeader.sqf:29 |
| leaders | Spent leaders persisted | ALiVE data | not kept; a restart brings all three back | fnc_start.sqf:58, fnc_save.sqf:16 |
| qrf | Watch list | commanders' objectives + `jmfsb_qrf*` markers | `jmfsb_qrf*` markers only | qrf/functions/fnc_gather.sqf:59 |
| qrf | Who answers | first hostile commander | the mission's enemy, its men's faction (fallback); nobody when no QRF module is placed (reaction's burn-through used to reach the waves with their values unset) | fnc_onCaptured.sqf:25, :32 |
| qrf | Squads | profiled, ALiVE waypoint | walk in live (fallback; was: nothing sent) | fnc_waveSquads.sqf:31 |
| qrf | Artillery | asked of the commander's guns | off - no guns to ask, one RPT line | fnc_waveArty.sqf:53 |
| qrf | Contested by virtual troops | ALiVE profiles near | live men only | fnc_contested.sqf:35 |
| qrf | FRONT line on a commander capture | on | off (no commanders capture) | qrf/XEH_postInit.sqf:41 |
| qrf | Start | on ALiVE ready | at mission start (was: before postInit, which reset the watch list) | fnc_moduleController.sqf:52 |
| reaction | "Has your position" | ALiVE COP knowledge | the hostile side's own `knowsAbout` the man, 3+ (fallback) | reaction/XEH_postInit.sqf:94 |
| reaction | MAJOR / counter-battery answering side | first hostile commander | the mission's enemy (fallback): drone comes looking, gated virtual barrage | fnc_major.sqf:43, fnc_cbFire.sqf:41 |
| reaction | Town hostility on the roll | ALiVE civilian model | the chance as set | fnc_roll.sqf:65 |
| hacking | Body intel by kind of war | phones / radios by commander type | documents by chance on every side, one RPT line | hacking/XEH_postInit.sqf:376 |
| hacking | Intel tally persisted | ALiVE data | not kept past the mission | XEH_postInit.sqf:394, fnc_srvDeposit.sqf:77 |
| hacking | AA / arty / camp / logistics / installation hunts | offered when ALiVE has them | not offered (counts read 0); package, anti-ship, radar, jammer, leader hunts unchanged | fnc_intelOptions.sqf:84, fnc_productLocate*.sqf |
| hacking | Product scoping by ground | ALiVE TAOR control type | none - every product the mission has is offered | fnc_taorType.sqf:44 |
| hacking | Intel back to ALiVE G2, hostility bump | on | off | fnc_intelHint.sqf:219, fnc_ladderCircle.sqf:98, fnc_popWitness.sqf:57 |
| hacking | `#jmfsb hack.taor` | each commander's TAOR | says ALiVE is not loaded, nothing scoped out | XEH_postInit.sqf:292 |
| jamming | Jammer Site modules | jam, GPS uplink registered as an objective | jam, not registered | jamming/functions/fnc_spawnJammerSite.sqf:122 |
| jamming | Objective jammers | over commanders' objectives | off, one RPT line | fnc_moduleController.sqf:99 |
| uas | Drone Patrol Zone modules, caches, top-up | profiled / registered / resupply asked | fly live, plain caches, no resupply | uas/functions/fnc_topUp.sqf:179, fnc_placeCaches.sqf:84, fnc_cacheDown.sqf:45 |
| uas | "Patrol ALiVE objectives" zones | opt-in setting | off; one RPT line when the setting is on; setting says "Needs ALiVE" | uas/XEH_postInit.sqf:79 |
| antiship | Coastal batteries | each non-player commander's TAOR | the module's own area at mission start (was: after a 300 s wait); with ALiVE but no commanders, once the adapter gives up | antiship/functions/fnc_moduleAntiShip.sqf:207 |
| antiship | Launcher as an ALiVE objective, crews ignored | on | off | fnc_launcherInit.sqf:77, fnc_moduleAntiShip.sqf:182 |
| bft | Virtual friendlies layer | ALiVE's off-map groups, faded | nothing to draw; setting says "Needs ALiVE" | bft/functions/fnc_draw.sqf:242 |
| messaging | CONTACTREP / SITREP posted to C2ISTAR | on | message sent as normal, not posted; one RPT line; setting says "Needs ALiVE" | messaging/functions/fnc_srvForward.sqf:45 |
| maptools | ALiVE marker system | listed, opens ALiVE's dialog | not listed; a saved ALiVE choice opens the built-in card | maptools/script_component.hpp:120, fnc_markerOpen.sqf:50, fnc_markerDelete.sqf:41 |
| curator | Zeus drones kept out of ALiVE | `profileIgnore` | skipped (guarded) | curator/XEH_preInit.sqf:25 |
| cas | Loiter / strike aircraft kept out of ALiVE | `profileIgnore` | skipped (was unguarded) | cas/functions/fnc_request.sqf:342 |
| support_air, support_logistics, jumpmaster, support | Aircraft and items kept out of ALiVE | `profileIgnore` | skipped (already guarded) | fnc_prepareAircraft.sqf:67, fnc_qrfLaunch.sqf:99, fnc_spawnAircraft.sqf:78, fnc_spawnItem.sqf:69, jumpmaster fnc_spawnAircraft.sqf:62, support fnc_escort.sqf:116 |
| respawn, init | - | comments only; no calls | - | - |

## Waits

- `whenReady` hooks run only with ALiVE. Every module that started on them
  now has a path without the adapter (air defence, leaders, QRF start at
  `time > 0`; jamming and uas say once and carry on; hacking says once).
- `whenReady [code, args, fallback]`: the third argument is that same path
  without ALiVE. Each consumer hands in the branch it runs when the adapter
  is not loaded, so there is one path without ALiVE, not two.
- Anti-ship now starts on `whenReady` like the rest; its own 300 s timeout
  (`AS_ALIVE_WAIT`) is gone - the adapter's give-up below replaced it.

## ALiVE loaded, no commanders = not loaded

User, 2026-11-02: "same as not loaded". Built, not seen in game.

- The adapter waits for ALiVE as before and says so every minute
  (`waiting on ALiVE init`).
- Still no commander (`OPCOM_instances` nil or empty) `READY_GIVE_UP` (300 s,
  adapter_alive/script_component.hpp) into the mission: one RPT line,
  `WARNING ... no ALiVE commander after 300s - ALiVE treated as not loaded
  for this mission`, and ALiVE is absent for the rest of the mission.
- The flag: server truth in `localNamespace` `jmfsb_adapter_alive_absent`,
  public copy in `missionNamespace` (same pattern as `ready`).
- From then on `aliveLoaded` answers no (server: the localNamespace flag;
  clients: the public copy), and says its once-per-feature line as
  `<feature>: ALiVE loaded with no commanders - treated as not loaded - <what
  instead>`.
- Every queued `whenReady` hook runs its fallback; a later `whenReady` call
  runs its fallback at once. The adapter's own pools, event bridge, COP and
  LAMBS settings never start (no fallback - as when its PBO is skipped).
- Commanders that exist but are still starting up: waited for as long as
  they take, no give-up.
- Decisions that ask `aliveLoaded` beside their `isNil` guard, so they flip
  with it: common `groundFor`, `settlements`, `hostileCommander` (and
  `taorGate` through `groundFor`); air defence `plan`, `profileGuards`;
  leaders `start` (side, faction, spent leaders read), `spawnLeader`, `save`;
  QRF `gather`, `waveSquads`, `waveArty`, `contested`; reaction spotted
  warning, `major`, `cbFire`, `roll`; hacking `taorType`, `hack.taor`,
  `intelHint`, `intelOptions` (installations), `ladderCircle`,
  `popWitness`, `srvDeposit`.
- Left as they are: `profileIgnore` calls (a variable on the unit, harmless),
  and the adapter reads that already answer nothing until ready
  (`registerSite`, `requestSupply`, `logisticsHubs`, `commanders` off the
  empty public summary). ALiVE's own UI systems - its marker system
  (maptools), C2ISTAR posting (messaging), virtual friendlies (bft) - follow
  ALiVE's modules, not its commanders, and are unchanged.

## Launch

`hemtt launch` (any profile but `alive`) is the run without ALiVE;
`hemtt launch alive` adds ALiVE (workshop 620260972). Tests: docs/TESTS.md
P59.
