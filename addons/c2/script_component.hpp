#define COMPONENT c2
#define COMPONENT_BEAUTIFIED C2
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_C2
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_C2
    #define DEBUG_SETTINGS DEBUG_SETTINGS_C2
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// C2 MEASURES (docs/DESIGN_WATCH_HUD.json c2_app, decided 2026-11-07: the
// whole side sees them). Each type: [id, label, kind, marker colour, marker
// type for points]. kind is line, area or point.
#define MEASURE_TYPES [ \
    ["phase_line", "PHASE LINE", "line", "ColorBLUFOR", ""], \
    ["loa", "LOA", "line", "ColorRed", ""], \
    ["boundary", "BOUNDARY", "line", "ColorBlack", ""], \
    ["route", "ROUTE", "line", "ColorGreen", ""], \
    ["objective", "OBJECTIVE", "area", "ColorBLUFOR", ""], \
    ["no_fire_area", "NO FIRE AREA", "area", "ColorRed", ""], \
    ["lz", "LZ", "point", "ColorBLUFOR", "mil_end"], \
    ["rally_point", "RALLY POINT", "point", "ColorBLUFOR", "mil_flag"], \
    ["checkpoint", "CHECKPOINT", "point", "ColorBLUFOR", "mil_dot"] \
]
#define APP_ID              "c2"
#define APP_W               0.62
#define APP_H               0.70
#define APP_REFRESH         2
// The world HUD (AiTR goggles): lines and areas within LINE_RANGE, an
// objective's outline to LINE_RANGE, points as a dot beyond POINT_DOT_RANGE.
#define LINE_RANGE          1000
#define POINT_DOT_RANGE     250
#define HUD_SIZE            0.028
#define HUD_FONT            "RobotoCondensedBold"
#define HUD_UP              1.5
#define DOT_ICON            "\a3\ui_f\data\map\markers\military\dot_ca.paa"
#define POINT_ICON          "\a3\ui_f\data\map\markers\military\flag_ca.paa"
// Prompts: within WARN_RANGE of an LOA, within NEAR_RANGE of a point, a
// recent event reportable with the action key for REPORT_WINDOW seconds.
#define WARN_RANGE          50
#define NEAR_RANGE          25
#define REPORT_WINDOW       60
#define TICK_SECONDS        1
#define REPORT_NET          "C2.reports"
#define NOTE_TITLE          "C2"
#define NOTE_COLOUR         [0.761, 0.659, 0.471, 1]
#define NOTE_WARN           [0.95, 0.4, 0.2, 1]
#define COLOUR_LINE         [0.3, 0.5, 0.95, 1]
#define COLOUR_RED          [0.9, 0.2, 0.15, 1]
#define COLOUR_INK          [0.95, 0.95, 0.93, 1]
#define MARKER_PREFIX       "jmfsb_c2_"
// Drawn in the world even with the player's C2 HUD off (design locked_by_default).
#define HUD_LOCKED          ["loa", "no_fire_area"]
#define REPORT_TEMPLATE     "freetext"
#define REPORT_FIELD        "Text.A"
// World drawing: lines this far above the ground; the far point's dot size.
#define LINE_LIFT           0.3
#define DOT_SIZE            0.5
