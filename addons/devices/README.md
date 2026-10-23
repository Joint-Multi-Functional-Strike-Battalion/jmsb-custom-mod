# Devices

`jmfsb_devices`

The device shells: a rugged tablet today, with a vehicle set, a phone and two
side devices to follow on the same mechanism. In TABLET display mode
(`jmfsb_tacpad_displayMode`) the tacpad suite comes off the map screen and is
drawn inside a device instead; the vanilla map becomes a plain map.

## How a device hosts the suite

The shell (`jmfsb_tacpad`) draws wherever its **host** says: a display and a
rectangle, set by `jmfsb_tacpad_fnc_setHost`. On the vanilla map that is display
12 and the safe zone. A device is a dialog with a frame texture and a map
control; at open it computes where its screen rectangle lands on this monitor,
hands the dialog and that rectangle to the shell, and calls the shell's own
`open`. Every panel, app and reader then lays itself out inside the screen the
way it does inside the safe zone, scaled by the ratio of the two - see
`HOST_*` in `tacpad/shared.inc.hpp`. Nothing in the suite was rewritten for the
device; it was taught where it is.

The map control carries idc 51, which is the map's idc on the vanilla map
display, so the shell's `displayCtrl 51` finds the right map on either host
without knowing which one it is on.

## The tablet screen

On the large tablet, the UAV tablet and the vehicle tablet the screen is cut
into the rows of docs/DESIGN_TABLET.md ("Layout", in design px of a 1364 x 1000
screen), by `fnc_tabletRows`:

- **Device bar** (34) - TAC//APP, the time, `GRID <easting> <northing>`,
  callsign · group on the left; the device right-aligned beside ESC CLOSES,
  which is in the accent. The vehicle tablet's device reads
  `VEHICLE · <callsign>` (`fnc_vehicleName`: the vehicle's variable name, else
  its crew's group when that is not the player's, else the class name).
- **Notification line** (30) - the unseen count as a solid accent cell
  (nothing when nothing is new), the newest entry's title in the accent and
  its text in ink, its time. A mirror: the popups stay upper right in every
  mode. Clicking it closes any app and turns the docked reader to its LOG view
  (`fnc_tabletLog`), building the reader first if the player switched it off.
- **Live tiles** (96 + a 3 px rule) - tacpad_apps' own tile band, drawn one
  row wide (`jmfsb_tacpad_apps_fnc_panelTiles` with its row flag), asked
  every two seconds and redrawn only when `tileData` has changed; the band
  panel itself is not built on the tablet.
- **Map area** (the rest) - the map control, and the shell's host. Panels and
  apps lay out inside it, so an app opens over the map and the rows stay.
