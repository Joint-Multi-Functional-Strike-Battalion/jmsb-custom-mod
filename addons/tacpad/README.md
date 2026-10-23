# Tacpad

`jmfsb_tacpad`

The map screen is the shell. Panels are controls groups drawn on the vanilla map
display, so the map stays a map — the player keeps panning, clicking and marking
it, and a panel is something laid on top rather than something that replaced it.

Every panel is dragged by its header, the way ACE's map tools are. Release and
the position is saved as **safe-zone fractions**, not pixels, so the same profile
still makes sense on a different resolution. Right-click a header to put that
panel back where the design put it.

## Input

**Controls on the map display take input.** BCE declares a whole toolbar into
`RscDisplayMainMap` and drives it with `onButtonClick`; this does the same thing
at runtime. Anything pressable is an `RscButton` — the `hit` class — laid over
the text, carrying its own `ButtonClick` handler. That is the whole mechanism.

It is written down because the opposite was believed for six builds. The theory
was that display 12 gives every click to the map control at IDC 51, so the suite
registered *rectangles* and hit-tested them from a dispatcher hung off the map.
That could not work: the transparent button over each row consumed the click —
which is what a button is — so neither the map nor the display ever saw the
event, and the dispatcher never ran. **Nothing in the suite could be pressed.**
The narrower thing that is true, and the reason the hit class exists at all, is
that `RscText` and `RscStructuredText` raise no `ButtonClick`.

**A structured text label takes the press away from the button under it.** That
is the other half of the story and the one that made the suite feel broken: a
structured text control receives mouse input — it has to, it can carry links —
and it raises no `ButtonClick`, so wherever a label covered a cell the cell
answered only in the margins around it. The settings strip, whose label runs from
the gear to the far edge, answered *only on the gear*. `drawHit` now hands the
press on: every label drawn into the same group this frame and lying inside the
button's rectangle gets a press handler that fires that button's own handler.
Nothing double-fires — one control receives a press, and the first hit to cover a
label owns it.

Dragging is the one thing that needs more, because a drag outruns the header it
started on: `dragStart` creates a full-screen transparent **catcher** for the
duration of the drag and deletes it on release.

**A live app must know it is still the app on screen.** Three screens refresh by
reopening themselves on a timer, and they decided whether to keep going by asking
whether an app group existed — which is true of *any* app, including the one that
just replaced them. So opening SETTINGS after HACK left the hack's loop running:
it tore the settings screen down and rebuilt its own every second, under the
cursor, and **a control deleted between the press and the release never raises a
click**. That is the whole of "the window would not click and would not close",
and it applied to whichever screen was opened second. `openApp` writes down which
app is open and every refresh loop compares that against its own id.

**A reopen is refused once the window that queued it is gone.** Every redraw
reopens the app — a live app reopens itself on a timer, a press inside the app
queues a reopen for next frame — and the only thing that says a reopen is still
wanted is the window it came from still being the open one. CLOSE fires on the
press, so "press a row, then close the window" had its reopen land *after* the
close and the window came straight back: the same stuck window wearing the coat
of "I closed it and it opened again". `openApp` refuses any reopen whose app is
no longer the one on screen; only a panel or a tile is trusted to open one.

**A draw that throws must not take the layer with it.** A handler dying halfway —
bad data, a race, a config gone missing — used to abort `openApp` before the
panels hid or the escape hatch drew, leaving `appCurrent` set to a screen nobody
could see and no way out of it. It is caught and logged, and the bookkeeping
carries on: a broken window still has to close.

**A page closes the way every other window in the game closes: ESC, or a click
on the map.** Both are hung on the map display once, and both run the same
teardown as the frame's own CLOSE — `appClose`. There is no panic button: one
was built and removed, because a page that always closes needs no rescuing.
`appClose` also sweeps the display for groups the suite owns but no longer
tracks, which is what let a page get stuck in the first place — an orphan is
deleted by nothing and replaced by nothing.

**A drag handle cannot be a button.** It was one, and that is why no panel could
ever be moved: a button raises `ButtonDown` and `ButtonClick` and does **not**
raise `MouseButtonDown`, so the handler hung on it was never called once. The
grab is a plain fill now — statics do raise it, and it carries the cursor
position a drag needs.

