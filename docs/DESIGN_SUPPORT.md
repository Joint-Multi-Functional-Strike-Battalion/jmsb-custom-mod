# Support - our own Simplex

Status: design, for code. Date 2026-10-19. Reference only: `D:\Git\Simplex-Support-Services` (GPLv2 -
read for behaviour, never copy code; this mod is APL-SA).

## Decisions (user, 2026-10-19)

1. **Our own code**, Simplex as a behaviour reference only.
2. **Replace ALiVE support.** TAC//SUPPORT stops depending on ALiVE combat support.
3. **Not all of Simplex.** The motor pool already exists. Wanted: artillery (real and **virtual**),
   CAS, transport, **logistics drop**, **QRF insertion**, **loitering munitions**, **cruise missiles**.
4. **QRF = an AI squad**, inserted by static line or air assault. HALO and HAHO were built and then
   removed (user, 2026-10-19: "remove halo and haho").
5. **Swarm = loitering munitions** (Switchblade-style: orbit the area, strike what they find).
6. **Cruise missiles fly the whole route** - seen, heard, and interceptable by air defence.
7. **Loitering munitions and cruise missiles exist only if a module for them is on the map.**
   Same rule for every asset: no module, no row in TAC//SUPPORT.
8. **No Simplex dependency** (user, 2026-10-20). Nothing detects, lists, opens or configures
   Simplex Support Services: the Simplex provider, the Simplex request window and the forced
   `sss_*` CBA settings are removed. Simplex stays a behaviour reference only.
9. **"The modules should act like Simplex, except arty should be virtual"** (user, 2026-10-20).
   Fires: no gun aims or fires - every battery is a virtual one. JMSB - Virtual Artillery is the
   artillery module; JMSB - Artillery Battery is retired (hidden from Eden and Zeus, kept so placed
   modules load, run as a virtual battery). Artillery requests carry Simplex's fire mission (sheaf
   type, delay, interval, repeat, coordination); cruise missiles take its VLS behaviour (response
   time, per-missile cooldown, delay); all three fires assets mark their target and say when they are
   ready again.

## Shape

```
  Eden modules (one per asset)          TAC//SUPPORT (tacpad_apps appSupport)
         |  register                              |  rows / request / ack
         v                                        v
              jmfsb_support  (core: registry, request, gate, cooldown, ammo)
         ^            ^             ^                 ^
   support_fires  support_air    cas (drones)    adapter_alive (optional, legacy provider)
   virtual arty,  CAS, transport,
   cruise         logistics drop,
   missiles,      QRF insertion
   loitering
```

- **`addons/support` (core).** The asset registry moves here from `adapter_alive`
  (`EGVAR(adapter_alive,providers)` today). Owns: asset rows, availability, ammo/sortie counts,
  cooldowns, the request -> validate -> task -> ack flow, the tasking tag gate, the side
  (`player_side`, D59 - never a new side attribute), events the screen listens to. Knows no asset kind.
- **Providers** register a kind: rows, tasks, parameters, and the code that executes a task.
  `cas` (CAS drones) is a provider; `adapter_alive` stays as an optional,
  legacy provider until missions stop using ALiVE CS, then goes.
- **`addons/support_fires`**: **virtual artillery** (no gun aims or fires: the module is the
  battery, rounds spawned on a ballistic path into the target - decision 9), **cruise missiles**,
  **loitering munitions**.
- **`addons/support_air`**: CAS (crewed or drone aircraft from a class), transport (pickup / land /
  move / extract), **logistics drop** (crate under parachute or sling), **QRF insertion**.
- **TAC//SUPPORT** reads only the core. The screen built in phase 4 of PLAN_MESSAGING_UI stays: asset
  > unit > task chain, steppers, ROE, RTB double confirm, map overlay.

## Modules (category JMSB - Support)

Every configurable value is a module attribute (docs/new.md rule: module variables for everything
configurable). Location = the module's position or synced objects, never a setting.

