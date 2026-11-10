#define COMPONENT back_to_game
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_BACK_TO_GAME
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_BACK_TO_GAME
    #define DEBUG_SETTINGS DEBUG_SETTINGS_BACK_TO_GAME
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The server's machine: a client asks it by remoteExec, and it answers the
// same way (review S7).
#define SERVER_OWNER 2
