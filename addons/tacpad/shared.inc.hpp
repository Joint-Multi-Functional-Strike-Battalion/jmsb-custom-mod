// Geometry and idcs the shell and its panels both need. Deliberately free of
// script_mod.hpp and script_macros.hpp: an addon that included the shell's
// whole script_component.hpp would have its own COMPONENT redefined out from
// under it, and every PREP in it would then look for its functions in the
// shell's folder.

// THE MAP IS THE SHELL. Every panel is a controls group on the vanilla map
// display, not a dialog of its own - so the map stays a map, the player keeps
// panning and clicking it, and a panel is laid on top rather than replacing it.
#define IDD_MAP 12

// THE HOST. Where the suite draws, as [x, y, w, h] in screen units, and the
// display it draws on. In NATIVE mode that is the vanilla map's safe zone and
// display 12, as it always was. In TABLET mode jmfsb_devices hands over its
// dialog and the screen rectangle inside the device frame, and every panel,
// app, row and reader lays itself out inside that instead - the same layout,
// rescaled. Set by EFUNC(tacpad,setHost); read through these and nothing else.
//
// NOTHING IN THE SUITE NAMES safeZone* ANY MORE. A panel that did would draw
// at monitor size inside a screen two thirds that wide. The one exception is
// TAC//SUPPORT's dialog, which is a dialog of its own on the NATIVE host only
// and keeps its safe-zone geometry there. On the tablet it opens no dialog: it
// draws on the host display like every other app and picks on the host's own
// map - see IDC_HOST_MAP.
//
// THE HOST'S MAP. idc 51 on both hosts - the vanilla map's own control, and
// the device dialog's screen (jmfsb_devices declares its map with the same
// idc on purpose). An app that needs map picks claims it through
// QGVAR(appMapClaim) so the click-outside-closes rule stands down while it
// holds it - see FUNC(appExits).
#define IDC_HOST_MAP 51
//
// HOST_K scales type with the host. Text is set in pixelGrid units, which know
// nothing about the host, so a screen 0.65 of the monitor wide would carry
// full-size type and three words per row. The smaller of the two ratios, so a
// tall narrow screen gets text that fits its width. 1 on the vanilla map.
#define HOST_RECT (EGVAR(tacpad,host))
#define HOST_X (HOST_RECT select 0)
#define HOST_Y (HOST_RECT select 1)
#define HOST_W (HOST_RECT select 2)
#define HOST_H (HOST_RECT select 3)
#define HOST_K ((HOST_W / safeZoneW) min (HOST_H / safeZoneH))
#define HOST_DISPLAY (call EFUNC(tacpad,hostDisplay))
#define HOST_NATIVE (EGVAR(tacpad,displayMode) isEqualTo "native")
#define HOST_DEVICE (EGVAR(tacpad,displayMode) isNotEqualTo "native")

// Panels get a block of idcs each, so a panel can own its children without
// asking anyone. 20 is more than any panel needs and keeps the ranges legible
// in a debug readout.
#define IDC_BASE 9200
#define IDC_STRIDE 20
#define IDC_PANEL(n) (IDC_BASE + (n) * IDC_STRIDE)
#define IDC_HEADER(n) (IDC_BASE + (n) * IDC_STRIDE + 1)
#define IDC_TITLE(n) (IDC_BASE + (n) * IDC_STRIDE + 2)
#define IDC_BODY(n) (IDC_BASE + (n) * IDC_STRIDE + 3)

// The header's right-aligned readout - "13 / 16", "3 NETS MONITORED". Part of
// the frame rather than of a panel's content, because it belongs to the title
// bar and a panel that redraws its body must not have to redraw it.
#define IDC_META(n) (IDC_BASE + (n) * IDC_STRIDE + 4)

// The ground, and the rule under a non-inverted header. Addressed by idc because
// the frame is now an outline of four edges, and "the first two children" - how
// fit and repaint used to find them - stopped meaning anything.
#define IDC_GROUND(n) (IDC_BASE + (n) * IDC_STRIDE + 5)
#define IDC_RULE(n) (IDC_BASE + (n) * IDC_STRIDE + 6)

