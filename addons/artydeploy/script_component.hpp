#define COMPONENT artydeploy
#define COMPONENT_BEAUTIFIED Artillery Carriers
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ARTYDEPLOY
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_ARTYDEPLOY
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ARTYDEPLOY
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// THE DEPLOY CYCLE (user, 2026-10-25): the gun goes this far behind the
// vehicle's rear edge; the vehicle must be slower than this to deploy or pack;
// the driver must be this close to pack a gun he has left; the marker that
// shows the spot right away.
#define DEPLOY_TIME_DEFAULT 60
#define REAR_GAP            2.5
#define STOPPED_SPEED       1
#define PACK_RANGE          30
#define SPOT_MARKER_CLASS   "ace_csw_mortarBaseplate"
#define SPOT_MARKER_FALLBACK "Land_Sign_WarningUnexplodedAmmo_F"
#define ACTION_ICON         "\a3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa"
#define NOTE_OK             [0.4, 0.702, 0.4, 1]
#define NOTE_WARN           [0.871, 0.361, 0.188, 1]
#define ACT_PRE             "pre"
#define ACT_CLEAR           "clear"
#define ACT_DEPLOY          "deploy"
#define ACT_PACK            "pack"

// Where a step is sent: the server, by remoteExec, which checks that the
// driver named is the sender's own unit (review S6).
#define SERVER_OWNER        2
