#define COMPONENT aps
#define COMPONENT_BEAUTIFIED APS
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define CBA_DEBUG_SYNCHRONOUS
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_APS
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_APS
    #define DEBUG_SETTINGS DEBUG_SETTINGS_APS
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// --- tuning constants (everything a mission maker might want is a CBA setting) ---
#define APS_SWEEP        5       // s between the server's scans for vehicles it has not looked at
#define APS_TICK         0.05    // s between a fitted vehicle's incoming-round checks while hot
#define APS_TICK_QUIET   0.25    // s between them while nothing is in the air near it (review P3)
#define APS_QUIET_MARGIN 250     // m - a quiet scan reaches this far past the range (a 1000 m/s round in 0.25 s)
#define APS_HOT_HOLD     3       // s a vehicle stays hot after it last saw a round
#define APS_WATCH_BUDGET_MS 0.3  // ms one vehicle's watch may take (review R9; logged, not enforced)
#define APS_MS_PER_S     1000
#define APS_RF_TICK      0.5     // s between a fitted vehicle's RF threat checks
#define APS_KILL_RANGE   30      // m - the hard kill fires when the round is this close
#define APS_SHELL_RANGE  300     // m - the enhanced fit sees a tank round this far out
#define APS_SHELL_FLASH  5       // m - a tank round killed on sight flashes this far out
#define APS_SEEN_TTL     20      // s a handled projectile stays on a vehicle's seen list

// the map panel: at most this many vehicles, and where it lands the first
// time - right of the squad rail, under the tile band (see tacpad shared.inc.hpp)
#define APS_PANEL_MAX    6
#define DEFAULT_APS      [0.165, 0.15, 0.24, 0.30]

// the fits, worst to best - see fnc_fitFor
#define FIT_NONE         "NONE"
#define FIT_BASIC        "BASIC"
#define FIT_LIGHT        "LIGHT"
#define FIT_MEDIUM       "MEDIUM"
#define FIT_HEAVY        "HEAVY"
#define FIT_ENHANCED     "ENHANCED"
