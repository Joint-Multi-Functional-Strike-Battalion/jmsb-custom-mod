#define COMPONENT zenmodules
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written
// against, plus the notification colours and the logistics shorthand. Included
// AFTER jmfsb's macros so the #undef in there lands on the right definitions.
#include "\z\jmfsb\addons\diag\roomba_macros.hpp"

// Seconds after Call Endex before shots count against a player, so rounds
// already in flight when it is called do not.
#define ENDEX_HOLDFIRE_DELAY 10

// Call Endex goes Zeus -> server -> every machine by remoteExec, so the server
// can check who called it (review S7).
#define SERVER_OWNER 2
#define TARGET_ALL 0