// Eight was exactly the number registered, so the next panel anybody added was
// silently rejected at the bottom of FUNC(register). Ten leaves room; the idc
// blocks are 20 apart from 9200, so ten of them is 9200-9400 and collides with
// nothing.
// 12, not 10: with hide, settings, tools and the APS panel registered the
// eleventh was refused every start ("panel 'aps' rejected", rpt 2026-10-08).
#define PANEL_MAX 12

// RESERVED ZONES, in safe-zone fractions. The design names three regions a
// panel must never cover, and they are here rather than in the panels because a
// panel does not get an opinion about it: the vanilla game menu top-left, the
// chat overlay bottom-left (8 grid cells by 2.5), and the scale and contour
// legend bottom-right.
// The vanilla map's own top bar - mission name, player slot, the icon row and
// the clock - runs the FULL width, so it is not covered by the top-left menu
// zone. A panel dropped at the top of the screen lands on it, which is where
// the tiles and the reader both were.
#define ZONE_TOP [0, 0, 1, 0.028]

#define ZONE_MENU [0, 0, 0.13, 0.16]
#define ZONE_CHAT [0, 0.80, 0.36, 0.20]
#define ZONE_LEGEND [0.85, 0.92, 0.15, 0.08]

// Frame geometry. Exact dividers and zero corner radius everywhere is the whole
// look, so a border is a real control rather than a stretched texture.
//
// RULES ARE IN REAL SCREEN PIXELS and are not scaled by anything. The design
// separates a 1px row boundary from a 2px region boundary, and that difference
// is the grid being visible; multiply either by the UI scale and they converge.
// They were `pixelW * pixelGrid * 0.5 * BORDER_PX` once, which is about 4px on a
// default grid - every edge in the suite was drawn at twice its weight.
#define RULE_THIN 1
#define RULE_THICK 2

// A TITLE BAR IS A LABEL, NOT A REGION. It was 0.040 of the safe zone - taller
// than the rows underneath it - which made every panel look like a box with a
// lid. It is the same height on every panel and always will be: the whole point
// of the shell owning the frame is that they cannot drift.
#define HEADER_H 0.021

// A ROW IS TYPE PLUS AIR, NOT A BAND WITH TYPE IN IT. This was 0.030, which at
// the default text scale is about three and a half times the height of the line
// standing in it - so every list in the suite read as widely spaced labels with
// nothing between them, and the squad rail needed half the screen to show four
// men. Tightened twice, to about one and a half times the line: the design's
// own density, and the point at which a twelve-row readout is a block of data
// rather than a page of it.
#define ROW_H 0.021
#define PAD 0.004

// The body size every <t> tag scales off. One number, so a size='0.8' kicker is
// the same kicker in every panel - and one number to turn up when the suite is
// too small to read at a glance, which is what a map screen is for.
//
// It was 1.45, which put the design's own type sizes on screen almost exactly -
// 9.5px micro-labels, a 26px tile value. That was the mistake: the design was
// drawn for a 1280x800 tablet held at arm's length, and 9.5px of a 1080p map
// screen is not the same thing at all. Everything is set about 40% up from the
// drawn sizes so the proportions survive and the labels can be read.
#define TEXT_BASE 2.0