- **Net row** (48) - one square cell per voice net the player is on, from
  `fnc_overlayNets` (the voice API's `jmfsb_voice_fnc_netState`), the same
  nets the walking view shows, with `0 <` and `> .` at the ends for the device
  arrows that step the active net. A dark (ink) row: idle cells ink with light
  labels, the active net filled with the ground, a muted net's name dim, the
  ear (L / B / R) as a small tag. Outline green when the net is reachable, red
  when it is not (never hidden); a ringing call with no call net yet is a RING
  cell in the alert colour.
- **Who is talking** - a dark chip at the top of the map area, right of the
  rail (`fnc_tabletTalk`, from `fnc_overlayTalker`, as on the walking view):
  the member's number and name, `on <NET>` and the net's ear; RINGING and the
  caller while a call rings. Hidden when nobody is talking and while an app
  page is open.

The rows are drawn by `fnc_tabletChrome` and kept by `fnc_tabletTick` every
half second, each row redrawn only when what it says has changed. The rows'
grounds are tacpad theme tokens; the net outlines and the chip use the walking
view's fixed status colours.

**Fixed panel places.** The device hands the shell a layout table with the
host (`jmfsb_tacpad_fnc_setHost`, third argument), and the shell's `place`
uses it in place of the safe-zone defaults: squad rail top left, the button
strip (TOOLS, SETTINGS, ADMIN, HIDE) top right, TROOPS IN CONTACT under it,
map tools and the reader below, the talking chip right of the rail and APS
under it. A panel mapped to `[]` is not built on the device. The table is
`TABLET_PLACES` / `TABLET_PLACES_VEHICLE` in `script_component.hpp`. The
panels then fit to the type size, so the right-hand column is stacked from
their real bottoms (`fnc_tabletStack`, at open and on the row tick): map tools
under TROOPS IN CONTACT, the reader under the map tools and down to the foot
of the map area. Only the three tablets wear this dialog - `fnc_open` refuses
the phone and side devices, which are the walking view only. A change of
display mode closes the tablet.

## The vehicle tablet

**ACE self-interaction > Vehicle tablet**, from any seat of a land vehicle,
an aircraft or a boat, in tablet mode - not a static weapon or a parachute
(`VEHICLE_TABLET_EXCLUDED`; `fnc_open` refuses them too). It opens the
`vehicle` frame for that vehicle and closes when the player leaves it. The
left rail is **ON BOARD** (`fnc_panelOnBoard`, a shell panel) in place of the
squad rail, at the rail's height: everyone aboard as the squad rail draws a
man - medical icon, name, seat (CMDR, DRV, GNR, PAX), TX / VOX - under a
header with the vehicle's callsign and the seats taken.

**VEHICLE STATUS** (`fnc_appVehicle`) is the vehicle tablet's own app, and
it exists only there: `fnc_onLoad` registers it with the shell when the
dialog wears the vehicle frame and `fnc_onUnload` takes it out, so the large
and UAV tablets, the phone and the native map have no tile for it, no F-key
opens it and the arrows (with no voice addon, when they step the apps) do not
pass through it. The **VEHICLE** live
tile (`fnc_vehicleTile`, through tacpad_apps' `tileProviders`; listed in
`tileUngated`, so a mission's role `tiles[]` cannot hide it - the vehicle
tablet is its gate) opens it, as does an F-key set to it. One
page, three columns, read-only, redrawn every two seconds while open:

- **Damage** by part group from `getAllHitPointsDamage` (hull, engine, fuel,
  optics, turret, gun, tracks / wheels, rotors, avionics, controls, armour,
  glass, other), each group as bad as its worst part, worst group first.
  **Fuel** and a rough **range**, measured from fuel burnt over ground covered
  since the last refill, partial ones included (`fnc_vehicleFuel`; MEASURING
  until there is enough of both).
- **Ammunition** per turret and weapon from `magazinesAllTurrets`, rounds and
  magazines; the `[-1]` seat reads DRIVER, or PILOT on an aircraft.
  **Countermeasures** (smoke, flares) counted apart: a `shotCM` magazine is
  smoke when a `SmokeLauncher` takes it, a flare otherwise.
- **APS**: fit, charges by side, launcher and RF holds and the burst's
  cooldown, read off the vehicle (`jmfsb_aps_fnc_charges` and its variables);
  the switches stay on the APS panel. **Voice nets**: the nets the player is
  on while aboard, from the voice API (`fnc_vehicleRf`) - VEH, the crew
  intercom on VON's Vehicle channel, among them - each ACTIVE / INTERCOM / MON
  or NO ROUTE. There is no radio rack any more: VON has channels, not sets.
  **Crew** last, from `fnc_vehicleSeats`
  (the read ON BOARD draws too): the crew seats one row each, passengers
  folded into one PAX row with only the hurt ones listed, worst first.

Green and amber are the theme's swatches, drawn only as fills (a bar, a square
beside an ink value); red is an inverted accent block with a word in the value
(CRIT, LOW, EMPTY, KIA, NO ROUTE, DESTROYED), because the accent is red only on
some schemes.

## Frames

`data/<device>.paa` are 2048² RGBA textures: the render at native resolution,
centred, with the background and the screen interior cut to transparent.
`frames.hpp` carries, per device, where the device body sits inside the canvas
and where its screen is, as canvas fractions. Both files are **generated** by
`tools/gen_devices.py` from the renders in `art/devices`; the screen
rectangle is measured off the image rather than typed. The hole is cut square out to the
frame's straight inner edge, through the black bezel band, so the screen meets the frame on
four sides with no dark gap and no rounded corner over it (user, 2026-10-20). Re-run the
generator after replacing a render; never hand-edit either output.

