# CAS

`jmfsb_cas`

Player-tasked fixed-wing CAS drones, on the support page.

Place one **JMSB - CAS Drone** module per airframe. Many are allowed and each
is its own asset: its own callsign, its own aircraft, its own approach and its
own losses. Two Reapers and a Bayraktar is three modules and three rows in
TAC//SUPPORT.

The module carries the operation values - which airframe, the run-in floor,
how fast it runs, how many replacements it has, how long before it can be
asked again. **It never carries the geometry.** The target grid, the ingress
heading and the egress heading are set per request on the support page, which
is why one module can run a strike onto any grid on the map rather than only
the ground it was dropped beside.

**Ingress and egress are points on the map, picked the same way the target
is** - click the map, or take a placed marker off the `MKR` list. The aircraft
flies from its module to the ingress point and runs out towards the egress
point, so a section puts the run-in behind the ridge they are looking at
rather than converting it into a heading first. The support page shows the
run as two legs through the target, so the geometry gets checked on the map
rather than in the head.

Either may be left unset and the run still flies: **ingress** then is straight
in from the module, where the drone is made, **egress** carries straight on
through. Requiring three map picks before anything could be called in would
make the fast case slow.

**Virtual until tasked** (user, 2026-11-02: "all support aircraft needs to be
virtual till tasked, then they spawn in at alt over the support module
location"; it replaced the same day's "on station from the start"; built, not
seen in game). No drone exists between tasks. The row reads READY with the
respawns left; the reach card's and the verdict's ETA is the flight from the
module to the target (by the ingress point when one is set) at the module's
run speed.

- **Tasked** - a board ATTACK RUN / SAD / LOITER, a `cas` card or a REQUEST ON
  STATION accepted (`fnc_request`, `fnc_srvThread`) - the drone is made at
  once (`fnc_launch`, `fnc_spawnDrone`): in the air directly over the module at
  the hold altitude (4000 m ATL), engines on and flying, dark, full of fuel and
  stores, clear of any other aircraft (the support core's `spawnAirborne`).
  It flies the run as built: the card's ingress point first when it gave one,
  then in through the target and out to the egress; a LOITER or a strike held
  for CLEARED HOT orbits the grid. A REQUEST ON STATION answers `LAUNCHING - ON
  STATION IN m:ss`. The Response Delay is retired (a mission that set it still
  loads; the value is not read).
- **After the task** - egressed, recalled (RTB / CLOSE / ABORT), out of
  patience, a loiter released, NO RESPONSE, BINGO, Winchester (`fnc_recover`):
  the seat given back and the drone taken back to the server, then it flies
  home to the module at the hold altitude - a BDA whose decision is EGRESS by
  its egress point first - and is removed, crew and airframe, within 600 m of
  the module (or where it is after twenty minutes). The asset is virtual again;
  its cooldown runs from the end of the run as before. The next tasking makes a
  new drone, restocked.
- **Respawns** (user, 2026-11-02; `fnc_gone`, `fnc_killed`). The module's
  **Respawns** (default 0) and **Respawn Delay (sec)** (default 300). A drone
  LOST - shot down on its run or on its way home - spends one: the row reads
  REARMING (the reach card `REPLACING n S`) for the delay, then READY; the next
  tasking makes a new drone. Going home normally uses none. None left: the
  asset is gone - off the support list, and a card to it answers CANTCO
  `UNABLE - NO AIRFRAME`. Each airframe is counted once.

The module's **Ingress Distance** is a floor, not a fixed range - a point
dropped two hundred metres off the target is an aircraft with no room to line
up, so anything closer is pushed back along its own bearing. The player still
chooses the direction, which is what he actually cared about.

**Altitudes are ATL throughout.** Height is above the ground under the
aircraft, so a run over a ridge is flown that high over the ridge - not over
the sea with the ridge eating into it.

**It flies tactically** (user, 2026-11-01; the support core's README,
"Tactical flight"). A strike runs in at **4000 m ATL**; a LOITER orbits
**over the grid** at 4000 m. The drone is made in the air, so it has no
airfield: **no lights at any time**, and its crew is kept from
switching them on. The module's Attack Altitude is retired - missions that
set it keep loading, the value is not read.

**Drones are exempt from the off-map hold** (user, 2026-11-01): a drone's
LOITER orbits over the grid, dark, at 4000 m, so the ISR operator in the
seat can see it. Crewed fixed-wing support aircraft still hold 8 km off the
map when on station. CAS drones take no drone escorts.

**The grid is where the strike starts, not where it lands.** A map click is
accurate to the pixel, which over four kilometres of run-in is the building
next to the one that was meant. So the aircraft looks again on the way in -
every second, because a designator comes on late far more often than early -
and shifts onto whatever it finds inside the module's terminal search radius:

| | |
|---|---|
| **Laser** | Own side's spots only. Unambiguous, aimed by a man who can see the target, and the only one of the three that tracks something moving. |
| **Smoke** | Any colour. Every rifleman has it and it needs no equipment; asking a man under fire to find the right grenade is asking for the strike to go in on nothing. |
| **The grid** | No spot and no smoke is not a failure. It is a map-grid strike, which is what was ordered, and it goes in. |

Terminal search 0 turns the whole thing off and the grid is final.

The AI is not flying it and is not shooting it. The group runs CARELESS with
targeting disabled; the strike is **the pass** (below), which lines the drone
up, dives it and pulls the trigger by script, and guided ordnance is pinned to
a dummy laser target so a release either hits or says in the log why it did
not. Arma's air AI given a SAD waypoint orbits an objective without engaging
often enough that every support mod in existence has stopped asking it.

**It is a real aircraft and it can be lost.** Shooting it down is worth doing:
each loss spends one of the module's **Respawns** (2026-11-02; it replaced
Airframes Available), and an asset that loses its last drone is gone from the
support list for the rest of the mission. A mission that set Airframes
Available still loads; the value is not read. A drone down on the ground that
cannot move is lost the same way (2026-11-05).

