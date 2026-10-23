# EW

`jmfsb_ew`

Electronic warfare on top of the RF core (docs/DESIGN_EW.md): direction
finding, tracks, jamming in three domains, GPS spoofing and decoys, and the
TAC//EW app. Rules, not a second engine: emitters are RF nodes, jamming is RF
noise, decoys are RF nodes marked `intent = "decoy"`. EW reads RF only through
its hooks (`addListener`, `addNoiseSource`) and public calls. NOT RUN IN GAME.

## Emitters

Every DF tick (setting, 3 s) the server collects what radiates:

| Source | What |
|---|---|
| `rf` | every emitting RF node (RF's listener) - radios, relays, drone links, decoys |
| `jammer` | this addon's jammers and spoofers while they transmit |
| `ext` | emitters other addons register with `fnc_addEmitter` - the Drone40 Jammer |
| `zone` | the jamming addon's sites (`jmfsb_jamming_fnc_emitters`) |

A set carrying traffic is always heard; an idle one beacons at its EMCON duty
(0.5 / 0.25 / 0.1 per tick); SILENT never. From EMCON 1 its power is capped
at 2 W.

## ES - DF and tracks

A sensor is an emitting RF node of a DF-capable profile: handheld 15 deg,
manpack and relay 10, vehicle 5, satcom 10. An **EW Receiver** carried (or in
the vehicle's cargo) makes it the dedicated 2 deg set that hears every band;
an ISR operator (`jmfsb_common_fnc_isISR`) is one class better. Drone links
and legacy sets cannot DF.

Each emitter is heard by up to three sensors of every other side, nearest
first. Received power is RF's budget run one way - `pathLossFree` on the band,
RF's terrain samples and terrain dB, the emitter's spread gain off unless the
sensor holds its key (`jmfsb_rf_fnc_sharedNets`) - against RF's noise at the
sensor (a jammer against the band floor). A cut is the true bearing plus an
error that grows as SNR drops (x1 at 20 dB, up to x3).

Cuts build a **track** per side and emitter: band, strength, class, cuts,
fix, confidence, first and last heard. Two cuts inside the fix window (30 s)
from sensors 50 m apart, crossing at 10 deg or more, make a **fix**; its
error is the best pair's (the ellipse is carried as a circle). A track
nobody heard for the lifetime (300 s) is dropped. Tracks are the side's: one
sensor's intercept is every man's picture.

**Identify:** a key held names the track (net / set). Otherwise the class:
JAM, SPOOF, VIDEO (drone link), DATA (data net only), DECOY? (no traffic for
120 s since first heard), COMMS. Non-ISR players see only JAM / SPOOF / VIDEO
and UNKNOWN for the rest.

**Threat warnings** (notify rail and the OVERVIEW tab): DF ON YOU (to the
cut set's players, every 30 s), JAMMER / SPOOFER / ENEMY DRONE (new track of
that class, to the side), NEW FIX (to the side), SPOT JAM (to players holding
the jammed net in reach), SPOOFER (anti-spoof set in a spoofer's field).

## EA - jamming, spoofing, decoys

The **EW Jammer Module** (`jmfsb_ew_jammerPack`) in a vehicle's cargo lets the
crew jam from the vehicle (VHF / UHF / SAT / VIDEO, 1 / 5 / 20 / 50 W). Worn it
does nothing: there are no man packs (user, 2026-10-21). One jammer per operator, server-owned
(`fnc_jamSet`), checked against his kit every tick.

| Mode | Domain | Effect |
|---|---|---|
| barrage | voice or data | RF noise on one band; spread gain applies |
| spot (ISR) | one net | RF noise on the net of an ES track's emitter only, +10 dB, half the spread back |
| sweep | all its bands | each band in turn, 5 s each |
| gps | GPS | a jamming-addon GPS zone on the host (200-1000 m by power) |
| spoof (ISR) | GPS | unprotected GPS in reach drifts up to the drift setting (SPOOFED); an EW Receiver reads SUSPECT |

Noise is power + 3 dBi - `pathLossFree`, times the duty cycle as average power,
out to the reach setting. The three domains: voice is the VHF/UHF nets, data
the DATA net's band (UHF), GPS the jamming addon's GPS denial plus spoofing.
A jammer on air is itself an emitter and gets DF'd.

**Hacked spoof:** the hacking addon's SPOOF action (HACK app, on a unit's
net - a handset, or a vehicle RF says carries a set) lands in
`fnc_spoofNode`: every man of that group is walked off true by the same
engine for the "Hacked GPS spoof" setting's length, then walks back. Gated
as a TAP on that net is (range, clock, fail and detection rolls).

**Decoys (ISR):** a ground antenna registered in RF with a handheld, manpack
or legacy profile, claiming his first voice net under a key nobody holds:
no traffic, no relay, `intent = "decoy"` (the Drone40 decoy's mark). Two per
man; the battery is the decoy setting.

## GPS readers

The spoof engine (`fnc_spoof`) runs for players (every DF tick, from
`fnc_publish`) and for the AI men it has to keep (`fnc_spoofTick`: a hacked
net's men, the enemy's DF sensors while a spoofer is on air, anyone still off
true). Each man's state and offset are hung on him (`jmfsb_ew_gps`, public,
10 m grid, on change); his own client reports GPS denial on the edge
(`jmfsb_ew_gpsDenied`, from the jamming addon's `jmfsb_jamming_gpsDenied`,
`fnc_gpsWatch`). Four states: GOOD, SPOOFED (the false position, nothing
said), SUSPECT (an EW Receiver holds the fix and flags it), NO FIX (denied:
no position shown).

| Reader | What it shows |
|---|---|
| BFT member dots (`jmfsb_bft`) | every man at his GPS position; a denied man not drawn; your own dot "- GPS SUSPECT" |
| BFT group markers | built from the members' GPS positions (a denied man counts at his true one) |
| Map tools CENTRE | the GPS position; NO FIX: the map stays and the rail says so |
| Map tools GRID | a line under the cursor's grid: `GPS <ten digits>`, `SUSPECT`, or `GPS NO FIX` |
| CUR LOC (report cards), CURRENT LOC (compose pin), + GRID (reply) | the GPS position; NO FIX: nothing filled, the rail says so; SUSPECT: filled, the rail warns |
| TIC (one-key contact report) | Location = the GPS position; NO FIX: refused, send the card with a typed grid |
| DF cuts | measured from where the sensor stands, plotted from where its GPS says: a spoofed sensor's fixes land off target |
| TAC//EW OVERVIEW | GPS GOOD / SPOOFED / SUSPECT / NO FIX |
| devices' tablet bar | not yet - `fnc_gpsGrid` is its getter (docs/TODO_DEVICES.md) |

## AI EW (D17)

Setting "Enemy AI EW skill" (OFF / BASIC / ACTIVE / SMART, default BASIC)
for the enemy side, which is worked out from the mission
(`jmfsb_common_fnc_enemySide`, D59) - never typed. RF counts no AI sets
(`jmfsb_rf_aiNodes` off, no adapter registers them), so the AI hears through
the same rules rather than through RF's listener:

- **Sensors** (`fnc_aiSensors`, BASIC and up): each enemy AI group whose
  radio (`fnc_aiSet`: the best set any man carries, by its RF profile through
  `jmfsb_rf_fnc_carriedSets`, cached 30 s) is DF-capable is one sensor at
  that man, priced like a player's set - the class's bearing error, the
  profile's bands, RX sensitivity and gain; an EW Receiver in his kit makes
  it the 2 deg all-band set. A vanilla radio is a handheld (15 deg). At most
  six AI sensors are tried per emitter per tick, nearest first. Cuts and
  fixes are the side's tracks as for players, and DF ON YOU reaches the
  player cut.
- **On a fix** (`fnc_aiReact`), within "Enemy AI fix reaction range" of one
  of its groups, once per track per 120 s:
  - BASIC: the groups in range that the report reaches go AWARE and watch
    the fix for 60 s (`fnc_aiAlert`, where the group is local), and the
    player on the set goes through `jmfsb_reaction`'s ladder (source `df`:
    a silent flag, MAJOR on a flagged man). Needs the Reaction module, as
    every source does.
  - ACTIVE: also a drone to look (`jmfsb_uas_fnc_respondTo`, inside its
    ceiling); once per side per 300 s.
  - SMART: also a QRF to the fix (`jmfsb_qrf_fnc_onCaptured`, through the
    adapter's commanders).
- **Comms gate** (`fnc_aiLink`): inside 50 m a report is shouted; beyond, one
  radio hop of 2 s that gets through with the chance of RF's link budget
  for the group's set at both ends over clear-ground path loss, against RF's
  noise at the group - so player jamming on the AI's band cuts its
  reporting. A group with no set hears only by voice. Nobody reached: no
  reaction.
- **Static jammers** (BASIC's EA) are the jamming addon's sites, unchanged.

## EP

The EP tab sets EMCON 0-3 per own set (`jmfsb_rf_fnc_setState`) and shows how
far each is heard (`fnc_exposure`: a -115 dBm, 3 dBi receiver without the key).

## TAC//EW and the map

App `ew` (`jmfsb_tacpad_fnc_registerApp`), opened from the EW tile (a tile
provider, like MEDIC): OVERVIEW, ES (spectrum rise per band, track table, tap
to show on map), EA, EP. The map layer draws the side's fresh DF lines with
their error wedge, fixes with their error circle and label, and the side's own
jammers, on the vanilla map and the device host's map. Everything is drawn
from the man's slice (`jmfsb_ew_slice`, sent with `publicVariableClient` on
change - see `fnc_publish` for the layout).

## API

| Function | Where | Notes |
|---|---|---|
| `jmfsb_ew_fnc_addEmitter` `[object, bands, dBm, intent, side, id]` -> id | server | an emitter that is not an RF node |
| `jmfsb_ew_fnc_removeEmitter` `[id]` | server | |
| `jmfsb_ew_fnc_jamSet` `[unit, changes]` | any (client forwards) | mode, band, track, power, duty, on |
| `jmfsb_ew_fnc_decoyPlace` `[unit, profile, net]` | any (client forwards) | |
| `jmfsb_ew_fnc_tracks` `[side]` | server: any side; client: his own | rf_tracks |
| `jmfsb_ew_fnc_gpsState` -> `[state, offset, pos ASL]` | client | the player's GPS: GOOD / SPOOFED / SUSPECT / NO FIX |
| `jmfsb_ew_fnc_gpsOf` `[unit]` -> `[state, offset, pos ASL]` | any | any man's GPS as the network carries it (the player: `gpsState`) |
| `jmfsb_ew_fnc_gpsHere` `[loud]` -> pos ATL or `[]` | client | for "my position" fields; `[]` = NO FIX; loud warns on the rail |
| `jmfsb_ew_fnc_gpsGrid` `[unit]` -> STRING | any | "041 116", "041 116 SUSPECT", "NO FIX" - for status bars |
| `jmfsb_ew_fnc_spoofNode` `[group, hacker]` | any (client forwards) | spoof a net's GPS (the hacking addon's SPOOF) |
| `jmfsb_ew_fnc_exposure` `[profile, emcon]` -> m | any | |
| `jmfsb_ew_fnc_kit` `[unit]` | any | the equipment gate |

Server events (CBA local): `jmfsb_ew_trackNew` `[side, track, class]`,
`jmfsb_ew_trackLost`, `jmfsb_ew_fix` `[side, track, pos, error, class]`,
`jmfsb_ew_jamOn`, `jmfsb_ew_dfOnYou`, `jmfsb_ew_spoofed` `[group, hacker]`,
`jmfsb_ew_aiReact` `[side, track, pos, groups told]`.

## Not built (docs/DESIGN_EW.md)

AI EW beyond BASIC's fix reaction: ACTIVE's drone jamming, EW teams that
hunt, EMCON 1 and moving after transmitting; SMART's spot jamming, spoofing,
decoys, hacking, EMCON 3, rekey, PACE, movement plotting, jammers as priority
targets. The comms gate's mesh (multi-hop, terrain), the path to an HQ node
for support (no AI RF nodes, no HQ node), sighting sharing between groups,
LAMBS, isolated-group behaviour. AI sensors' own GPS denial. INSPECT /
EXPLOIT / LOAD KEY, drone soft and hard kill, hardware (battery, heat,
damage, generators), sector antennas, PACE, the RF link budget's EMCON power
cap, drone navigation on the spoofed GPS, the devices' tablet bar grid,
support requests that take "my position" (support_air pickup), sharing fixes
over DATA (tracks reach the whole side at once).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `jmfsb_rf`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `cba_xeh` _(external)_
- `cba_settings` _(external)_
- `cba_jr` _(external)_
- `A3_Weapons_F` _(external)_
- `A3_Supplies_F_Enoch_Bags` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 1 weapon/item class, 52 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_ew_dfTick` | SLIDER | DF tick (sec) |
| `jmfsb_ew_fixWindow` | SLIDER | Fix window (sec) |
| `jmfsb_ew_trackTtl` | SLIDER | Track lifetime (sec) |
| `jmfsb_ew_decoyLife` | SLIDER | Decoy battery (sec) |
| `jmfsb_ew_spoofRadius` | SLIDER | GPS spoof radius (m) |
| `jmfsb_ew_spoofDrift` | SLIDER | GPS spoof max drift (m) |
| `jmfsb_ew_jamRange` | SLIDER | Jammer reach (m) |
| `jmfsb_ew_jamBatteryWh` | SLIDER | Jammer battery (Wh) |
| `jmfsb_ew_jamChargeW` | SLIDER | Jammer charge with the engine running (W) |
| `jmfsb_ew_jamHeatRise` | SLIDER | Jammer heating (% per sec at full output) |
| `jmfsb_ew_jamHeatCool` | SLIDER | Jammer cooling (% per sec) |
| `jmfsb_ew_spoofHackTime` | SLIDER | Hacked GPS spoof (sec) |
| `jmfsb_ew_aiSkill` | LIST | Enemy AI EW skill |
| `jmfsb_ew_aiReactRange` | SLIDER | Enemy AI fix reaction range (m) |

## Functions

<details><summary>52</summary>

- `jmfsb_ew_fnc_addEmitter`
- `jmfsb_ew_fnc_aiAlert`
- `jmfsb_ew_fnc_aiLink`
- `jmfsb_ew_fnc_aiReact`
- `jmfsb_ew_fnc_aiSensors`
- `jmfsb_ew_fnc_aiSet`
- `jmfsb_ew_fnc_app`
- `jmfsb_ew_fnc_appButton`
- `jmfsb_ew_fnc_appEa`
- `jmfsb_ew_fnc_appEp`
- `jmfsb_ew_fnc_appEs`
- `jmfsb_ew_fnc_appOverview`
- `jmfsb_ew_fnc_classShown`
- `jmfsb_ew_fnc_classify`
- `jmfsb_ew_fnc_collect`
- `jmfsb_ew_fnc_cut`
- `jmfsb_ew_fnc_decoyPlace`
- `jmfsb_ew_fnc_detect`
- `jmfsb_ew_fnc_exposure`
- `jmfsb_ew_fnc_fix`
- `jmfsb_ew_fnc_gpsGrid`
- `jmfsb_ew_fnc_gpsHere`
- `jmfsb_ew_fnc_gpsOf`
- `jmfsb_ew_fnc_gpsState`
- `jmfsb_ew_fnc_gpsWatch`
- `jmfsb_ew_fnc_jamAuto`
- `jmfsb_ew_fnc_jamOff`
- `jmfsb_ew_fnc_jamPower`
- `jmfsb_ew_fnc_jamSet`
- `jmfsb_ew_fnc_jamUpdate`
- `jmfsb_ew_fnc_kit`
- `jmfsb_ew_fnc_listener`
- `jmfsb_ew_fnc_mapDraw`
- `jmfsb_ew_fnc_mapHook`
- `jmfsb_ew_fnc_noise`
- `jmfsb_ew_fnc_onThreat`
- `jmfsb_ew_fnc_publish`
- `jmfsb_ew_fnc_receiveSlice`
- `jmfsb_ew_fnc_removeEmitter`
- `jmfsb_ew_fnc_sensor`
- `jmfsb_ew_fnc_showOnMap`
- `jmfsb_ew_fnc_spoof`
- `jmfsb_ew_fnc_spoofNode`
- `jmfsb_ew_fnc_spoofTick`
- `jmfsb_ew_fnc_spotWarn`
- `jmfsb_ew_fnc_tick`
- `jmfsb_ew_fnc_tile`
- `jmfsb_ew_fnc_trackMhz`
- `jmfsb_ew_fnc_tracks`
- `jmfsb_ew_fnc_upkeep`
- `jmfsb_ew_fnc_warn`
- `jmfsb_ew_fnc_warnSide`

</details>