The device **body** is what is fitted to the monitor, not the canvas - the
large tablet is 64% of its canvas tall, and fitting the canvas would draw it at
two thirds of the size it could be.

## Keys and the way in

THE NUMPAD IS THE DEVICE'S KEY BLOCK (docs/SPEC_TACNET.json D16; user,
2026-10-20: "we are not using keyboard F1-F4, we are using numpad"). Every key
is a CBA keybind in the JMSB category, rebindable in Configure Addons:

| Numpad | Keybind | Walking view | Tablet open |
|---|---|---|---|
| 1 2 3 4 | Device button F1-F4 | the button's setting - accept call, ear / quick add, mute, decline / hang up by default; the RADIO app's soft keys while it is open | the frame's F1-F4: the app each is set to |
| 0 / . | Device button left / right | active net left / right (quick-add cursor; the RADIO app's cursor) | active net left / right (no voice addon: round the apps) |
| 5 | Open Tablet | opens the tablet; in a drone's seat, releases the drone | closes it |
| 6 | Device RADIO app | RADIO app on the phone / side device | the tablet's RADIO app |
| 7 / 8 | Device previous / next tab | the RADIO app's tabs | RADIO's tabs while it is open |
| 9 | Troops In Contact (`jmfsb_tacpad_apps_ticKey`) | sends TIC | sends TIC |

CBA's keys do not reach the mission display under a dialog, so the tablet's
`fnc_keyDown` matches each press against the player's own bindings
(`CBA_fnc_getKeybind`) and runs the same action; a focused text box keeps
every key, numpad digits included.

- **Open Tablet** - numpad 5 by default (it was Ctrl+Home). Toggles.
- **ACE self-interaction > Tablet** (top level) - shown only in tablet mode. With
  **Vehicle tablet** on a vehicle, the only ACE actions this addon adds.
- ESC closes it, like any dialog. The first ESC closes an open app, the second
  the tablet - the shell's own ESC handler runs first.

- The F1-F4 and arrow keys printed on the frame are mouse buttons over the
  art, and numpad 1-4 / 0 / . press them: F1-F4 open the app each is set to
  (`jmfsb_devices_keyF1`..`F4`, in Addon Options or on the tablet, SETTINGS >
  DEVICE KEYS), the arrows step the active voice net (`fnc_softKey`). The
  keyboard's own arrows and F1-F4 are not taken any more.
- The **map** is placed with `ctrlMapSetPosition`, not `ctrlSetPosition`: the
  control is declared 0 x 0, and a map moved with `ctrlSetPosition` keeps its
  declared viewport, so a centre put on it lands off the middle.

## The walking view: phone and side devices

Three GPS-slot items - `jmfsb_devices_phone`, `_side`, `_side2` - each the
vanilla `ItemGPS` under a JMSB name, so they replace the vanilla GPS in the
slot and keep its behaviour. While one is **assigned** and the display mode is
TABLET, its frame is drawn on screen as a **title layer** (`overlay.hpp`,
`jmfsb_devices_overlay`): read-only, no clicks, over the world. The phone is
bottom centre at the **Phone size** setting; a side device sits against the
left or right edge, vertically centred, at the **Side device size** setting.
`fnc_overlayLayout` places it the way `fnc_layout` places the tablet - body
fitted, canvas square via pixelW/pixelH, screen rect from `CfgJmfsbDevices`.

On the screen, rows cut from the design's units (`fnc_overlayRows`;
docs/DESIGN_PHONE_WALKING.md, DESIGN_SIDE_DEVICES.md):

- **No status cells and no notification line** (user, 2026-10-21). The rows
  sit inside a rim, clear of the frame's corner bumpers.
- **Header bar** on top, the tablet bar's facts (`fnc_deviceFacts`, shared
  with `fnc_tabletBar`): TAC//APP, time, the grid (`fnc_overlayGrid`: 6 or 8
  figures by **Device grid digits**, from the GPS - NO FIX red, SUSPECT amber),
  name . group, and the custom-channel gauge `CH n/10 %` (`fnc_channelText`,
  `jmfsb_voice_fnc_channelUse`). One line on the phone, two on a side device.
