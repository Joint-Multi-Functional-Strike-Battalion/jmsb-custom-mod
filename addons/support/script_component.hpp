#define COMPONENT support
#define COMPONENT_BEAUTIFIED Support
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_SUPPORT
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_SUPPORT
    #define DEBUG_SETTINGS DEBUG_SETTINGS_SUPPORT
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// An asset id is "<provider kind>:<the provider's own id>". The kind is what
// routes a request back to the provider that listed the row.
#define ID_SEP ":"

// Row status a core cooldown writes over a provider's "idle".
#define STATUS_IDLE "idle"
#define STATUS_COOLDOWN "cooldown"

// The task token that recalls an asset. Never gated by availability or by a
// cooldown: an asset you want home is by definition one that is busy.
#define TASK_RTB "rtb"

// Order of a declared asset type nobody gave an order to - after every
// type that did.
#define TYPE_ORDER_LAST 1000
