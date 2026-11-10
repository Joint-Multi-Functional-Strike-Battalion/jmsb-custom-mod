#define COMPONENT maptools
#define COMPONENT_BEAUTIFIED Map Tools
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_MAPTOOLS
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_MAPTOOLS
    #define DEBUG_SETTINGS DEBUG_SETTINGS_MAPTOOLS
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The host geometry and idcs - IDD_MAP and IDC_HOST_MAP. Geometry only: the
// shell's own script_component.hpp would redefine COMPONENT.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// ------------------------------------------------------------- the tools ---
// The ids EFUNC(maptools,start) takes. Public: the TOOLS panel names them.
#define TOOL_RULER "ruler"
#define TOOL_PROTRACTOR "protractor"
#define TOOL_MARK "mark"
#define TOOL_GRID "grid"
#define TOOL_VIEWSHED "viewshed"
#define TOOL_ROUTE "route"
// RINGS and LOS (user, 2026-10-30).
#define TOOL_RINGS "rings"
#define TOOL_LOS "los"
#define TOOLS_ALL [TOOL_RULER, TOOL_PROTRACTOR, TOOL_MARK, TOOL_GRID, TOOL_VIEWSHED, TOOL_ROUTE, TOOL_RINGS, TOOL_LOS]

// RANGE RINGS: the settings' ranges - metres between rings, and how many.
// Each ring's reading sits at its north.
#define RING_STEP_MIN 25
#define RING_STEP_MAX 2000
#define RING_STEP_DEFAULT 100
#define RING_COUNT_MIN 1
#define RING_COUNT_MAX 10
#define RING_COUNT_DEFAULT 5
// LOS: how far apart the line is sampled, m, for where the ground blocks it
// (FUNC(losCheck)), and the readings.
#define LOS_STEP 25
#define LOS_CLEAR "  LOS CLEAR"
#define LOS_BLOCKED "  LOS BLOCKED AT %1"

// --------------------------------------------------------------- numbers ---
#define DEG_PER_TURN 360
#define MILS_PER_TURN 6400
#define M_PER_KM 1000
#define BEARING_DIGITS_DEG 3
#define BEARING_DIGITS_MIL 4
#define KM_DECIMALS 2

// THE 10-DIGIT GRID: five digits an axis, metres inside a 100 km square. The
// map's own coarse square comes from mapGridPosition (whatever digit count the
// terrain's config gives it) and the metres inside it from where the square's
// lines were found to fall - see FUNC(gridCalibrate).
#define GRID_DIGITS 5
#define GRID_SPAN 100000
#define GRID_BISECT 12

// --------------------------------------------------------------- the draw ---
// Map labels, in drawIcon text units at a full-width map. A smaller host (the
// tablet's screen) shrinks them by its width against the safe zone, never
// below TEXT_MIN_K.
#define LABEL_SIZE 0.045
#define LABEL_FONT "RobotoCondensedBold"
#define LABEL_SHADOW 2
#define TEXT_MIN_K 0.5
#define ICON_NONE "#(argb,8,8,3)color(0,0,0,0)"
#define ICON_SIZE_LABEL 1
#define ICON_SIZE_DOT 12
#define FILL_SOLID "#(rgb,8,8,3)color(1,1,1,1)"

// A release this far (screen units) from where its press anchored the ruler
// is a drag; nearer than this it was a click and the ruler waits for a second.
#define DRAG_MIN 0.01

// The protractor: radius in screen units at a full-width map, its tick steps
// in degrees, and tick lengths as fractions of the radius.
#define PROT_RADIUS 0.09
#define PROT_TICK_MINOR 10
#define PROT_TICK_MAJOR 30
#define PROT_TICK_MINOR_K 0.08
#define PROT_TICK_MAJOR_K 0.18
#define PROT_CARDINALS [["N", 0], ["E", 90], ["S", 180], ["W", 270]]
#define PROT_LABEL_K 1.15

// CENTRE's pan, seconds.
#define CENTRE_ANIM 0.2

// YOUR GPS (jmfsb_ew_fnc_gpsState / gpsHere, read only when jmfsb_ew is
// loaded): CENTRE goes where your GPS says you are, and GRID shows your GPS
// grid a line under the cursor's - the false one when spoofed, SUSPECT when
// an anti-spoof set flags it, NO FIX when it is denied.
#define GPS_PREFIX "  GPS "
#define GPS_STATE_NOFIX "NO FIX"
#define GPS_STATE_SUSPECT "SUSPECT"
#define GPS_LINE_K 1.2

