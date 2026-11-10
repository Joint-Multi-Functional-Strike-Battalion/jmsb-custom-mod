#include "script_component.hpp"

// TFAR LOADED: OUR RADIOS ARE TFAR RADIOS AGAIN. Without TFAR the MPU5 and the
// TW-950 are plain items (jmfsb_radios) and voice is VON; with TFAR this patch,
// and only it, makes them TFAR short range radios with their numbered
// instances and the MPU5's own screen, with the values the 1268 build carried.
// Class names never change; each keeps its jmfsb_rf_profile. The radio bags
// become TFAR long range sets (CfgVehicles.hpp): TFAR keeps its man packs,
// only game voice has none (user, 2026-10-21).
class CfgPatches {
    class SUBADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_radios",
            "jmfsb_backpack",
            "jmfsb_uniform",
            "jmfsb_uniform_ru",
            "tfar_core",
            "tfar_handhelds",
            "tfar_backpacks"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgWeapons.hpp"
#include "CfgVehicles.hpp"
#include "dialog.hpp"