Four regions are reserved and a panel is slid clear of them on drop: the map's
own top bar (full width — the design's three zones miss it, and the tiles and the
reader were both drawn over it), the vanilla game menu (top-left), the chat
overlay (bottom-left, 8 grid cells × 2.5) and the scale and contour legend
(bottom-right). Covering the chat overlay costs a
player the only text channel they have, so it is not left to chance — though
`respectZones` turns it off for anyone who disagrees.

**Growing is checked against them too.** `place` pushes a panel clear of the
chat overlay when it is dropped, and `fit` then grew it straight back down over
the chat: the squad rail reserved sixteen rows whatever the group held, which
from its default position ended below the top of the chat zone. `fit` clamps to
the nearest reserved edge underneath the panel, and the rail is the size of the
section actually in it.

## TAC//MSG inside the tablet

In tablet mode, with a device open, TAC//MSG never opens a window over it
(user, 2026-10-20: "tac//msg needs to be inside the tablet"). `openReader`
creates the reader's root on the device dialog in the tablet's map area and
adopts it as the tablet's open app (`appHost`, id `reader`): the panels hide
under it, the device bar, notification line, tiles and net row stay round it,
**ESC**, CLOSE (`readerClose`) or a press on the map close it and leave the
tablet up, and a tile or soft key replaces it like any other app. Everything
TAC//MSG draws - the rail, the list and its filter, the thread and net views,
the composer, the template and recipient pickers, the report card, the quick
replies, the FLASH banner - is drawn into that root or onto the device, and
its edit boxes are created into the device dialog, which takes keyboard
focus. The comms app's COMPOSE, NEW, OPEN FULL on the docked reader and the
keybind all arrive here. On the vanilla map, and in tablet mode with no device
open, the reader is the dialog it always was.

