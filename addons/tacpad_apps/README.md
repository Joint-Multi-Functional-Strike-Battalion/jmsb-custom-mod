# Tacpad Apps

`jmfsb_tacpad_apps`

The four panels that sit on the map screen, each with its own switch.

| panel | what it is | source |
|---|---|---|
| **LIVE TILES** | the top band — kicker, one big live value, one detail line; clicking a tile opens that app | drones and jam off `jmfsb_hacking`'s scanner, weather off the engine, radio stubbed |
| **SQUAD** | the left rail — one row per man with a health swatch | ACE medical where present, engine damage where not |
| **TAC//MSG READER** | the docked reader — threads newest first, precedence first in the eye | `jmfsb_messaging`'s index |
| **MAP TOOLS** | the bottom strip | a front end for `jmfsb_maptools` |

**The band is aligned to its neighbours**: it starts where the squad rail's right
edge is and ends where the reader column's left edge is, so the three read as one
layout rather than three panels that happen to be near each other. Six tiles have
to fit that 0.562 of the safe zone, which is why `TILE_W` is 0.086 rather than
the design's 0.092 — at 0.092 the sixth tile ran through the reader's edge and
the band dropped it.

`jmfsb_tacpad_apps_tileRows` stacks the same tiles in **two rows** for a screen
where the rail and the reader have taken the width the band wanted; one row is
the design's and the default. The panel keeps whatever width it was dragged to,
so a two-row band is usually worth dragging narrower.

Six tiles: DRONES, JAM, **HACK**, WEATHER, RADIO, **TIMER** — the band's default width is
cut for exactly six. A tile that does not fit is not drawn at all, so a band
dragged narrower says `+N` at its right edge rather than quietly losing one.

**TIMER** is the archived cTab device's alarm page rebuilt, with a stopwatch
under it. The roster is armed alarms, soonest first — each a *running* clock and
not a rounded minute, numbered and named by whoever set them, red inside thirty
seconds and amber inside two — with `+1 / +5 / +10 MIN` to arm and a `DEL #N` per
row whose number is the number on the roster. It says RINGING while one is.

**The alarms are `jmfsb_hacking`'s, not this addon's.** They ring through its
handler, they are public so a section shares one roster, and the hand-held
scanner arms into the same list. Two alarm systems would be two sets of alarms
nobody could reconcile.

The stopwatch beneath is this addon's own and is a different tool — an alarm is a
mark you set for later, a stopwatch is a thing you time. It is three numbers in
`missionNamespace` read through `fnc_timerState`, so it is right whether or not
anything has been ticking, and it rings onto `jmfsb_common`'s alert bus locally.

The tile follows the same rule: an armed alarm counts the nearest one down,
because that is a thing that will happen to you; the stopwatch has the tile the
rest of the time.

## The EW scanner on a vanilla info panel — REMOVED

This addon used to carry a **Custom Info** panel resource for the EW readout —
the game's own side panels — plus a `scanPanelFoot` setting that turned one on
while walking. All of it is gone.

**It broke the vanilla info panels.** The component was never wired into any
vehicle (that patch was pulled earlier for blanking every panel in the game), so
`setInfoPanel` was being asked to select a component the player did not have.
Turning a panel on and then naming a component that is not there is what left the
built-in panels dead — a runtime call, not a config patch, which is why removing
the config the first time did not fix it.

The wiring cannot be done safely mod-wide either. Every vehicle writes its own
full component list — a helicopter has `SlingLoadDisplay`, a tank does not — so
adding one entry means transcribing BI's list per class, which goes stale the
first time they add a panel to anything.

**The readout lives on `jmfsb_hud` instead**, which is the same information on
the game screen in a box the player positions in Options > Game > Layout, and
owes nothing to BI's furniture.

