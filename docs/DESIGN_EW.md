# EW - design

Addons in jmsb-custom-mod: `addons/rf` (`jmfsb_rf`, base) and `addons/ew` (`jmfsb_ew`, needs rf). Rules in [SPEC_TACNET.json](SPEC_TACNET.json) rf.ew.
UI: RF app on the tablet, see [DESIGN_TABLET_APPS.md](DESIGN_TABLET_APPS.md).
Status: design, for code. Date 2026-10-19.

## Basics

- EW is rules on top of the RF mod: same radio registry, same link budget, same mesh. No second engine.
- Nets, not frequencies. Holding a net's key gives spread gain: resists jamming, and ES cannot tell which net it is hearing.
- Jamming is noise added at the receiver. Distance, terrain, buildings, trees and antenna pattern all count, from the antenna's real position.
- Three domains can be jammed:

| Domain | Band | What breaks |
|---|---|---|
| Voice | VHF / UHF per net | static, then cut |
| Data | UHF data | BFT stale, messages queue, CAS waits, drone control lost, calls drop |
| GPS | GPS | own grid and own BFT dot gone, drones drift |

- EW is grouped the doctrinal way: **ES** listens and locates, **EA** attacks, **EP** protects.
- **EW is both ways.** The AI uses every rule here against players, with the same data.

## Mod split

| Mod | Owns |
|---|---|
| `jmfsb_rf` | registry, link budget, mesh, keys, noise-source hook, EMCON fields (they change the link budget), raw "who hears whom", basic exposure. No EW behaviour. |
| `jmfsb_ew` | jammers, spoofers, decoys, DF fusion, classification, threat warning, INSPECT / EXPLOIT, AI EW and the comms gate, hardware power / heat / damage, the ES / EA / EP tabs of the RF app |

- RF exposes a hook for EW to add noise sources and listen to transmissions. RF never knows what EW is.
- Without `jmfsb_ew`, the RF app shows OVERVIEW, NETS and MESH only. Basic "who can hear you" stays in RF, so exposure still shows.
- The separate EW app is dropped. The EW tile opens the RF app on the EA tab.

## ES - listening and locating

![threats](images/app_rfthreats.png)

- **Intercept:**
  - Nodes with an ES-capable profile hear emitters above their RX sensitivity in their bands.
  - What they hear builds tracks for their side.
- **DF:**
  - Bearing error by set: handheld ±15°, manpack ±10°, vehicle ±5°, dedicated ±2°.
  - Error grows as signal-to-noise drops.
  - 2+ cuts within 30 s make a fix with an error ellipse.
- **Identify:**
  - Key held: the track shows the net and node.
  - Otherwise it is classified by band, power, duty cycle and intent: comms, data, video, jam, spoof, radar, or "decoy?" (no traffic for 120 s).
- **Threat warning:** DF ON YOU, SPOT JAM on a net, JAMMER, SPOOFER, NET JAMMED, ENEMY DRONE. Each shows time, detail and what to do.
- **Outputs:** map layer, INTEL report per new fix, send fix to C2, AI tasking.
- **Exposure:** how detectable you are and how far you are heard, shown in the EP tab.

## EA - attacking

![ea](images/app_rfea.png)

- **Jam modes:**
  - **Barrage:** whole band. Key holders subtract their spread gain.
  - **Spot:** one net, needs an ES track on it. +10 dB, and the target's spread gain is halved.
  - **Sweep:** cycles bands every 5 s. Each band gets full power one tick in four.
