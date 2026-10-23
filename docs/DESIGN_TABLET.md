# Tablet and vehicle tablet - design

Devices: large tablet (always available) and vehicle tablet (every vehicle). Spec: [SPEC_DEVICES.json](SPEC_DEVICES.json).
Status: design, for code. Date 2026-10-19.
Apps: [DESIGN_TABLET_APPS.md](DESIGN_TABLET_APPS.md). Member icons: [DESIGN_BFT_MEMBERS.md](DESIGN_BFT_MEMBERS.md).
Canvas: TAC//APP Tablet (artifact AF6PUzUbiRWvj8nkhgHd2A).

## What it is

The native DIVINER map screen (tacpad) ported into a device. Same panels, same tiles, same apps. Used when the CBA display mode is TABLET. Opened with ACE self-interaction (large tablet) or from a crew seat (vehicle tablet). ESC closes.

## Images

In game, 1080p:

![tablet in game](../art/images/tablet_ingame.png)

Screen (1364 x 1000 design px):

![tablet screen](../art/images/tablet_screen.png)

Vehicle tablet in game:

![vehicle in game](../art/images/vehicle_ingame.png)

Messaging (TAC//MSG reader, compose, templates) is left out of this design.

## Size and placement

| | Large tablet | Vehicle tablet |
|---|---|---|
| Frame texture | `tablet_body_cut.png` 1874 x 1312 | `vehicle_body_cut.png` 2030 x 1562 |
| Glass rect in texture | 171,105 - 1682,1213 (1511 x 1108) | 268,285 - 1779,1393 (1511 x 1108) |
| Frame at 1080p | 1485 x 1040, centred, top 20 | 1352 x 1040, centred, top 20 |
| Screen at 1080p | 1198 x 878 (scale 0.878) | 1006 x 738 (scale 0.738) |

- One screen design: 1364 x 1000 px. Both glasses are the same size in the texture, so the same content fits both.
- "As large as possible": frame height = screen height minus 40 px. Use `safeZone`.
- Frame textures have the glass cut out; content draws under the frame.

## Layout (top to bottom, design px)

| Row | Height | Content |
|---|---|---|
| Device bar | 34 | TAC//APP, time, grid, callsign · group, device, battery, "ESC closes" |
| Notification line | 30 | count, newest line, time. Click opens the log |
| Live tiles | 96 + 3 rule | 8 tiles: NET, MESH, EW, DRONES, FIRES, HACK, TIMER, PAC |
| Map area | rest (~789) | map control with floating panels |
| Net row | 48 | nets you are on, name + ear tag; numpad 0 / . move the active net |

### Map area

A real map control: pans, zooms, takes marker clicks. Panels float on it like native.

| Panel | Place | Content |
|---|---|---|
| Squad rail | top left, 290 wide | BFT member icon + name + role + talk flag + link dot; LINK legend; NODES ON C2 |
| Who is talking | top, right of the rail | `<N> <NAME> on <NET>` |
| Button strip | top right, 410 wide | TOOLS, SETTINGS, ADMIN, HIDE |
| TROOPS IN CONTACT | under the strip | red, full width of the column |
| Map tools | under TIC | 4 x 3: RULER, PROTRACTOR, CENTRE, MARK / NET COVER, DF CUTS, JAM FIELDS, TRACKS / GRID, VIEWSHED, ROUTE, CLEAR |

Map layers drawn: own squad (BFT member icons), other groups (BFT NATO markers), C2 net cover, jam fields, DF bearings, drones, targets.

Differences from native:

- No vanilla map menu (the device has none).
- Clicking the map does not close the page; ESC does.
- Panels are not draggable on the tablet; their places are fixed above.
- Notifications go to the notification line, not upper right.

### Vehicle tablet

Same screen and apps. Two changes in the left rail:

- **ON BOARD** instead of the squad: everyone in the vehicle with seat (CMDR, DRV, GNR, PAX).
- **VEHICLE SET** instead of NODES ON C2: gateway state, power, relay count, mast.

Device bar says `VEHICLE · <vehicle callsign>`.

## Colour schemes

Same four as the tacpad theme (`ghostD_tacpad_fnc_theme`): light, olive, sand, night. Tokens: ground, ink, accent, plus line and dim derived. The map ground is a fourth token (`mapg`).

| Scheme | Ground | Ink | Accent |
|---|---|---|---|
| light | `#f3f2f2` | `#201e1d` | `#ec3013` |
| olive | `#e8e7e2` | `#16281d` | `#7d8f24` |
| sand | `#efece4` | `#2b2119` | `#b8741a` |
| night | `#141514` | `#e6e5e2` | `#ff563c` |

Status colours (all schemes): good `#2f8a3c`, weak `#d99427`, poor/hostile `#c62828`, own signal `#1e6fb8`, unknown `#8a3fc0`.

## Keys on the frame

F1-F4 and the arrows printed on the frame are mouse buttons over the art (user, 2026-10-19). F1-F4 each open an app the player picks in the settings ("F1 key on the tablet opens" ...); clicking again closes it. The arrows step through the apps, and the keyboard's arrow keys do the same. The keyboard's F1-F4 are not taken - they keep selecting units.

## Build notes

- One dialog per device class; the screen is a controls group scaled into the glass.
- Reuse tacpad's panel code (`build`, `place`, `drawHit`, `openApp`, `appClose`) with a tablet layout table instead of safe-zone defaults.
- Apps open as a page over the map area (tiles and net row stay). See the apps doc.
- Member icons: hook `ghostD_bft_fnc_drawMembers` on the tablet's map control.