**The EW SCANNER screen is not a tile — the DRONES and JAM tiles open it.**
Each of those answers its own question on the band (what is overhead, how bad the
jamming is) and both press through to the one page that holds the whole sweep.
They used to have a screen each, which was two half-views of one reading with no
way to see the rest of it; those two screens are gone and this is what replaced
them. It is the readout the archived cTab
device split across three pages — the whole sweep on one screen: air contact with
bearing, range and airframe, jamming level and what it has done to your net,
channel and frequency, mesh relays, armed alarms, and the last few entries off
`jmfsb_common`'s alert bus. It *presents* and does not measure: every number is
the same cached `jmfsb_hacking_fnc_scannerRead` sweep the tiles and the drone
screen read, so no two screens in the suite can disagree about what is overhead.
With the receiver taken off a unit it says NO RECEIVER rather than a page of
dashes. It is registered as the app `scanner`, and `["scanner"] call
jmfsb_tacpad_fnc_openApp` opens it from anywhere.

A fifth panel, **SETTINGS**, is the gear directly under the reader — one cell,
the whole strip wide, that opens a settings screen covering scheme, text size,
opacity, which panels are shown, reader density and a reset for panel positions.
It writes the same CBA settings Addon Options writes - through CBA's own
setter (`CBA_settings_fnc_set`, client source, stored), so there is one set of
values rather than two that can disagree. A setting the server or mission
forces is drawn read-only, LOCKED (`fnc_settingLocked`), and `fnc_setSetting`
refuses it. `fnc_settingStep` and `fnc_settingCycle` are the minus / plus and
previous / next presses for a slider and a list.

Another addon adds sections to the rail through
`jmfsb_tacpad_apps_settingsSections` (`[key, label, rows code]`, pushed in its
preInit). `jmfsb_devices` adds **DEVICES** - the device in the GPS slot,
walking view shown, side device edge, phone and side device size, map zoom,
opacity, member voice rings - and **DEVICE KEYS** - the tablet's F1-F4 and
the walking view's six frame buttons - since the phone and side devices have
no ACE menu.

The scheme section's **MISSION PRESETS** row is the mission's own, not the mod's.
A unit writes a row of ready-made palettes into its
`config\config_tacpad.hpp` — a `JMFSB_TacpadSchemes` class, one entry per
preset, each a `name` and the three tokens `ground`, `ink` and `accent` in hex —
and everyone in that mission gets the same cards, drawn exactly like the shipped
six. It is read once per mission by `jmfsb_tacpad_apps_fnc_missionSchemes`; a
mission with nothing to say about colour draws no row at all.

**A mission preset *is* the custom scheme.** Pressing one writes the three custom
tokens and switches the scheme to `custom`, so nothing downstream learns a
seventh scheme name that would mean nothing in the next mission — which is also
why the card says ACTIVE on the tokens matching rather than on a name. Without
it the only way to a unit palette was twenty people reassembling the same three
colours by hand off the swatch strips.

A sixth, **PANELS**, is HIDE ALL and the SHOW ALL that undoes it. It is its own
panel because of what it survives: it was a second cell inside the settings
strip, and the strip had to be pinned against the master switch for it — so
hiding the suite left a gear on the map with nothing left to configure. Split,
HIDE ALL takes the gear with everything else and leaves exactly one control
behind, drawn in the accent so it can be found without hunting.

A seventh, **CONTACT**, is the TROOPS IN CONTACT button under the rail — the one
control in the suite that is loud on purpose. One press files the deck's own TIC
report on the command net, which is what marks the map for your side, alerts
every player on it and opens the thread: the engine already does all three off
the template's broadcast flag, so a TIC fired from the button is identical to one
filled in by hand. The marker and the alert carry the same label, `TIC <callsign>
<time>`, because a mark and the shout that sent you to it have to be the same
contact. It holds for 30 seconds after a press — a man under fire presses a big
red button more than once, and one contact is one report. The **Troops In
Contact** keybind (`jmfsb_tacpad_apps_ticKey`) is numpad 9 by default since the
numpad became the device's key block (docs/SPEC_TACNET.json D16, 2026-10-20);
the tablet dialog passes it through (`jmfsb_devices_fnc_keyDown`).

