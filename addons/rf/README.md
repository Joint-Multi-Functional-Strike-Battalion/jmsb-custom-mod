# RF

`jmfsb_rf`

The core of the radio, EW, jamming, hacking and networking systems, and the
bridge between them and the radio mod (docs/DESIGN_RF.md). It answers one
question every tick: who can reach whom, on which net, and how well. Depends on
CBA only - no other jmfsb addon - so adapters and consumers depend on it, never
the reverse. Milestone 1. NOT RUN IN GAME.

## Model (server)

- **Node** `jmfsb_rf_nodes`: id, object, side, profile, nets (the fill,
  `[net, key]`; key `""` = the side's key), state (on, tx, relay, activeNet,
  monitorNet, emcon 0-3), battery, owner mod, holder (whose client gets the
  slice).
- **Profile** `jmfsb_rf_profiles`: the "Radio profiles" table of DESIGN_RF.md,
  written once in `script_component.hpp` (`RF_PROFILES`): handheld, manpack,
  vehicle, relay, base (the base station: VHF/UHF/SAT, the relay's 20 W,
  6 dBi and hop limit 8, powered by its site), drone, droneRelay, legacy,
  satcom.
- **Net** `jmfsb_rf_nets`: id, name, band, one key per side (made when the net
  is created), spread, PACE, state (cut / held / patchedTo), source. RF makes
  `DATA` (UHF) itself, so it runs with no radio mod loaded.

## Carried sets

RF recognises a radio set from its config, with no radio mod loaded: an item or
backpack class names its profile with `jmfsb_rf_profile` (`EGVAR(rf,profile)`
in our configs). The MPU5 (`jmfsb_radios`) is `handheld`, the TW-950 `legacy`,
the MPU5 manpack and every radio bag (`jmfsb_backpack`, `jmfsb_uniform`,
`jmfsb_uniform_ru`, the Western Sahara overlay) `manpack`. Any other item in the
radio slot (simulation `ItemRadio`, the vanilla radio) is a `handheld`; a bag
without the property is not a set. `fnc_carriedSets` is what a voice adapter
registers as a man's nodes.

## Link budget and mesh

`fnc_linkBudget` is the pure formula (rx, snr, quality = clamp((snr - thr) /
span), 0 below the receiver's sensitivity); `fnc_pathLoss` is the world part
(log-distance per band, terrain at 3 samples, clutter counted). Per tick and
per net, nodes are partitioned by key (only sets holding the same key decode
each other); each pair inside the band's clear-ground range gets an edge
(two-way: the weaker direction), and `fnc_mesh` runs the widest-path search
ported from the old radio_mesh addon's `fnc_signal` (radio_mesh was removed
2026-10-31, DEC1), with the hop limit = the smallest
profile hop limit among the relays on the path.

Cost: the terrain and clutter casts in `fnc_pathLoss`. They are cached per pair
and band (`jmfsb_rf_edgeCache`) and re-cast only when an end moved more than
10 m or the entry is older than its life - the static tick plus a random half
of it, so pairs cast together do not all expire together - which is how
"static nodes 5 s" is implemented. Past 150 casts in one tick, pairs that did
not move wait for a later tick (code review P2, 2026-10-31). The player tick
is 1 s.

The search is memoised per node set, band and net (`jmfsb_rf_meshMemo`): edges
are quantised to 0.05 first, and while the edges and the relays are the same
as last tick, the last answer is reused (code review P1).

## The satellite link

User, 2026-10-20 (docs/DESIGN_RF.md "The satellite link"). SAT is not a ground
band. Two nodes whose profiles both have SAT (vehicle, base, satcom), holding
the same key, each under open sky, link in one hop at any distance, terrain
and clutter ignored, whatever band the net is on - a SAT terminal backhauls
any net, so such a node is on every net's mesh it holds. The edge is the
better of the ground link and the satellite.

- **Open sky** (`fnc_openSky`): one `lineIntersectsSurfaces` ray 30 m
  straight up from the antenna, ignoring the node's object and the vehicle a
  man is in. Cached per node in `jmfsb_rf_sky`, re-cast by the tick on the
  static tick or after 10 m of movement, never per frame.
- **Quality** (`fnc_satBudget`): 0.9 in clear sky at any threshold and span,
  less the tick's rain fade (`jmfsb_rf_satFade` = setting "SAT rain fade",
  default 6 dB, x rain, overcast counting a quarter). Through the link-budget
  formula against the SAT noise at each end (`fnc_noise`, band SAT), so the
  noise hooks - EW's SAT jamming - degrade it like any link. Two-way: the
  weaker end.