`appHost` is public: any screen that draws its own group on the host can be
the open app that way (TAC//PAC does). Every way an app stops being open -
`appClose`, another app replacing it, the host going - raises
`jmfsb_tacpad_appClosed` with its id.

## Composing

**There is no compose window.** Composing is a state of the reader's right pane:
NEW and + TEMPLATE switch what the right third of the screen is showing, and the
nets, the traffic list and the thread being answered all stay on screen while the
answer is written. It was a second dialog over the top of the reader, which put
the thread behind the reply to it.

**The message is the default.** The pane opens on a box you can type into, and a
report is *inserted* from there with the TEMPLATE button — the design's
+ TEMPLATE. Sending with nothing inserted goes as the `freetext` template, so the
thread it opens is the same kind of thing as every other thread.

| | |
|---|---|
| `composeOpen` | put the pane into compose — thread, template, whether to open on the picker, addressees, answers to start with |
| `composePane` | header, addressing, the message box or the card, SEND |
| `composePicker` | the deck as cards, two up, with what each one will ask for |
| `composeCard` | the inserted template's lines, two columns, a control per field type |
| `composeHarvest` | everything typed, into the answer map — **before every redraw** |
| `composeSend` | the answers, converted and submitted |

The harvest is the load-bearing piece. The pane is thrown away and rebuilt on
every press, so without it, ticking a box halfway down a 9-line wiped the eight
lines above it — which the old compose form did on every single press.

**A refusal is drawn beside SEND**, not only sent to the notification stack. The
stack is an `RscTitles` layer and this screen is a dialog, so a dialog is always
in front of it: the one message telling you why nothing happened was behind the
screen it was about.

**Nothing is auto-filled.** A grid that fills itself in with where you are
standing is a grid nobody reads before sending, and a CASEVAC pick-up that is
quietly your own position is how a bird goes to the wrong field. A location field
is asked for, and there are three honest ways to answer it: **CURRENT LOC**,
**MAP MARKER** (the marker list, nearest first, off `markerGrids`), or type it.
Either button stores a real position and shows it as a grid, so the thread
anchors somewhere the map can pin and the text can still be typed over.

**"Where I am" is where the GPS says** (`jmfsb_ew_fnc_gpsHere`, when EW is
loaded) - CUR LOC on a card, CURRENT LOC on the compose pin and + GRID in a
reply all take it: the false position when the set is spoofed (it does not
know), the held fix with a warning on the rail when it is SUSPECT, and
nothing - with "NO GPS FIX" on the rail - when it is denied. Type the grid.

The one exception is FILE CASEVAC FOR *name* in the squad app, which fills the
pick-up site with that man's position — because the button names the man it is
filling it in for. It writes the template's own `anchor` field, so nothing has to
know which line that is.

A field that *names* a marker rather than holding a position — an LZ name, a DZ
mark — carries `source = "marker"` in the deck and gets the same list, taking the
marker's **name** from it. A call sign and a time still prefill: neither is a
place, both are facts the game already knows about the sender, and both sit in a
box that can be typed over.

**+ MARKER is a quick reply that sends a place.** Beside + TEMPLATE under an open
thread, it drops down the same `markerGrids` list and posts the marker's name
*and* its grid as a free-text reply, in one press. Half of what gets typed into a
thread is somebody reading a grid off the map and typing it back in, which is
where a digit gets dropped; the marker already knows both. The name alone would
not do — a call sign nobody else has on their map is not a location.

## Colour

Nothing in `gui.hpp` carries a colour. Every control is painted at runtime from
four tokens — **ground, ink, accent, line** — which is what makes a scheme change
a repaint of what is already on screen rather than a rebuild.

| scheme | |
|---|---|
| `jmsb` | **JMSB Day** — the unit's paper, `#e9e4d3`, ink `#20261c`, accent `#8a7550` (a darker tan; the logo's `#c2a878` is too pale on a light ground) |
| `light` | **Field Grey** — the design's own ground, `#f3f2f2`, ink `#201e1d`, accent `#ec3013` |
| `olive` | `#e8e7e2`, ink `#16281d`, accent `#b5cc4a` |
| `sand` | `#efece4`, ink `#2b2119`, accent `#d99427` |
| `nightJmsb` *(default)* | **JMSB Night** — the unit's own look (the G logo, ranger green and tan): `#20261c`, ink `#e9e4d3`, accent `#c2a878` |
| `dark` | **Night / Red** — `#141514`, ink `#e6e5e2`, accent `#ff563c` |
| `nightOlive` | **Night Olive** — `#101411`, ink `#d9e0d4`, accent `#9cb43c` |
| `nightSand` | **Night Sand** — `#161310`, ink `#e5e0d6`, accent `#c78221` |
| `custom` | three settings, each `#RRGGBB` or the older `r,g,b`; anything empty falls back to the Field Grey answer |

Four day grounds and four night ones, in **matching pairs** — JMSB Day with JMSB Night, Field Grey with
Night / Red, Olive with Night Olive, Sand with Night Sand — so a unit that runs
olive by day is not forced onto red the moment the sun goes down. A night scheme
is the dark ground under its day scheme's own accent, held down to what does not
blow your eyes out at 0200.

The dark one was called *Night / NVG*, which claimed something it never did: no
scheme here knows or cares whether the player is wearing tubes. It is the red
night ground, and it is named that.

All eight are switchable in game from the settings app, which shows them as the
three tokens they are made of rather than as eight words. The website offers
the same eight (DIVINER_Web `src/schemes.php`).

**A mission can add its own row.** `JMFSB_TacpadSchemes` in the mission's
`config\config_tacpad.hpp` — one class per preset, `name` plus `ground`, `ink`
and `accent` — is drawn under the shipped eight as MISSION PRESETS. Each one is
the `custom` scheme with its three tokens filled in, so a unit palette costs the
mission one file and this addon nothing: there is no extra scheme name here,
and there is nothing for a mission that does not define any to fall over.
See `jmfsb_tacpad_apps_fnc_missionSchemes`.

Reading the player's Arma interface colours was tried and **dropped**. It made
the tacpad a different mod on every machine, and the near-white ink most people
run turned every divider and tile border into a white cage over the map. The
suite is set in one palette so it reads as one thing.

Light and dark are switchable in game from the gear under the message reader,
not just in Addon Options.

## Size

Two levers, deliberately separate:

