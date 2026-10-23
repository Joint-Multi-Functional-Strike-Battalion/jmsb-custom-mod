# Map Tools

`jmfsb_maptools`

The map tools, built in-house: the PLP MapTools feature set without PLP. The
TOOLS panel (`jmfsb_tacpad_apps`, `fnc_panelTools`) is the front end; this addon
is the tools themselves, and nothing here depends on another mod.

| | |
|---|---|
| **CENTRE** | puts the map back on the player - or his vehicle - at the zoom he left it at, where his GPS says he is (`jmfsb_ew_fnc_gpsHere` when EW is loaded: the false fix when spoofed; NO FIX leaves the map and says so). Momentary; the running tool keeps running. |
| **RULER** | press and drag, or press twice: distance and bearing, drawn as a line with the reading at its middle. Between the two presses a rubber band follows the cursor. |
| **PROTRACTOR** | press to place a rose (a tick every 10°, a long one every 30°, N E S W); the arm follows the cursor with bearing and distance until the next press locks it; the press after that places a new rose. The rose is a fixed size on screen at any zoom. |
| **MARK** | press to drop a marker labelled with its ten-digit grid and the time. The cursor previews the grid. |
| **GRID** | the ten-digit grid under the cursor, and a line under it with your own GPS grid (`jmfsb_ew_fnc_gpsState`): `GPS <grid>`, `SUSPECT` after it when an anti-spoof set flags it, `GPS NO FIX` when denied; spoofed, the false grid. |
| **VIEWSHED** | press to shade what can be seen from that point: accent where a standing man can be seen from eye height, ink where he cannot. |
| **ROUTE** | press waypoints in order: every leg shows its own distance and bearing, the last waypoint the total, and the leg the next press would add follows the cursor. Starting ROUTE starts a new route. |
| **CLEAR** | wipes everything the tools drew, and this player's own local marks. |

Bearings read in degrees, NATO mils (6400) or both, per player
(`jmfsb_maptools_angleUnit`).

## Drawn in world positions, on every host

The state is client-side and held in **world positions**, not on a control. The
tools attach themselves (`fnc_attach`) to the vanilla map whenever it opens, and
the TOOLS panel attaches them to whichever host map it is drawn on - the
vanilla map in native mode, the tablet's screen in tablet mode (both idc 51,
`IDC_HOST_MAP`). So a ruler laid on the tablet is the same ruler on the paper
map, and a host coming or going loses nothing. Attaching is once per control.

Everything is drawn from `jmfsb_tacpad_fnc_theme`'s tokens: lines and labels in
the accent, the viewshed in accent over ink. Labels shrink with the host's
width, so the tablet's screen gets proportionate type.

## Map clicks and the apps

Both hosts close an open app on a press on the map, and TAC//SUPPORT claims the
map (`jmfsb_tacpad_appMapClaim`) while it picks on it. The tools never claim it
and never take a press while an app is open or the map is claimed: that press
is the app's (`fnc_hasInput`). The press that *closes* an app is stamped by
frame off `jmfsb_tacpad_appClosed`, so it is not counted as a tool press
whichever of the two handlers the engine runs first. Shift, ctrl and alt
presses are the game's own and are left alone.

