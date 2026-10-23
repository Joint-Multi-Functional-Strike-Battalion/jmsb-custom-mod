#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "A3_Weapons_F" // defines ItemCore, parent of our root ItemInfo definition
        };
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgEden.hpp"
#include "CfgWeapons.hpp"
#include "CfgModuleCategories.hpp"
#include "DisplayEden.hpp"