| | |
|---|---|
| `textScale` | a **legibility** choice — bigger type, taller rows, fewer of them |
| `uiScale` | a **scale** — the same layout, smaller or larger: panels, rows and type together |

A player who wants big text on a small suite can have both. The settings screen's
**UI SIZE** section steps `uiScale` by 1, 5 or 10 percent in either direction with
a RESET TO 100%, because "a bit smaller" is a press rather than a number to look
up; the slider behind it is still in Addon Options.

`uiScale` multiplies a panel's placed **width and height**, not its position — a
suite taken down ten percent keeps every panel where its corner was and gives the
screen back from the other two edges. Dragging the whole layout towards the top
left is not what "make it smaller" means to anyone looking at it.

A size change **rebuilds** rather than repaints, since panel geometry comes out of
`place` — and a rebuild makes every panel the newest control on the display, so
`open` puts the open app back in front afterwards. Arma has no way to raise a
control; reopening the app is a redraw either way.

## Drawing

Panels do not call `ctrlCreate`. Five functions are the whole vocabulary, so a
kicker is the same kicker and a 2px rule is the same 2px rule wherever it lands:

| | |
|---|---|
| `drawFill` | a flat rectangle of colour |
| `drawFrame` | an outline of four edges, drawn *around* what is inside rather than behind it — the only version that composes over a wash |
| `drawText` | one line in a type role, optionally letter-tracked (Arma has no letter-spacing, so a tracked label is drawn with a space between each glyph) |
| `drawIcon` | an image, tinted and squared through the pixel scales |
| `drawHit` | the transparent button and its handler, as one call |
| `textH` | how tall one line is at a given size, so a cell can be sized from the label it holds rather than from a guess at the player's UI scale |
| `headerMeta` | a panel's right-aligned header readout — `13 / 16`, `3 NETS` |
| `appFrame` | the chrome a full-size app opens in, and the body to fill — one copy, where there used to be one per app |
| `appClose` | the one teardown every exit runs — CLOSE, ESC, a click on the map — including the orphan sweep |

`drawText` centres its line vertically in the box it is given, because structured
text renders against the top edge and every label in the suite was sitting high
in its own row with all the air underneath it.

Rule weights are `RULE_THIN` and `RULE_THICK` **in real screen pixels**. The
design separates a 1px row boundary from a 2px region boundary and that
difference is the grid being visible; they were multiplied by the UI grid once,
which drew both at about 4px and made them the same rule.

## Adding a panel

```sqf
["squad", "SQUAD", DEFAULT_SQUAD, FUNC(panelSquad), FUNC(panelSquad), 2] call jmfsb_tacpad_fnc_register;
```

Register in preInit. The shell owns the frame, the dragging, the theming and the
saved position; a panel is handed a body control and fills it. Whether it is
drawn at all is read from `jmfsb_tacpad_apps_show_<id>`, so a new panel needs a
CBA setting with a matching name and nothing else.

The last flag is the **inverted title bar** — ink fill, ground text. An app takes
it, a rail does not; the reader is the only panel that does.

`shared.inc.hpp` carries the geometry and the idc scheme and is deliberately free
of `script_mod.hpp` — an addon that included this one's whole
`script_component.hpp` would have its own `COMPONENT` redefined out from under
it, and every `PREP` in it would then look for its functions in this folder.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_

## Ships

