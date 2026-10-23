# Tablet apps - design

Shell: [DESIGN_TABLET.md](DESIGN_TABLET.md). Status: design, for code. Date 2026-10-19.
Canvas: TAC//APP Tablet (artifact AF6PUzUbiRWvj8nkhgHd2A), one board per app.

## Rules for every app

- Opens as a page over the map area. Device bar, notification line, tiles and net row stay.
- App header: name, tabs, a status note on the right, CLOSE. ESC also closes.
- Panels: title + right label, 3 px ink rule under the header.
- Rows are buttons (whole row clickable). Selected row uses the light accent tint.
- Segmented controls for choices; filled = selected.
- Numbers and data in mono; labels in sans caps.
- An app only reads data its owner already has; it does not compute RF or BFT itself.

| App | Opened from | Owner / data |
|---|---|---|
| RF | MESH tile, EW "OPEN RF" | `jmfsb_rf` client slice (incl. rf.ew EA / EP / ES) |
| RADIO | NET tile | `jmfsb_adapter_tfar` / `tacpad_apps` radio state |
| EW | EW tile | rf emitters + ewkit jammer |
| DRONES | DRONES tile | uas |
| FIRES | FIRES tile | fires / support request |
| HACK | HACK tile | hacking |
| INTEL | TOOLS, map | intel / hacking hints |
| TIMER | TIMER tile | hacking alarms + tacpad_apps stopwatch |
| WEATHER | TOOLS | engine weather |
| SQUAD | squad rail header | ACE medical, BFT member numbers |
| MEDIC | MEDIC tile (CLS / Medic only) | `jmfsb_medic`: ACE medical + ACM |
| PAC | PAC tile | TAC//PAC unit db |
| TIC | TROOPS IN CONTACT button | tacpad_apps ticSend |
| SETTINGS | SETTINGS button | CBA settings |
| ADMIN | ADMIN button (admin only) | bft describeGroup, rf admin |
| AUGUR | TOOLS | assistant |
| VEHICLE | VEHICLE tile, arrows, F-key (vehicle tablet only) | engine hit points / fuel / magazines, `jmfsb_aps` vehicle vars, `jmfsb_rf` client slice |

---

## RF

Tabs: OVERVIEW, NETS, MESH, ES (SPECTRUM / DF / THREATS), EA, EP. The RF mod has no screen of its own; this is its UI.

EW is grouped the doctrinal way: **ES** listens and locates, **EA** attacks, **EP** protects. Rules: `SPEC_TACNET.json` rf.ew.

