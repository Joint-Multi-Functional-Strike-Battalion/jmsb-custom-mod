#include "script_component.hpp"

class CfgPatches {
    class SUBADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "TMT_Gear"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgVehicles.hpp"