Every list in the suite is drawn by `fnc_row`, so the roster, the traffic list
and the tool strip cannot drift apart in padding, type size or divider weight —
which is exactly what happens when three panels each draw their own.

## Map tools are jmfsb_maptools'

The strip is a front end. CENTRE, RULER, PROTRACTOR, ROUTE, MARK, GRID,
VIEWSHED and CLEAR are `jmfsb_maptools`' (see its README); the strip starts and
stops them, hangs them on the host's map (`jmfsb_maptools_fnc_attach`) so they
work on the vanilla map and the tablet's screen alike, and lights the running
one. CANCEL on its title bar stops whatever is running. There is no other mod
behind it any more - PLP Map Tools Remastered is gone - and a build without
`jmfsb_maptools` has no strip and no MAP TOOLS settings section, rather than a
strip of dead buttons.

## Hue is the data, once

Squad health is the one place in the system allowed to break the near-mono rule:
green up, amber wounded, grey unconscious, black killed. A player scanning the
rail is looking for the row that is not green, and colour answers that in a
glance where a number does not. Everything else is ink on ground with the accent
reserved for selection, FLASH traffic and alert states.

## Reading beside the map, sending in the app

Clicking a thread in the reader opens it **in the rail**, not over the map.
Reading a report and looking at the ground it is about are the same act — a
MEDEVAC grid means nothing without the map under it — so the thread and the map
sit side by side and `< BACK TO LIST` returns.

Nothing in the rail can send. `REPLY` and `NEW` open the full TAC//MSG reader
with its right pane in compose — see the tacpad README. That split is
deliberate: composing needs room the rail has not got, and a WILCO fired off a
panel you were only scanning ends up on somebody else's task.

The quick replies under an open thread are **the unit's own**, set in
`jmfsb_tacpad_quickReplies` as a comma-separated list, five to a row. An entry
naming a reply template — `roger`, `wilco`, `inprogress`, `cantco`, `close` —
sends that template, so the thread's state still moves; anything else is sent as
those words, as free text. Either way the button is only drawn when the engine
would accept it in the thread being read, so the row can never offer something
the server would refuse.

That list used to be whichever reply templates happened to need no fields —
a list nobody chose. The design draws six phrases a unit actually says, and
which six is a unit decision.

Beside + TEMPLATE are the design's other two: **+ GRID**, which drops your own
grid into the reply box, and **+ MARKER**, a quick reply that is a dropdown of
the map markers, nearest first, and sends the marker's name and grid in one
press.

The squad app's **FILE CASEVAC FOR** *name* opens the CASEVAC card with the
pick-up site already set to that man's position: the one location in the suite
filled in for you, because the button names the man it is filling it in for.

A man's own **A/C/E letters are published the moment he presses them**, not when
anything is sent: the roster table draws that column off the same variable, so
pressing AMBER and watching your own row stay green was the screen disagreeing
with itself. **There is no SEND TEAM ACE REPORT any more** — the platoon view
reads every squad's letters at once, live, so the filed roll-up (and the `ace`
template behind it) was a second, staler copy of a state the screens already
carry. The letters are the report.

## The intrusion suite on a tile

`jmfsb_hacking`'s suite is reached from the **HACK** tile, and *only* from there
— its old entry lived on the cTab device and went into the archive with it. So
the tile says whether it can be opened **before** it is pressed: not cleared,
nothing in range, or a target in range. "Nothing happened" is the worst answer a
tile can give.

*Only* from there is literal. The DRONES and JAMMING apps each grew an OPEN
INTRUSION button, and they are gone: those screens read a sensor, the suite has
its own tile, and a second door into it from every screen that mentions it is how
one app becomes four half-apps. Both still say in words what can be done about
what they are showing.

