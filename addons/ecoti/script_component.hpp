#define COMPONENT ecoti
#define COMPONENT_BEAUTIFIED ECOTI
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ECOTI
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_ECOTI
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ECOTI
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// DIK_N for the power key. The macro header does not pull these in.
#include "\a3\ui_f\hpp\definedikcodes.inc"

// --- When it is on ----------------------------------------------------------
// currentVisionMode: 0 day, 1 image intensifier, 2 thermal. ECOTI rides the
// intensifier, and day too on a goggle that says jmfsb_ecoti_day = 1 - never
// TI, where the picture already IS a thermal.
#define VISION_MODE_NVG 1
#define VISION_MODE_TI 2
#define IDD_ZEUS 312

// --- Cadence -----------------------------------------------------------------
// Who is in range is asked twice a second; whether each of them can be SEEN is
// asked in VIS_SLICES slices a VIS_TICK apart, so every target is re-checked
// every VIS_TICK * VIS_SLICES seconds (0.2 s) and no frame pays for all of them.
#define CANDIDATE_TICK 0.5
#define VIS_TICK 0.05
#define VIS_SLICES 4

#define MAN_TYPES ["CAManBase"]
#define VEHICLE_TYPES ["LandVehicle", "Air", "Ship"]
#define ANIMAL_TYPES ["Animal"]

// --- Visibility --------------------------------------------------------------
// LINE OF SIGHT ONLY (user, 2026-10-17). A box is drawn while the player can
// SEE the target - checkVisibility from his eyes against the VIEW LOD, the one
// AI sight uses, in which vegetation is partly transparent and walls are not -
// and goes at the first re-check that he cannot: nothing is held on screen
// after the target is out of sight.
#define VIS_LOD "VIEW"
// Against flicker without holding a box: it appears once at least VIS_SHOW of
// the target shows, and goes once less than VIS_MIN does. A ray grazing a leaf
// edge moves between the two without blinking the box.
#define VIS_SHOW 0.15
#define VIS_MIN 0.05

// --- The thermal window ------------------------------------------------------
// Screen maths in UI units. The screen centre is 0.5, 0.5 in safeZone terms, and
// one x unit is ASPECT_4_3 y units wide in pixels - the 4:3 design frame - so a
// circle measured in screen heights is round on any monitor.
#define SCREEN_CENTRE 0.5
#define ASPECT_4_3 (4 / 3)
#define OFF_WINDOW 1e3
// The window under a full-screen goggle (FUNC(isFullScreen)), in screen heights
// from the centre: past the corners of a 32:9 screen, so all of it is drawn,
// and not much further, so what is off to the side is not drawn for nothing.
#define FULL_SCREEN_WINDOW 2
// Distance of a worldToScreen result from the centre, in screen heights.
// worldToScreen returns [] behind the camera; that counts as outside.
#define SCREEN_DIST(SCR) (if ((SCR) isEqualTo []) then {OFF_WINDOW} else {(sqrt (((((SCR) select 0) - SCREEN_CENTRE) * ASPECT_4_3) ^ 2 + (((SCR) select 1) - SCREEN_CENTRE) ^ 2)) / safeZoneH})
// A worldToScreen result as a point in that same plane - screen heights from
// the centre, x widened - where a circle is round. Not for [].
#define SCREEN_XY(SCR) [((((SCR) select 0) - SCREEN_CENTRE) * ASPECT_4_3) / safeZoneH, (((SCR) select 1) - SCREEN_CENTRE) / safeZoneH, 0]

// --- The sensor --------------------------------------------------------------
// Contrast falls off with range: full at the near distance, this at max range.
#define FAR_ALPHA_MIN 0.35

// Model and camera origin.
#define ORIGIN [0, 0, 0]

// --- Colour (FUNC(targetColour), user 2026-10-17) ----------------------------
// The engine's own line: getFriend below this is hostile, at or above friendly.
#define FRIENDLY_MIN 0.6
// Sides that are nobody's force - drawn as unknown. Civilians are their own
// case (white, red when armed); sideEnemy (a renegade) is not here - getFriend
// puts him below FRIENDLY_MIN for everyone.
#define UNKNOWN_SIDES [sideUnknown, sideEmpty, sideLogic, sideAmbientLife]
#define UNKNOWN_RGB [1, 0.85, 0.2]
#define CIVILIAN_RGB [1, 1, 1]

// --- The boxes (FUNC(boxRect)) -----------------------------------------------
// One box per target, never outlines: the traced outlines took the game from
// 50+ to under 10 FPS (user, 2026-10-17).
// A man's box runs feet to crown; the crown is this far past his eyes.
#define BODY_CROWN_PAST_EYES 0.12
// Prone: his feet are this far behind his eyes, along the way he faces.
#define PRONE_LENGTH 1.6
// Metres of box round a man's feet-to-crown line - his width.
#define MAN_BOX_MARGIN 0.25