// THE TYPE SCALE - one font (RobotoCondensed, bold for emphasis) and these four
// sizes, as multiples of the body size, for every app on every device (user,
// 2026-10-21: "make sure all apps have the same font and font size"). There were
// some forty sizes from 0.5 to 2.4; each is now the role it was nearest to.
//   LABEL    kickers, small-caps labels, notes and hints
//   BODY     rows, values, buttons, list and message text
//   TITLE    app titles, headers, subjects, the emphasised value in a row
//   DISPLAY  the big read-outs: the timer, a tile's value, a state word
#define TEXT_LABEL 0.6
#define TEXT_BODY 0.7
#define TEXT_TITLE 0.85
#define TEXT_DISPLAY 1.6
// LABEL and BODY are drawn this many pixels larger than the scale (FUNC(textSize);
// user, 2026-10-21: "make the font on all the apps 1px larger, not the headers").
#define APP_TEXT_PX 1
// Two pixels more than that for the text the user asked up on 2026-10-22 -
// the squad rail and the tiles' small lines ("2px larger") - through
// jmfsb_tacpad_fnc_textPx, whose answer FUNC(textSize) then leaves alone.
#define TEXT_UP_PX 2
#define APP_TEXT_UP_PX (APP_TEXT_PX + TEXT_UP_PX)

// Where a panel goes when it has never been placed, as [x, y, w, h] fractions.
// Taken off the mockup: tiles across the top band, squad down the left rail,
// the reader docked right, tools along the bottom centre.
// Y clears ZONE_TOP. They both sat at 0.02 and were drawn over the vanilla top
// bar - the panels were on the screen before the map screen's own furniture.
// ALIGNED TO ITS NEIGHBOURS. The band starts where the squad rail's right edge
// is (0.008 + 0.150) and ends where the reader column's left edge is (0.72), so
// the three panels read as one layout instead of three that happen to be near
// each other. What is left is 0.562 of the safe zone, and six tiles fit it -
// see TILE_W, which was trimmed by four thousandths to make them.
// Expanded LEFT over the free space above the squad rail (the rail starts at
// y 0.20; nothing lives left of the old band edge at tile height) to seat the
// SUPPORT tile - the user's call: compress a little, expand left if needed.
// 0.60, and the band ALSO self-clamps against the reader's placed edge in
// FUNC(panelTiles) - because placement multiplies width by the player's UI
// scale, and every constant that cleared the reader at scale 1 ran back
// under it at scale 1.1+. That is how this overlapped three times.
#define DEFAULT_TILES [0.008, 0.031, 0.60, 0.11]
#define DEFAULT_SQUAD [0.008, 0.20, 0.150, 0.60]
#define DEFAULT_READER [0.72, 0.031, 0.27, 0.66]
// The tools strip is three rows of four now that CENTRE has joined it, so it
// starts higher: at 0.875 the third row was being squeezed by FUNC(fit) against
// the bottom of the safe zone. Panels no longer move, so a default is the only
// position there is and it has to be right.
#define DEFAULT_TOOLS [0.40, 0.845, 0.30, 0.11]

// THE STRIP UNDER THE READER: three buttons, edge to edge across the reader's
// own width, with a four-thousandth gutter between them.
//
// NONE OF THE THREE HAS A TITLE BAR. They are buttons, not panels - a header
// reading SETTINGS over a cell reading SETTINGS is the same word twice, and on a
// control this short the bar was half its height. They are registered chromeless
// (see FUNC(register)), which is also what lets three of them fit in the space
// two of them used to need.
//
// The gear sits directly under the reader, which is what makes it findable:
// settings for the suite live where the suite is, not in a menu three layers
// down.
// THREE STRIPS IN THE SAME RUN, 0.72 to 0.99, four thousandths apart. A
// fourth - FORCE CLOSE - lived here briefly and was removed: a page closes
// on ESC or on a click on the map now, so there is nothing for a panic
// button to rescue.
// FOUR BUTTONS NOW, EDGE TO EDGE ACROSS THE READER'S OWN WIDTH. The reader runs
// 0.72 to 0.99, which is 0.27; three gutters of four thousandths leaves 0.258 for
// the buttons, so each is 0.0645. The left edge of the first and the right edge
// of the last land exactly on the reader's, which is the whole point of the row.
//
//   TOOLS 0.7200 | SETTINGS 0.7885 | ADMIN 0.8570 | HIDE 0.9255 -> 0.9900
//
// TOOLS hides the MAP TOOLS bar - three rows of four buttons is a lot of map to
// give up when nobody is measuring anything.
#define DEFAULT_TOOLSBTN [0.7200, 0.700, 0.0645, 0.032]
#define DEFAULT_SETTINGS [0.7885, 0.700, 0.0645, 0.032]