**EW is both ways.** The enemy AI runs the same EA, EP and ES rules on players (skill 0-3 per side: jams, spot-jams nets it has DF'd, spoofs GPS, places decoys, runs EMCON, moves after transmitting, hunts fixes). Players only see AI EW through their own ES and its effects.

![rf overview](../art/images/app_rf.png)

- **OVERVIEW**:
  - NETS table: net, band, reach, quality, state.
  - MESH graph for the selected net.
  - LINK BUDGET for the selected link.
  - NODE (your set: state, battery, exposure, TX power, relay, active net).
  - SPECTRUM · SIGNALS.
  - DF TRACKS.
- **Link budget rows** follow the spec formula: TX, gains, path loss, terrain, clutter, body, RX, noise floor, jammers (minus spread unless key held), noise, SNR, quality = (SNR − 3) / 20.

![rf nets](../art/images/app_rfnets.png)

- **NETS**:
  - Columns: key, reach, quality, PACE (P·A·C·E), state (P / CUT / DEG / NO FILL), and YOU (TX / MON / DATA).
  - Side panel lists the selected net's members, each with quality, hops and via.
  - Buttons: SET ACTIVE, MONITOR, GO TO PACE ALT, REKEY (leader).

![rf mesh](../art/images/app_rfmesh.png)

- **MESH**:
  - Net chips and SHOW toggles (links, dB, jammers, names).
  - Large graph with the selected path in bold.
  - PATH panel lists the hops with dB per hop. Widest path = route whose weakest link is strongest.

![rf spectrum](../art/images/app_rfspectrum.png)

- **ES · SPECTRUM**:
  - One row per band: band name, range and floor; energy now (own blue, jam red, unknown purple); noise rise over the last 60 s; rise in dB.
  - AT selector: my position / map cursor / selected node.
  - SIGNALS list below.
  - Nets have no frequencies, so the x axis is position within the band.

![rf df](../art/images/app_rfdf.png)

- **ES · DF**:
  - Plot of bearings from every station that heard the emitter, with the fix ellipse.
  - TRACKS list with SEND FIX TO C2, MARK ON MAP, CLEAR.
  - YOU, SEEN BY THEM: your exposure, how far you are heard, what lower power does.

![rf threats](../art/images/app_rfthreats.png)

- **ES · THREATS**:
  - Threat warning list: DF ON YOU, SPOT JAM on a net, JAMMER, SPOOFER, NET JAMMED, ENEMY DRONE. Each has time, detail and what to do.
  - ES CLASSIFIES panel: how an emitter is classed when its net key isn't held (comms, data, video, jam, spoof, radar, decoy?).

![rf ea](../art/images/app_rfea.png)

- **EA**:
  - EA IN PLAY: every attack emitter your side knows of (enemy AI from ES tracks, own from the registry), with kind, bands, effect at your position and bearing.
  - YOUR EA:
    - JAM: mode BARRAGE / SPOT / SWEEP, bands, the spot target taken from an ES track, power, pattern, red JAM ON.
    - SPOOF: needs a spoofer (ewkit).
    - DECOY: copies a profile and can claim a net.
  - IF YOU JAM NOW: what it does to your own nets and drones, which enemy links go down (soft kill / hard kill), how loud you get, and battery.

![rf ep](../art/images/app_rfep.png)

- **EP**:
  - EMCON levels 0 NORMAL, 1 REDUCED, 2 MINIMISE, 3 SILENT: what each limits and the exposure change. Leader can order a level for the group or net.
  - KEYS · FILL: key held, fill, spread gain per net; lost sets that still hold the key; REKEY; PACE auto-switch.
  - GPS: OK / SUSPECT / SPOOFED / DENIED, drift, anti-spoof set, source.
  - ANTENNA: omni or sector, azimuth, null toward a jammer.

## RADIO

![radio](../art/images/app_radio.png)

- **CHANNELS**: key, net, band, link, ear, volume, state (ACTIVE / MON), who is talking.
- **RADIO SET**: active net, 2nd PTT net, ear, power, battery.
- **CALLS**: live, recent and missed calls, pending callbacks, add people. Buttons: CALL, + ADD, GROUP +, CALL BACK, HANG UP. (No voice notes on VON.)
- Frequencies are never shown. Game voice (VON) runs underneath by default; TFAR standalone is an optional adapter. Full RADIO design (NETS, CALLS, MANAGE): [DESIGN_VOICE.md](DESIGN_VOICE.md).

## EW

![ew](../art/images/app_ew.png)

- **EMITTERS NEAR YOU**: emitter, band, level, bearing, kind. Buttons: DF THIS, MARK, SEND TO C2, OPEN RF.
- **JAMMER (carried)**:
  - State and bands (VHF / UHF / VIDEO / GPS).
  - Power, pattern, sector azimuth, and mode (ALWAYS / ON CONTACT).
  - Battery.
  - A warning when you would jam your own nets.
  - Red TRANSMIT button.
- **JAMMING ON YOU**: voice, data and GPS, each with what you lose and its state now.
- Must not look like the EWDJ jammer panel (reference only).

## DRONES

![drones](../art/images/app_drones.png)

- **FLEET**: own drones with link, quality, battery and task; enemy drones heard.
- **FEED**: video placeholder with HUD text (alt, speed, heading, target grid, link). Buttons: TAKE CONTROL, ORBIT, GO TO, MARK TARGET, LASE, RTB.
- Control needs the DATA link. A drone that loses its link flies home by itself.

## FIRES

![fires](../art/images/app_fires.png)

- **CAS 9-LINE**: the nine fields plus remarks. Location can come from a DF fix or a map click. Buttons: SEND, READ BACK, ABORT.
- **ASSETS**: callsign, type, state.
- **MISSIONS**: number, status, TOT, plus a timeline for the selected mission.
- Posts over DATA; waits (queued) while jammed.

## HACK

![hack](../art/images/app_hack.png)

- **NODES IN REACH**: node, type, range, security.
- **ACTION**: target, action (DISABLE / SPOOF / TAP), progress, your risk (you may be DF'd), requirements. Buttons: START, ABORT.
- **LOG** of the current hack.

## INTEL

![intel](../art/images/app_intel.png)

- **REPORTS**: time, report, from, confidence.
- **REPORT** detail with what, where, how, seen and linked items. Buttons: SHOW ON MAP, SEND TO C2, ADD NOTE.
- Works without ALiVE.

## TIMER

![timer](../art/images/app_timer.png)

- **ALARMS**: shared with your section. Each has number, name, time and countdown; red inside 30 s, amber inside 2 min. Buttons: +1 / +5 / +10 MIN, AT TIME, DEL #N.
- **STOPWATCH**: local only, with START/STOP, LAP, RESET.

## WEATHER

![weather](../art/images/app_weather.png)

- **NOW**: sky, wind, visibility, temperature.
- **FORECAST**: next 8 h, with the effect on drones and CAS.
- **LIGHT**: sunrise, sunset, moon, fog.

## SQUAD

![squad](../art/images/app_squad.png)

- **Roster**: BFT member icon and number, name, role, state, link, flags.
- **MEMBER**: wounds, blood, ammo, radio, distance. Buttons: SHOW ON MAP, CALL, MEDIC TO HIM.

## MEDIC

- For a CLS or medic only (PAC skill tags). The tile shows the squad's wounded count and goes alert on cardiac arrest or heavy bleeding.
- **PATIENTS**: the player's group, worst first (ARREST, UNCONSCIOUS, WOUNDED, OK, DEAD last), with bleeding, wounds, blood and range.
- **PATIENT**:
  - HR / BP / SpO2 / RR tiles. Each is live only while its ACM device is on the patient; otherwise it shows the last hand check with its age, or NOT MONITORED.
  - Status lines: blood type, blood volume, bleeding, pain, airway, chest, rhythm.
  - Body table: wounds, TQ, fracture / splint and IVs per part.
  - Buttons: BACK, SHOW ON MAP.
- Without ACE medical the app reads MEDICAL SYSTEM NOT LOADED. See `addons/medic/README.md`.

## PAC

![pac](../art/images/app_pac.png)

- **ROSTER**: callsign, rank, role, slot, online.
- **ME**: unit, role, quals, ops count, next event. Buttons: REQUEST SLOT, PROFILE.

## TROOPS IN CONTACT

![tic](../art/images/app_tic.png)

- One-touch answers: direction, distance, enemy, fire, us.
- Big SEND button.
- **On send**: marks the map, alerts the side, reports to C2, and pre-fills a FIRES call for fire.
- Sending with no answers still sends grid and time.

## SETTINGS

![settings](../art/images/app_settings.png)

- **DISPLAY**: mode (native / tablet), scheme, opacity, tile rows, HUD tiles, where notifications go.
- **DEVICES**: walking view on/off, position, device, toggle key, member voice rings.
- **KEYS**: list of the CBA keybinds.

## ADMIN

![admin](../art/images/app_admin.png)

- **GROUPS · BFT CODES**: group, side, units, TX and RX codes (from `ghostD_bft_fnc_describeGroup`).
- **CONTROLS**:
  - God view, enemy jamming, RF debug.
  - Place jammer or relay.
  - Rekey C2 or all nets.
  - Reset RF, push fill.

## AUGUR

![augur](../art/images/app_augur.png)

- Chat with the assistant.
- TRY panel of example questions.
- WHAT IT SEES: reads the RF slice, BFT, INTEL and weather.
- Acts only when the player presses a button.

## VEHICLE

VEHICLE STATUS, the vehicle tablet's own app: registered with the shell only while the vehicle tablet is up, so no other device has its tile, F-key or place in the arrows' ring. The tile is gated by the device, not by the role. Read-only, redrawn every 2 s while open.

- Strip: the vehicle's callsign and type (type only when it differs), speed and engine; DESTROYED as an alert block.
- DAMAGE + FUEL: one bar per part group, worst first; the tank and a range measured from fuel burnt since the last refill.
- AMMUNITION + COUNTERMEASURES: turret by turret ([-1] is DRIVER, or PILOT on aircraft), weapon by weapon, rounds and magazines; smoke and flares apart.
- APS + RF SET + CREW: APS charges and holds; the rack's nets (only at the rack seat; NO RADIO RACK when the vehicle has none); crew seats, with passengers folded into one PAX row plus the hurt.
- Tones: green / amber are swatch fills beside ink values; red is an inverted accent block with a word, never a hue alone.

## Not in scope

- Messaging: TAC//MSG reader, compose and message templates.

- Phone and side device apps (walking view only for now).
- Real map tiles and live data in the mockups.
