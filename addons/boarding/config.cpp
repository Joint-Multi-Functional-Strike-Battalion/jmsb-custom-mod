#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {"jmfsb_moduleBoarding"};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // ace_interact_menu is what puts the action on the synchronised
        // object; without ACE there is nothing to press, so it is required
        // rather than checked at runtime.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "ace_interact_menu",
            "cba_xeh"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