// MARK: the marker type and colour a marker gets when nobody picked one, and
// the channel a shared MARK is filed on - the group's. Channels are the
// engine's ids (0 global, 1 side, 2 command, 3 group, 4 vehicle).
#define MARK_TYPE "mil_dot"
#define MARK_COLOR "ColorBlack"
#define MARK_CHANNEL 3
#define MARK_TIME_FORMAT "HH:MM"

// ------------------------------------------------------------ map markers ---
// THE MARKER SYSTEM (user, 2026-11-01: "make an option to use ALiVE marker
// system or ACE ... but must be able to place markers"). Each player's own
// choice, jmfsb_maptools_markerSystem. ACE and ALiVE are offered only when
// loaded: ace_markers, and jmfsb_adapter_alive, which loads only with ALiVE.
#define MARKERS_BUILTIN "builtin"
#define MARKERS_ACE "ace"
#define MARKERS_ALIVE "alive"
#define MARKERS_HAS_ACE (isClass (configFile >> "CfgPatches" >> "ace_markers"))
#define MARKERS_HAS_ALIVE (isClass (configFile >> "CfgPatches" >> QUOTE(DOUBLES(PREFIX,adapter_alive))))
#define MARKERS_VALUES ([MARKERS_BUILTIN] + ([[], [MARKERS_ACE]] select MARKERS_HAS_ACE) + ([[], [MARKERS_ALIVE]] select MARKERS_HAS_ALIVE))
#define MARKERS_LABELS (["Built-in"] + ([[], ["ACE"]] select MARKERS_HAS_ACE) + ([[], ["ALiVE"]] select MARKERS_HAS_ALIVE))

// The channels a marker can go out on, as the game's own marker dialog lists
// them: no DIRECT (the engine files no marker there - ACE leaves it out for
// the same reason). MY MAP is ours, not the engine's: a marker kept local.
#define MARKER_CHANNEL_LOCAL -1
#define MARKER_CHANNEL_LOCAL_LABEL "MY MAP"
#define MARKER_CHANNELS [[0, "GLOBAL"], [1, "SIDE"], [2, "CMD"], [3, "GROUP"], [4, "VEH"]]
// The engine's own channel names, for a channel list ACE's dialog matches by
// name (FUNC(markerAceInit)).
#define MARKER_CHANNEL_STRINGS ["str_channel_global", "str_channel_side", "str_channel_command", "str_channel_group", "str_channel_vehicle"]

// A player's own marker: the engine names it _USER_DEFINED #<player id>/...
#define USER_MARKER_PREFIX "_USER_DEFINED #"

// THE MARKER CARD's icons, by category (user, 2026-11-02: "need more map
// markers in the map marker solution" - "and all that are in this mod"). The
// lists are read from CfgMarkers at runtime (FUNC(markerCardCatalog)) and kept
// for the mission; this table only says which tabs there are, in what order,
// and which class prefixes each takes:
//   [id, tab label, tab tooltip, class prefixes, draw in the icon's own colours]
// A class this mod defines goes under CARD_CATEGORY_MOD whatever its name -
// found by its source addon, not a list, so a new jmfsb marker shows up there
// on its own. Flags and the mod's icons are coloured pictures, drawn as they
// are; every other icon is a shape, drawn in the ink.
#define CARD_CATEGORY_MOD "mod"
// The tabs stand in one row (user, 2026-11-02: "ugly" - one tidy row), so the
// labels are short; the tooltip names each in full.
#define CARD_CATEGORIES [ \
    ["basic", "BASIC", "Basic", ["hd_"], false], \
    ["mil", "MIL", "Military", ["mil_"], false], \
    ["blufor", "BLU", "NATO BLUFOR", ["b_"], false], \
    ["opfor", "OPF", "NATO OPFOR", ["o_"], false], \
    ["indep", "IND", "NATO Independent", ["n_"], false], \
    ["civil", "CIV", "Civilian, unknown and places", ["c_", "u_", "loc_"], false], \
    ["flags", "FLAG", "Flags", ["flag_"], true], \
    [CARD_CATEGORY_MOD, "JMSB", "JMSB markers", [], true] \
]
// The marks a marker is most often, first in their tab and in this order; the
// rest follow in CfgMarkers' order.
#define CARD_TYPES_LEAD ["hd_dot", "hd_objective", "hd_flag", "hd_warning", "hd_destroy", "hd_pickup", "mil_dot", "mil_objective", "mil_flag", "mil_warning", "mil_destroy", "mil_pickup"]
// The colour that is no colour: the marker drawn in its own (a NATO symbol in
// its side's, a flag as it is). Its swatch shows the picked icon's own colour.
#define CARD_COLOR_DEFAULT "Default"
// Icons a row, swatches a row; the most icon rows a page shows - fewer when
// the host is too short for them (FUNC(markerCardDraw)), never fewer than one.
#define CARD_COLS 6
#define CARD_SWATCH_COLS 9
#define CARD_PAGE_ROWS 4
// The page readout under the icons: "2 / 4".
#define CARD_PAGE_FORMAT "%1 / %2"
// SIZE (markerSize, both axes) and DIRECTION (markerDir, degrees): the three
// sizes [label, size, tooltip], and the direction's step a press.
#define CARD_SIZE_NORMAL 1
#define CARD_SIZES [["S", 0.7, "Small"], ["M", CARD_SIZE_NORMAL, "Normal"], ["L", 1.5, "Large"]]
#define CARD_DIR_STEP 15
#define CARD_DIR_FORMAT "%1°"
#define CARD_DIR_DIGITS 3
// The card's width as a share of the host's - an app's - and how far right of
// the point it stands, as a share of the host's width.
#define CARD_W 0.34
#define CARD_OFFSET 0.012
// The card's margin and the air between its sections, in pads.
#define CARD_MARGIN 2
#define CARD_GAP 2
// Icon cells and swatches are square; an icon cell no taller than this many
// rows, a swatch no taller than one. The icon inside its cell.
#define CARD_ICON_ROWS 1.5
#define CARD_ICON_K 0.7
// The pager's and the direction's step keys.
#define CARD_PREV "<"
#define CARD_NEXT ">"
// The text box's type, against its row.
#define CARD_EDIT_FONT_K 0.72
// What the empty text box says.
#define CARD_TEXT_HINT "TEXT"
// The chosen icon on the map at the card's point, screen pixels.
#define CARD_PREVIEW_PX 24
#define KEY_ENTER 28
#define KEY_NUMPAD_ENTER 156

