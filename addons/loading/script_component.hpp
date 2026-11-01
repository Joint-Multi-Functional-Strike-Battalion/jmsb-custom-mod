#define COMPONENT loading
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_LOADING
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_LOADING
    #define DEBUG_SETTINGS DEBUG_SETTINGS_LOADING
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

#define IDC_LOADINGSTART_CUSTOM_BG 657001
#define CFG_LOADING_SCREEN (configFile >> QGVAR(CfgLoadingScreen))

// THE UNIT CREST on the mission loading screen: a square this many pixels a
// side at the safe zone's left edge, its top on the mission box's top (user,
// 2026-10-30: "aligned with the mission box, double size" - it shipped at 256
// in the bottom-left corner, which is where it still goes when there is no box).
#define LOGO_SIZE_PX 512

// THE HOLIDAY CRESTS (CfgLoadingScreen.hpp's Holidays; FUNC(holiday),
// FUNC(holidayDate)): a crest runs this many days ahead of its day unless its
// class says otherwise. The date maths is in day counts from
// EFUNC(common,daysFromCivil), whose epoch (0000-03-01) was a Wednesday;
// weekdays are 0 Sunday .. 6 Saturday. A window may cross New Year, so last
// year's, this year's and next year's dates are all tried.
#define HOLIDAY_RUN_UP_DAYS 7
#define DAYS_PER_WEEK 7
#define EPOCH_WEEKDAY 3
#define WEEKDAY(days) (((days) + EPOCH_WEEKDAY) mod DAYS_PER_WEEK)
#define WEEKDAY_MONDAY 1
#define WEEKDAY_THURSDAY 4
// nth = NTH_LAST: the month's last such weekday (Memorial Day)
#define NTH_LAST -1
#define NEIGHBOUR_YEARS [-1, 0, 1]

// THE QUICK BRIEF PANEL, right of the engine's mission box, laid out in the
// engine's own GUI grid (defineCommonGrids.inc: 40 columns x 25 rows over the
// centred 1.2 x 1 area) so it is drawn in the same hand as the box. The
// numbers mirror RscDisplayLoadMission's Mission group: a 2.7-row black title
// bar carrying a 1.5-row name and, 1.3 rows down, a 1-row author line in
// 0.8-row light type at half white; a 0.1-row gap under the bar; and the
// 3-column gap the engine's own DLC column keeps from the box.
#define BRIEF_TITLE "QUICK BRIEF"
#define BRIEF_OVERVIEW_SUBTITLE "MISSION OVERVIEW"
#define BRIEF_GAP_COLS 3
// the panel stops this many columns short of the safe zone's right edge
#define BRIEF_RIGHT_MARGIN_COLS 4
// narrower than this and there is no room beside the box (4:3 screens) - not drawn
#define BRIEF_MIN_COLS 10
#define BRIEF_BAR_ROWS 2.7
#define BRIEF_TITLE_ROWS 1.5
#define BRIEF_SUBTITLE_ROW 1.3
#define BRIEF_SUBTITLE_ROWS 1
#define BRIEF_SUBTITLE_SIZE 0.8
#define BRIEF_BODY_ROW 2.8
// structured text size relative to the control's, as MissionDescription's Attributes
#define BRIEF_BODY_TEXT_SIZE 0.8
// the allowance the engine's loading script leaves under a text-fitted description
#define BRIEF_BODY_PAD 0.01
#define BRIEF_FONT_LIGHT "RobotoCondensedLight"
#define COLOUR_BRIEF_BAR [0, 0, 0, 1]
#define COLOUR_BRIEF_BODY [0, 0, 0, 0.6]
#define COLOUR_BRIEF_SUBTITLE [1, 1, 1, 0.5]
