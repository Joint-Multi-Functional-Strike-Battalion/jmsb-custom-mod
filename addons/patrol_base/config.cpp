#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(kit_sand_object),
            QGVAR(kit_olive_object)
        };
        weapons[] = {
            QGVAR(kit_sand),
            QGVAR(kit_olive)
        };
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        authors[] = {QAUTHOR};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
#include "CfgWeapons.hpp"