| Module | Key attributes |
|---|---|
| Artillery Battery *(retired 2026-10-20)* | hidden; a placed one runs as a virtual battery: synced guns give only position, gun count and (ammunition blank) their magazines' rounds; callsign; ammunition per gun; cooldown |
| Virtual Artillery | callsign; gun count; shell types (HE, smoke, illum, + optional cluster/guided); rounds per type; min/max range from module; dispersion; muzzle velocity (charges) and trajectory; reload; cooldown and cooldown per round; response time min/max; sheaf types offered; max rounds / interval / delay / repeats; coordination distance |
| Cruise Missiles | callsign; launcher position = module (off-map is fine: ship or ground site); missile count; missile class; cruise speed and altitude; warhead; salvo size; cooldown and cooldown per missile; response time min/max; max delay |
| Loitering Munitions | callsign; launch site = module; munition class (Switchblade mod if loaded, else a built-in fallback); count; loiter time; strike rules (vehicles / infantry / both) |
| CAS | callsign; aircraft class or synced aircraft; sorties; altitude; run-in; time on station; terminal search; ingress distance; friendly range; response delay; cooldown + cooldown starts; respawn delay |
| Transport | callsign; helicopter class or synced; seats; airframes; flight height; extract wait; paradrop height; tasks allowed (11); response delay; cooldown + cooldown starts; respawn delay |
| Logistics Drop | callsign; aircraft class; crate contents (PAC arsenal lists, `;` between loads the requester picks from, or a crate class); crate signal; drops; method (parachute / sling); cooldown + cooldown starts; respawn delay |
| QRF | callsign; squad composition (faction group class or unit list); insertion methods allowed (static line, air assault); aircraft class; count; cooldown + cooldown starts; respawn delay |

## Behaviour notes

- **Virtual artillery** is not a gun: each round is a shell spawned high above the target on the
  correct descent, with a time of flight from the module's distance (a vacuum arc - Arma shells fly
  without drag - on the lowest charge that reaches at high angle). Counter-battery cannot find
  it; the dispersion and the splash delay make it feel like guns. The fire mission is Simplex's:
  response time and DELAY before the first round, reload plus INTERVAL between rounds, the four
  sheaf types (converged, parallel, box, creeping) sized by SHEAF, REPEAT volleys a cooldown apart,
  and COORDINATE with free batteries in reach that carry the same shell.
- **Every fires asset** marks its target on the map for the side while the mission runs, refuses a
  target out of range before the request leaves the client, and cools down for its cooldown plus a
  per-round (or per-missile) share, then says it is ready.
- **Cruise missiles** are real projectiles/vehicles flying waypoints at cruise altitude from the
  launch module to the target, terrain-following near the end. IADS and APS can shoot them down
  (they register as targets the way `fa_missiles` threats do).
- **Loitering munitions** launch from the module, fly to the area, orbit for the loiter time,
  then dive on the best target matching the strike rules; out of time = self-destruct.
- **QRF insertion**: static line (low, slow pass) or air assault (land or fast-rope). No HALO or
  HAHO (removed 2026-10-19). The squad then takes a defend task at the grid or
  joins the requester's command (attribute).
- **Logistics drop**: aircraft flies over the grid and releases the crate; contents from the PAC
  arsenal list named in the module, so it carries the unit's gear.

### Air modules act like Simplex (user, 2026-10-20)

"The modules should act like Simplex, except arty should be virtual." Behaviour matched, our own code:

