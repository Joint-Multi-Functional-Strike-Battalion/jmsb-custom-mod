#define COMPONENT adapter_alive
#define COMPONENT_BEAUTIFIED ALiVE Adapter
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADAPTER_ALIVE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_ADAPTER_ALIVE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADAPTER_ALIVE
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// Eden class names of the ALiVE modules this reads (verified: mil_opcom and
// mil_placement script_component COMPONENT + the ALiVE PREFIX).
#define OPCOM_CLASS         "ALiVE_mil_OPCOM"

// fnc_ready poll cadence, and how often it says it is still waiting.
#define READY_POLL          5
// Registering our factions' default AA (FUNC(registerFactionAA)): polled off
// the hash rather than off FUNC(ready), because a placement module can read
// the fallback before OPCOM has finished standing up.
#define AA_REGISTER_POLL    2
#define AA_REGISTER_TIMEOUT 180
#define AA_REGISTER_MAX     3
#define READY_REPORT        60

// Probe 4's test objective: how big, and how long it must be held.
#define PROBE_RADIUS        100
#define PROBE_HOLD          10

// CBA hash layout, as ALiVE reads it itself (x_lib fnc_hashRem.sqf:46 and
// x/cba/addons/hashes/script_hashes.hpp:2-3). Named here so the two places
// that walk a hash directly do not repeat a bare index.
// The military placement module, whose stored clusters carry the camps -
// see FUNC(camps). Named here for the same reason OPCOM_CLASS is.
#define PLACEMENT_CLASS     "ALiVE_mil_placement"
#define ATO_CLASS           "ALiVE_mil_ATO"
// Nearest settlement counted for FUNC(hostilityAt).
#define HOSTILITY_RADIUS    1500
// How far round a camp's stand-off point the garrison is counted when
// deciding whose camp it is - see FUNC(camps).
#define CAMP_SIDE_RADIUS 250


#define HASH_KEYS       1
#define HASH_VALUES     2

// How often the pool sizes are republished for the tablet's button gates.
#define POOL_TICK       30

// How long a fire mission is watched for rounds actually leaving the tubes.
// Long enough for a 24-round mission at a staggered rate to finish; the
// handlers come off whether or not anything fired.
#define ARTY_WATCH_WINDOW   180

// ALiVE's hints, rerouted to jmfsb_notify (FUNC(sendHint)): the lines of a
// message are joined with this, and the notification takes ALiVE's own
// title yellow.
#define HINT_LINE_JOIN " - "
#define HINT_NOTIFY_COLOUR [1, 0.85, 0.2, 1]
