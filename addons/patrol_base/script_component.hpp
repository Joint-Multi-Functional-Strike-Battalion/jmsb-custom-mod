#define COMPONENT patrol_base
#define COMPONENT_BEAUTIFIED Patrol Base
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_PATROL_BASE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_PATROL_BASE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_PATROL_BASE
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// --- kit / world classes ---
#define KIT_ITEMS       [QGVAR(kit_sand), QGVAR(kit_olive)]
#define KIT_OBJECTS     [QGVAR(kit_sand_object), QGVAR(kit_olive_object)]
#define BASE_BEACON     "SatelliteAntenna_01_Black_F"
#define KIT_MASS        180     // 3x a vanilla ToolKit (mass 60)
#define MARKER_TYPE     "Contact_pencilTask2"

// --- requests (review S7) ---
// remoteExec target of the server: kit drops, builds and unbuilds are asked
// for by remoteExec so the server knows who sent them.
#define SERVER_OWNER    2
// How far from the beacon the server still takes an unbuild: the action's own
// 3 m, with room for the man's position to lag on the server.
#define UNBUILD_RANGE   10
// Notify colours: done, refused.
#define NOTE_DONE       [0.914, 0.651, 0.235, 1]
#define NOTE_FAIL       [1, 0.3, 0.3, 1]
