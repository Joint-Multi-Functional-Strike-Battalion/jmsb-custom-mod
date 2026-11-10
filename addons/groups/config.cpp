#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_diag",
            "jmfsb_notify",
            "cba_xeh"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        // Brought into jmfsb from the Task Force Roomba mission's scripts\ folder.
        authors[] = {"CPL.Brostrom.A", "YonV"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

#include "gui.hpp"
