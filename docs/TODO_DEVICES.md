# TODO - devices, BFT, apps, TAC//NET

Built from DESIGN_TABLET, DESIGN_TABLET_APPS, DESIGN_PHONE_WALKING, DESIGN_SIDE_DEVICES,
DESIGN_BFT_MEMBERS, SPEC_DEVICES.json and SPEC_TACNET.json. Date 2026-10-19.

Marks: **[x]** built and passing `check_all` · **[g]** built and seen working in game ·
**[ ]** to do · **[?]** needs a decision. Nothing below is [g] yet unless it says so: almost all of
this session's work is NOT RUN IN GAME.

The design docs name DIVINER functions (`ghostD_...`). In this mod they are `jmfsb_...`.

## Conflicts between the docs and later decisions

| Doc says | Decided (user) | Follow |
|---|---|---|
| Tablet/phone: upper-right notifications suppressed, go to the notification line | 2026-10-18: popups stay upper right in every mode; device rows only mirror | decision |
| Rounded screen corners in the frames | 2026-10-19: every screen hole square | decision |
| Phone fixed at 610 x 274 at 1080p | 2026-10-19: "a bit wider", size is a setting (default 0.3 of height) | decision |
| Phone map ~50 m radius | 2026-10-19: zoomed in, follow every frame; zoom is a setting | decision, tune radius in play |
| Phone/side font IBM Plex Mono / Etelka | 2026-10-19: same font as the UI now (RobotoCondensed) | decision |
| Tasks in support (ADD TASK) | 2026-10-19: skipped | decision |

## 1. Shell and frames

- [x] Display mode setting (native / tablet); tablet is the default
- [x] Large tablet dialog hosting the tacpad suite
- [x] Map moved behind frame and panels (fixes "no UI" and the corners) - needs in-game check
- [x] Square screen hole in every frame; enclosed white pockets cut (vehicle cradle)
- [x] Frame generator `tools/gen_devices.py`; all art in `art/` (devices, signs, images)
- [x] F1-F4 programmable to apps, left/right cycle apps, Ctrl+Home opens, ACE self action
- [x] UAV tablet (grips) for players with the UAV trait, screen matched to the large tablet
- [x] HUD off by default in tablet mode, player can re-enable
- [x] Tablet layout from DESIGN_TABLET: device bar, notification line, live tiles in one row, map area (the host), net row; [ ] battery in the bar
- [x] Fixed panel places on the tablet (squad rail, button strip, TIC, map tools, reader, APS) via a layout table passed to setHost; [ ] who-is-talking
- [x] Vehicle tablet: ACE vehicle action, ON BOARD rail, `VEHICLE · <name>` bar; [ ] VEHICLE SET panel
- [x] VEHICLE STATUS app, on the vehicle tablet ONLY (user, 2026-10-19): damage by part, fuel, ammo by turret, crew seats, APS charges, RF vehicle set state, smoke/flares. Queued after the tablet layout workflow.
- [x] QRF: remove HALO and HAHO, keep static line and air assault (user, 2026-10-19) - after the support fix workflow
- [x] CAS drone: after the run, fly on the egress heading to the nearest map edge and despawn off the map, not a few km past the target (user, 2026-10-19) - after the support fix workflow
- [x] MEDIC app + tile (user, 2026-10-19): for CLS/Medic skill holders; tile = squad wounded count (red on arrest / bleeding out); app = squad patient list worst-first, patient page with pulse, BP, SpO2, respiration, blood type (ACM), blood volume, pain, airway/pneumothorax, wounds per body part, tourniquets/splints/IVs, SHOW ON MAP. Data: ACM (circulation BloodType, breathing RespirationRate, pulse oximeter, pressure cuff) + ACE medical. [?] live vs device-gated (default device-gated). Queued after the tablet layout workflow.
- [x] Map tools rebuilt in-house (PLP MapTools feature set: ruler, protractor, centre, mark, grid, viewshed, route, clear) - `addons/maptools`, 2026-10-20, not run in game
- [x] Notification line on the tablet mirroring popups, with the log on click
- [x] Frame keys: F1-F4 and arrows are mouse buttons over the printed keys on every frame; F1-F4 open apps set per player; keyboard F1-F4 not taken (user, 2026-10-19)

## 2. Phone and side devices (walking view)