**The session is the suite's, not its dialog's.** It was created inside
`jmfsb_hacking_fnc_tabletOpen`, so it existed only once that addon's own screen
had been opened — and this app never opens it. `tabletAdvance` found no session
and returned on its first line every tick, so the device list was never scanned:
the tile said a tower was in range and the app said NOTHING IN RANGE for the
whole mission. The session is created in `jmfsb_hacking`'s postInit now, and the
app scans once before drawing its first frame.

The suite itself was not rebuilt. Device cards, intel choice, the progress bar
and the session that survives the dialog closing all already work; what was
missing was a way in from the map and a palette matching everything around it.
`fnc_themeTablet` repaints its controls from the tacpad tokens on open.

That repaint lives **here, not in `jmfsb_hacking`** — the suite has to keep
working on a mission that never loads the tacpad, so it cannot depend on a theme
it might not have. It raises `jmfsb_hacking_tabletOpened` and this listens. That
is the entire coupling, and its config colours remain the fallback, so removing
the tacpad leaves the suite exactly as it was.

Opening the map to hack is the accepted cost of that. Pressing the tile closes
the map first — every reason to hack is something in front of you, and two
full-screen things fighting for the same close key is not a UI.

**SPOOF is live on a net** (2026-10-20). The HACK board's ACTIONS row draws
the action the hack will do filled; on a unit's net — a handset, or a vehicle
RF says carries a set — TAP and SPOOF are a choice
(`jmfsb_hacking_fnc_canSpoof` / `tabletSelectAction`), and under SPOOF the
PRODUCT row becomes EFFECT (drift and length from `jmfsb_ew`'s settings). The
hack runs and is rolled exactly as a TAP; on completion the net's GPS is
walked off true by `jmfsb_ew_fnc_spoofNode` instead of a product being pulled.
Without `jmfsb_ew` SPOOF stays dead.

**The TIC key reports the GPS position** (`jmfsb_ew_fnc_gpsHere` when EW is
loaded): the false fix when spoofed; with no fix it is refused and the card,
where a grid is typed, is the way.

## TAC//SUPPORT

The support board (`fnc_appSupport`, app `support`) fronts the support core
(`jmfsb_support`) and names no provider. Design: `docs/DESIGN_SUPPORT.md`,
"The screen".

- **Tabs, one per support type that has a row** — the types are the providers'
  declarations merged by `jmfsb_support_fnc_types`, filtered to those with at
  least one asset, so a tab never leads nowhere. Each tab is counted
  (`CAS · 2`). The last tab pressed is remembered for the session
  (`jmfsb_tacpad_apps_supportTabPref`) and reopened when it has rows again.
- **The form, left of the map**: the verdict row, UNIT, TASK (two to a line
  when a unit offers more than five), then LOCATION - the task's point, named
  by the task (`TARGET`, `LZ`, `PICKUP`, `DROP POINT`, `DROP ZONE`, `HOVER
  POINT`: task declaration field 6), then one row per further point the task
  declares (field 7: INGRESS, EGRESS, VIA - each click adds a leg - LZ, SET
  DOWN) - then PARAMETERS, the steppers the task declares, and PASSENGERS for
  a transport. Map click or MKR fills the armed point row
  (`fnc_supportPointSet`, `fnc_supportPointVars`). The form scrolls when it
  outgrows the column and keeps its scroll across redraws.
- **READY and CONFIRM TASKING**, alone at the foot of the form: one checklist
  line per thing the order needs (UNIT, TASK, the point, every required
  declared point), each done (an ink square) or missing (an accent outline,
  the value in accent-700), then the provider's VERDICT (`jmfsb_support_fnc_preview`
  - an ETA, OUT OF RANGE) once the rest is set. CONFIRM is the accent cell only
  when nothing is missing; pressed early it sends nothing and names the first
  missing line in the verdict row. It sends `fnc_supportRequestParams`, the
  same array the verdict was asked with.