- **Hops:** a satellite leg is one edge, so it is one hop; the hop limit
  counts the relays at its ends as usual.
- The SAT row of the band table (exponent, loss at 1 m, floor) now prices only
  ground emitters on SAT (jammers, intercept). `fnc_budget` on SAT is the
  satellite budget with a fresh sky check; `fnc_rangeTable` reports SAT as
  any distance (-1) with the quality it has now.

## Base stations

User, 2026-10-20 ("use our patrol base as a relay", "a staging zone ... as a
sat uplink"). The `base` profile is what `jmfsb_pac_fnc_baseStation` registers
at every staging zone (`jmfsb_mission`, setting "Staging zone satellite
uplink") and every built patrol base (`jmfsb_patrol_base`, setting "Patrol
base radio relay"): no holder, the players' side, every plan net plus DATA and
C2, relay and TX on. RF treats it as any placed node: it meshes, relays,
emits to the listener hooks (EW) and takes noise. RF itself knows nothing of
sites.

## Batteries

A set with a battery of its own (profile `batteryWh` > 0: the handhelds, the
manpack, a placed relay) runs down while it is on, at the rate `Battery life`
gives the handheld's 38 Wh scaled by its own Wh - four times as fast while
keyed - and charges in a vehicle with its engine running, full in an hour.
Flat, it switches itself off (out of the mesh; `jmfsb_rf_batteryFlat` on the
server) and comes back when it has charge again or is swapped
(`fnc_batterySwap`, raised by the holder's client). A set powered by its host
(`-1`) never drains. Each player gets `jmfsb_rf_batteries` on his unit -
`[[node id, level], ...]` in 5 % steps, sent only when a step changes - and
reads it through `fnc_battery`. The devices and the RADIO app show it; the
spare is `jmfsb_radios`' `jmfsb_mpu5_battery`.

## API

| Function | Where | Notes |
|---|---|---|
| `jmfsb_rf_fnc_register` `[object, profile, nets, id, owner, holder, side, data]` -> id | any (a client forwards) | upsert by id; data = `[[key, value], ...]` merged into the node's extra-data field (e.g. `intent`) |
| `jmfsb_rf_fnc_unregister` `[id]` | any (a client forwards) | |
| `jmfsb_rf_fnc_setState` `[id, [[key, value], ...]]` | any (a client forwards) | on, tx, relay, activeNet, monitorNet, emcon, keys, data |
| `jmfsb_rf_fnc_nodesFor` `[holder, skipOwners]` -> `[[id, owner, profile, fill], ...]` | server | the nodes a man holds, fill copied |
| `jmfsb_rf_fnc_quality` `[node, net]` -> 0..1, -1 unknown | server: any; client: own slice | best path quality to any peer on the net |
| `jmfsb_rf_fnc_netBand` `[net]` -> band | server | "" when the net does not exist |
| `jmfsb_rf_fnc_pathLossFree` `[m, band]` -> dB | any | clear-ground loss from the band table, for noise sources |
| `jmfsb_rf_fnc_netSet` `[net, [[key, value], ...]]` | server (a client forwards; admins only) | create or change a net |
| `jmfsb_rf_fnc_link` `[a, b, net]` -> `[quality, hops, lastHop]` | server: any pair; client: own slice | |
| `jmfsb_rf_fnc_reach` `[id, net]` -> ids | server: any; client: own slice | |
| `jmfsb_rf_fnc_budget` `[tx, rx, band, net]` -> `[rx dBm, snr, quality]` | server | fresh, uncached |
| `jmfsb_rf_fnc_noise` `[pos, band, net, spread]` -> dBm | any | floor plus noise hooks |
| `jmfsb_rf_fnc_addNoiseSource` `[code]` | server | EW jammers register here |
| `jmfsb_rf_fnc_addListener` `[code]` | server | EW intercept and DF register here; each emitter carries the node's data field last |
| `jmfsb_rf_fnc_rangeTable` | any | the range self-test, to the RPT |
| `jmfsb_rf_fnc_profile` `[profile]` -> hashmap | any | read-only copy of a profile (EW prices DF and exposure with it) |
| `jmfsb_rf_fnc_bandInfo` `[band]` -> `[exp, ref, floor]` | any | read-only row of the band table |
| `jmfsb_rf_fnc_nodeInfo` `[id]` -> hashmap | server | read-only copy of a node (net ids, not keys) |
| `jmfsb_rf_fnc_sharedNets` `[a, b]` -> net ids | server | nets on which both hold the same key (EW: a NAMED track) |
| `jmfsb_rf_fnc_itemProfile` `[class]` -> profile | any | the profile a radio item or bag names in config, `""` = not a set (cached) |
| `jmfsb_rf_fnc_carriedSets` `[unit]` -> `[[kind, class, profile], ...]` | any | his radio-slot set (`sr`) and radio bag (`lr`) |

**Who may change the registry (review R1).** On a client, `register`,
`unregister`, `setState`, `batterySwap` and `netSet` go to the server by
`remoteExec` to `jmfsb_rf_fnc_srvRequest`, never by a CBA event (any client
could raise those to unregister or retune anyone's node). A client may act
only on nodes it holds - the holder is a unit of its machine, or the node was
registered to its Steam id - and register only nodes it holds itself; an
admin may act on any. A client's `netSet` is an admin's only: nets are
everyone's. Local events: `jmfsb_rf_linkChanged`
`[node, net, [[peer, quality, hops, lastHop], ...]]` (server: every node;
client: his own nodes, from the slice), `jmfsb_rf_netCut`,
`jmfsb_rf_emconChanged`.

## Slices

After each tick the server builds each client's slice - the links of the
nodes whose holder is his player, `[[node, [[net, links, reach], ...]], ...]` -
and sends it with `publicVariableClient` as `jmfsb_rf_slice` only when it
differs from what he was last sent. Qualities are quantised to 0.05, so jitter
is not a change. The client's handler (`fnc_receiveSlice`) only indexes it.
Debug overlay (setting, off by default): the server publishes the direct links
as `jmfsb_rf_debugEdges` on change, and clients draw them on the map, red to
green.

## Range self-test

`[] call jmfsb_rf_fnc_rangeTable`: the distance at which two identical sets
reach quality 0 on flat, clear ground with the spec constants and thr 6 dB.
Worked through by hand (the function computes the same formula):

| Profile | Band | Range | Target (DESIGN_RF.md) |
|---|---|---|---|
| handheld 5 W, 2 dBi | VHF | 22.2 km | ~3 km |
| handheld | UHF | 2.8 km | ~3 km |
| manpack 20 W, 3 dBi | VHF | 45 km | ~8 km |
| manpack | UHF | 5.3 km | ~8 km |
| vehicle 50 W, 6 dBi | VHF | 109 km | ~15 km |
| vehicle | UHF | 11.7 km | ~15 km |
| relay 20 W, 6 dBi | VHF | 77 km | ~10 km |
| relay | UHF | 8.5 km | ~10 km |
| drone 1 W, 3 dBi | VIDEO | 0.25 km | ~4 km |
| legacy 5 W, 2 dBi | VHF | 22.2 km | ~3 km |
| 5 W VHF, 0 dBi (not a profile) | VHF | 15.6 km | ~5 km open |
| 0.5 W, 0 dBi (not a profile) | VHF / UHF | 6.4 / 0.9 km | ~1.5 km open |

**The constants miss.** UHF is close (short by 5-35 %). VHF is 3-7x too long:
exponent 2.6 with 32 dB at 1 m is near free space. VIDEO is 16x too short
(exponent 3.2 and 48 dB at 1 m against 1 W). Quality 1 sits one span (20 dB)
inside quality 0, which on UHF is about a fifth of the range. With thr 3 dB
(open item 7) every range grows by 10^(3/10n), about 30 %. Nothing was
retuned; the whole band table is settings, so tuning is a settings change.
The voice nets of the PAC net plan are VHF (`jmfsb_pac_fnc_netPlan`), so today
any two sets on a voice net link at any normal map distance unless terrain cuts
them.

## Not in milestone 1 (next steps)

- EW (DF, tracks, jam / spoof / decoy) is `jmfsb_ew`, through the noise and
  listener hooks and the four read-only calls above. EMCON is stored; in RF
  its only effect is still no relaying at 2 and above (EW reads it for
  exposure and intercept; the power cap is not in RF's link budget).
- Voice degradation: game voice (`jmfsb_voice`, VON) sets each speaker's
  volume from link quality (docs/DESIGN_VOICE.md). TFAR and ACRE are no
  longer voice options (removed 2026-10-31, DEC1).
- Gateways, PACE, battery drain, antenna height, faction tiers and AI nodes by
  tier (only the "AI nodes counted" switch exists).
- Porting the consumers: hacking, messaging, bft and uas. Jamming is ported:
  its radio and data zones are RF noise sources (`jmfsb_jamming_fnc_rfNoise`);
  GPS is still its own.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `cba_main` _(external)_
- `cba_xeh` _(external)_
- `cba_settings` _(external)_

## Ships

46 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_rf_tickPlayers` | SLIDER | Player tick (sec) |
| `jmfsb_rf_tickStatic` | SLIDER | Static tick (sec) |
| `jmfsb_rf_aiNodes` | CHECKBOX | AI nodes counted |
| `jmfsb_rf_debugOverlay` | CHECKBOX | Debug map overlay |
| `jmfsb_rf_batteryHours` | SLIDER | Battery life (hours) |
| `jmfsb_rf_vhfExp` | SLIDER | VHF path-loss exponent |
| `jmfsb_rf_vhfRef` | SLIDER | VHF loss at 1 m (dB) |
| `jmfsb_rf_vhfFloor` | SLIDER | VHF noise floor (dBm) |
| `jmfsb_rf_uhfExp` | SLIDER | UHF path-loss exponent |
| `jmfsb_rf_uhfRef` | SLIDER | UHF loss at 1 m (dB) |
| `jmfsb_rf_uhfFloor` | SLIDER | UHF noise floor (dBm) |
| `jmfsb_rf_satExp` | SLIDER | SAT path-loss exponent |
| `jmfsb_rf_satRef` | SLIDER | SAT loss at 1 m (dB) |
| `jmfsb_rf_satFloor` | SLIDER | SAT noise floor (dBm) |
| `jmfsb_rf_satFadeDb` | SLIDER | SAT rain fade (dB) |
| `jmfsb_rf_videoExp` | SLIDER | VIDEO path-loss exponent |
| `jmfsb_rf_videoRef` | SLIDER | VIDEO loss at 1 m (dB) |
| `jmfsb_rf_videoFloor` | SLIDER | VIDEO noise floor (dBm) |
| `jmfsb_rf_thr` | SLIDER | Quality threshold (dB SNR) |
| `jmfsb_rf_span` | SLIDER | Quality span (dB) |
| `jmfsb_rf_terrainDb` | SLIDER | Terrain per blocked sample (dB) |
| `jmfsb_rf_wallDb` | SLIDER | Wall (dB) |
| `jmfsb_rf_treeDb` | SLIDER | Tree (dB) |
| `jmfsb_rf_proneDb` | SLIDER | Prone (dB) |
| `jmfsb_rf_vehicleDb` | SLIDER | Inside a vehicle (dB) |

## Functions

<details><summary>46</summary>

- `jmfsb_rf_fnc_addListener`
- `jmfsb_rf_fnc_addNoiseSource`
- `jmfsb_rf_fnc_bandInfo`
- `jmfsb_rf_fnc_bandMhz`
- `jmfsb_rf_fnc_battery`
- `jmfsb_rf_fnc_batteryPublish`
- `jmfsb_rf_fnc_batterySwap`
- `jmfsb_rf_fnc_batteryTick`
- `jmfsb_rf_fnc_bodyLoss`
- `jmfsb_rf_fnc_budget`
- `jmfsb_rf_fnc_carriedSets`
- `jmfsb_rf_fnc_drawDebug`
- `jmfsb_rf_fnc_edge`
- `jmfsb_rf_fnc_itemProfile`
- `jmfsb_rf_fnc_link`
- `jmfsb_rf_fnc_linkBudget`
- `jmfsb_rf_fnc_maxRange`
- `jmfsb_rf_fnc_mayTouch`
- `jmfsb_rf_fnc_mesh`
- `jmfsb_rf_fnc_netBand`
- `jmfsb_rf_fnc_netFreq`
- `jmfsb_rf_fnc_netSet`
- `jmfsb_rf_fnc_newKey`
- `jmfsb_rf_fnc_nodeInfo`
- `jmfsb_rf_fnc_nodeKey`
- `jmfsb_rf_fnc_nodePos`
- `jmfsb_rf_fnc_nodesFor`
- `jmfsb_rf_fnc_noise`
- `jmfsb_rf_fnc_openSky`
- `jmfsb_rf_fnc_pathLoss`
- `jmfsb_rf_fnc_pathLossFree`
- `jmfsb_rf_fnc_patternGain`
- `jmfsb_rf_fnc_profile`
- `jmfsb_rf_fnc_quality`
- `jmfsb_rf_fnc_rangeTable`
- `jmfsb_rf_fnc_reach`
- `jmfsb_rf_fnc_receiveSlice`
- `jmfsb_rf_fnc_register`
- `jmfsb_rf_fnc_satBudget`
- `jmfsb_rf_fnc_setState`
- `jmfsb_rf_fnc_sharedNets`
- `jmfsb_rf_fnc_slices`
- `jmfsb_rf_fnc_srvRequest`
- `jmfsb_rf_fnc_tick`
- `jmfsb_rf_fnc_unregister`
- `jmfsb_rf_fnc_updateBands`

</details>