- [x] GPS-slot items phone / side / side2, UAV-terminal ground model, in the testing arsenal
- [x] Title-layer overlay, toggle Ctrl+End, phone bottom centre, side left/right via ACE
- [x] Status row (text labels), notification line (mirror), net cells from TFAR, map
- [x] Map follows the player every frame, zoom setting, own icon in accent colour
- [x] Net-row script error fixed
- [ ] Check in game that a map inside a title layer renders and follows (main unknown)
- [x] Status row NET, MESH, JAM, GPS, DRONES, MSG; [ ] FIRES, BATT sources
- [x] **Tablet bar GRID from the GPS** (done 2026-10-20) (EW work 2026-10-20 left the devices files to their owner): in `addons/devices/functions/fnc_tabletBar.sqf`, the `GRID %2 %3` half of `_facts` (built from `mapGridPosition _unit` split in two) becomes `GRID %2` with `[_unit] call jmfsb_ew_fnc_gpsGrid` when `!isNil "jmfsb_ew_fnc_gpsGrid"` - it returns "041 116", "041 116 SUSPECT" or "NO FIX" (the false grid when spoofed). The phone/side status row GPS cell could read `jmfsb_ew_fnc_gpsState` the same way
- [x] Squad list with TX / VOX / + / ·· and who-is-talking chip; [ ] ★ buddy
- [x] 25 m / 50 m rings; [ ] drone, jammer, target marks
- [x] Net cells green/red/grey from RF; [ ] R receive-only (needs EMCON in the client slice)
- [x] Hidden in arsenal, dead, spectator (display ids to check in game)
- [x] Opacity setting 0.4-1; state saved per profile
- [x] Side devices: 2x4 status, squad list and nets in 2 columns
- [x] Phone/side settings live in the tablet's SETTINGS > DEVICES; no ACE actions on phone or side (user, 2026-10-20)

## 3. BFT member icons