- **The map, in both hosts** (`fnc_supportMapDraw`, `fnc_supportMapLive`):
  every asset out and the plan it flies (row field 8) as task markers joined
  by a line, the picked asset's provider shapes (`jmfsb_support_fnc_overlay` -
  range rings), and the request live - point, declared points and their legs,
  effect radius, approach bearing, danger-close ring.
- **SITREP** for every type, batteries included.
- **ORDER UNIT RTB and CLOSE**, under the map. RTB still double-confirms.

**Two hosts.** On the vanilla map (native mode) the board is the
`jmfsb_tacpad_apps_supportDlg` dialog and its map is the dialog's own control,
laid into the board's map hole each draw. On the **tablet** it opens no dialog:
it is the open app on the device dialog, drawn inside the app area with the
device bar, tiles and net row round it, and its map hole is a hole over the
tablet's own map (idc 51). The board claims that map while it is open
(`jmfsb_tacpad_appMapClaim`), so a click there sets the armed point instead of
closing the app. Rows, tabs, steppers and MKR are control hits; SITREP, RTB,
CONFIRM and CLOSE are dispatched from the display's press handler; ESC closes
the board, not the tablet. The ack listener redraws it in either host.

There is no Simplex dependency (user, 2026-10-20). The Simplex provider and
the Simplex request window are gone; every row on the board comes from our
own providers.

## RADIO: game voice

