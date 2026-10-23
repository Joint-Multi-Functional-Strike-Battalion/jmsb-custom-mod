# RF mod - design

Addon: `addons/rf` (`jmfsb_rf`) in jmsb-custom-mod (user, 2026-10-19). Deps: CBA only - no other jmfsb addon; adapters and consumers depend on it, never the reverse. Rules: [SPEC_TACNET.json](SPEC_TACNET.json) `rf`.
EW on top of it: [DESIGN_EW.md](DESIGN_EW.md). UI: RF app on the tablet, [DESIGN_TABLET_APPS.md](DESIGN_TABLET_APPS.md).
Status: design, for code. Date 2026-10-20.

## What it is

The base of the comms ecosystem. It answers one question every tick: who can reach whom, on which net, and how well. Voice, data, BFT, drones, calls and EW all read the answer. It has no screen of its own: the tablet's RF app is its UI.

- **Nets, not frequencies.** A net is a group with a key. Players never see frequencies.
- **Mesh.** Any capable radio can relay. Traffic takes the best path.
- **One answer for everything.** Voice quality, data delivery, BFT freshness and drone control all come from the same link quality, so they can never disagree.

## Where it runs

| Side | Does |
|---|---|
| Server | registry, link budget, mesh, raw intercepts, client slices |
| Client | reads its own slice only; no computation |

- Tick: players 1 s, static nodes 5 s.
- A slice is pushed to a client only when it changes (`publicVariableClient`), never every tick.

## Objects

| Object | Holds |
|---|---|
| **Node** | id, object (unit / vehicle / prop), side, profile, nets with keys, state (on, tx, relay, activeNet, monitorNet, emcon 0-3), battery, owner mod |
| **Profile** | bands, TX power, RX sensitivity, antenna gain, pattern (omni / sector + angle), hop limit, relay capable, spread gain, data rate, battery Wh, idle and TX watts, ES capable, DF class, anti-spoof GPS |
| **Net** | id, name, band, key, spread gain, PACE (P/A/C/E net ids), state (cut, held, patchedTo), source (signal plan) |
| **Link** | a, b, net, SNR, quality 0-1, hops, last hop |
| **Emitter** | node, band, power, pattern, azimuth, intent (comms / data / video / jam / spoof / decoy / radar / de), exposure |
| **Track** | side, emitter, band, dBm, bearing ± error, fix ± error, named (key held), class, time, cuts |

## Link budget

```
rx      = tx + gainTx + gainRx - pathloss(d, band) - terrain - clutter - body
noise   = floor(band) + sum(jammers in band, each minus spread gain unless the key is held)
snr     = rx - noise
quality = clamp((snr - 6) / 20, 0, 1)
```

**Path loss**: log-distance per band.

| Band | Exponent | Ref at 1 m | Noise floor |
|---|---|---|---|
| VHF | 4.22 | 9 dB | −110 dBm |
| UHF | 4.22 | 4 dB | −105 dBm |
| SAT | 2.0 | 45 dB | −115 dBm |
| VIDEO | 2.46 | 48 dB | −95 dBm |

