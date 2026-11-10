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
| **MARK** | press to place a real map marker there through the player's marker system (see "Map markers"): the built-in card opens with the ten-digit grid and the time as its text. A press on a marker of your own deletes it. The cursor previews the grid. |
| **GRID** | the ten-digit grid under the cursor, and a line under it with your own GPS grid (`jmfsb_ew_fnc_gpsState`): `GPS <grid>`, `SUSPECT` after it when an anti-spoof set flags it, `GPS NO FIX` when denied; spoofed, the false grid. |
| **VIEWSHED** | press to shade what can be seen from that point: accent where a standing man can be seen from eye height, ink where he cannot. |
| **ROUTE** | press waypoints in order: every leg shows its own distance and bearing, the last waypoint the total, and the leg the next press would add follows the cursor. Starting ROUTE starts a new route. |
| **RINGS** | press to draw range rings about that point: `jmfsb_maptools_ringCount` rings `jmfsb_maptools_ringStep` metres apart, each read at its north. |
| **LOS** | press where you look from, then where you look to: the line in the accent when a standing man there can be seen from eye height, in ink with a dot where the ground or a building stops it when not (`fnc_losCheck`). |
| **GO TO GRID** | type a grid in the box and press GO: the map goes there at the zoom it is at (`fnc_goTo`). |
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

Both hosts close an open app on a press on the map, and an app that picks on
it (the drones' GO TO, Point Man) claims the map
(`jmfsb_tacpad_appMapClaim`) while it does. The tools never claim it
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

## Map markers (2026-11-01)

User: "map markers need to be able to place map markers here; make an option to
use ALiVE marker system or ACE or think of a better solution". Built, not seen
in game.

**Why the tablet could not place markers.** The engine opens its marker dialog
for a double-click on its own map display (12) only. The tablet's screen is a
map control in jmfsb_devices' dialog; a double-click there reached nothing. No
script command opens the engine's dialog at a point.

**One placement path.** A double-click on a device's map (`fnc_mapDblClick`)
and a MARK press both call `fnc_markerOpen`, which opens the player's
**Map marker system** (`jmfsb_maptools_markerSystem`, a client setting):

| | |
|---|---|
| **Built-in** (default) | the marker card (`fnc_markerCard`), beside the point: the whole marker set in tabs, every marker colour, size and direction, a text box (Enter places), the channels, PLACE / CANCEL - see "The marker card". The picked icon in the picked colour, size and direction shows on the map at the point while it is open. |
| **ACE** | ACE's own marker dialog (`fnc_markerAce`). Listed only with `ace_markers` loaded. |
| **ALiVE** | ALiVE's Advanced Marker dialog, through `jmfsb_adapter_alive_fnc_markerOpen` only. Listed only with ALiVE loaded; without the Advanced Markers module in the mission it falls back to Built-in. |

A system that cannot open falls back to the card. The vanilla map's own
double-click stays the game's dialog (ACE's when ACE is loaded); MARK on the
vanilla map goes through the setting like on the tablet.

**Channels.** MY MAP (local: kept off the network, CLEAR takes it back), then
GLOBAL, SIDE, CMD, GROUP, VEH - each only when the engine allows a marker there
now (`fnc_markerChannels`: `setCurrentChannel` answers false on a disabled
channel; ACE asks the same way). No DIRECT: the game's dialog has none either.
A double-click opens on the player's current channel; MARK on GROUP with
`jmfsb_maptools_markShare` on, MY MAP with it off.

**The marker.** `fnc_mark` is the one maker for the card and the ACE path:
`jmfsb_common_fnc_createPlayerMarker`, so it is an ordinary player marker
(`_USER_DEFINED #<id>/...`) that the vanilla map edits and deletes like any
other and TAC//MSG's MAP MARKER list offers. Local markers stay local; any other
channel is sent by making the last setter the global one. `[position]` alone
still drops MARK's old dot with grid and time.

