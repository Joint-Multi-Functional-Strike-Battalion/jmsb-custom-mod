#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {QGVAR(module)};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // A3_Data_F_Decade_Loadorder: after vanilla, so the pop-up targets'
        // hit handler below replaces the game's own. jmfsb_notify: results.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "A3_Data_F_Decade_Loadorder"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {""};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