The SAT row prices only ground emitters on SAT (a jammer's noise, an intercept). The link through the satellite has no path loss: see The satellite link.

**Obstacles:**
- Terrain: 3 samples along the path (`terrainIntersectASL`); each blocked sample costs 12 dB.
- Clutter: `lineIntersectsSurfaces`, counted. Wall 18 dB, tree 5 dB.
- Body: prone 3 dB, in a vehicle 6 dB.

**Without the key:**
- Detection: rx minus spread gain.
- Jamming noise: jammer minus spread gain.

**Tuning targets (user, 2026-10-19): one third of the original table.** Handheld ~1 km, manpack ~2.7 km, vehicle set ~5 km, relay ~3.3 km, drone link ~1.3 km, flat and clear. MESH RADIOS ARE SUB-WATT AND RELAY (user, 2026-10-19): the MPU5 handheld transmits 25 mW and reaches ~0.5 km per hop (user, 2026-10-19: "get that down to .5 km"; it was 0.5 W / ~1 km); range beyond that is carried by relaying through other MPU5s (relay-capable, up to 4 hops), manpacks, vehicles and ground relays. VHF / UHF are fitted to those targets with the handheld anchored (exponent 4.22, close to ground-level two-ray falloff; the loss-at-1-m term is a fitting constant, not physics). Fitted result per hop: handheld 0.48 km, manpack 2.6 km, vehicle 4.5 km, relay 3.6 km, legacy 5 W 1.7 km (no relay), drone 1.3 km.

## The satellite link

Built 2026-10-20 (user: "can we assume a staging zone or patrol base as a sat uplink"). SAT is a real satellite, not a ground band:

- **Who:** two nodes whose profiles both have SAT (vehicle set, base station, SAT terminal) and hold the same key (same side; the mesh only pairs key holders).
- **Open sky:** each end needs open sky - one ray (`lineIntersectsSurfaces`, GEOM) straight up 30 m from the antenna, ignoring the node's own object and the vehicle a man sits in. Cached per node, re-cast on the static tick or after 10 m of movement, never per frame. A roof, a bridge or a hangar blocks the dish.
- **One hop, any distance:** terrain and clutter are ignored. A SAT terminal carries any net through the bird, whatever the net's band: a base station holding C2 (VHF) links C2 by satellite. The edge is the better of the ground link and the satellite link. A satellite leg is one edge in the mesh, so it counts as one hop, and each relay at its ends counts once against the hop limit.
- **Quality:** constant, 0.9 in clear sky (the signal is placed at that point of the quality span, whatever the threshold and span settings), less **rain fade**: setting "SAT rain fade" (default 6 dB) x rain, overcast counting a quarter (capped at full rain). Clear 0.9; full rain 0.6 at the defaults.
- **Jamming:** the noise at each end is `rf_noise` on the SAT band, so a jammer on SAT (EW barrage or sweep on SAT, anything a noise source returns for SAT) degrades the satellite link exactly like a ground link. Spot jamming of a net hits the net's own band, not its SAT backhaul.

## Base stations

Built 2026-10-20 (user: "can we lose the LR or use our patrol base as a relay"). Every staging zone (`jmfsb_mission_fnc_addStagingZone`: object, marker or position) and every built patrol base gets a base-station node, put up by the server (`jmfsb_pac_fnc_baseStation`):

- **Profile `base`:** VHF, UHF and SAT; the ground relay's 20 W, 6 dBi, hop limit 8, spread 25 dB; relay capable; powered by its site (battery -1).
- **Where:** on the zone's object, at a marker's or position's centre (an invisible helper object), on the patrol base's mast.
- **Fill:** every net of the PAC plan (`jmfsb_pac_fnc_netPlan`), DATA and the default plan's C2, under the side's keys; relay and TX on. Refreshed when the plan changes.
- **Side:** the players'. A patrol base takes its builder's side; a staging zone the players' side (`jmfsb_common_fnc_playerSides`).
- **What it does:** locally it is a ground relay round the site; by satellite it links every base station (and every SAT-capable vehicle) of the side under open sky in one hop. A squad on handhelds that meshes into a patrol base reaches C2 at the staging zone and every other base. The weak leg is the handheld's own 25 mW uplink: handheld to base station is about 0.6 km on flat, clear ground (the base station's power does not help the handheld's direction), so a squad further out needs MPU5 relays, a manpack or a vehicle in between.
- **Gone:** a staging zone removed, a patrol base unbuilt, or the site's object destroyed (MPKilled) or deleted takes its station down.
- **EW:** an RF node that transmits, so it is an emitter EW hears, DFs and jams like any node.
- **Settings:** "Patrol base radio relay" (Patrol Base) and "Staging zone satellite uplink" (Staging), both on by default.
- **The LR manpack is optional:** every set carries the C2-kind net; a manpack only extends range away from the bases.

## Mesh

- Built per net, every tick.
- **Vertices:** nodes on the net that are on and either relay-capable or an endpoint. A node is on a net's mesh when its profile has the net's band or SAT.
- **Prefilter:** skip pairs beyond the band's maximum range at maximum power.
- **Edges:** link budget per pair, cached for the tick.
- **Search:** widest path, maximising the weakest link (from `radio_mesh`).
- **Hop limit:** the smallest profile hop limit along the path.
- **Gateway:** a node on two nets with relay on joins the two graphs.
- **Relay cost:** a relaying node drains battery at TX watts while it carries traffic.
- **AI nodes:** only if the profile or node is flagged.

## What quality does

| Domain | Quality → effect |
|---|---|
| Voice | voice adapter: VON sets each listener's volume per speaker from quality, static overlay as it falls, muted at 0 (TFAR adapter: per-unit multipliers). See DESIGN_VOICE.md |
| Data | delivery and delay; messages queue below threshold, send when the link returns |
| BFT | update rate falls with quality; stale marker when no path |
| Drones | control and feed need the VIDEO link; below 0.2 control is lost and the drone RTBs |
| Calls | connect only with reach on DATA; drop when the link drops |
| GPS | own position good / degraded / denied from the GPS band |

## Nets (default plan)

| Net | Who | Band |
|---|---|---|
| TEAM 1-5 | that team (Arma group) | VHF |
| C2 | everyone, all-call, by signal plan | VHF |
| A2G | everyone, air to ground | UHF |
| DATA | everyone, data only | UHF data |
| CALL x | 2+ nodes, temporary, created on dial | UHF data |

Fill: rifleman and leader get TEAM, C2, A2G. PACE and gateways are added when nets grow.

## Radio profiles

| Profile | Bands | TX | RX sens | Gain | Hops | Spread | Battery | Range (flat, clear) |
|---|---|---|---|---|---|---|---|---|
| Handheld (MPU5) | VHF/UHF | 25 mW | −112 dBm | 2 dBi | 4 | 20 dB | 38 Wh | ~0.5 km |
| Manpack | VHF/UHF | 20 W | −115 dBm | 3 dBi | 6 | 20 dB | 90 Wh | ~2.7 km |
| Vehicle set | VHF/UHF/SAT | 50 W | −118 dBm | 6 dBi mast | 8 | 25 dB | vehicle | ~5 km |
| Ground relay | VHF/UHF | 20 W | −118 dBm | 6 dBi | 8 | 25 dB | 200 Wh | ~3.3 km |
| Base station | VHF/UHF/SAT | 20 W | −118 dBm | 6 dBi | 8 | 25 dB | site | ~3.3 km ground, SAT any distance |
| Drone link | VIDEO | 2 W | −95 dBm | 3 dBi | 0 | 10 dB | drone | ~1.8 km |
| Drone relay | VHF/UHF | 2 W | −112 dBm | 3 dBi | 4 | 20 dB | drone | ~1.5 km |
| Legacy / commercial | VHF | 5 W | −110 dBm | 2 dBi | 0 | 0 dB | 30 Wh | ~1 km |
| SAT terminal | SAT | 10 W | −120 dBm | 12 dBi | 0 | 10 dB | 60 Wh | sky view |

**Faction tiers**, set in the faction builder:
- **A peer:** same sets as players.
- **B regular** (default when unset): legacy sets plus some manpacks, 10 dB spread.
- **C irregular:** commercial radios and phones only, no spread.

## Who gets a node

- **Players:** from the radio or device they carry (GPS slot device, radio item).
- **Vehicles:** every vehicle with a set gets a vehicle node; the crew uses it.
- **AI:** leaders and vehicles, with the profile set by the faction tier.
- **Placed:** ground relays, jammers (EW), decoys (EW), static HQ nodes from the mission.
- **Sites:** a base station at every staging zone and built patrol base (see Base stations).

## What players do with RF

- **Everyone with a set:**
  - Pick the active net (numpad 0 / .), hear every net they are on, mute or set the ear per net.
  - Call another node, add people to a call, request a callback.
  - Set power, relay on/off, and antenna (omni / sector + heading).
  - See their own link quality, hops, battery and exposure.
- **RTO, leaders, crews:**
  - Carry a manpack as a relay, or place, pick up and re-battery a ground relay.
  - Raise a vehicle mast.
  - Run a gateway between nets.
  - Load the fill, order EMCON, rekey nets, switch the group to its PACE alternate.
- **Physical:** destroy enemy relays and antennas; capture and INSPECT enemy sets (EW).

## What the AI does with RF

- Same physics as players: terrain, range and jamming all apply.
- **Comms gate (EW):** AI groups share sightings, call support and get orders only over links. Isolated groups fight alone. See the EW doc.
- **AI drones:** drop their waypoints when the link is lost, then hold or RTB.

## Public API

| Call | Scope |
|---|---|
| `rf_register` / `rf_unregister` | node in / out |
| `rf_setState` | on, tx, relay, activeNet, monitorNet, keys, emcon |
| `rf_link`, `rf_reach` | client slice |
| `rf_tracks`, `rf_emitters` | per side |
| `rf_noise` | pos, band → dBm |
| `rf_budget` | server: full budget for a pair |
| `rf_netSet`, `rf_rekey` | server / admin |
| `rf_emcon` | server |
| `rf_gpsState` | client slice |
| EW calls (`rf_jam`, `rf_spoof`, `rf_decoy`, `rf_threats`) | provided when `jmfsb_ew` is loaded, through RF's noise-source and listener hook |

**Events:** `rf_linkChanged`, `rf_netCut`, `rf_rekeyed`, `rf_emconChanged`, `rf_exposureHigh`. With EW: `rf_trackNew`, `rf_trackLost`, `rf_jamOn`, `rf_spoofDetected`, `rf_dfOnYou`.

**Settings:**
- Tick rates.
- Band table.
- SAT rain fade.
- Terrain and clutter dB.
- AI nodes counted.
- Max nodes per net.
- PACE auto time.
- Debug overlay.

## UI

The RF app on the tablet (and vehicle tablet):

- **Without EW:** OVERVIEW, NETS, MESH.
- **With EW:** also ES, EA, EP.
- **Phone and side devices:** RF state appears in the status icons (NET, MESH, JAM, GPS) and the net row (green / red outline per net).

![overview](images/app_rf.png)
![nets](images/app_rfnets.png)
![mesh](images/app_rfmesh.png)

## Later: 2040 radio kit

Where spread spectrum is heading, as game features. Spread gain is assumed in 2040; the edge comes from adaptive behaviour, low detectability, directional antennas and not using radio at all.

| Item | What it does | Cost / counter |
|---|---|---|
| Adaptive set | profile flag `adaptive`: senses jamming and dodges it; barrage jamming costs it about half as much | spot jamming still works; dearer kit, faction tier A only |
| LPD profile | profile flag `lpd`: signal near the noise floor; ES must be closer to detect it, DF cuts take longer | shorter range (about −30%), lower data rate |
| Optical link | fixed point-to-point laser between two placed terminals; cannot be jammed or intercepted | needs clear line of sight; broken by smoke, fog and rain; setup time |
| Fibre-optic drone | drone on a tether; immune to jamming and DF | tether length limit (5-10 km); the cable can be cut; slower to deploy |

## Open

1. Antenna height and radio horizon: masts, aircraft and drones at altitude. The link budget ignores height today, and it matters most.
2. Power: battery drain, swap, vehicle charging.
3. Performance: node and pair limits, spreading work over frames, caching terrain samples.
4. Sync: slice contents and size, JIP, headless client.
5. Mission maker: Eden signal-plan module (nets, keys, PACE), placing relays, Zeus controls.
6. Weather: rain fade on VIDEO, foliage by season. (Rain fade on SAT is built, 2026-10-20: see The satellite link.)
7. The quality threshold is 6 dB in the spec, but the tablet mockups show 3 dB. One of them needs to change.