**ACE on a device's map.** `createDisplay "RscDisplayInsertMarker"` on the host
display: ACE's onLoad builds its whole dialog and reads the map at idc 51 under
it - the tablet's map. What the engine does not do for a script-made dialog is
done here: the point is set to the press (`fnc_markerAceInit`, off ACE's
`ace_markers_editingMarker` event; an edited marker keeps its place), the
channel list is filled when empty, and on OK (`fnc_markerAceDone`) the marker
is made with ACE's icon, colour, text (timestamp included) and channel, then
ACE's `ace_markers_setMarkerNetwork` sets angle and scale everywhere. ACE's own
search for the new marker may miss it and log one RPT error; nothing else
follows. A second marker of this player's made in the same moment is deleted.

**Deleting.** The game's map: hover and Delete, as with any player marker. The
tablet: a MARK press on a marker of your own deletes it (`fnc_markerDelete`;
an ALiVE marker of yours through `jmfsb_adapter_alive_fnc_markerRemove`); a
double-click on one opens the card on it, with DELETE, and PLACE replaces it.

**The marker card (2026-11-02).** User: "need more map markers in the map
marker solution", "and all that are in this mod", and the card "is ugly".
Built, not seen in game.

```
MARK                                   0123456789   ink band
BASIC  MIL  BLU  OPF  IND  CIV  FLAG  JMSB          tabs, one row
[ ][ ][ ][ ][ ][ ]                                  square icon cells
[ ][ ][ ][ ][ ][ ]                                  rows as the host allows
<              2 / 4              >                 pager
[■][■][■][■][■][■][■][■][■]                         swatches, nine a row
S  M  L                  <    045°    >             size, direction
TEXT
MY MAP  GLOBAL  SIDE  CMD  GROUP  VEH
PLACE            CANCEL
```

- **Icons** come from CfgMarkers at runtime (`fnc_markerCardCatalog`, kept for
  the mission): every class with scope above 0 and an icon, by class prefix -
  `hd_` BASIC, `mil_` MIL, `b_` BLU, `o_` OPF, `n_` IND, `c_` / `u_` / `loc_`
  CIV, `flag_` FLAG. Scope 1 counts (the game gives its NATO symbols, flags and
  places scope 1; `jmfsb_map` gives `hd_` scope 1). System marks, group sizes,
  respawn and selection marks take no prefix and are left out. The tab table
  and the dozen marks that lead BASIC and MIL are the only lists
  (`CARD_CATEGORIES`, `CARD_TYPES_LEAD`).
- **JMSB** is every class whose source addons (`configSourceAddonList`) are all
  this mod's (`jmfsb_...`): the CAS points, LZs, DZ, dive points and the rest
  in `jmfsb_map` today, and any added later, with no list. `hd_dot` and
  `mil_objective`, which `jmfsb_map` only re-scopes, stay in their own tabs.
- Flags and the JMSB icons are pictures and draw in their own colours; every
  other icon is a shape and draws in the ink. Each names itself on hover.
- **Pages**: the grid gets the rows the host has left after the rest of the
  card - four at most, one at least - so the card never runs past the map;
  `<` / `>` turn the page and wrap. A tab opens on the page holding the picked
  icon; the card opens on the tab holding it.
- **Colours**: every CfgMarkerColors class with scope above 0, as square
  swatches nine a row - with this mod, Default, black, grey, red, brown,
  orange, yellow, khaki, green, blue, pink, white, the four side colours, the
  side-unknown yellow and JMSB. Default's swatch is the picked icon's own
  colour, which is what Default gives it.
- **Size** S / M / L (`markerSize` 0.7, 1, 1.5) and **direction** in 15° steps,
  through `fnc_mark`. A new card opens at M, pointing north; an edited marker
  opens as it stands.
- **Look**: an app's ink header band, the theme's line round each cell and the
  pick filled in the ink, one column for every row, PLACE the one filled
  button. Tacpad primitives and theme tokens only; no tracked values.