// ADMIN, between the two. It is only registered when jmfsb_adminpanel is loaded
// and only drawn for an admin - see EFUNC(adminpanel,panelAdmin) - so for most
// players the strip is the two buttons it always was, with the gap closed up by
// their own saved positions.
#define DEFAULT_ADMIN [0.8570, 0.700, 0.0645, 0.032]

// TROOPS IN CONTACT, under the three strips: the loudest control in the suite,
// where the rail ends and a thumb lands without aiming. Chromeless like them -
// a title bar reading CONTACT over a cell reading TROOPS IN CONTACT was a label
// for a label, and this is the one control on the map that has to be pressed
// without being read first.
//
// THE SAME AIR ABOVE IT AS THE STRIPS HAVE UNDER THE READER. The reader ends at
// 0.691 and the strips sit at 0.700; a chromeless strip fits to about 0.044 at
// the default text size, so the strips end near 0.744 and this starts nine
// thousandths under them. It was 0.784, which was right when all three carried a
// title bar and left a hole once they stopped.
#define DEFAULT_TIC [0.72, 0.753, 0.27, 0.046]

// How long the TIC button holds after a press. A man under fire presses a big
// red button more than once; one contact is one report.
#define TIC_COOLDOWN 30

// HIDE / SHOW IS ITS OWN PANEL, and the only pinned one. It was a second cell
// inside the settings strip, which meant the master switch could not take the
// gear with it - hiding the suite left a settings button on the map with
// nothing to configure. Separated, HIDE ALL clears everything except the one
// control that undoes it.
#define DEFAULT_HIDE [0.9255, 0.700, 0.0645, 0.032]

// THE READER, as a real display. Not because the map display cannot take a
// click - it can, and every panel on it does - but because the composer has to
// be typed into, and an edit control wants a dialog with keyboard focus. The
// screen itself is drawn with the same vocabulary as the panels.
#define IDD_READER 8900
#define IDC_RD_BG 8901
#define IDC_RD_INPUT 8902
#define IDC_RD_ROOT 8903
#define IDC_RD_CONTENT 8904
// The thread list's filter box and the FLASH banner (FUNC(readerFlash)).
#define IDC_RD_FILTER 8905
#define IDC_RD_FLASH 8906

// COMPOSING IS A STATE OF THE RIGHT PANE, NOT A WINDOW. It was a second dialog
// over the top of the reader - so sending a report meant closing the traffic you
// were answering, and the thread you were replying to was behind the thing you
// were typing into. NEW and + TEMPLATE now switch the pane the thread was in.
//
// The message body is the default state. A template is something you INSERT
// with the TEMPLATE button, the way the design draws it, rather than something
// you must pick before the screen will let you type a word.

// THE DERIVED THEME STEPS (FUNC(theme)): how far each is mixed from the three
// tokens. Matched to the handoffs' ramps on Field Grey: accent-100 is ground
// with a sixteenth of accent, accent-700 is accent a quarter of the way to ink.
#define TINT_ACCENT 0.06
#define MIX_ACCENT_HOVER 0.12
#define MIX_ACCENT_TEXT 0.25
#define MIX_ACCENT_DEEP 0.5
#define TINT_SURFACE 0.05
#define MIX_MUTED 0.3
#define MIX_DIM 0.45

// The two colour swatches the theme does not already carry - GREEN and YELLOW
// on a report card's GREEN / YELLOW / RED / BLACK lines (RED is the accent,
// BLACK the ink). The handoff's oklch(0.55 0.13 145) and oklch(0.78 0.14 85).
#define SWATCH_GREEN [0.29, 0.58, 0.31, 1]
#define SWATCH_YELLOW [0.85, 0.68, 0.28, 1]