69 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_tacpad_enabled` | CHECKBOX | Enable tacpad |
| `jmfsb_tacpad_displayMode` | LIST | Display mode |
| `jmfsb_tacpad_scheme` | LIST | Colour scheme |
| `jmfsb_tacpad_opacity` | SLIDER | Panel opacity |
| `jmfsb_tacpad_respectZones` | CHECKBOX | Keep clear of reserved areas |
| `jmfsb_tacpad_customGround` | EDITBOX | Custom: ground |
| `jmfsb_tacpad_customInk` | EDITBOX | Custom: text |
| `jmfsb_tacpad_customAccent` | EDITBOX | Custom: accent |
| `jmfsb_tacpad_quickReplies` | EDITBOX | Quick replies |
| `jmfsb_tacpad_uiScale` | SLIDER | UI size |
| `jmfsb_tacpad_textScale` | SLIDER | Text size |

## Functions

<details><summary>69</summary>

- `jmfsb_tacpad_fnc_appAlive`
- `jmfsb_tacpad_fnc_appClose`
- `jmfsb_tacpad_fnc_appExits`
- `jmfsb_tacpad_fnc_appFrame`
- `jmfsb_tacpad_fnc_appHost`
- `jmfsb_tacpad_fnc_appIdle`
- `jmfsb_tacpad_fnc_build`
- `jmfsb_tacpad_fnc_clock`
- `jmfsb_tacpad_fnc_close`
- `jmfsb_tacpad_fnc_composeCard`
- `jmfsb_tacpad_fnc_composeCardHead`
- `jmfsb_tacpad_fnc_composeCcDrop`
- `jmfsb_tacpad_fnc_composeCcIds`
- `jmfsb_tacpad_fnc_composeHarvest`
- `jmfsb_tacpad_fnc_composeOpen`
- `jmfsb_tacpad_fnc_composePane`
- `jmfsb_tacpad_fnc_composePicker`
- `jmfsb_tacpad_fnc_composeSend`
- `jmfsb_tacpad_fnc_composeTargets`
- `jmfsb_tacpad_fnc_composeTiles`
- `jmfsb_tacpad_fnc_composeToPicker`
- `jmfsb_tacpad_fnc_diaryWatch`
- `jmfsb_tacpad_fnc_drawFill`
- `jmfsb_tacpad_fnc_drawFrame`
- `jmfsb_tacpad_fnc_drawHit`
- `jmfsb_tacpad_fnc_drawIcon`
- `jmfsb_tacpad_fnc_drawText`
- `jmfsb_tacpad_fnc_fit`
- `jmfsb_tacpad_fnc_headerMeta`
- `jmfsb_tacpad_fnc_hexOf`
- `jmfsb_tacpad_fnc_hostDisplay`
- `jmfsb_tacpad_fnc_hotspot`
- `jmfsb_tacpad_fnc_markerGrids`
- `jmfsb_tacpad_fnc_netBox`
- `jmfsb_tacpad_fnc_netLabel`
- `jmfsb_tacpad_fnc_open`
- `jmfsb_tacpad_fnc_openApp`
- `jmfsb_tacpad_fnc_openReader`
- `jmfsb_tacpad_fnc_place`
- `jmfsb_tacpad_fnc_rankShort`
- `jmfsb_tacpad_fnc_readerCallUnits`
- `jmfsb_tacpad_fnc_readerCard`
- `jmfsb_tacpad_fnc_readerChip`
- `jmfsb_tacpad_fnc_readerClose`
- `jmfsb_tacpad_fnc_readerComposer`
- `jmfsb_tacpad_fnc_readerDraw`
- `jmfsb_tacpad_fnc_readerFlash`
- `jmfsb_tacpad_fnc_readerInput`
- `jmfsb_tacpad_fnc_readerList`
- `jmfsb_tacpad_fnc_readerMarkers`
- `jmfsb_tacpad_fnc_readerNetView`
- `jmfsb_tacpad_fnc_readerPreview`
- `jmfsb_tacpad_fnc_readerQuick`
- `jmfsb_tacpad_fnc_readerRail`
- `jmfsb_tacpad_fnc_readerReplies`
- `jmfsb_tacpad_fnc_readerRow`
- `jmfsb_tacpad_fnc_readerThreadView`
- `jmfsb_tacpad_fnc_rebuild`
- `jmfsb_tacpad_fnc_register`
- `jmfsb_tacpad_fnc_registerApp`
- `jmfsb_tacpad_fnc_repaint`
- `jmfsb_tacpad_fnc_rgbOf`
- `jmfsb_tacpad_fnc_roleShort`
- `jmfsb_tacpad_fnc_setHost`
- `jmfsb_tacpad_fnc_textH`
- `jmfsb_tacpad_fnc_textPx`
- `jmfsb_tacpad_fnc_textSize`
- `jmfsb_tacpad_fnc_theme`
- `jmfsb_tacpad_fnc_xmlSafe`

</details>
