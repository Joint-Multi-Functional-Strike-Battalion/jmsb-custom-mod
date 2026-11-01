#define COMPONENT boarding
#define COMPONENT_BEAUTIFIED Boarding
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_BOARDING
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_BOARDING
    #define DEBUG_SETTINGS DEBUG_SETTINGS_BOARDING
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// How far a player may be from the MODULE and still be picked up, unless the
// mission says otherwise. Generous: this is a muster point, and people
// standing around a briefing are spread over a compound rather than a room.
#define BOARD_RANGE_DEF     50

// How far from the module vehicles are looked for when none are synchronised.
#define BOARD_VEH_SEARCH    150

// How far the presser may be from the thing he pressed, checked again on the
// server (review R1): ACE's reach plus a vehicle's bulk when the button is one.
#define BOARD_PRESS_RANGE   15

#define SERVER_OWNER        2