- **Real synced aircraft** for CAS and transport (Simplex syncs real transports): the aircraft flies
  from its stand and is parked, repaired, refuelled, re-armed and re-crewed there after a sortie.
  Nothing synced: the class is spawned, as before. Its crew is photographed at mission start and put
  back seat for seat (Simplex's crew snapshot).
- **Respawn Delay** on every air module (Simplex RespawnDelay, -1 = gone for good): a lost synced
  aircraft is rebuilt on its stand after the delay; a lost class aircraft makes the asset read
  REPLACING until then. A stuck transport (cannot move, pilot dead) counts as lost, as in Simplex.
- **Cooldown Starts** at the end of the sortie (default) or at the request (Simplex START/END).
- **CAS** is flown Simplex-style: a class aircraft appears the Ingress Distance out on the INGRESS
  bearing and leaves on the EGRESS bearing, removed there; a synced one flies to the ingress point
  first. ORDNANCE on SAD and ATTACK RUN, DANGER CLOSE against the module's Friendly Range, a new SAD
  or LOITER on station repositions it, "leaving in one minute" before time on station ends.
- **Transport** takes PICKUP, LAND, LAND ENG OFF, HOVER, EXTRACT, PICKUP > LZ, LOITER, FASTROPE
  (ACE), HELOCAST, PARADROP and SLINGLOAD, with VIA legs (up to four), final approach bearing, LZ
  signal (smoke / IR / flare, landed on when seen), lights, height, speed, door guns and wait.
- **Logistics** offers CONTENTS per request (the module's loads) and a crate signal.
- **Not built:** a gunship module (Simplex has none of its own - its gunship is a LOITER aircraft;
  our CAS SAD over an armed class is that orbit), a logistics station (the motor pool already
  exists, decision 3), Simplex's per-weapon quantity / burst / strafe spread, signal confirmation
  from a list (the crew takes the nearest matching signal), follow / relocate / remote-control
  transport tasks, append-or-overwrite plans of mixed tasks (VIA legs are the multi-waypoint plan),
  and per-request QRF squad composition.

## The screen (TAC//SUPPORT, 2026-10-20)

User, 2026-10-20: "all apps need to be inside the tablet", tabs per support type, tasking laid out
more like Simplex, CONFIRM isolated with what is missing shown.

```
+------------------------------------------------------------+
| TAC//SUPPORT                         AVAILABLE · n  SITREP |
| CAS · 2 | ARTILLERY · 1 | TRANSPORT · 1 | QRF · 1          |   one tab per type with a row
+----------------------+-------------------------------------+
| verdict              |                                     |
| UNIT  rows           |              map                    |
| TASK  rows           |                                     |
| LOCATION  LZ / ...   |                                     |
| PARAMETERS steppers  |                                     |
|----------------------|-------------------------------------|
| READY  checklist     |  ORDER UNIT RTB                     |
| [ CONFIRM TASKING ]  |  CLOSE                              |
+----------------------+-------------------------------------+
```

- **Tabs** replace the ASSET list: one per declared type that has at least one row, in the core's
  order, counted. Never a hard-coded list. The last tab pressed is remembered for the session.
- **Where before how**, the way a Simplex request reads: the task's point comes straight after the
  task, named by the task declaration's `pointLabel` (field 6 - `LZ`, `PICKUP`, `DROP POINT`,
  `DROP ZONE`, `HOVER POINT`; `TARGET` when absent). Further points are the task declaration's
  field 7: INGRESS / EGRESS (both CAS providers), VIA legs (a row that takes several clicks), an LZ
  or a SET DOWN point; required ones join the READY checklist.
- **Per-type parameters** are the steppers each provider declares for the picked task (support
  core README): artillery - ordnance, rounds per gun, sheaf type, sheaf, guns, interval, delay,
  repeat, coordinate; cruise - missiles, delay; loitering - munitions, search radius; CAS - radius
  or passes, altitude, danger close, ordnance on SAD and a run; transport - height (jump height on
  a paradrop), speed, door guns, lights, approach, LZ signal, wait, loiter radius; logistics - drop
  height (chute), contents, crate signal. A list of more than five tasks is drawn two to a line, and
  the form scrolls (keeping its scroll across redraws) when the steppers outgrow it.
- **READY checklist + CONFIRM** stand alone at the foot of the form: UNIT, TASK, the point and every
  required declared point, each done or missing in theme tokens, then the provider's VERDICT
  (`preview` hook - an ETA, OUT OF RANGE) once the rest is set. CONFIRM is dead until nothing is
  missing; a verdict against the request counts as missing.
- **The map** draws, in both hosts, every asset out with its plan (row field 8) as task markers
  joined by a line, the picked asset's provider shapes (`overlay` hook - range rings), and the
  request live: the point, the declared points and their legs, the effect radius, the approach
  bearing and the danger-close ring. SITREP is offered for every type, artillery included. RTB (double confirm) and
  CLOSE stay under the map.
- **Hosts.** Native mode: a dialog over the vanilla map with its own map control. Tablet mode: no
  dialog - the board is the open app on the device dialog, inside the app area, and picks on the
  tablet's own map (idc 51), which it claims while open (`jmfsb_tacpad_appMapClaim`).

**Simplex-style fields not offered** (no provider accepts them yet; adding a stepper with nothing behind
it would be a dead knob): CAS weapon choice on LOITER (it is weapons tight), strafe distribution and
per-weapon quantity / burst; transport follow, relocate and remote control, signal confirmation from
a list, mixed-task plans (VIA legs only); artillery multi-task
plans (several targets in one order - the board has one point), picking which batteries coordinate
(COORDINATE takes every one that can), a mission-maker sheaf area angle and box length apart from
the width, endless repeats, battery relocation and manual grid entry; QRF squad composition per
request (the module decides). The core has had the `overlay` and `preview` hooks since 2026-10-20 -
range rings and an ETA verdict are each provider's to answer.

## Phases

1. **Core** - `addons/support`, move the registry out of `adapter_alive`, make `cas` a
   provider, point `appSupport` at the core. No new assets yet; nothing visible
   changes for players.
2. **Fires** (`support_fires`) and **Air** (`support_air`) - built in parallel on the core API.
3. **Cut ALiVE CS** - remove the ALiVE provider from missions once the new assets cover them.

## Open

- RF gate: should a request need a DATA link (`rf_reach`) to the asset's node? (Natural fit; off
  by default until RF is tested in game.)
- Enemy use: the AI could call the same assets later (QRF addon already answers player captures).
