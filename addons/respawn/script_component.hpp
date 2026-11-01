#define COMPONENT respawn
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_RESPAWN
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_RESPAWN
    #define DEBUG_SETTINGS DEBUG_SETTINGS_RESPAWN
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

#define TIME_DISABLED 1e10
#define TIME_MINIMUM 1

// remoteExec target of the server (review S7: a forced respawn is asked for
// by remoteExec so the server knows who sent it).
#define SERVER_OWNER 2
