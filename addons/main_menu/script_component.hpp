#define COMPONENT main_menu
#include "\z\jmfsb\addons\main\script_mod.hpp"

#include "\a3\ui_f\hpp\defineCommonGrids.inc"
#include "\a3\ui_f\hpp\defineResincl.inc"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_MAIN_MENU
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_MAIN_MENU
    #define DEBUG_SETTINGS DEBUG_SETTINGS_MAIN_MENU
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

#define MP_PWD_BORDER_CONTROL (_display displayCtrl ([108, 143] select (_displayName == 'RscDisplayRemoteMissions')))

#define POS_X(N) ((N) * GUI_GRID_W + GUI_GRID_CENTER_X)
#define POS_Y(N) ((N) * GUI_GRID_H + GUI_GRID_CENTER_Y)
#define POS_W(N) ((N) * GUI_GRID_W)
#define POS_H(N) ((N) * GUI_GRID_H)

// JMFSB RED, #CC4331 - 204/67/49. These read the PLAYER'S OWN interface
// colour before, out of their profile, so the mod's panels and buttons on
// the menu came out a different colour on every machine. This is ours and
// it is the same everywhere.
#define COLOR_BCG {0.125, 0.149, 0.110, 0.8}         // #20261C, the unit's green

#define COLOR_BCG_TRANS {0.125, 0.149, 0.110, 0.3}

// OUR CONTROLS ON BI'S MAIN MENU. High and out of the way on purpose -
// RscDisplayMain is Arma's own display and its controls own the low numbers.
//
// NAMED BY POSITION, because what a button says is a CBA setting now and the
// side of the screen it is on is not. Left, centre, right - matching servers
// 1, 2 and 3 in Addon Options.
#define IDC_QUICKCONNECT_LEFT 657010
#define IDC_QUICKCONNECT_CENTRE 657011
#define IDC_QUICKCONNECT_RIGHT 657012
// the crest above the buttons (RscDisplayMain.hpp), swapped for a holiday's
#define IDC_MAINMENU_LOGO 657013

#define IDC_SERVERSTATUS_TITLE 1000
#define IDC_SERVERSTATUS_DESCRIPTION 1001
#define IDC_SERVERSTATUS_PASSWORD 1002
#define IDC_SERVERSTATUS_LOGIN 1003
#define IDC_SERVERSTATUS_MISSIONS 1004
