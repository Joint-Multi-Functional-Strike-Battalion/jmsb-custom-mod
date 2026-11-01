#define COMPONENT boc
#define COMPONENT_BEAUTIFIED Backpack On Chest
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define CBA_DEBUG_SYNCHRONOUS
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_BOC
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_BOC
    #define DEBUG_SETTINGS DEBUG_SETTINGS_BOC
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The rope-top helper a lowered chestpack hangs from (FUNC(actionLower)). The
// server deletes only this class when it lands (review S7).
#define ROPE_TOP_CLASS "ace_fastroping_helper"
