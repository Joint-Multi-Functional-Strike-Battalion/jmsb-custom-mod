#define COMPONENT pointman
#define COMPONENT_BEAUTIFIED Point Man
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_POINTMAN
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_POINTMAN
    #define DEBUG_SETTINGS DEBUG_SETTINGS_POINTMAN
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The tacpad's drawing grammar - host rectangle, row height, padding, rule
// weights - so the page is drawn in the same hand as every other app.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// ---------------------------------------------------------------------------
// POINT MAN (user, 2026-10-30: "a navigation app to way points ... call it
// point man, where you open an app drop down of waypoints or type in grids,
// have an add to keep adding waypoints then draw on the map and update the
// phone with distance when using"). The waypoints are this player's own,
// client side, in order; USE walks them from the first, moving on at the
// arrival radius (the CBA setting) and ending at the last.
// ---------------------------------------------------------------------------
#define APP_ID "pointman"
#define APP_TITLE "POINT MAN"
#define APP_W 0.5
// The page's height: the fixed rows, plus one row height per waypoint.
#define APP_H_BASE 0.34
// Seconds between redraws while the page is open: the distances walk.
#define PM_REFRESH 2
// Seconds between arrival checks, and the attach to a tablet map that opened.
#define PM_TICK 1
// A waypoint: [position, label, target]. The label is the grid it was given,
// or the ten-figure grid of the point picked on the map. A FOLLOW waypoint's
// target is the man it walks with (objNull otherwise) and its position is
// where he was last seen (FUNC(wpPos)).
#define WP_POS 0
#define WP_LABEL 1
#define WP_TARGET 2
#define MAX_WAYPOINTS 20
// FOLLOW (user, 2026-10-30): the contacts on the page are the BFT picture's
// friendlies (FUNC(contacts)); the waypoint is labelled with the man's
// number and name, the name cut to this many letters.
#define FOLLOW_LABEL "FOLLOW %1 %2"
#define FOLLOW_NAME_MAX 14
// THE ELEVATION PROFILE (FUNC(profile)): this many samples of the ground
// along the route, drawn as a strip this many rows high; a route flatter
// than this span of metres is drawn flat rather than stretched to the strip.
#define PROFILE_BARS 60
#define PROFILE_ROWS 3
#define PROFILE_MIN_SPAN 10
// A waypoint with no name on it yet, when the grid could not be read.
#define WP_UNNAMED "WP"
// PICK ON MAP: the map claimed through the tacpad (EGVAR(tacpad,appMapClaim))
// so the press is this app's, like TAC//SUPPORT's; left adds, right ends,
// and it ends itself after this long untouched.
#define CLAIM "pointman"
#define MOUSE_PICK 0
#define MOUSE_CANCEL 1
#define PM_PICK_S 180
#define PM_PICK_TICK 0.5
// The phone's status cell (jmfsb_devices' row: icon word, value, state - its
// STATE_OFF .. STATE_ALERT), first in the row while navigating.
#define STATUS_ICON "PM"
#define PM_STATE_OFF 0
#define PM_STATE_OK 1
#define PM_STATE_WARN 2
#define PM_STATE_ALERT 3
// Drawn like the map tools' route: their label size, floor and dot
// (jmfsb_maptools LABEL_SIZE, TEXT_MIN_K, ICON_SIZE_DOT, MARK_TYPE).
#define LABEL_SIZE 0.045
#define TEXT_MIN_K 0.5
#define ICON_SIZE_DOT 12
#define DOT_MARKER "mil_dot"
// What the tablet bar says while navigating (jmfsb_devices_fnc_deviceFacts).
#define NAV_FORMAT "PM WP%1 %2 %3"
#define NOTIFY_TITLE "POINT MAN"
