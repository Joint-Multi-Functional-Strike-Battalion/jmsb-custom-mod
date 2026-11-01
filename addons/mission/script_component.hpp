#define COMPONENT mission
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written
// against, plus the notification colours and the logistics shorthand. Included
// AFTER jmfsb's macros so the #undef in there lands on the right definitions.
#include "\z\jmfsb\addons\diag\roomba_macros.hpp"

#define SERVER_OWNER 2

// A client's staging-zone position is taken when it is one of these markers
// (the names jmfsb_init_fnc_staging reads, first 12 characters, lower case),
// to within this many metres (fnc_stagingUplink, review R1).
#define STAGING_MARKER_PREFIXES ["zone_staging", "respawn_west"]
#define STAGING_MATCH_M         1
