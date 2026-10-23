#define COMPONENT common
#include "\z\jmfsb\addons\main\script_mod.hpp"

#include "\a3\ui_f\hpp\defineCommonGrids.inc"
#include "\a3\ui_f\hpp\defineResincl.inc"
#include "\a3\ui_f\hpp\defineResinclDesign.inc"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_COMMON
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_COMMON
    #define DEBUG_SETTINGS DEBUG_SETTINGS_COMMON
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

#define POS_X(N) ((N) * GUI_GRID_W + GUI_GRID_CENTER_X)
#define POS_Y(N) ((N) * GUI_GRID_H + GUI_GRID_CENTER_Y)
#define POS_W(N) ((N) * GUI_GRID_W)
#define POS_H(N) ((N) * GUI_GRID_H)

#define COLOR_BCG { \
    "(profileNamespace getVariable ['GUI_BCG_RGB_R',0.13])", \
    "(profileNamespace getVariable ['GUI_BCG_RGB_G',0.54])", \
    "(profileNamespace getVariable ['GUI_BCG_RGB_B',0.21])", \
    "(profileNamespace getVariable ['GUI_BCG_RGB_A',0.8])" \
}

#define IDC_MODAL_TITLE_L       1000
#define IDC_MODAL_TITLE_R       1001
#define IDC_MODAL_GROUP_CONTENT 2000
#define IDC_MODAL_CONTENT_TEXT  2001

// Grid columns fnc_modal keeps clear on the right of the content when a briefing
// runs past the panel, so the group's scrollbar sits beside the words instead of
// over the last character of every line. 0.7 columns is a shade over the engine
// scrollbar's own width at every grid size, which is the point - it is a margin,
// not a measurement.
#define MODAL_SCROLLBAR_W       0.7

// Admin chat-command prefix. Seven characters - fnc_debugCommand slices on it.
#define DEBUG_PREFIX "#jmfsb "

// Intel markers fade in this many scheduled steps - never a per-frame handler.
#define INTEL_FADE_STEPS 5


// Shared HUD reposition dialog
#define IDD_HUDMOVE          8400
#define IDC_HUDMOVE_CATCH    8401
#define IDC_HUDMOVE_BOX      8402
#define IDC_HUDMOVE_SAVE     8403
#define IDC_HUDMOVE_RESET    8404
#define IDC_HUDMOVE_CANCEL   8405

// Shared artillery. Values carried over from the old ambient system so behaviour is
// unchanged by the extraction.
#define BARRAGE_ROUND_GAP    0.7    // sec between rounds when no window is given
#define BARRAGE_SHELL_ALT    260    // m the shell spawns above the impact point
#define BARRAGE_SHELL_SPEED  130    // m/s downward

// How many alerts a device keeps. Enough to answer "what was that?"
// after a busy few minutes, not a mission log.
#define ALERT_KEEP 12

// --- the threat board -------------------------------------------------------
// How long a contact is worth anything. Confidence decays from 1 at the moment
// it was seen to 0 here, and it is dropped on the next read - a sighting ten
// minutes old is a place somebody USED to be.
#define CONTACT_LIFETIME 600
// Two reports closer than this are the same fight however tight their errors
// claim to be - no sensor is truly metre-perfect and stacking near-duplicates
// is how a board turns into noise.
#define CONTACT_MERGE_MIN 75

// The class picker hides classes from addons whose CfgPatches name holds one of
// these (lower case) - Aegis and Atlas are not run by the unit (FUNC(listClasses)).
#define LIST_HIDE_SOURCES ["aegis", "atlas"]
