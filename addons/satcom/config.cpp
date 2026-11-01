#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(deployed)
        };
        weapons[] = {
            QGVAR(item)
        };
        requiredVersion = REQUIRED_VERSION;
        // A deployable mast - what patrol_base wants it for. Its ACRE2 antenna
        // went with ACRE (DEC1, 2026-10-31).
        requiredAddons[] = {
            "jmfsb_main",
            "ace_interact_menu",
            "cba_xeh"
        };
        skipWhenMissingDependencies = 1;
        authorUrl = URL;
        author = QAUTHOR;
        authors[] = {"JMSB", "Alezm"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgWeapons.hpp"
#include "CfgVehicles.hpp"
