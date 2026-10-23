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
#define TOOLS_ALL [TOOL_RULER, TOOL_PROTRACTOR, TOOL_MARK, TOOL_GRID, TOOL_VIEWSHED, TOOL_ROUTE]

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

// MARK: the marker type and the channel the marker is filed on - local unless
// the player shares marks, when the group channel carries it.
#define MARK_TYPE "mil_dot"
#define MARK_CHANNEL "group"
#define MARK_TIME_FORMAT "HH:MM"

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
// Fill alphas: what the point sees, and what it does not.
#define VS_ALPHA_SEEN 0.35
#define VS_ALPHA_HIDDEN 0.3
#define PERCENT 100
