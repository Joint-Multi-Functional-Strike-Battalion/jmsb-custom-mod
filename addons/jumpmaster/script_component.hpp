#define COMPONENT jumpmaster
#define COMPONENT_BEAUTIFIED Jumpmaster
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_JUMPMASTER
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_JUMPMASTER
    #define DEBUG_SETTINGS DEBUG_SETTINGS_JUMPMASTER
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The tacpad's drawing grammar, so the page is drawn in the same hand as
// every other app.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// ---------------------------------------------------------------------------
// JUMPMASTER (user, 2026-10-30): HALO, HAHO and static-line jumps for a
// squad, run by its leader from the tablet. He picks the type, a flight path
// of a RED LIGHT point and a GREEN LIGHT point, the passes and whether the
// stick goes automatically at the green light or each man exits himself;
// the page checks every man's mask and chute first. LAUNCH puts the squad in
// a moving aircraft at altitude on the path; the server flies it.
// ---------------------------------------------------------------------------
#define APP_ID "jumpmaster"
#define APP_TITLE "JUMPMASTER"
#define APP_W 0.58
// The page's height: the fixed rows, plus one row height per man.
#define APP_H_BASE 0.5
// Seconds between redraws while the page is open: the stick's readiness and
// the run's phase change under it.
#define JM_REFRESH 2

#define TYPE_HALO "HALO"
#define TYPE_HAHO "HAHO"
#define TYPE_STATIC "STATIC"
#define TYPES [TYPE_HALO, TYPE_HAHO, TYPE_STATIC]
// The types that fall free from altitude - a mask is needed up there.
#define FREEFALL_TYPES [TYPE_HALO, TYPE_HAHO]
#define EXIT_AUTO "auto"
#define EXIT_MANUAL "manual"
#define BAY_SEATS "seats"
#define BAY_STAND "stand"
// Who runs a jump: the voice permission table's squad leader and admin
// (jmfsb_tacpad_apps_fnc_radioRole).
#define JUMPMASTER_ROLES ["SL", "ADMIN"]
#define PASSES_MIN 1
#define PASSES_MAX 4
// The server's machine. LAUNCH and ABORT reach it by remoteExec, and it sends
// each man's board, light, jump and word back the same way (review S7).
#define SERVER_OWNER 2
#define EXITS [EXIT_AUTO, EXIT_MANUAL]

// THE FLIGHT PATH, m: the aircraft appears RUN_IN before the red light on the
// line through it and the green light, carries straight on RUN_OUT past the
// green light before turning, and a manual stick's window is WINDOW_LEN past
// it. POINT_RING is how close to a turning point counts as there.
#define RUN_IN 3000
#define RUN_OUT 1500
#define WINDOW_LEN 1500
#define POINT_RING 600
// A plane appears at this share of its top speed.
#define PLANE_START_SPEED 0.6
// The hold over the drop zone while men are still aboard after the last pass.
#define HOLD_RADIUS 800
// Gone: this far from the green light with nobody aboard, and a run lasts
// this long at most.
#define LEAVE_DIST 4000
#define RUN_MAX_S 1800
// The run's watch, s.
#define RUN_TICK 0.5

// THE STICK: seconds between jumpers out, the static line's pull after exit
// and its canopy watch (support_air's JUMP_INTERVAL, STATIC_OPEN_DELAY and
// CHUTE_TICK, whose chuteTick opens the canopy).
#define JUMP_INTERVAL 0.7
#define STATIC_OPEN_DELAY 1
#define CHUTE_TICK 0.1
// Out behind the aircraft, not through it: clearance behind the tail and
// under the belly, m, and the spread either side.
#define EXIT_TAIL_GAP 3
#define EXIT_BELLY_GAP 3
#define EXIT_SIDE 2
// STANDING IN THE BAY (setting "stand"): fixed to the hull in two files
// either side of the centreline, this far apart, from this share of the
// hull's length back of centre to this share forward, this high over the
// hull's floor. Fixed, not walked: the engine does not carry a walking man
// in a moving aircraft; an aircraft that does gets "seats" and its own bay.
#define STAND_FILE_X 0.8
#define STAND_SPACING 1
#define STAND_FROM -0.35
#define STAND_TO 0.1
#define STAND_FLOOR 1.2
// The side's cargo aircraft when the setting names none: west, east, independent.
#define DEFAULT_AIRCRAFT ["B_T_VTOL_01_infantry_F", "O_T_VTOL_02_infantry_F", "B_T_VTOL_01_infantry_F"]

// A run's phases.
#define PHASE_IN "in"
#define PHASE_RED "red"
#define PHASE_GREEN "green"
#define PHASE_CIRCLE "circle"
#define PHASE_HOLD "hold"
#define PHASE_LEAVE "leave"
#define PHASE_WORDS [["in", "INBOUND"], ["red", "RED LIGHT"], ["green", "GREEN LIGHT"], ["circle", "CIRCLING"], ["hold", "HOLDING OVER DZ"], ["leave", "LEAVING"]]

// PICK PATH ON MAP: the map claimed through the tacpad, two presses - red
// then green - right click cancels, over after this long untouched.
#define CLAIM "jumpmaster"
#define MOUSE_PICK 0
#define MOUSE_CANCEL 1
#define JM_PICK_S 120
#define JM_PICK_TICK 0.5
// Drawn like the map tools' route: their label size, floor and dot.
#define LABEL_SIZE 0.045
#define TEXT_MIN_K 0.5
#define ICON_SIZE_DOT 12
#define DOT_MARKER "mil_dot"
// The manual exit's place in the action menu.
#define ACTION_PRIORITY 10
#define NOTIFY_TITLE "JUMPMASTER"

// WIND (user, 2026-10-30): where the stick lands. The engine carries a canopy
// with the wind and a free-falling man not at all, so the drift is the wind
// for the seconds under canopy at this sink rate - the engine's canopies,
// near enough (FUNC(drift)). LAND is drawn, and SHIFT PATH FOR WIND offered,
// from this much drift, m.
#define CANOPY_SINK_MS 5
#define WIND_MIN_M 20
#define LAND_LABEL "  LAND %1 %2"
// THE FREEFALL READOUT (FUNC(altCell)) on the phone's status row -
// jmfsb_devices' cell: icon word, value, state (its STATE_OFF .. STATE_ALERT)
// - from this height over the ground, red at this share of the pull
// altitude. The watch that takes it off the row again (FUNC(altWatch)) looks
// every this many seconds for the man this low out of any vehicle.
#define ALT_ICON "ALT"
#define ALT_MIN_AGL 20
#define ALT_PULL_K 0.5
#define ALT_WATCH_S 1
#define ALT_DOWN_M 2
#define JM_STATE_OFF 0
#define JM_STATE_OK 1
#define JM_STATE_WARN 2
#define JM_STATE_ALERT 3
