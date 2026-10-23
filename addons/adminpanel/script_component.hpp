#define COMPONENT adminpanel
#define COMPONENT_BEAUTIFIED Admin Panel
#include "\z\jmfsb\addons\main\script_mod.hpp"

// The engine's own control styles and grid constants - ST_LEFT, ST_CENTER and
// friends. The console is a real dialog rather than something drawn onto the
// map, so unlike the tacpad's panels it declares its controls in config.
#include "\a3\ui_f\hpp\defineCommonGrids.inc"
#include "\a3\ui_f\hpp\defineResincl.inc"
#include "\a3\ui_f\hpp\defineResinclDesign.inc"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADMINPANEL
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_ADMINPANEL
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADMINPANEL
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The tacpad's shared geometry - PAD, RULE_THICK, and where the ADMIN strip sits
// on the map screen. The console is a dialog of its own, but the button that
// opens it is a panel on the map like everything else in the suite.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// EVERY CONTROL NUMBER, ONCE. The ported functions each carried their own copy
// of the handful of idcs they touched - forty-five files with a #define block at
// the top, which is forty-five places for a number to fall out of step with the
// dialog. They are declared here and the copies are gone.
#include "ui\idcs.inc.hpp"

// The one type height every control in the console, the message box and TIME /
// WEATHER is set to; inline <t size> varies it (FUNC(style), FUNC(fitHost)).
#define ADMIN_FONT_BASE (0.8 * (0.025 * safeZoneH))

// --- Time / weather (FUNC(envLoad) and friends) -----------------------------
// What the combos offer. Weather is in tens of percent, wind in m/s.
#define ENV_MINUTE_STEP     5
#define ENV_SPEEDS          [1, 2, 4, 6, 12, 24, 60, 120]
#define ENV_PERCENT_STEP    10
#define ENV_WIND_STEP       2
#define ENV_WIND_MAX        20
// Presets as [overcast %, rain %, fog %, wind m/s]. Rain only falls under heavy
// overcast - the engine's rule - so STORM carries full cloud with it.
#define ENV_PRESET_CLEAR    [0, 0, 0, 2]
#define ENV_PRESET_CLOUDY   [60, 0, 0, 4]
#define ENV_PRESET_STORM    [100, 100, 10, 14]
#define ENV_PRESET_FOGGY    [40, 0, 60, 0]
#define ENV_NOON            12
#define ENV_READOUT_TICK    1
// Below this the wind has no direction worth keeping; a set wind blows north.
#define ENV_WIND_CALM       0.1
#define ENV_PERCENT         100
#define ENV_MINUTES_PER_HOUR 60

// A picture showing a render-to-texture camera - PLAYER VIEW (FUNC(fitHost) keeps its shape).
#define RENDER_TARGET_TAG "r2t("