A tool stops when its map closes (the vanilla map's Map event, the tablet
dialog's Unload); what it drew stays until CLEAR.

## Ruler: drag or two clicks

Whether a release ends a drag is decided **on screen, against where the anchor
is drawn now**. If the map panned under the drag the anchor moved with the
cursor and the release lands on it - that was a pan, and the ruler waits for a
second press instead of reading zero.

## The grid

`fnc_gridText` builds the ten digits on the engine's own square
(`mapGridPosition`), so the leading digits always agree with what the map
prints. Where the square's lines fall, and which way each axis counts, is
asked of `mapGridPosition` once per mission by bisection (`fnc_gridCalibrate`)
rather than read from CfgWorlds' Grid class, which terrain makers fill in every
way there is. A grid that is not all digits gets the engine's string as is.

## MARK

Made through `jmfsb_common_fnc_createPlayerMarker`: an ordinary player marker on
the group channel, which the vanilla map edits and deletes like any other and
TAC//MSG's MAP MARKER list offers like any other. It stays local unless the
player turns on `jmfsb_maptools_markShare`, when the last setter is the global
one and the group sees it. CLEAR takes back local marks only; a shared one is
the group's.

## Viewshed

A coarse polar grid: rings `jmfsb_maptools_viewshedCell` metres apart out to
`jmfsb_maptools_viewshedRadius`, each cut into sectors about a cell wide at the
outer ring (24 to 180). One ray per cell from 1.7 m over the point to 1.5 m over
the cell's middle: `terrainIntersectASL` first, and only a ray the ground lets
through is asked of `lineIntersectsSurfaces` against view geometry. Traced as a
per-frame handler, 60 rays a frame nearest ring first, so it grows out from the
point and no frame stalls; the percentage shows at the centre until it is
done. Cells are sorted into two triangle lists as they finish, so the draw is
two `drawTriangle` calls a frame however many cells there are.

Both settings are operation values, server-forceable: how far and how fine.

## Public

| | |
|---|---|
| `jmfsb_maptools_fnc_start` | `[tool]` - toggle `ruler`, `protractor`, `mark`, `grid`, `viewshed`, `route`; returns the tool now running |
| `jmfsb_maptools_fnc_stop` | stop the running tool, keep the drawings |
| `jmfsb_maptools_fnc_clear` | wipe the drawings |
| `jmfsb_maptools_fnc_centre` | `[map control]` |
| `jmfsb_maptools_fnc_attach` | `[map control]` - hang the tools on another map |
| `jmfsb_maptools_fnc_gridText` | `[position]` - ten-digit grid |
| `jmfsb_maptools_fnc_mark` | `[position]` |
| `jmfsb_maptools_fnc_viewshedStart` | `[position]` |

`jmfsb_maptools_tool` is the running tool's id, `""` for none.

## Not verified

None of it has been run in game. `drawTriangle` (the viewshed fill) needs a
game build that has it; whether returning true from the map's MouseButtonDown
stops a left-drag panning the map is untested - if it does not, a ruler drag
reads as a pan and the two-press ruler is the way to measure.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_tacpad`
- `cba_xeh` _(external)_

## Ships

22 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_maptools_angleUnit` | LIST | Bearing units |
| `jmfsb_maptools_markShare` | CHECKBOX | Share marks with group |
| `jmfsb_maptools_viewshedRadius` | SLIDER | Viewshed radius |
| `jmfsb_maptools_viewshedCell` | SLIDER | Viewshed resolution |

## Functions

<details><summary>22</summary>

- `jmfsb_maptools_fnc_attach`
- `jmfsb_maptools_fnc_bearingText`
- `jmfsb_maptools_fnc_centre`
- `jmfsb_maptools_fnc_clear`
- `jmfsb_maptools_fnc_distanceText`
- `jmfsb_maptools_fnc_draw`
- `jmfsb_maptools_fnc_drawLeg`
- `jmfsb_maptools_fnc_drawProtractor`
- `jmfsb_maptools_fnc_drawViewshed`
- `jmfsb_maptools_fnc_gridCalibrate`
- `jmfsb_maptools_fnc_gridText`
- `jmfsb_maptools_fnc_hasInput`
- `jmfsb_maptools_fnc_label`
- `jmfsb_maptools_fnc_mark`
- `jmfsb_maptools_fnc_mouseDown`
- `jmfsb_maptools_fnc_mouseMove`
- `jmfsb_maptools_fnc_mouseUp`
- `jmfsb_maptools_fnc_start`
- `jmfsb_maptools_fnc_stop`
- `jmfsb_maptools_fnc_viewshedCancel`
- `jmfsb_maptools_fnc_viewshedStart`
- `jmfsb_maptools_fnc_viewshedStep`

</details>
