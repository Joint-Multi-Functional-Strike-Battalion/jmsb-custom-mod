#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {QGVAR(moduleGarrison), QGVAR(moduleArea), QGVAR(moduleMedical), QGVAR(moduleVehicles)};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_common: the groupSpawned bus. cba_ai: CBA_fnc_taskDefend.
        // jmfsb_notify: the instructor's confirmations. jmfsb_tacpad(_apps):
        // the TAC//TRAINING app and its tile.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "cba_ai"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {""};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
