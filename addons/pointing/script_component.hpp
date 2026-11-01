#define COMPONENT pointing
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_POINTING
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_POINTING
    #define DEBUG_SETTINGS DEBUG_SETTINGS_POINTING
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

#define POINT_DISTANCE 5000
// What the server allows past POINT_DISTANCE: camera vs eye position (review R1).
#define POINT_SLACK 50
#define SERVER_OWNER 2
