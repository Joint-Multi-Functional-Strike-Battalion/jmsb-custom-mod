#define COMPONENT curator
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_CURATOR
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_CURATOR
    #define DEBUG_SETTINGS DEBUG_SETTINGS_CURATOR
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// remoteExec target of the server (review S7: Zeus requests go by remoteExec
// so the server knows who sent them).
#define SERVER_OWNER 2

// Seconds between unassigning a man's old curator and assigning the new one -
// an unassign takes a moment to land.
#define ASSIGN_DELAY 5

// The unit roles (the unit variable jmfsb_Player_Unit) that carry Zeus - the
// same list as jmfsb_players_fnc_isCurator, read by the server on its own
// copy at mission start.
#define CURATOR_ROLES ["s3", "zeus", "curator", "debug"]
