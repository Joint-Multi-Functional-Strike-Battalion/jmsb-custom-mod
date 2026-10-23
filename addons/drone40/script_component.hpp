#define COMPONENT drone40
#define COMPONENT_BEAUTIFIED Drone40
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_DRONE40
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_DRONE40
    #define DEBUG_SETTINGS DEBUG_SETTINGS_DRONE40
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// THE GX DRONE40 VARIANTS. Rounds for the GX Drones mod's Drone40 that unfold
// into a relay, a decoy or a jammer. Loads only with GX
// (skipWhenMissingDependencies). RF never knows a drone40 class: this addon
// talks to it through its public calls (register / unregister / setState /
// nodesFor / pathLossFree) and the noise hook - never its registry.

// What a drone is, read off its config (GVAR(role) on the vehicle).
#define ROLE_RELAY  "relay"
#define ROLE_DECOY  "decoy"
#define ROLE_JAMMER "jammer"
#define ROLES       [ROLE_RELAY, ROLE_DECOY, ROLE_JAMMER]
// THE MODE a drone flies in (FUNC(setMode), public on the drone as
// GVAR(mode)): one of its roles - any of the three, whatever round it came
// from - or off: no node, no noise, no emitter.
#define MODE_OFF    "off"
#define MODES       [ROLE_RELAY, ROLE_DECOY, ROLE_JAMMER, MODE_OFF]

// RF profiles (RF_PROFILES in addons/rf/script_component.hpp). The decoy is
// a handheld on the air: same band and power, so EW DF will take it for one.
#define PROFILE_RELAY "droneRelay"
#define PROFILE_DECOY "handheld"

// Node ids, the owner tag on every node this addon registers, RF's own data
// net (the fill when the launcher holds no node), and the decoy's mark (a key
// of the node's data field, jmfsb_rf_fnc_register).
#define NODE_ID_FORMAT      "drone40_%1"
#define OWNER_TAG           QUOTE(ADDON)
#define NET_DATA            "DATA"
#define INTENT_KEY          "intent"
#define INTENT_DECOY        "decoy"
// What the jammer is to EW (jmfsb_ew_fnc_addEmitter's intent).
#define INTENT_JAMMER       "jam"
// A decoy holds a key nobody else holds: it claims the nets, decodes nothing
// and is decoded by nobody, so it carries no traffic.
#define DECOY_KEY_FORMAT    "decoy_%1"

// CfgVehicles side number -> side.
#define SIDES_BY_NUMBER     [east, west, independent, civilian]

// The creating client waits this long before telling the server, so the
// object has reached the server and GX has crewed it.
#define DEPLOY_DELAY_S      2

// The server tick: cleanup and power state.
#define TICK_S              5

// The jammer's RF noise: barrage over the voice and data bands, from an omni
// whip, at a power the setting gives.
#define JAMMER_BANDS        ["VHF", "UHF"]
#define JAMMER_GAIN_DBI     3

// Setting defaults and ranges.
#define DEFAULT_JAMMER_RADIUS   300
#define MIN_JAMMER_RADIUS       50
#define MAX_JAMMER_RADIUS       2000
// dBm: 5 W. 1 W = 30, 20 W = 43.
#define DEFAULT_JAMMER_POWER    37
#define MIN_JAMMER_POWER        20
#define MAX_JAMMER_POWER        47

// The three rounds, for the CfgPatches list, the magazine wells and UGL_F.
#define DRONE40_MAGAZINES QGVAR(1Rnd_relay_M203), QGVAR(1Rnd_decoy_M203), QGVAR(1Rnd_jammer_M203)