Not jmfsb's design. The run geometry, the terminal guidance and the dummy-laser
delivery are **Simplex Support Services'** model, rebuilt against jmfsb's own
support seam. **CAS runs modelled on Simplex Support Services; no code of it
used** (GPL-2; this mod is APL-SA).

## The pass (2026-11-05)

User: "the back end should be based on simplex". Simplex read for how it flies
a strafe; everything written here. One attack run of any CAS aircraft - these
drones', and support_air's jets and helicopters through `jmfsb_cas_fnc_passBegin`
/ `passTick` / `passEnd` - on the airframe as `jmfsb_cas_pass`. Before, one
trigger pull inside a 600 m ring (700 m for support_air) from wherever the AI
had the aircraft: at 4000 m, level, an unguided bomb landed kilometres long and
the gun fired at nothing.

- **The store** (`fnc_pickStore`): the one asked for when it is aboard with
  rounds left, else the heaviest; its kind from the config - *guided* (a laser,
  IR or NV lock: the seeker takes the dummy), *bomb* (no muzzle speed: released
  at the airframe's speed and flown to the aim, `fnc_bombDrop`), *shell* (gun,
  rockets at burnout speed: a ballistic arc). The salvo: bombs in pairs, one
  guided round, four rockets, a 2 s gun burst (PASS_SALVO_*).