// --- The boxes on screen (FUNC(drawBoxes)) ----------------------------------
// UI controls on the mission display, placed on whole pixels: a box's four
// strips are laid inside its rectangle edge to edge, so the corners meet.
#define IDD_MISSION 46
#define PIXEL_X(V) ((round ((V) / pixelW)) * pixelW)
#define PIXEL_Y(V) ((round ((V) / pixelH)) * pixelH)
// No more boxes than this in one frame - a crowd costs no more than this many.
#define MAX_BOXES 48

// --- The AiTR label (FUNC(targetLabel)) --------------------------------------
// Under each box: what it is, one thing about it, and its range - a line of
// text this many pixels high, in a control this wide (UI units), centred.
#define LABEL_SEPARATOR " | "
#define LABEL_PIXELS 18
#define LABEL_WIDTH 0.5
// Past this the range reads in kilometres.
#define LABEL_KM 1000
// One line of label text is LABEL_PIXELS high; a line takes this much of it again.
#define LABEL_LINE_SPACING 1.15

// --- The net card (FUNC(targetCard)) ------------------------------------------
// The squad page's own line: below this health a man is wounded.
#define CARD_HURT_BELOW 90
// ACE report colours, by index + 1 - unreported and OK green, amber, red, KIA
// grey - the squad page's HEALTH_ colours, KIA lifted to grey to read at night.
#define ACE_COLOURS ["#338c40", "#338c40", "#d9ad26", "#d9331a", "#8c8c8c"]
// How often this player's frequency is looked at (it is sent only on change),
// and how it is written.
#define FREQ_TICK 5
#define FREQ_DECIMALS 3

// --- The compass (FUNC(drawCompass), user 2026-10-19) -------------------------
// A DUI-style line compass across the top centre while AiTR is up. Laid out on
// DUI's own grid - a row is a 108th of the safe-zone height, a column that much
// narrowed to the 4:3 frame - so it sits where a DUI player expects one.
#define COMPASS_GRID (safeZoneH / 108)
#define COMPASS_GX(V) ((V) * COMPASS_GRID / ASPECT_4_3)
#define COMPASS_GY(V) ((V) * COMPASS_GRID)
// Columns per degree, and how far either side of the heading is drawn: 180 of
// the 360 degrees on the strip, as DUI's.
#define COMPASS_DEG_COLS 0.5
#define COMPASS_HALF_SPAN 90
// Ticks every 5 degrees, a label every 15, the cardinals and intercardinals by name.
#define COMPASS_TICK_STEP 5
#define COMPASS_LABEL_STEP 15
#define COMPASS_NAME_STEP 45
#define COMPASS_NAMES ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
#define COMPASS_TICKS (2 * COMPASS_HALF_SPAN / COMPASS_TICK_STEP + 1)
#define COMPASS_LABELS (2 * COMPASS_HALF_SPAN / COMPASS_LABEL_STEP + 1)
#define FULL_CIRCLE 360
#define HEADING_DIGITS 3
// Full strength out to this far from the centre (degrees); faded to nothing at
// the ends of the strip.
#define COMPASS_FADE 30
// Rows from the top of the safe zone, and sizes - rows down, columns across.
#define COMPASS_TOP 1
#define COMPASS_TICK_PIXELS 2
#define COMPASS_TICK_MINOR 0.8
#define COMPASS_TICK_MAJOR 1.4
#define COMPASS_LABEL_TOP 1.8
#define COMPASS_LABEL_W 6
#define COMPASS_LABEL_H 2.2
#define COMPASS_FONT_NAME 2.4
#define COMPASS_FONT_NUMBER 1.8
// The centre marker: an accent bar through the tick band, a little past it each way.
#define COMPASS_MARKER_PIXELS 3
#define COMPASS_MARKER_OVER 0.4
// The heading readout, under the labels.
#define COMPASS_READOUT_TOP 4.2
#define COMPASS_READOUT_W 8
#define COMPASS_READOUT_H 2.6
#define COMPASS_FONT_READOUT 2.4
#define COMPASS_WHITE [1, 1, 1, 1]

// Frames Draw3D may miss before FUNC(hideCovered) treats the scene as not drawn
// (EachFrame can run before Draw3D in the same frame, so one frame is allowed).
#define DRAW_FRAME_GAP 1

// The engine's control style for centred text; its own header's IDC_ names are
// not wanted here.
#ifndef ST_CENTER
    #define ST_CENTER 2
#endif