- [x] Body + pointer in team colour, outline, number inside (upright), name + skill tags beside
- [x] `jmfsb_bft_fnc_memberNumber`
- [x] Voice rings from TFAR (red radio, magenta direct), setting, unconscious at half alpha
- [ ] Check text centring of the number in game
- [?] Ring colours: red = radio, magenta = direct (doc's assumption, unconfirmed)
- [ ] Group (NATO) markers smaller on the phone - not possible per map; they are markers

## 4. Tablet apps (DESIGN_TABLET_APPS)

Registered today: comms, squad, weather, scanner, drones, jam, timer, radio, hack, intel, support, settings.

| App | State |
|---|---|
| RADIO | [x] NETS / CALLS / FILL boards, nets via adapter_tfar (2026-10-20); [ ] DIAL / HANG UP / NOTE (no call service) |
| SQUAD | [x] exists; [ ] member icons + numbers, MEMBER detail page |
| TIMER | [x] exists; [ ] alarms shared with section per design |
| WEATHER | [x] exists; [ ] FORECAST effect on drones/CAS, LIGHT |
| DRONES | [x] FLEET / FEED (r2t camera) / CONNECT, TAKE CONTROL, ORBIT, MARK (2026-10-20); [x] GO TO (map pick), LASE, RTB, Drone40 mode switches (2026-10-20, not run in game) |
| HACK | [x] NODES IN REACH from RF, ACTION, LOG (2026-10-20); [x] SPOOF on a unit's net or a set-carrying vehicle, through jmfsb_ew's spoof engine (2026-10-20, not run in game) |
| INTEL | [x] exists |
| SETTINGS | [x] exists; [x] DEVICES + DEVICE KEYS sections (2026-10-20); [ ] DISPLAY |
| FIRES | [x] TAC//SUPPORT covers it: virtual artillery, cruise, loiter, Simplex-style requests (2026-10-20) |
| EW | [x] TAC//EW app: OVERVIEW / ES / EA / EP (2026-10-20, standalone app until an RF app exists); [x] OVERVIEW GPS reads NO FIX too (2026-10-20) |
| RF (OVERVIEW, NETS, MESH, ES, EA, EP) | [ ] new (needs RF base) |
| PAC | [x] tile/app and admin page inside the tablet (2026-10-20) |
| TIC | [x] exists (ticSend); [ ] one-touch answers + pre-filled FIRES call |
| ADMIN | [x] admin strip exists; [ ] GROUPS · BFT CODES, RF controls |
| AUGUR | [ ] new (assistant) |

## 5. Messaging (PLAN_MESSAGING_UI.md)

- [x] Notifications: popups stay upper right; corner setting; hide setting
- [x] Colour steps derived from the three scheme tokens
- [x] Report forms fidelity pass (CUR LOC / MARKER cells, accent tags, REQ outline, one-tap replies); [?] accent tag vs FLASH; REMARKS gaps logged at load
- [x] Thread view three panes, tabs, quick replies, FLASH banner; [ ] ACK tab = unread until the index tracks per-player acks
- [x] Combat support 2a/2b: guidance labels, row states, steppers, 5 ROE, RTB double confirm, passengers (aboard now), map overlay; tabs per type, READY checklist + verdict, range rings, plan markers, Simplex-style tasks (2026-10-20)
- [ ] Voice messages (15 s) - BLOCKED: needs record/play in the TFAR standalone DLL + voice-server, which is ltsammy's repo and not ours to edit (user, 2026-10-20). Design kept in docs/DESIGN_VOICE_MESSAGES.md in case he adds it
- [ ] Admin console restyle (GPL-3 addon, last)

## 6. TAC//NET (SPEC_TACNET milestones)

| # | Milestone | State |
|---|---|---|
| 0 | Toolchain: HEMTT, TFAR standalone, relay, test server | [x] HEMTT; TFAR removed 2026-10-20, voice is VON; [?] relay/test server not checked here |
| 1 | RF core: registry, link budget, mesh, rf_link, DF | [x] addons/rf + adapter_tfar + adapter_acre stub; ranges a third of design, MPU5 25 mW ~0.5 km/hop relayed, drone link 2 W; [x] DF in addons/ew (2026-10-20, not run in game) |
| 2 | Voice: game VON through jmfsb_voice / adapter_von (D14, 2026-10-20) | [x] channels, mesh-driven per-speaker volume, calls, callbacks, sounds, RADIO apps, numpad keys (D16); TFAR removed; [ ] in-game self test (jmfsb_voice_fnc_selfTest) |
| 3 | Radio on net: MPU5 items, fill, active/monitor, speaking dots | [x] MPU5 (SR + LR) and TW-950 items; [ ] fill, active/monitor; [x] MPU5 on the ground uses the vanilla radio model (2026-10-20) |
| 4 | Data on graph: BFT health, messaging, CAS tasks, notes via rf_reach; GPS domain | [ ] |
| 5 | Tablet shell | [x] mostly (section 1) |
| 6 | EW: emitters, DF, spectrum, jammer, three jam domains | [x] jam zones are RF noise (radio, data); [x] addons/ew: DF, tracks, barrage/spot/sweep/GPS jam, spoof, decoys, TAC//EW app + map layer (2026-10-20, not run in game); [x] GPS readers: BFT dots and group markers, map tools CENTRE / GRID, CUR LOC / pin / + GRID / TIC (2026-10-20, not run in game); [x] AI EW BASIC: enemy AI DF sensors, fix reaction through jmfsb_reaction, one-hop comms gate; ACTIVE / SMART fix dispatch only (drone / QRF) (2026-10-20, not run in game); [ ] rest of AI EW (ACTIVE / SMART EA and EP, mesh comms gate, HQ path), INSPECT/EXPLOIT, drone kill, hardware, drone navigation on the spoofed GPS |
| 7 | Drones + fires apps | [ ] |
| 8 | Phone, mini, vehicle shells | [x] phone + side + vehicle tablet |
| 9 | Play test | [ ] |
| 10 | DLL trim: RECORD/NOTE voice notes, per-pair hearing | [ ] - this is where the 15 s voice message lands |
| 11 | Hardware, hacking both ways, AUGUR, DIVINER swap | [ ] |

### Open questions from SPEC_TACNET
- [x] Simplex link for FIRES - no: no Simplex dependency; FIRES is our own `support_fires` (user, 2026-10-20)
- [x] Mini device: keep or drop - kept: the spec's mini (3:5, mini2_body_cut.png, keys along the bottom) is the side2 device already built (user, 2026-10-20)
- [x] RTO console: player job or admin-only - player job: MANAGE and the RTO column belong to the RTO role, one test `jmfsb_voice_fnc_isRto` used by radioRole (tablet + small-device MANAGE, CALLS FLASH) and canFlash; MANAGE actions still not built (user, 2026-10-20)
- [?] C2 membership; calls open or signal-plan restricted
- [x] A2G: who is air - pilots and copilots, by seat (user, 2026-10-20)
- [x] Vanilla UAV terminal: removed from the PAC arsenals; drones flown from our devices with the UAV trait (user, 2026-10-20)
- [x] MPU5 asset licence: settled, the licence is proper for this mod (user, 2026-10-20)

## 7. Other work done this session (outside the docs)

- [x] Drone40 Relay / Decoy / Jammer (GX) in addons/drone40; decoy inert until EW
- [x] Drone40 uses public RF calls (nodesFor, register data, pathLossFree)
- [x] Jammer drone is RF noise only; [?] not on the jam meter / scanner any more

- [x] AiTR compass (DUI style, heading in accent colour, setting)
- [x] Arsenal: RPG-32, SPS M27, Alpine fatigues removed; devices in the testing arsenal
- [x] Extended arsenal: OCP option on in-mod backpack groups
- [x] Common arsenal backpacks: base game and DLC out, radio bags in (applied 2026-10-19, backups in D:/Git/_jmsb_db_backup_2026-10-19)
- [x] DB boot speed: unscheduled parse, read-once cache, no poll sleep, throttled checklist, timing in RPT; [?] pacdb request ids / getMany (DIVINER extension)