// A double-click this soon (s) after an app closed began on the press that
// closed it - the app's, not a marker's.
#define DBLCLICK_GRACE 0.5
// How often (s) the tools look for a device host's map to hang on.
#define ATTACH_TICK 1

// ACE's dialog: the game's insert-marker display, which ace_markers rebuilds
// (a3\ui_f\hpp\defineResincl.inc: the text box and the channel list). Exit 1
// is its OK.
#define ACE_INSERT_DISPLAY "RscDisplayInsertMarker"
#define IDC_INSERT_MARKER 101
#define IDC_INSERT_MARKER_CHANNELS 103
#define ACE_EXIT_OK 1
// ace_markers' own names, read only when it is loaded: the event its dialog
// raises when set up, the one that sets a marker's look on every machine,
// and the values its dialog keeps while open.
#define ACE_EDITING_EVENT "ace_markers_editingMarker"
#define ACE_SET_MARKER_EVENT "ace_markers_setMarkerNetwork"
#define ACE_DRAW_IDDS "ace_markers_mapDisplaysWithDrawEHs"
#define ACE_MARKER_POS "ace_markers_currentMarkerPosition"
#define ACE_MARKER_TYPE "ace_markers_currentMarkerConfigName"
#define ACE_MARKER_COLOR "ace_markers_currentMarkerColorConfigName"
#define ACE_MARKER_DIR "ace_markers_currentMarkerAngle"
#define ACE_MARKER_SCALE "ace_markers_currentMarkerScale"

// ------------------------------------------------------------- viewshed ---
// Eye and target heights over the ground, metres: a man standing looking for
// a man standing.
#define VS_EYE 1.7
#define VS_TARGET 1.5
// Rays a frame. The whole of the cost is here: a frame never traces more.
#define VS_RAYS_PER_FRAME 60
// Sectors: enough that the outer ring's cells are about the cell size wide,
// held between these so a small radius is not a pie and a large one does not
// trace thousands of slivers.
#define VS_SECTORS_MIN 24
#define VS_SECTORS_MAX 180
// The settings' ranges, metres.
#define VS_RADIUS_MIN 200
#define VS_RADIUS_MAX 3000
#define VS_RADIUS_DEFAULT 1000
#define VS_CELL_MIN 20
#define VS_CELL_MAX 200
#define VS_CELL_DEFAULT 50
// The most cells one viewshed draws (two triangles each, every frame the map is
// open); a finer setting at a wide radius gets a coarser cell instead.
#define VS_CELLS_MAX 4000
// Fill alphas: what the point sees, and what it does not.
#define VS_ALPHA_SEEN 0.35
#define VS_ALPHA_HIDDEN 0.3
#define PERCENT 100
