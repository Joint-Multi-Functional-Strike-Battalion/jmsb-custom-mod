#define COMPONENT radio_mesh
#define COMPONENT_BEAUTIFIED Radio Mesh
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define CBA_DEBUG_SYNCHRONOUS
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_RADIO_MESH
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_RADIO_MESH
    #define DEBUG_SETTINGS DEBUG_SETTINGS_RADIO_MESH
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// --- tuning constants ---
#define MESH_EDGE_TTL       3       // sec a computed leg (radio -> radio) stays cached
#define MESH_FREQ_TOL       0.0015  // MHz - "same frequency" tolerance (ACRE steps are 0.025)
#define MESH_NO_SIGNAL      -200    // dBm - below anything a radio could hear