The RADIO board (`fnc_appRadio`; docs/DESIGN_VOICE.md, "Tablet RADIO app") is
Arma 3's own VON through `jmfsb_voice`'s API, read once per draw into the
board's context and handed to each panel. It names no radio mod; with the
voice addon absent it says so and draws nothing to press. It redraws when what
it shows changes (`fnc_appRadioKey`), on the voice events (ring, call state,
nets changed), never under a press and never while its search box has focus.
Numpad 6 opens it on the tablet, 7 / 8 step its tabs (`jmfsb_devices`' keys).

- **NETS** - MY NETS (`fnc_appRadioNets`): every net the player is on (only
  those), its VON channel (`fnc_radioVon`), link (RF's quality for the net
  when RF knows it, else the talkers', else reach; NO ROUTE never hidden), the
  ear as L / B / R segments, MUTE, the state and who is talking. A net's name
  makes it active. SOUNDS and KEYS (`fnc_appRadioSounds`): the voice addon's
  sound settings (`RADIO_SOUNDS`; NOT BUILT for one it does not declare), and
  the numpad as the player has it bound (`CBA_fnc_getKeybind`).
- **CALLS** (`fnc_appRadioCalls`): + MY TEAM / + SQUAD LEADERS / + RTOs /
  + MEDICS / + HQ (`fnc_radioGroup` - in reach only, stops at 8), NEXT:
  FLASH for RTOs and admins, and FIND by name or callsign; VON CHANNEL SLOTS
  (C2, A2G, CALL 1-8 from `jmfsb_voice_fnc_callSlots`); CONTACTS
  (`fnc_appRadioContacts`) with ON CALL / + ADD / CALL / CALL BACK; LIVE CALL
  (`fnc_appRadioLive`) - an incoming ring with ACCEPT / DECLINE, the call's
  slot, clock, people, priority and size, RECENT contacts (`fnc_radioQuick`,
  kept off the call events by `fnc_radioCalls`), HANG UP, MUTE CALL, and a
  line with the call's last word (failure reason, priority warning, end) - and
  CALLBACKS with how long each has waited. Every ring goes through
  `fnc_radioDial`: into the live call when there is one, a new call otherwise.
- **MANAGE** (`fnc_appRadioManage`): leaders, RTOs and admins
  (`fnc_radioRole`: the admin flag, the RTO job by the one RTO test
  `jmfsb_voice_fnc_isRto` - the RTO console is a player job, user 2026-10-20 -
  the slot's leader words, leading the group); WHO CAN for everyone, its RTO
  column holding every action but the signal plan export. NETS lists the player's
  nets with VON channel, kind and state; MEMBERS lists a TEAM net's (the
  group) and a CALL net's (the call) with their reach. **RTO nets** (user,
  2026-10-22: "allow rtos to add custom channels"): under NETS, the nets the
  voice server holds, each with REMOVE, and the ADD NET form - a name box,
  the squads as tick chips, CREATE (`fnc_radioCustomPanel`); pick one on NETS
  and MEMBERS becomes its editor - squad chips, every contact as a tick row
  (dim when he is on it through his squad), APPLY / RESET
  (`fnc_radioMembersPanel`, `fnc_radioMembersToggle`, the tick cell
  `fnc_radioTick`, the callsigns `fnc_radioSquads`). The drafts live in
  uiNamespace and are part of the redraw key. Only an RTO or admin
  (`jmfsb_voice_fnc_canManageNets`) gets the presses; the voice server
  re-checks. On a TFAR / ACRE night the block only says so.

`fnc_radioState` / `fnc_radioPublish` publish the player's active voice net for
the squad table and the target card; `fnc_radioTune` (the roster's TUNE) makes
another man's active net the player's when he is on it too.

## DRONES: no UAV terminal

The vanilla UAV terminal is out of the arsenal (2026-10-20), so DRONES no
longer calls `connectTerminalToUAV` or asks `isUAVConnectable`. CONNECT /
DISCONNECT are the devices' drone link and TAKE CONTROL their seat
(`jmfsb_devices_fnc_uavControl`, by `remoteControl`); a dead CONNECT says why in
the gate's own words (`jmfsb_devices_fnc_uavCan`: not the UAV operator, not
your side, someone else has it, no DATA link). A fleet row's task reads
`LINKED - NAME` while a player holds the link and `MANUAL - NAME` while he is in
the seat. Out of the seat: the drone's action menu or the tablet key. Not run
in game.

**Orders (2026-10-20).** On the drone he has linked, while the DATA link
holds, the FEED's ORBIT, GO TO, LASE and RTB are live, and each asks the gate
again at the press. They are the devices' (`jmfsb_devices_fnc_uavOrder`), which
sends the order to the machine that owns the drone's crew - the server, or the
launcher's client for a hand-thrown drone - so waypoints, `lockCameraTo` and
the designator (`BIS_fnc_fire`) run where they are local.

- **GO TO** closes the app and claims the host's map
  (`jmfsb_tacpad_appMapClaim`, as TAC//SUPPORT does) - the vanilla map or the
  tablet's screen. A left click sends the drone there as a MOVE at its current
  height, then a LOITER circle; a right click cancels. The claim lets go by
  itself after 30 s, when another app opens, when the map or the tablet closes,
  or when the drone dies (`fnc_appDronesPick`). The board comes back after the
  pick.
- **LASE** locks the designator's turret on the gunner's assigned target, else
  the point under the optic, else the ground under the drone, and switches the
  designator on; **LASE OFF** (drawn in the alarm fill while lasing) switches it
  off. An airframe with no designator (`jmfsb_devices_fnc_uavLaser`) is refused
  with the reason. The FEED's target line reads `LASE <grid> - <n> M` while it
  lases.
- **RTB** flies to the drone's home (`jmfsb_devices_fnc_uavHome`: the launch
  point it records, else the nearest staging zone or patrol base of your side,
  else you). A helicopter-type drone lands there; any other loiters.
- **MODE** - a Drone40 Relay / Decoy / Jammer gets a RELAY / DECOY / JAMMER /
  OFF row over the buttons, its mode filled, live on CONNECT's gate (yours, or
  one you may link). The switch is the server's
  (`jmfsb_drone40_fnc_setMode`).

Not run in game.

## Not built yet

- **RADIO** (said in words on the board, never drawn as buttons): per-net
  beep volume (the voice API has one beep volume); MAKE FLASH on a call already
  up; cancelling a callback; HOPS on a contact; ADD TO CALL from the map or the
  squad list; MANAGE's keys, PACE alternates, patches, listen-only, rekey,
  force PACE, order EMCON, members of C2 / A2G, signal plan load / export
  (the RTO nets are built; their rights the voice server enforces, the rest
  of the role gate only decides what the board shows); captured-key nets;
  voice notes - the voice API has no call for them yet.