- **Call strip** along the map's bottom - call business only (`fnc_voiceLine`): `CALL from
  <name> - F1 accept - F4 decline` while one rings, `CALL 02:14 - <names> -
  F2 add - F4 hang up` in a call, `CALLBACK pending - <name>` while one waits,
  the F2 quick-add list, and for a few seconds a call's last word off
  `jmfsb_voice_callState` (no route / busy / no answer - CALL BACK is
  available, declined, dropped, bumped, ended; the FLASH priority warning
  outranks a live call). Hidden otherwise; notifications pop up top right only.
- **Map** - centred on the player every frame at **Phone map zoom**, his own
  icon, BFT's member icons, 25 m / 50 m rings. Over it on the phone: the
  **squad list** top left (`<N> <NAME>`, number in team colour from
  `jmfsb_bft_fnc_memberNumber`; flags TX red / VOX magenta from the voice
  API's talking list (`fnc_voiceTalkers`; a net of kind `direct` is VOX),
  `+` wounded, `··` no RF link) and the **talking box** top right: the last
  speaker's number and name, `on <NET>` and the net's ear, held four seconds;
  RINGING and the caller while a call rings.
  On a side device the chip is top left and the squad list sits under the map
  in two columns of three.
- **Nets** - one square cell per voice net the player is on, and only those
  (`fnc_overlayNets` over `jmfsb_voice_fnc_netState`: VEH inside a vehicle,
  CALL while a call is live; a captured key's net is not built), never a
  frequency. Outline green when the net is reachable, red when not - a net
  out of reach is never hidden; the active net filled light; a muted net's
  name dim; the ear (L / B / R) as a small tag at the cell's right; a RING
  cell in the alert colour while a call rings. Two columns on a side device.

Only one player carries one of the three; the phone wins if he has more.
**Device opacity** (0.4 - 1) fades frame and screen together. The shown /
hidden state and a side device's edge are kept in the player's profile
(`fnc_overlaySetShown`, `fnc_overlaySetEdge`).

**Centred on the player, every frame.** `fnc_overlayFollow` runs on the map's
Draw event and puts the map's centre on the man at **Phone map zoom**; his own
icon (`fnc_overlayDrawPlayer`) is drawn there. The map control is moved with
`ctrlMapSetPosition` (`fnc_overlayPlace`) - it is declared 0 x 0 at the top
left, and moved with `ctrlSetPosition` it kept that viewport, so the centre
landed on the old origin and the player was off the phone. With
`DEBUG_MODE_FULL` the follow logs the world position under the control's own
centre against the player's (`ctrlMapScreenToWorld`).

The layer is cut - not hidden - whenever a dialog or the map is up, an
arsenal (ACE or vanilla) or a spectator (ACE or vanilla) is open, the player
is dead, the item is unassigned, in native mode, and at mission end: a title
layer draws over every dialog and outlives the mission otherwise.
`fnc_overlayTick` (a CBA per-frame handler at half a second) is the one place
that decides.

- **Toggle Device** - CBA keybind, Ctrl+End by default (no numpad key was
  given to it). Hides and shows.
- **No ACE actions.** The phone and side devices have no ACE menu (user,
  2026-10-20); everything about them is on the tablet, **SETTINGS > DEVICES**
  (`fnc_settingsRows`, registered into tacpad_apps' settings app): the device
  in the GPS slot (a line), walking view shown / hidden, side device edge
  LEFT / RIGHT (applies at once to an open walking view), phone size, side
  device size, map zoom, opacity, member voice rings (`jmfsb_bft`), and
  **SETTINGS > DEVICE KEYS**: the tablet's F1-F4 and the six walking-view
  buttons. CBA settings are changed through CBA's setter, so they persist as
  Addon Options keeps them; one the server or mission forces reads LOCKED.
- **Device button F1 / F2 / F3 / F4 / left / right** - six CBA keybinds,
  numpad 1-4, 0 and . by default, for the six buttons printed on the phone
  and side frames. The walking view is a title layer and takes no mouse, so
  the keybind is the only way to press one; it acts only while the walking
  view is up (`fnc_overlayButton`), and a voice key with nothing to act on
  falls through to the game. What each does is its setting
  (`jmfsb_devices_buttonF1`..`buttonRight`): the voice keys (accept call, ear
  / quick add, mute the active net, decline / hang up, active net left /
  right - `fnc_voiceAction`), the RADIO app, map zoom in / out, side device to
  the left / right edge, hide the walking view, open the tablet, or open the
  tablet on an app. Defaults (docs/DESIGN_VOICE.md): F1 accept a call, F2 ear
  for the active net (during a call: the quick-add list), F3 mute the active
  net, F4 decline or hang up, left / right the active net. While the RADIO app
  is open they are its soft keys and cursor whatever they are set to.
  Push-to-talk is the voice addon's and not offered.

## Game voice on the devices

Voice is Arma 3's own VON through `jmfsb_voice`'s API (docs/DESIGN_VOICE.md);
this addon reads that API and names no radio mod. Every call into it is
guarded: without the voice addon the net rows are empty, the flags never show
and the voice keys fall through.

- **Quick add** (walking view, F2 during a call): a list on the notification
  line of the people of recent calls, then the player's group, then anyone in
  reach (`jmfsb_tacpad_apps_fnc_radioQuick`); 0 / . move, F1 adds
  (`jmfsb_tacpad_apps_fnc_radioDial`), F4 closes.
- **RADIO app on the phone and side devices** (numpad 6; `fnc_radioApp`,
  `fnc_radioRows`, `fnc_radioKey`, `fnc_radioDraw`): full screen on the
  carried device, drawn on the walking view over the map, squad list and net
  row, so the player keeps walking. It opens on CALLS while a call is live or
  ringing, on NETS otherwise. 0 / . move the cursor, 7 / 8 the tabs, the
  device keys are the soft keys shown along the bottom (phone) or in a 2 x 2
  grid (side devices, whose rows stack onto two lines):

  | Tab | F1 | F2 | F3 | F4 |
  |---|---|---|---|---|
  | NETS | MUTE | EAR | SET ACTIVE | BACK |
  | CALLS | ADD | CALL | GROUP + | HANG UP (BACK with no call) |
  | MANAGE | ADD | REMOVE | REKEY | BACK |

  A ringing call turns F1 / F4 into ACCEPT / DECLINE on every tab. CALLS lists
  the live call over the contacts (on the call, in reach, the rest) with
  ON CALL / + ADD / CALL / CALL BACK, and the group chips (+ TEAM, + SLs,
  + RTOs, + MEDICS, + HQ) that GROUP + moves the cursor onto. MANAGE is for
  leaders, RTOs and admins (`jmfsb_tacpad_apps_fnc_radioRole`) and lists the
  nets; its ADD / REMOVE / REKEY are not built, so F1-F3 are blank there.

## Flying drones without a UAV terminal

The vanilla UAV terminal is out of the arsenal (user, 2026-10-20), and the
engine's `connectTerminalToUAV` / `isUAVConnectable` both want one in the GPS
slot. So this addon flies drones itself, and every caller - the tablet's DRONES
board, the CAS drone's loiter handover, dtvd's view distance - goes through it:

| Function | Does |
|---|---|
| `jmfsb_devices_fnc_uavCan [uav, unit, needLink]` | the gate: `[may, why not, DATA quality]`. The UAV operator trait (`UAVHacker`, the same test that gives him the UAV tablet), the players' side (derived as the DRONES board does, D59), nobody else holding the drone, and the DATA link (an unknown link does not block, one under 0.2 does) |
| `jmfsb_devices_fnc_uavControl [mode, uav, seat]` | `"link"` / `"unlink"` - the board's CONNECT / DISCONNECT, one drone at a time, public on the drone as `jmfsb_devices_uavOperator`; `"take"` - closes the tablet or the map, then `player remoteControl` the gunner (else the driver) and `switchCamera` onto the drone, the way Zeus's remote control does; `"release"` - `objNull remoteControl`, the camera back on the player in the view he left in; `"linked"` / `"flying"` read the state |
| `jmfsb_devices_fnc_uavOperator [uav]` | who holds a drone: the linked player while alive and connected, else a vanilla terminal still connected to it, else nobody |
| `jmfsb_devices_fnc_uavOrder [order, uav, args]` | the drone's AI orders - `"orbit" [radius]`, `"goto" [pos, radius]` (MOVE at the drone's height, 50 m off the ground, then LOITER), `"rtb" [pos, radius]` (MOVE, then `land` for a helicopter-type drone, else LOITER), `"lase" [on, target]` (`lockCameraTo` the designator's turret and `BIS_fnc_fire` it on / off; the point public as `jmfsb_devices_uavLase`). Refusals (no laser, no point) come back on the caller as `[false, why]`; the rest is sent by CBA targetEvent `jmfsb_devices_uavOrder` to the machine that owns the crew. Who may order is the caller's gate (`uavCan`) |
| `jmfsb_devices_fnc_uavLaser [uav]` | the designator: `[weapon, turret]` - a turret weapon (the driver's as `[-1]`) whose magazine's ammo simulates `laserDesignate`, or one of the `Laserdesignator_mounted` / `Laserdesignator` families - else `[]`; cached per class |
| `jmfsb_devices_fnc_uavHome [uav, unit]` | RTB's home, `[pos, label]`: the drone's public `jmfsb_devices_uavHome` (jmfsb_drone40 sets it to the launcher's position; `"link"` sets it when the drone is linked sitting on the ground), else the nearest staging zone (`jmfsb_mission`) or patrol base of the players' side (`jmfsb_patrol_base`), else the unit |
| `jmfsb_devices_fnc_uavTick` | every 0.5 s: drops the link on death or when the gate stops letting him have the drone (gone, hacked to another side, trait lost, taken); gives the seat back on a lost DATA link, a lost seat, unconsciousness, or the camera coming back to him on its own |

The way out from inside the drone: **Release drone control** in its action
menu, or the tablet key (numpad 5). The seat is also given back at mission
end. No terminal class was made: `UavTerminal_base` items are side-locked, and
a terminal brings back the vanilla terminal UI the user took out. Not run in
game.

## Not yet

The small devices' RADIO app takes no mouse (the walking view is a title
layer), and its MANAGE has no member actions: the voice API has no call for
them. Per-net beep volume is not on the devices. The tablet has no battery in
the bar and no link dot on the rails. Map tools are `jmfsb_maptools`', on the tablet's screen
through the MAP TOOLS strip. The vehicle tablet has no VEHICLE SET panel yet (VEHICLE STATUS shows
the voice nets aboard but not gateway, power, relays or mast). FIRES has no provider and BATT has no model. Drones, jammers and
targets are not marked on the walking map, and there is no buddy flag. The
walking view, the numpad keys and the RADIO apps have not been run in game. The support-request dialog keeps its
monitor-size geometry on both hosts.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `cba_xeh` _(external)_

## Ships

3 weapon/item classes, 72 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_devices_keyF1` | LIST | F1 key on the tablet opens |
| `jmfsb_devices_keyF2` | LIST | F2 key on the tablet opens |
| `jmfsb_devices_keyF3` | LIST | F3 key on the tablet opens |
| `jmfsb_devices_keyF4` | LIST | F4 key on the tablet opens |
| `jmfsb_devices_tabletFill` | SLIDER | Tablet size |
| `jmfsb_devices_phoneFill` | SLIDER | Phone size |
| `jmfsb_devices_phoneZoom` | SLIDER | Phone map zoom |
| `jmfsb_devices_sideFill` | SLIDER | Side device size |
| `jmfsb_devices_overlayOpacity` | SLIDER | Device opacity |
| `jmfsb_devices_buttonF1` | LIST | Device button F1 |
| `jmfsb_devices_buttonF2` | LIST | Device button F2 |
| `jmfsb_devices_buttonF3` | LIST | Device button F3 |
| `jmfsb_devices_buttonF4` | LIST | Device button F4 |
| `jmfsb_devices_buttonLeft` | LIST | Device button left |
| `jmfsb_devices_buttonRight` | LIST | Device button right |
| `jmfsb_devices_tabletFrame` | LIST | Tablet frame |
| `jmfsb_devices_gridDigits` | LIST | Device grid digits |

