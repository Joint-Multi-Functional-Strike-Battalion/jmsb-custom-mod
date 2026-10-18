#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {
            QGVAR(MIG_AIRFRAME_TAN_CLEAN),
            QGVAR(MIG_AIRFRAME_OCP_CLEAN),
            QGVAR(MIG_AIRFRAME_TAN_COVER),
            QGVAR(MIG_AIRFRAME_OCP_COVER),
            QGVAR(MIG_AIRFRAME_TAN_FULL_KIT),
            QGVAR(MIG_AIRFRAME_OCP_FULL_KIT),
            QGVAR(MIG_FBINO_BLK_STD),
            QGVAR(MIG_FBINO_BLK_LOW),
            QGVAR(MIG_FBINO_BLK_LOW_Up),
            QGVAR(MIG_FBINO_BLK_DayOps_STD),
            QGVAR(MIG_FBINO_FDE_STD),
            QGVAR(MIG_FBINO_FDE_LOW),
            QGVAR(MIG_FBINO_FDE_LOW_Up),
            QGVAR(MIG_FBINO_FDE_DayOps_STD),
            QGVAR(MIG_FPANO_BLK),
            QGVAR(MIG_FPANO_FDE),
            QGVAR(MIG_FPANO_DayOps_BLK),
            QGVAR(MIG_FPANO_DayOps_FDE),
            QGVAR(MIG_FTHS_TAN_CLEAN),
            QGVAR(MIG_FTHS_OCP_CLEAN),
            QGVAR(MIG_FTHS_BLK_CLEAN),
            QGVAR(MIG_FTHS_TAN_FULL_KIT),
            QGVAR(MIG_FTHS_MOAB_FULL_KIT),
            QGVAR(MIG_FTHS_OCP_FULL_KIT),
            QGVAR(MIG_FTHS_TAN_PLATATAC),
            QGVAR(MIG_FTHS_BRN_PLATATAC),
            QGVAR(MIG_FTHS_Arctic_PLATATAC),
            QGVAR(MIG_FTHS_OCP_PLATATAC),
            QGVAR(MIG_FTHS_BLK_PLATATAC),
            QGVAR(MIG_FTHS_OCP_SCRIM),
            QGVAR(MIG_FTHS_OD_SCRIM),
            QGVAR(MIG_FTHS_ARCTIC_SCRIM),
            QGVAR(MIG_FTHS_ARCTIC2_SCRIM),
            QGVAR(MIG_FTHS_SCRIM_TAN),
            QGVAR(MIG_Galvion_Bump_BLK_CLEAN),
            QGVAR(MIG_Galvion_Bump_BLK_Full),
            QGVAR(MIG_Galvion_Bump_TAN_CLEAN),
            QGVAR(MIG_Galvion_Bump_TAN_Full),
            QGVAR(MIG_Galvion_Bump_OD_CLEAN),
            QGVAR(MIG_Galvion_Bump_OD_Full),
            QGVAR(MIG_Galvion_Bump_OCP_CLEAN),
            QGVAR(MIG_Galvion_Bump_OCP_Full),
            QGVAR(MIG_Galvion_Ballistic_BLK_CLEAN),
            QGVAR(MIG_Galvion_Ballistic_BLK_Full),
            QGVAR(MIG_Galvion_Ballistic_TAN_CLEAN),
            QGVAR(MIG_Galvion_Ballistic_TAN_Full),
            QGVAR(MIG_Galvion_Ballistic_OD_CLEAN),
            QGVAR(MIG_Galvion_Ballistic_OD_Full),
            QGVAR(MIG_Galvion_Ballistic_OCP_CLEAN),
            QGVAR(MIG_Galvion_Ballistic_OCP_Full),
            QGVAR(MIG_Galvion_Visor_UP),
            QGVAR(MIG_Galvion_Visor_DOWN),
            QGVAR(MIG_GPNVG18_BLK),
            QGVAR(MIG_GPNVG18_FDE),
            QGVAR(MIG_GPNVG18_DayOps_BLK),
            QGVAR(MIG_GPNVG18_DayOps_FDE),
            QGVAR(MIG_PVS14_L),
            QGVAR(MIG_PVS14_DayOps_L),
            QGVAR(MIG_PVS14_R),
            QGVAR(MIG_PVS14_DayOps_R),
            QGVAR(MIG_PVS14_B),
            QGVAR(MIG_PVS14_DayOps_B),
            QGVAR(MIG_PVS14_B_TAN),
            QGVAR(MIG_PVS14_DayOps_B_TAN),
            QGVAR(MIG_PVS31_STD),
            QGVAR(MIG_PVS31_LOW),
            QGVAR(MIG_PVS31_LOW_Up),
            QGVAR(MIG_PVS31_DayOps_STD),
            QGVAR(MIG_SFHC_TAN_CLEAN),
            QGVAR(MIG_SFHC_BLK_CLEAN),
            QGVAR(MIG_SFHC_OCP_CLEAN),
            QGVAR(MIG_SFHC_RG_CLEAN),
            QGVAR(MIG_SFHC_TAN_Peltor),
            QGVAR(MIG_SFHC_BLK_Peltor),
            QGVAR(MIG_SFHC_OCP_Peltor),
            QGVAR(MIG_SFHC_RG_Peltor),
            QGVAR(MIG_SFHC_TAN_FULL_KIT),
            QGVAR(MIG_SFHC_BLK_FULL_KIT),
            QGVAR(MIG_SFHC_OCP_FULL_KIT),
            QGVAR(MIG_SFHC_RG_FULL_KIT)
        };
        requiredVersion = REQUIRED_VERSION;
        // MIG's own patches: every jmfsb class here inherits one of their classes, so this addon
        // drops with MIG rather than leaving parentless items in the arsenal.
        requiredAddons[] = {
            "jmfsb_main",
            "AIRFRAME",
            "FBINO",
            "FPANO",
            "FTHS",
            "GPNVG18",
            "Galvion",
            "MIG_Helmets",
            "PVS14",
            "PVS31",
            "SFHC",
            "Visor"
        };
        skipWhenMissingDependencies = 1;
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {"Brucey"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgWeapons.hpp"
#include "XtdGear.hpp"
