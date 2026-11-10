#define COMPONENT teleport
#define COMPONENT_BEAUTIFIED Teleport
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_TELEPORT
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_TELEPORT
    #define DEBUG_SETTINGS DEBUG_SETTINGS_TELEPORT
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The menu. IDCs are jmfsb's own block rather than the 7000s the mission
// version used - 7000 is inside the range other people's dialogs sit in.
#define IDD_TP              9600
#define IDC_TP_MAP          9601
#define IDC_TP_LIST         9602
#define IDC_TP_OK           9603
#define IDC_TP_CANCEL       9604
#define IDC_TP_TITLE        9605
#define IDC_TP_BG           9606

// The list itself: [object, display name, side] per point. The server's copy
// is in localNamespace; a copy for the menus is published in missionNamespace
// under the same name (review S7, FUNC(listPublish)).
#define TP_LIST             GVAR(list)
#define QTP_LIST            QGVAR(list)

// THE GUARD ON THE PUBLIC COPY (XEH_postInit): a client's overwrite is put
// right once per TP_REPUBLISH_S, however many arrive, and said in the RPT at
// most once per TP_WARN_S with how many there were (2026-11-06: the line
// filled a server's RPT about twenty times a second).
#define TP_REPUBLISH_S      1
#define TP_WARN_S           60

// remoteExec target of the server (review S7: the Zeus module asks for a new
// point by remoteExec so the server knows who sent it).
#define SERVER_OWNER        2