- **The line-up** (`fnc_passTick`, every tick of the owner's watch): the AI
  flies it on its own orders (a drone `doMove`; support_air its `moveTo`) - to
  the aim while within 25 deg of the ingress bearing seen from the aim, else
  to the prep point 1.4 x the line-up distance out on that bearing; ordered
  again when idle or the point moved. The line-up distance is the release range
  (2000 m plane, 1000 m helicopter) plus 800 m, or 8 s at top speed plus the
  salvo and half the height over the aim. The speed is capped at the run speed
  (half the top speed, 160 m/s at most; a helicopter 28 m/s) once on the line.
  A laser or smoke is looked for every second while the grid is all it has.
  Three minutes without lining up: it commits from wherever it is inside the
  line-up distance, else the pass is missed.
- **The commit**: inside the commit distance (the release range, or 3 s at the
  run speed plus the salvo and the height buffer) and outside 0.8 of the
  range, on the line, nosed within 50 deg, fast enough. The owner drops its
  order (a helicopter's transit order), the turret's camera is put on the dummy,
  the bays opened.
- **The dive** (`fnc_passFrame`, every frame, velocity only - the crew rides
  it): heading onto the aim at 20 deg/s (40 a helicopter), pitch at 20 deg/s
  onto the line of sight, then inside the release range onto the solution
  (`fnc_passAim`: the round flown as the engine flies it, air friction and
  gravity, the elevation corrected by the secant of the range error); bank with
  the turn; speed to the run speed. On the solution within 2 deg for 1.5 s the
  trigger is pulled (`fnc_fireAt`: the crewman on the store's turret,
  `forceWeaponFire`, the reload cleared) at the fire mode's interval until the
  salvo is down; a drift past 6 deg ends it. Broken off at 200 m over the ground
  ahead (25 m a helicopter), past 85 deg nose down, past the aim, or after 45 s.
- **The end** (`fnc_passEnd`): AI targeting back as it was, the speed cap off,
  the camera freed, the bays closed, its height back (no lower than 150 m now,
  the height it came in at 6 s later), the dummy kept 20 s for rounds still
  flying. The result - `fired`, `missed`, `aborted`, `dry`, `lost` - waits for
  the owner's next tick. RPT: `pass: '<class>' ...` lines for the plan, each
  order (one per 30 s), the commit, the solution, each release, the end;
  `bomb '<class>' steered n m onto the aim`.
- **This drone**: the pass begins when the run-in starts (at once for a board
  strike, at CLEARED HOT for a thread's) on the bearing from the ingress point
  (the module's side when none); a re-attack or a re-task comes in from where
  it is. After it, out to the egress point as before. A pass under way is
  finished before the run's patience ends it; a recall ends it at once.

## Ordnance

The run comes in with the heaviest air-to-ground thing the airframe is
carrying — bomb, then missile, rocket, shell, gun. That is **AUTO**, and it is
the default, because a section calling a strike in wants a strike and should
not have to answer a loadout question to get one.

**Anything else on the list is a store that is actually hanging on the
aircraft.** The page used to offer five categories — AUTO / BOMB / MISSILE /
ROCKET / GUN — which is the same five words over a Reaper, a Bayraktar and a
Buzzard: it cannot tell a GBU from a Scalpel when an airframe has both, and it
offers three kinds nothing aboard has ever carried. The column now reads the
airframe's own stores, by name and with the rounds left on them:

```
ORDNANCE    < AUTO >
ORDNANCE    < GBU-12 X2 >
ORDNANCE    < SCALPEL X4 >
ORDNANCE    < 20MM HE X600 >
```

Both places ordnance hides are read — turret magazines for the gun and the
fixed-armament airframes, the pylon component for everything with a dynamic
loadout — and air-to-air missiles are dropped, because a Falchion is not
something a man asking for a strike on a treeline can use. The list is ranked
heaviest-first, so it reads down in the order AUTO would have picked.

The list is published on the asset's own row — the same column a battery
carries its shell types in — and the page sends back an **index**, which the
tasking turns into a magazine class before the order leaves the client. The
page never learns what it selected. A store that has been shot off between the
request and the release falls back to AUTO rather than flying over dry, and
says so in the log.

## Loiter

**LOITER is a different task, not a strike with a different name.** The support
page has always offered it beside the attack run, and this asset used to fly
both the same way: an aircraft asked to hold overhead put its bombs down and
left, which is neither of the things the word means.

Now the aircraft flies the same ingress, holds an orbit over the task point
(drones are exempt from the off-map hold, 2026-11-01) and releases nothing. **On station, the gunner's seat goes to the drone
controller** — the drone is linked and the seat handed over, so the
optics, the sensors and whatever the airframe is hung with belong to a man
rather than to a script with a target list. The AI keeps flying the orbit; the
driver's seat stays locked, so a controller cannot fly the aircraft into the
ridge he is watching.

Who gets it:

| | |
|---|---|
| **The man who asked, if he is ISR** | Drone linked, gunner's seat taken, told so. The ISR flag is the mission's own `isISR` variable — the same one the hacking tablet gates on. The link itself is `jmfsb_devices_fnc_uavControl`'s, so he also needs the UAV operator trait and a DATA link; without them he is told he cannot take it and the aircraft holds. |
| **The man who asked, if he is not** | The aircraft holds over the grid and he is told his ISR operator can take the feed. A rifleman may call a loiter; he does not fly it. |
| **Everyone else on the side** | Told it is on station. It is on their DRONES board and a UAV operator can take it himself when the man who called it is finished. |

There is no UAV terminal (2026-10-20: out of the arsenal): the link and the seat
are the devices' own (`jmfsb_devices_fnc_uavControl` - remoteControl, no
terminal item). A link is exclusive — it drops whatever else that player was
flying — so only the man who asked is linked automatically. Nobody else's
drone is taken out from under them. The server says ON STATION to the side by
`remoteExec` (`jmfsb_cas_fnc_onStation`), which a client takes only from the
server (review S7): as a CBA event any client could name any drone and himself.

It holds for an hour, or until **RTB** on the support page, or until it is shot
down. Whatever ends it, the seat is given back first and the drone flies home
to its module (2026-11-02) - and again before the airframe is deleted there,
in case someone took it on the way home: a controller left in the turret of a
vehicle that is deleted under him is a black screen he cannot get out of.

Everything the server says about a run goes by `remoteExec` and a client takes
it only from the server (review S7): INBOUND (`jmfsb_cas_fnc_inbound`) and IN
HOT (`jmfsb_cas_fnc_release`) to the side, ON STATION (`jmfsb_cas_fnc_onStation`)
to the side, and the seat given back (`jmfsb_cas_fnc_offStation`) to every
machine, where only the one linked to that aircraft drops its link. They were
CBA events, and any client could raise them - a false "inbound" on a side's
screens, or another player's drone link dropped.

## Tasking

Assets reach TAC//SUPPORT through the support core (`jmfsb_support`) rather than
by name: this addon registers as provider `cas` - rows, task, sitrep,
availability and its one asset type with its three tasks - the core merges
whatever is registered, and neither learns the other's name. The ids handed out
carry the `cas:` prefix, so an order routes itself back here. The contract is
in `addons/support/README.md`.

Its three tasks declare their INGRESS and EGRESS as point declarations (task
declaration field 7, slots 8 and 9 - the same points support_air's CAS reads),
and its rows carry the airframe while it is out and the run it is flying
(row fields 7 and 8), so the board's map shows the drone and its run.

**Who may order a run (review S6).** The page's checks run on the client, so
the server asks again. An order goes by `remoteExecCall` to
`jmfsb_cas_fnc_request`, a recall to `jmfsb_cas_fnc_abort` - no CBA event,
which carries no sender. Both start with `jmfsb_cas_fnc_mayTask`: the caller is
the sending machine's own player (never a unit in the arguments), the module
is a registered CAS module of his side (his group's side), and the support
tasking gate (`jmfsb_support_fnc_canTask`) lets him. The order is then checked
again for availability, a known mode and a store the airframe carries. A
refused call does nothing but write a WARNING in the server RPT. A server whose
CfgRemoteExec is a whitelist must list both functions.

## Messaged in TAC//MSG (2026-11-01)

A JTAC tasks a drone by filing a card to its box, `B:SUPPORT:cas:<n>`
(`docs/DESIGN_SUPPORT_MESSAGING.md` steps 3 and 4). The support core hands the
card to `jmfsb_cas_fnc_srvThread` on the server, after the issuer's tasking
gate and side (`jmfsb_cas_fnc_side`). Built, not seen in game.

**No on-station step for a drone.** A `cas` card (the one CAS card since
2026-11-02) tasks it at once; a REQUEST ON STATION (`onstation`) is its LOITER
over the AREA - a map marker the card requires since 2026-11-02 (an older
deck's empty area: the issuer's position). The loiter is an order to get in
the air, not a fire mission (user, 2026-11-02): none of the strike checks
below are asked of it, and it releases nothing. It answers `ROGER, WILCO -
LAUNCHING - ON STATION IN m:ss` - the drone is made over the module and flies
there (2026-11-02, virtual until tasked). A REQUEST ON STATION being written stays one
when the drone is @ mentioned (it went as the drone's `cas` card before - a
strike, refused `DANGER CLOSE NOT ACKNOWLEDGED`). Built, not seen in game.

| Card field | The run |
|---|---|
| Line 1 grid | the target. A map click or a typed 6 / 8 / 10 figure grid; none: CANTCO `NO TARGET LOCATION` |
| Line 3 / Line 4 | ingress / egress points; empty: from the module's side / straight through, as on the board |
| Line 5 | the description, repeated in the WILCO |
| Line 6 range + DC tick | danger close (the core's `dangerClose`): friendlies under the card's threshold (300 m) without the tick - CANTCO `DANGER CLOSE NOT ACKNOWLEDGED` |
| Line 7 LASER + code | a laser-guided store (`jmfsb_cas_fnc_orderStore`); none aboard - CANTCO `CANNOT LASE <code>`. The run already looks for the side's laser spot inside the terminal search radius. Any other mark takes any store |
| PREFERRED MUNITIONS | the first store whose name holds the words; not carried or empty - AUTO |

Busy, rearming or waiting for a replacement: the reach card's word (`TASKED`,
`COOLDOWN n S`, `REPLACING n S`); the last drone gone: `UNABLE - NO AIRFRAME`;
nothing aboard: `NO STORES`.

**The replies**: ROGER (the core), WILCO `ETA m:ss - <description>` when the
order is taken - the ETA from the module (a loiter: `LAUNCHING - ON STATION
IN m:ss`), ON TASK at the release (or on station for a loiter), CLOSE when the
run is over, CANTCO when it ended before it released.

**"Leaves" below** (2026-11-02): the run is over and the drone flies home to
its module and is removed there (`fnc_recover`) - no respawn spent.

**CLEARED HOT.** A thread's strike orbits the grid at 4000 m, dark, and
releases nothing until the issuer's `clearedhot` reply
(`jmfsb_cas_fnc_threadReply`); then it runs in through the target and out to
the egress like any run. No clearance: AWAITING CLEARED HOT at 60 s and D9's
waits after it (below) - it leaves, CANTCO, unanswered. CLOSE (or ABORT / RTB) from the issuer recalls it. A run ordered from
the board needs no clearance.

**The AIRFRAME CHECK-IN** (user, 2026-11-02: "an aircraft when it arrives on
station needs to send an AIRFRAME CHECK-IN"; built, not seen in game). Inside
`CAS_STATION_RING` (1.6 km) of its grid, once a run, a drone files the
check-in in the thread that asked, as itself (`jmfsb_support_fnc_checkIn`,
support README): on a LOITER (REQUEST ON STATION) when it goes on station,
on a thread's strike when it reaches the grid still held for CLEARED HOT
(one cleared before it gets there runs straight in, and checks in when it
comes back over the grid after the pass, held for the BDA).
The drone's call sign, the grid at the hold or attack height, the minutes of
its time left (the loiter's hour, a strike's 30 min), remarks `OVER THE GRID,
DARK` or `OVER THE GRID, HOLDING FOR CLEARED HOT`; airframe, rounds left,
capabilities, laser code and abort code from the core. A board order has no
thread and checks in nowhere.

**The prompts and the BDA** (2026-11-01, `docs/DESIGN_SUPPORT_MESSAGING.md`
5.4, step 5; built, not seen in game). The words are the support core's
(`casPrompt`, `promptCleared`); the drone's side:

| When | It says / asks | Answers and what they do |
|---|---|---|
| WILCO, no CLEARED HOT in 60 s | `AWAITING CLEARED HOT` (FLASH) | CLEARED HOT - runs in; ABORT - leaves |
| Cleared, running in | ON TASK and `IN` | |
| Clear of the target after the release (2026-11-02: "bda while returning to on station") | one message: `OFF - RETURNING TO STATION - REQUEST BDA` | BDA - kept on the thread by the core; or a new `cas` card (the CAS tile) |
| At the egress point | does not leave: back over the grid, held, dark, 4000 m (ON STATION on the row) | |
| A BDA whose DECISION is EGRESS (user, 2026-11-02: "reattack or egress"; EGRESS = LEAVE) | out by its egress point (the card's Line 4, else the run's), then home to its module and removed (2026-11-02), CLOSED `EGRESS - RTB` | |
| A BDA whose DECISION is RE-ATTACK, a store left (`storesLeft`, the rounds in it, off the live airframe) | `RE-ATTACK - <n> <store> LEFT - AWAITING CLEARED HOT` (FLASH) | CLEARED HOT - in again, on the BDA's TARGET grid when it gave one, else the same grid, and back to OFF - RETURNING TO STATION - REQUEST BDA; a new `cas` card - re-tasked; ABORT - leaves |
| A BDA, nothing left | leaves - home and removed, no respawn spent - CLOSED `WINCHESTER` | |
| NO, or an older deck's BDA with neither decision | `<n> MIN ON STATION - FURTHER TASKING?` | a new `cas` card in the thread - its checks again on the drone in the air, WILCO with the ETA from where it is, held over the new grid for CLEARED HOT (it comes from where it is; the card's ingress is not flown). One it cannot fly: the same question, the reason in front. RTB / CLOSE - leaves |
| 2 min of its time left, or fuel at 25 % | `BINGO IN 2 MIN` (FLASH) | RTB / CLOSE - leaves now; else it leaves 2 min on, CLOSED `BINGO` |
| Any prompt silent 3 min / 5 min | `NO RESPONSE - HOLDING` / leaves, CLOSED `NO RESPONSE - RTB` | |
| ALL ATTACK sent to it (user, 2026-11-02: a fixed-wing flight's with escort drones - a drone has none) | `NO ESCORTS - USE CLEARED HOT` (FLASH) | CLEARED HOT - runs in; ABORT - leaves |

**BINGO's source.** A drone module has no time on station of its own: a
thread's strike may stay `CAS_THREAD_TIMEOUT` (30 min) from launch - its time
on station - and its fuel is watched too (`BINGO_FUEL`, a quarter of a tank);
whichever comes first. A REQUEST ON STATION (its loiter) says BINGO the same
way, its hour less 2 min. Either BINGO sends it home to the module, removed
there; the next tasking makes a new drone with a full tank.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_support`

## Ships

1 unit class, 48 functions.

## Eden modules

### JMSB - CAS Drone

`jmfsb_moduleCAS`, category jmfsb_modules

One taskable CAS drone on the support page. Place one module per airframe - many are allowed, and each is its own asset with its own losses.<br>VIRTUAL UNTIL TASKED: no drone is up between tasks. A request makes one in the air over the module at its hold altitude, dark, full of fuel and stores; after the task it flies back to the module and is removed.<br>The requester sets the TARGET GRID and the INGRESS and EGRESS points. Only a drone LOST uses one of the Respawns.<br>ORDNANCE on the support page lists what THIS airframe is carrying, by name - the run uses the heaviest thing aboard unless one is picked.<br>LOITER holds the drone over the grid instead of striking, and hands the gunner's seat to the ISR operator who asked for it - he needs the UAV operator trait and the isISR variable, no UAV terminal. RTB ends it.<br>Flies tactically: no lights, strikes from 4000 m above the terrain.<br>Airframe Class - Classname of the fixed-wing drone; blank for the side's vanilla UCAV Callsign - What the support page and the radio call it Respawns - Replacement drones after a drone is lost; 0 for none. Going home uses none Respawn Delay (sec) - Time after a loss before the asset can be tasked again Ingress Distance (m) - The run-in floor, and how far past the target it runs before the asset is free again Run Speed (km/h) - Capped at the airframe's own maximum Cooldown (sec) - Time after a run before this asset can be tasked again Terminal Search (m) - How far from the grid a laser spot or smoke is accepted as the real target; 0 for none

<details><summary>8 attributes</summary>

- `callsign`
- `cooldown`
- `droneClass`
- `respawnDelay`
- `respawns`
- `searchRadius`
- `spawnDistance`
- `speed`

</details>

## Functions

<details><summary>48</summary>

- `jmfsb_cas_fnc_abort`
- `jmfsb_cas_fnc_acquire`
- `jmfsb_cas_fnc_assetAvailable`
- `jmfsb_cas_fnc_assets`
- `jmfsb_cas_fnc_available`
- `jmfsb_cas_fnc_bombDrop`
- `jmfsb_cas_fnc_casAsk`
- `jmfsb_cas_fnc_entityRow`
- `jmfsb_cas_fnc_fireAt`
- `jmfsb_cas_fnc_fmtEta`
- `jmfsb_cas_fnc_gone`
- `jmfsb_cas_fnc_idleStatus`
- `jmfsb_cas_fnc_inbound`
- `jmfsb_cas_fnc_killed`
- `jmfsb_cas_fnc_launch`
- `jmfsb_cas_fnc_mayTask`
- `jmfsb_cas_fnc_moduleController`
- `jmfsb_cas_fnc_nearestTo`
- `jmfsb_cas_fnc_offStation`
- `jmfsb_cas_fnc_onStation`
- `jmfsb_cas_fnc_orderStore`
- `jmfsb_cas_fnc_overlay`
- `jmfsb_cas_fnc_passActive`
- `jmfsb_cas_fnc_passAim`
- `jmfsb_cas_fnc_passBegin`
- `jmfsb_cas_fnc_passEnd`
- `jmfsb_cas_fnc_passFrame`
- `jmfsb_cas_fnc_passTick`
- `jmfsb_cas_fnc_pickStore`
- `jmfsb_cas_fnc_preview`
- `jmfsb_cas_fnc_reach`
- `jmfsb_cas_fnc_recover`
- `jmfsb_cas_fnc_release`
- `jmfsb_cas_fnc_request`
- `jmfsb_cas_fnc_runOrder`
- `jmfsb_cas_fnc_runTick`
- `jmfsb_cas_fnc_side`
- `jmfsb_cas_fnc_sitrep`
- `jmfsb_cas_fnc_spawnDrone`
- `jmfsb_cas_fnc_srvThread`
- `jmfsb_cas_fnc_status`
- `jmfsb_cas_fnc_stores`
- `jmfsb_cas_fnc_storesLeft`
- `jmfsb_cas_fnc_task`
- `jmfsb_cas_fnc_threadReply`
- `jmfsb_cas_fnc_threadSay`
- `jmfsb_cas_fnc_threadTimeout`
- `jmfsb_cas_fnc_totTime`

</details>
