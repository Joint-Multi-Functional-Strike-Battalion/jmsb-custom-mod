#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {"jmfsb_moduleADSite"};
        weapons[] = {};
        ammo[] = {QGVAR(blast)};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "cba_xeh",
            "cba_settings"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgAmmo.hpp"
#include "CfgVehicles.hpp"