## Functions

<details><summary>72</summary>

- `jmfsb_devices_fnc_appVehicle`
- `jmfsb_devices_fnc_channelText`
- `jmfsb_devices_fnc_close`
- `jmfsb_devices_fnc_deviceFacts`
- `jmfsb_devices_fnc_keyButtons`
- `jmfsb_devices_fnc_keyDown`
- `jmfsb_devices_fnc_layout`
- `jmfsb_devices_fnc_netOutline`
- `jmfsb_devices_fnc_netSelect`
- `jmfsb_devices_fnc_onLoad`
- `jmfsb_devices_fnc_onUnload`
- `jmfsb_devices_fnc_open`
- `jmfsb_devices_fnc_overlayButton`
- `jmfsb_devices_fnc_overlayClose`
- `jmfsb_devices_fnc_overlayDevice`
- `jmfsb_devices_fnc_overlayDraw`
- `jmfsb_devices_fnc_overlayDrawRings`
- `jmfsb_devices_fnc_overlayFollow`
- `jmfsb_devices_fnc_overlayGrid`
- `jmfsb_devices_fnc_overlayHidden`
- `jmfsb_devices_fnc_overlayLayout`
- `jmfsb_devices_fnc_overlayNets`
- `jmfsb_devices_fnc_overlayOpen`
- `jmfsb_devices_fnc_overlayPlace`
- `jmfsb_devices_fnc_overlayProviders`
- `jmfsb_devices_fnc_overlayRf`
- `jmfsb_devices_fnc_overlayRows`
- `jmfsb_devices_fnc_overlaySetEdge`
- `jmfsb_devices_fnc_overlaySetShown`
- `jmfsb_devices_fnc_overlaySquad`
- `jmfsb_devices_fnc_overlayStatus`
- `jmfsb_devices_fnc_overlayTalker`
- `jmfsb_devices_fnc_overlayTick`
- `jmfsb_devices_fnc_overlayToggle`
- `jmfsb_devices_fnc_panelOnBoard`
- `jmfsb_devices_fnc_radioApp`
- `jmfsb_devices_fnc_radioDraw`
- `jmfsb_devices_fnc_radioKey`
- `jmfsb_devices_fnc_radioRows`
- `jmfsb_devices_fnc_settingsRows`
- `jmfsb_devices_fnc_softKey`
- `jmfsb_devices_fnc_tabletBar`
- `jmfsb_devices_fnc_tabletChrome`
- `jmfsb_devices_fnc_tabletLog`
- `jmfsb_devices_fnc_tabletNets`
- `jmfsb_devices_fnc_tabletNotify`
- `jmfsb_devices_fnc_tabletRadioTab`
- `jmfsb_devices_fnc_tabletReframe`
- `jmfsb_devices_fnc_tabletRows`
- `jmfsb_devices_fnc_tabletStack`
- `jmfsb_devices_fnc_tabletTalk`
- `jmfsb_devices_fnc_tabletTick`
- `jmfsb_devices_fnc_toggle`
- `jmfsb_devices_fnc_uavCan`
- `jmfsb_devices_fnc_uavControl`
- `jmfsb_devices_fnc_uavHome`
- `jmfsb_devices_fnc_uavLaser`
- `jmfsb_devices_fnc_uavOperator`
- `jmfsb_devices_fnc_uavOrder`
- `jmfsb_devices_fnc_uavTick`
- `jmfsb_devices_fnc_vehicleAmmo`
- `jmfsb_devices_fnc_vehicleColumn`
- `jmfsb_devices_fnc_vehicleDamage`
- `jmfsb_devices_fnc_vehicleFuel`
- `jmfsb_devices_fnc_vehicleLines`
- `jmfsb_devices_fnc_vehicleName`
- `jmfsb_devices_fnc_vehicleRf`
- `jmfsb_devices_fnc_vehicleSeats`
- `jmfsb_devices_fnc_vehicleTile`
- `jmfsb_devices_fnc_voiceAction`
- `jmfsb_devices_fnc_voiceLine`
- `jmfsb_devices_fnc_voiceTalkers`

</details>
