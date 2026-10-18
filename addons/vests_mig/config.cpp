#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {
            QGVAR(MIG_FERRO_BISON_MC),
            QGVAR(MIG_Ferro_FCPC_TL_CB),
            QGVAR(MIG_Ferro_FCPC_TL_OCP),
            QGVAR(MIG_Ferro_FCPC_TL_OD),
            QGVAR(MIG_Ferro_FCPC_TL_AOR1),
            QGVAR(MIG_Ferro_FCPC_SL_CB),
            QGVAR(MIG_Ferro_FCPC_SL_OCP),
            QGVAR(MIG_Ferro_FCPC_SL_OD),
            QGVAR(MIG_Ferro_FCPC_SL_AOR1),
            QGVAR(MIG_Ferro_FCPC_Slick_CB),
            QGVAR(MIG_Ferro_FCPC_Slick_OCP),
            QGVAR(MIG_Ferro_FCPC_Slick_OD),
            QGVAR(MIG_Ferro_FCPC_Slick_AOR1),
            QGVAR(MIG_Ferro_FCPC_slick_nb_CB),
            QGVAR(MIG_Ferro_FCPC_slick_nb_OCP),
            QGVAR(MIG_Ferro_FCPC_slick_nb_OD),
            QGVAR(MIG_Ferro_FCPC_slick_nb_AOR1),
            QGVAR(MIG_Ferro_FCPC_Rifleman_CB),
            QGVAR(MIG_Ferro_FCPC_Rifleman_OCP),
            QGVAR(MIG_Ferro_FCPC_Rifleman_OD),
            QGVAR(MIG_Ferro_FCPC_Rifleman_AOR1),
            QGVAR(MIG_Ferro_FCPC_MG_CB),
            QGVAR(MIG_Ferro_FCPC_MG_OCP),
            QGVAR(MIG_Ferro_FCPC_MG_OD),
            QGVAR(MIG_Ferro_FCPC_MG_AOR1),
            QGVAR(MIG_JPC_Rifleman_CB),
            QGVAR(MIG_JPC_Rifleman_OCP),
            QGVAR(MIG_JPC_Rifleman_OD),
            QGVAR(MIG_JPC_Slick_CB),
            QGVAR(MIG_JPC_Slick_OCP),
            QGVAR(MIG_JPC_Slick_OD),
            QGVAR(MIG_JPC_MG_CB),
            QGVAR(MIG_JPC_MG_OCP),
            QGVAR(MIG_JPC_MG_OD),
            QGVAR(MIG_JPC_SL_CB),
            QGVAR(MIG_JPC_SL_OCP),
            QGVAR(MIG_JPC_SL_OD),
            QGVAR(MIG_JPC_JTAC_CB),
            QGVAR(MIG_JPC_JTAC_OCP),
            QGVAR(MIG_JPC_JTAC_OD),
            QGVAR(MIG_TYR_Gunfighter_MAB_MC),
            QGVAR(MIG_TYR_Rifleman_CB),
            QGVAR(MIG_TYR_Rifleman_OCP),
            QGVAR(MIG_TYR_Rifleman_OD),
            QGVAR(MIG_TYR_Rifleman_BLK),
            QGVAR(MIG_TYR_TL_CB),
            QGVAR(MIG_TYR_TL_OCP),
            QGVAR(MIG_TYR_TL_OD),
            QGVAR(MIG_TYR_TL_BLK),
            QGVAR(MIG_TYR_Slick_CB),
            QGVAR(MIG_TYR_Slick_OCP),
            QGVAR(MIG_TYR_Slick_OD),
            QGVAR(MIG_TYR_Slick_BLK),
            QGVAR(MIG_TYR_Slick_NB_CB),
            QGVAR(MIG_TYR_Slick_NB_OCP),
            QGVAR(MIG_TYR_Slick_NB_OD),
            QGVAR(MIG_TYR_Slick_NB_BLK),
            QGVAR(MIG_TYR_MG_CB),
            QGVAR(MIG_TYR_MG_OCP),
            QGVAR(MIG_TYR_MG_OD),
            QGVAR(MIG_TYR_MG_BLK)
        };
        requiredVersion = REQUIRED_VERSION;
        // MIG's own patches: every jmfsb class here inherits one of their classes, so this addon
        // drops with MIG rather than leaving parentless items in the arsenal.
        requiredAddons[] = {
            "jmfsb_main",
            "Ferro",
            "JPC",
            "MIG_Vests",
            "TYR"
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
