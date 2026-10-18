#include "script_component.hpp"

// JMSB VERSIONS OF THE AEGIS NVG-SLOT ITEMS - full screen, with ECOTI. Named
// jmfsb_nvg_<original> like every other JMSB version (addons/nvg/CfgWeapons.hpp
// explains what they change). Aegis is not part of the jmfsb load order, so
// without it this addon skips itself instead of erroring.
class CfgPatches {
    class SUBADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {
            QEGVAR(nvg,Aegis_NVG_IVAS_01_blk_F),
            QEGVAR(nvg,Aegis_NVG_IVAS_01_grn_F),
            QEGVAR(nvg,Aegis_NVG_IVAS_01_tan_F),
            QEGVAR(nvg,Aegis_NV_G_scrimNet_black_F),
            QEGVAR(nvg,Aegis_NV_G_scrimNet_olive_F),
            QEGVAR(nvg,Aegis_NV_G_scrimNet_sand_F),
            QEGVAR(nvg,Aegis_NV_G_scrimNet_under_black_F),
            QEGVAR(nvg,Aegis_NV_G_scrimNet_under_olive_F),
            QEGVAR(nvg,Aegis_NV_G_scrimNet_under_sand_F)
        };
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_nvg",
            "A3_Aegis_Weapons_F_Aegis"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgWeapons.hpp"
#include "XtdGear.hpp"