**Apps keep the map.** No marker from a double-click while a tool runs, an app
is open, an app holds `jmfsb_tacpad_appMapClaim`, or within half a second of an
app closing (that double-click began as the app's way out). An app opening
takes the card down. The device's map gets the tools once a second whether or
not the MAP TOOLS strip is built (TOOLS can hide it).

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
| `jmfsb_maptools_fnc_mark` | `[position, type, colour, text, channel, size, direction]` - all but the position optional; returns the marker |
| `jmfsb_maptools_fnc_viewshedStart` | `[position]` |

`jmfsb_maptools_tool` is the running tool's id, `""` for none.

## Not verified

None of it has been run in game. `drawTriangle` (the viewshed fill) needs a
game build that has it; whether returning true from the map's MouseButtonDown
stops a left-drag panning the map is untested - if it does not, a ruler drag
reads as a pan and the two-press ruler is the way to measure.

Map markers: whether a map control in a dialog raises MouseButtonDblClick; whether
ACE's dialog made with `createDisplay` draws and fills as described; whether the
engine puts anything behind a script-made insert-marker dialog's OK.

The marker card (2026-11-02): whether the short tab labels and the S / M / L
keys sit clear in their cells on the smallest tablet; whether DLC and other
mods add markers under the same prefixes (they would join those tabs).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_tacpad`
- `cba_xeh` _(external)_

## Ships

41 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_maptools_angleUnit` | LIST | Bearing units |
| `jmfsb_maptools_markShare` | CHECKBOX | Share marks with group |
| `jmfsb_maptools_markerSystem` | LIST | Map marker system |
| `jmfsb_maptools_viewshedRadius` | SLIDER | Viewshed radius |
| `jmfsb_maptools_viewshedCell` | SLIDER | Viewshed resolution |
| `jmfsb_maptools_ringStep` | SLIDER | Range ring spacing |
| `jmfsb_maptools_ringCount` | SLIDER | Range rings |

## Functions

<details><summary>41</summary>

- `jmfsb_maptools_fnc_attach`
- `jmfsb_maptools_fnc_bearingText`
- `jmfsb_maptools_fnc_centre`
- `jmfsb_maptools_fnc_clear`
- `jmfsb_maptools_fnc_distanceText`
- `jmfsb_maptools_fnc_draw`
- `jmfsb_maptools_fnc_drawLeg`
- `jmfsb_maptools_fnc_drawProtractor`
- `jmfsb_maptools_fnc_drawViewshed`
- `jmfsb_maptools_fnc_goTo`
- `jmfsb_maptools_fnc_gridCalibrate`
- `jmfsb_maptools_fnc_gridText`
- `jmfsb_maptools_fnc_gridToPos`
- `jmfsb_maptools_fnc_hasInput`
- `jmfsb_maptools_fnc_label`
- `jmfsb_maptools_fnc_losCheck`
- `jmfsb_maptools_fnc_mapDblClick`
- `jmfsb_maptools_fnc_mark`
- `jmfsb_maptools_fnc_markLabel`
- `jmfsb_maptools_fnc_markerAce`
- `jmfsb_maptools_fnc_markerAceDone`
- `jmfsb_maptools_fnc_markerAceInit`
- `jmfsb_maptools_fnc_markerCard`
- `jmfsb_maptools_fnc_markerCardCatalog`
- `jmfsb_maptools_fnc_markerCardCells`
- `jmfsb_maptools_fnc_markerCardClose`
- `jmfsb_maptools_fnc_markerCardDraw`
- `jmfsb_maptools_fnc_markerCardIcons`
- `jmfsb_maptools_fnc_markerCardPlace`
- `jmfsb_maptools_fnc_markerChannels`
- `jmfsb_maptools_fnc_markerDelete`
- `jmfsb_maptools_fnc_markerOpen`
- `jmfsb_maptools_fnc_markerOwn`
- `jmfsb_maptools_fnc_mouseDown`
- `jmfsb_maptools_fnc_mouseMove`
- `jmfsb_maptools_fnc_mouseUp`
- `jmfsb_maptools_fnc_start`
- `jmfsb_maptools_fnc_stop`
- `jmfsb_maptools_fnc_viewshedCancel`
- `jmfsb_maptools_fnc_viewshedStart`
- `jmfsb_maptools_fnc_viewshedStep`

</details>