- **Glove mode (1c)** and the **admin template builder (1d panel 04)**. The
  picker and the fill-out card are built - in the reader's right pane, not as a
  window - but a template is still something a mission declares in
  `templates.inc.sqf` rather than something a unit builds in game.
- **Net tabs** on the reader — it currently shows every box the player can see,
  which is what `ALL` selects anyway.
- **Tile apps.** Only `comms` and `squad` are registered, and `squad` raises an
  event rather than drawing a screen. Drones, jam, weather and radio have tile
  states but no screens in the handoff either.
- **Radio tile** reads game voice (`jmfsb_voice_fnc_netState`): the active
  net, its kind, and who is talking on it, `warn` when it reaches nobody. With no
  `jmfsb_voice` it is drawn stale ("NO VOICE").

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_tacpad`
- `jmfsb_support`
- `cba_xeh` _(external)_

## Ships

87 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_tacpad_apps_show_tiles` | CHECKBOX | Show live tiles |
| `jmfsb_tacpad_apps_tileRows` | LIST | Live tile rows |
| `jmfsb_tacpad_apps_show_squad` | CHECKBOX | Show squad list |
| `jmfsb_tacpad_apps_show_reader` | CHECKBOX | Show message reader |
| `jmfsb_tacpad_apps_show_tic` | CHECKBOX | Show troops in contact button |
| `jmfsb_tacpad_apps_show_tools` | CHECKBOX | Show map tools |
| `jmfsb_tacpad_apps_readerDense` | CHECKBOX | Reader: high density |
| `jmfsb_tacpad_apps_show_settings` | CHECKBOX | Show settings gear |

## Functions

<details><summary>87</summary>

