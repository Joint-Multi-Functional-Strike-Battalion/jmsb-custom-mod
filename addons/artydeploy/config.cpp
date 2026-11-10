#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(des_MRAP_gmg_mortar), QGVAR(des_MRAP_gmg_rocket), QGVAR(des_MRAP_hmg_mortar), QGVAR(des_MRAP_hmg_rocket),
            QGVAR(des_LSV_armed_mortar), QGVAR(des_LSV_armed_rocket), QGVAR(des_LSV_AT_mortar), QGVAR(des_LSV_AT_rocket),
            QGVAR(des_APC_mortar), QGVAR(des_APC_rocket),
            QGVAR(ocp_MRAP_gmg_mortar), QGVAR(ocp_MRAP_gmg_rocket), QGVAR(ocp_MRAP_hmg_mortar), QGVAR(ocp_MRAP_hmg_rocket),
            QGVAR(ocp_LSV_armed_mortar), QGVAR(ocp_LSV_armed_rocket), QGVAR(ocp_LSV_AT_mortar), QGVAR(ocp_LSV_AT_rocket),
            QGVAR(ocp_APC_mortar), QGVAR(ocp_APC_rocket),
            QGVAR(tna_MRAP_gmg_mortar), QGVAR(tna_MRAP_gmg_rocket), QGVAR(tna_MRAP_hmg_mortar), QGVAR(tna_MRAP_hmg_rocket),
            QGVAR(tna_LSV_armed_mortar), QGVAR(tna_LSV_armed_rocket), QGVAR(tna_LSV_AT_mortar), QGVAR(tna_LSV_AT_rocket),
            QGVAR(tna_APC_mortar), QGVAR(tna_APC_rocket),
            QGVAR(wdl_MRAP_gmg_mortar), QGVAR(wdl_MRAP_gmg_rocket), QGVAR(wdl_MRAP_hmg_mortar), QGVAR(wdl_MRAP_hmg_rocket),
            QGVAR(wdl_LSV_armed_mortar), QGVAR(wdl_LSV_armed_rocket), QGVAR(wdl_LSV_AT_mortar), QGVAR(wdl_LSV_AT_rocket),
            QGVAR(wdl_APC_mortar), QGVAR(wdl_APC_rocket)
        };
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "jmfsb_faction_us_jtf_des",
            "jmfsb_faction_us_jtf_ocp",
            "jmfsb_faction_us_jtf_tna",
            "jmfsb_faction_us_jtf_wdl",
            "cba_xeh",
            "cba_settings"
        };
        skipWhenMissingDependencies = 1;
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {"YonV"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
