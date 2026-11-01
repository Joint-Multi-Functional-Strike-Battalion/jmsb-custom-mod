#define COMPONENT modules
#define COMPONENT_BEAUTIFIED Modules
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define CBA_DEBUG_SYNCHRONOUS
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_MODULES
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_MODULES
    #define DEBUG_SETTINGS DEBUG_SETTINGS_MODULES
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// A full blood volume in ACE medical, litres (the heal area treats a man below it).
#define HEAL_FULL_BLOOD 6