- `jmfsb_tacpad_apps_fnc_alarmAtDelay`
- `jmfsb_tacpad_apps_fnc_ammoState`
- `jmfsb_tacpad_apps_fnc_appComms`
- `jmfsb_tacpad_apps_fnc_appDrones`
- `jmfsb_tacpad_apps_fnc_appDronesAction`
- `jmfsb_tacpad_apps_fnc_appDronesCamera`
- `jmfsb_tacpad_apps_fnc_appDronesData`
- `jmfsb_tacpad_apps_fnc_appDronesEnemy`
- `jmfsb_tacpad_apps_fnc_appDronesFeed`
- `jmfsb_tacpad_apps_fnc_appDronesFleet`
- `jmfsb_tacpad_apps_fnc_appDronesKey`
- `jmfsb_tacpad_apps_fnc_appDronesPick`
- `jmfsb_tacpad_apps_fnc_appHack`
- `jmfsb_tacpad_apps_fnc_appHackAction`
- `jmfsb_tacpad_apps_fnc_appHackList`
- `jmfsb_tacpad_apps_fnc_appHackLog`
- `jmfsb_tacpad_apps_fnc_appHackNodes`
- `jmfsb_tacpad_apps_fnc_appHackTrack`
- `jmfsb_tacpad_apps_fnc_appIntel`
- `jmfsb_tacpad_apps_fnc_appJamming`
- `jmfsb_tacpad_apps_fnc_appPageBar`
- `jmfsb_tacpad_apps_fnc_appPageButton`
- `jmfsb_tacpad_apps_fnc_appPagePanel`
- `jmfsb_tacpad_apps_fnc_appPageTabs`
- `jmfsb_tacpad_apps_fnc_appRadio`
- `jmfsb_tacpad_apps_fnc_appRadioCalls`
- `jmfsb_tacpad_apps_fnc_appRadioContacts`
- `jmfsb_tacpad_apps_fnc_appRadioKey`
- `jmfsb_tacpad_apps_fnc_appRadioLive`
- `jmfsb_tacpad_apps_fnc_appRadioManage`
- `jmfsb_tacpad_apps_fnc_appRadioNets`
- `jmfsb_tacpad_apps_fnc_appRadioSounds`
- `jmfsb_tacpad_apps_fnc_appScanner`
- `jmfsb_tacpad_apps_fnc_appSettings`
- `jmfsb_tacpad_apps_fnc_appSquad`
- `jmfsb_tacpad_apps_fnc_appSupport`
- `jmfsb_tacpad_apps_fnc_appTimer`
- `jmfsb_tacpad_apps_fnc_appWeather`
- `jmfsb_tacpad_apps_fnc_missionSchemes`
- `jmfsb_tacpad_apps_fnc_panelHide`
- `jmfsb_tacpad_apps_fnc_panelReader`
- `jmfsb_tacpad_apps_fnc_panelSettings`
- `jmfsb_tacpad_apps_fnc_panelSquad`
- `jmfsb_tacpad_apps_fnc_panelTic`
- `jmfsb_tacpad_apps_fnc_panelTiles`
- `jmfsb_tacpad_apps_fnc_panelTools`
- `jmfsb_tacpad_apps_fnc_panelToolsBtn`
- `jmfsb_tacpad_apps_fnc_radioCalls`
- `jmfsb_tacpad_apps_fnc_radioCanAdd`
- `jmfsb_tacpad_apps_fnc_radioCustom`
- `jmfsb_tacpad_apps_fnc_radioCustomPanel`
- `jmfsb_tacpad_apps_fnc_radioDial`
- `jmfsb_tacpad_apps_fnc_radioGroup`
- `jmfsb_tacpad_apps_fnc_radioMembersPanel`
- `jmfsb_tacpad_apps_fnc_radioMembersToggle`
- `jmfsb_tacpad_apps_fnc_radioPublish`
- `jmfsb_tacpad_apps_fnc_radioQuick`
- `jmfsb_tacpad_apps_fnc_radioRfNodes`
- `jmfsb_tacpad_apps_fnc_radioRfQuality`
- `jmfsb_tacpad_apps_fnc_radioRole`
- `jmfsb_tacpad_apps_fnc_radioSquads`
- `jmfsb_tacpad_apps_fnc_radioState`
- `jmfsb_tacpad_apps_fnc_radioTick`
- `jmfsb_tacpad_apps_fnc_radioVon`
- `jmfsb_tacpad_apps_fnc_readerRow`
- `jmfsb_tacpad_apps_fnc_roleTiles`
- `jmfsb_tacpad_apps_fnc_row`
- `jmfsb_tacpad_apps_fnc_setSetting`
- `jmfsb_tacpad_apps_fnc_settingCycle`
- `jmfsb_tacpad_apps_fnc_settingLocked`
- `jmfsb_tacpad_apps_fnc_settingStep`
- `jmfsb_tacpad_apps_fnc_supportCell`
- `jmfsb_tacpad_apps_fnc_supportGroup`
- `jmfsb_tacpad_apps_fnc_supportHover`
- `jmfsb_tacpad_apps_fnc_supportMapDraw`
- `jmfsb_tacpad_apps_fnc_supportMapLive`
- `jmfsb_tacpad_apps_fnc_supportPassengers`
- `jmfsb_tacpad_apps_fnc_supportPointSet`
- `jmfsb_tacpad_apps_fnc_supportPointVars`
- `jmfsb_tacpad_apps_fnc_supportRequestParams`
- `jmfsb_tacpad_apps_fnc_supportStepper`
- `jmfsb_tacpad_apps_fnc_supportTint`
- `jmfsb_tacpad_apps_fnc_ticSend`
- `jmfsb_tacpad_apps_fnc_tileData`
- `jmfsb_tacpad_apps_fnc_timerSet`
- `jmfsb_tacpad_apps_fnc_timerState`
- `jmfsb_tacpad_apps_fnc_toggleNet`

</details>