- **The jammer module as a set** (2026-10-21, the JAMMER CONTROL panel: TAC//EW EA and the JAMMING app). Every value is server state in the operator's slice:
  - **Device ID:** per side, `GJ-01`, `GJ-02` ... - the lowest number free when the jammer first exists, kept while it exists. Shown in the panel header, the NETWORK footer (the side's other jammers by ID, mode, ON / STBY) and on the map.
  - **Switched on is not on the air.** A jammer transmits (`tx`) only while switched on, its battery not flat, not in thermal cutout, and - on AUTO - engaged. Noise, ES, spoof and the spot warning all read `tx`.
  - **Pattern:** OMNI, or SECTOR 120 deg about an azimuth stepped 15 deg (true). A sector reaches only receivers within +-60 deg of the azimuth, +3 dB inside (`jmfsb_rf_fnc_patternGain`, `RF_PATTERN_SECTOR`). Not applied to what ES hears from the jammer.
  - **Frequencies:** each band has its MHz ranges (rf `RF_BAND_MHZ`: VHF 30-88, UHF 225-400, SAT 7250-7750, VIDEO 2400-2483 / 5725-5850). Every net sits on a frequency hashed from its id onto the band's raster (`jmfsb_rf_fnc_netFreq`) - the same on every machine, never sent. A track is heard on its emitter's net frequency (or one hashed from the emitter id when it is on no net of that band). DETECTED and the spectrum show MHz.
  - **Freq filter (barrage):** BROADBAND sits on the whole band. TARGETED (ISR, as spot) is tuned to a detected track's MHz and jams only the nets within +-0.5 MHz of it (1 MHz bandwidth), +6 dB for the power put into that slice. A new band unhooks the tuning.
  - **Operation:** CONTINUOUS transmits whenever switched on. AUTO is looked at every 15 s on the server: it transmits only while a hostile drone (a live UAV of a side hostile to the operator's) or a fresh hostile ES track on a band it is working (within the tuned bandwidth when targeted) is in its reach; otherwise STANDBY - no noise, no draw, no heat. The panel shows what engaged it.
  - **Power system and heat:** see "EW hardware".
- **Drones:**
  - Soft kill: link quality < 0.2. AI drones drop waypoints and hold or RTB. A player's feed goes to static and control is lost; the drone flies home automatically when the link returns.
  - Hard kill (optional, EW kit): VIDEO band, HIGH power, inside 150 m. Engine cut, the drone falls.
- **GPS spoof:** unprotected GPS inside the radius drifts from true position up to a max offset. Own BFT dot and grid follow the false position, and drones navigate on it. Anti-spoof sets show SUSPECT instead.
- **Decoy:** copies the band, power and duty cycle of a chosen profile, and can claim a net. Carries no traffic and cannot relay. Draws enemy DF and fires.
- **Hacking** (hacking addon): DISABLE sets a node off; SPOOF injects false BFT; TAP gives the hacker side the node's key for a while.
- **Other mods:** APS burst and IADS radars register as emitters so ES sees them. Their effects live in their own mods.

## EP - protecting

![ep](images/app_rfep.png)

- **Keys and spread:** profiles have 0 (legacy) to 30 dB (MANET) of spread gain. This stands in for frequency hopping.
- **Rekey:** leader or admin. A captured set keeps only the old key.
- **EMCON**, per node; a leader can order a level for a group or net. Exposure and DF cuts drop as the level rises.

| Level | Limits |
|---|---|
| 0 NORMAL | none |
| 1 REDUCED | power ≤ 2 W, BFT every 10 s |
| 2 MINIMISE | burst data, no relay, PTT voice only, BFT every 30 s |
| 3 SILENT | receive only, no BFT, no relay |

- **Sector antenna:** gain in front, a null behind (−15 dB) to point at a jammer.
- **Anti-spoof GPS:** resists spoofing. Denial still works.
- **PACE:** auto-switch to the alternate net after the active net is cut for a set time (0 = manual).
- **Mesh:** the widest path routes round jammed links.

## Both ways: AI EW

The AI uses the same emitters, keys, EMCON and tracks as players. It only knows what its own side has detected; nothing is player-only or AI-only.

AI EW skill per side, default **1 BASIC**:

| | 1 BASIC | 2 ACTIVE | 3 SMART |
|---|---|---|---|
| EA | static jammers around objectives | also jams player drones it detects | also spot-jams player nets it has DF'd, spoofs GPS, places decoys, hacks |
| ES | reacts to fixes on player transmitters | EW teams and vehicles DF and hunt players | plots players' movement over time |
| EP | none | EMCON 1, moves after transmitting | EMCON 3 before ambushes, rekeys after a capture, PACE |
| On a fix | alert nearby groups, look toward the bearing | send a patrol or drone | send fires, drone or patrol; protect its jammers; a fix on a jammer becomes a priority target |

Players only see AI EW through their own ES and its effects: noise rise, a net going red, GPS SUSPECT, DF ON YOU, a dead drone feed, a patrol arriving where they last transmitted.

## Comms gate the AI

AI cooperation runs over RF links.

- **Sightings:**
  - A group shares its target knowledge only with groups it has a link to on a shared net.
  - Each hop takes 2 s.
  - The chance a sighting gets through equals link quality.
- **Support:** QRF, artillery, CAS, drones and reinforcements need a path to the node that provides them (HQ, battery, airbase, drone operator).
- **Orders:** commander orders (ALiVE-replacement OPCOM) only reach groups with a path.
- **Not gated:**
  - Within about 50 m, groups always share by voice.
  - The engine's sharing inside one group.
- **Isolated group:**
  - Keeps its last orders and fights alone, without other groups' knowledge.
  - Tries its PACE alternate.
  - SMART groups move to high ground to regain a link.
  - Falls back toward its last known HQ after a timeout.
- **Hooks:**
  - LAMBS danger.fsm shares information by radio range; replace that with an RF link check. The exact LAMBS hook still needs checking.
  - Our ALiVE replacement calls the gate directly.

## Captured radios: INSPECT and EXPLOIT

TFAR and ACRE radio items do not survive pickup cleanly, so the item is not relied on.

- **INSPECT:**
  - ACE action on a dead enemy, a dropped radio, a wrecked vehicle, or an enemy relay or jammer.
  - Takes 15 s on a body, 30 s on a vehicle or relay. ISR players take half the time.
- **Possible findings**, each with its own chance:
  - net names;
  - the key (if not zeroized);
  - the fill date;
  - the PACE plan;
  - the last BFT snapshot;
  - recent contacts.
- **Zeroize:**
  - Chance the AI zeroized its set before capture: BASIC 20%, ACTIVE 50%, SMART 80%.
  - Players have a ZEROIZE action for their own set.
- **EXPLOIT:**
  - Found data becomes an EXPLOIT entry, shown in the RF app's ES › EXPLOIT tab.
  - It is shared with the group at once, and with the side over DATA (queued while DATA is jammed).
- **LOAD KEY:** a leader or ISR player can load a captured key to listen in on that net until the enemy rekeys. SMART AI rekeys a set time after it notices the capture; BASIC AI never does.
- The same flow works for maps, documents and laptops through the intel addon.

## Player skill: ISR trait

Uses the existing DIVINER trait (`ghostD_common_fnc_isISR`).

| Everyone | ISR players also get |
|---|---|
| scan, threat warning, EMCON, barrage jamming with a carried jammer, ZEROIZE | DF one class better, classification of unknown signals, spot jamming, spoofing, decoys, INSPECT in half the time, LOAD KEY |

## EW hardware

Our own rules and numbers. Reference only: the EWDJ mod.

- **Power (built 2026-10-21 for the vehicle jammer module; kept on the host vehicle, so it outlives an operator):**
  - SOURCE is the GENERATOR while the engine runs with fuel in the tank (GEN FUEL is the vehicle's fuel): it carries the transmitter and charges the battery at the "Jammer charge" setting (300 W). Otherwise the BATTERY ("Jammer battery", 150 Wh) carries it.
  - The draw is the mean RF out (power x duty) over a 0.4 amplifier efficiency. W IN / W OUT and the NET (charging / draining) show in the POWER SYSTEM block, with a BATTERY bar.
  - Flat with the engine off: off the air, warned, back when the engine runs.
  - Not built: solar, separate packs, time left.
- **Noise:** a running generator is heard by AI within 200 m; jammer fans add 50 m.
- **Thermal:** generators and hot jammers show on thermal sights.
- **Heat (built 2026-10-21):**
  - 0-100%: rises with the mean RF out as a share of 50 W ("Jammer heating", 0.5 %/s at 50 W continuous), sheds the "Jammer cooling" setting (0.1 %/s) all the time.
  - THERMAL CUTOUT at 100%: off the air until it has cooled to 60% (hysteresis), warned both ways. COOLING reads NORMAL / HOT (80% up) / CUTOUT; a HEAT bar sits under BATTERY.
  - Not built: throttling, permanent burn-out.
- **Damage:**
  - A few rifle rounds or one grenade wreck a ground jammer or relay.
  - Antennas can be shot off separately: range drops, the unit still works.

## Radio profiles

| Profile | Bands | TX | RX sens | Gain | Hops | Spread | Battery | Range (flat, clear) |
|---|---|---|---|---|---|---|---|---|
| Handheld (MPU5) | VHF/UHF | 25 mW | −112 dBm | 2 dBi | 4 | 20 dB | 38 Wh | ~0.5 km |
| Manpack | VHF/UHF | 20 W | −115 dBm | 3 dBi | 6 | 20 dB | 90 Wh | ~2.7 km |
| Vehicle set | VHF/UHF/SAT | 50 W | −118 dBm | 6 dBi mast | 8 | 25 dB | vehicle | ~5 km |
| Ground relay | VHF/UHF | 20 W | −118 dBm | 6 dBi | 8 | 25 dB | 200 Wh | ~3.3 km |
| Drone link | VIDEO | 2 W | −95 dBm | 3 dBi | 0 | 10 dB | drone | ~1.8 km |
| Legacy / commercial | VHF | 5 W | −110 dBm | 2 dBi | 0 | 0 dB | 30 Wh | ~1 km |
| SAT terminal | SAT | 10 W | −120 dBm | 12 dBi | 0 | 10 dB | 60 Wh | sky view |

**Faction tiers**, set in the faction builder:

| Tier | Who | Sets | Spread | Effect |
|---|---|---|---|---|
| A peer | modern armies | same as players | 20 dB | hard to jam or read |
| B regular (default) | older armies | legacy handhelds + some manpacks | 10 dB | moderate |
| C irregular | insurgents | commercial radios and phones | 0 dB | easy to jam, DF and exploit |

## How players protect themselves

**Against being DF'd**
- Talk less: short transmissions; EMCON REDUCED / MINIMISE, and SILENT before an ambush.
- Lower power: 2 W is heard at roughly half the range of 5 W.
- Use the mesh: a short low-power hop to a relay is quieter than shouting straight to C2.
- Move after transmitting: a fix needs 2 cuts in 30 s.
- Sector antenna: less energy where you don't need it.
- Hold the key: the enemy hears energy but cannot name the net or node.
- Watch exposure in the EP tab. DF ON YOU means move.
- Decoys (ISR).

**Against jamming**
- Stay on spread-gain nets: the key takes about 20 dB off barrage jamming.
- Point the sector null at the jammer (−15 dB).
- Put terrain or buildings between you and the jammer, keeping the path to your relay clear.
- Reroute: move a relay or raise the vehicle mast.
- Go to the PACE alternate, or change band (UHF or SAT if VHF is jammed).
- Kill it: DF it, send the fix, then fires or a raid. A few rounds wreck it; shooting off the antenna cuts its range.
- Send data early: it queues and goes when the link returns.

**Against GPS denial and spoofing**
- Use anti-spoof sets.
- Map and compass; the BFT dot shows ±drift when GPS is SUSPECT.
- Manual position fix: mark yourself from a known point, and BFT uses that until GPS is good.
- Fly drones by video and keep them close.

**Protecting your drones**
- Hold the key on the video link.
- Keep line of sight; fly low with terrain between the drone and the jammer.
- Launch from somewhere safe, since a drone that loses its link flies home on its own.
- Spot-jam their drone first (ISR).

**Against capture and cyber**
- ZEROIZE your set before capture.
- Leader rekeys when a set is lost.
- A HACK warning on your node: turn it off or change net.
- Recover your dead's radios before the enemy can INSPECT them.

**Physical**
- Hide and guard relays and jammers; they are fragile.
- Generators are loud and hot: run them behind cover, only when needed.
- Keep jammers below 90% heat, or rotate units.

**Kit and roles**
- ISR players get the better ES and EA tools listed above.
- EW team: an ISR team with a vehicle set has the best DF and the most jamming power.
- Shielding: inside a vehicle or building you get 6–18 dB of protection, already in the link budget.

## Later: 2040 kit and EW

| Item | EW effect |
|---|---|
| Adaptive sets | barrage jamming hurts them half as much; spot jamming (needs an ES track) is the answer |
| LPD sets | ES detects them only at short range, and DF needs more time. Pushes EW teams closer to the target |
| Optical links | outside EW: no jam, no intercept. Counter: smoke, weather, physically breaking line of sight, killing a terminal |
| Fibre-optic drones | outside EW: the drone jammer does nothing. Counter: shoot the drone, follow and cut the cable |
| GPS backups | anti-jam antenna arrays and inertial navigation on tier A sets and drones: GPS denial degrades them slowly instead of cutting them |

Rule of thumb for 2040: jamming wins up close with power, so the fight is finding the jammer (ES) and killing it.

## Open

- Check the LAMBS hook for the comms gate.
- Put numbers on spoof radius and drift, decoy battery, heat rates and generator fuel.
- Write the INSPECT finding chances per item.
- Write the rules for the EW team role.
- Spec update: write this into SPEC_TACNET.json 0.5.0, with `jmfsb_ew` as its own mod.
