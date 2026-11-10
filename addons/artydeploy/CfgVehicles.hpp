// THE ARTILLERY CARRIERS (user, 2026-10-25: "4 new vehicles based on
// B_MRAP_01_gmg_F, B_MRAP_01_hmg_F, B_LSV_01_armed_F, B_LSV_01_AT_F - get all
// the camos the US uses - these will be arty vehicles", "a version of the
// AMV-7 Marshall APC also", "all vehicles need a version of either"). Each US
// faction gets every carrier in its own paint, each in a MORTAR version (the
// Mk6) and a ROCKET version (the Western Sahara Hunter-SP launcher, the mortar
// without the CDLC). Each carrier is that faction's own vehicle - its paint,
// crew and faction; Desert and OCP, which have no M-ATV GMG / HMG of their
// own, take the base game's sand ones.
//
// GVAR(weapons): the first class this mod set has is the gun deployed by the
// driver (FUNC(preDeploy), FUNC(deployStart), FUNC(undeployStart)).
class CfgVehicles {
    class B_MRAP_01_gmg_F;
    class B_MRAP_01_hmg_F;
    class jmfsb_faction_us_jtf_des_Aegis_B_D_LSV_01_armed_F;
    class jmfsb_faction_us_jtf_des_Aegis_B_D_LSV_01_AT_F;
    class jmfsb_faction_us_jtf_des_APC_Wheeled_01_apc_qav;
    class jmfsb_faction_us_jtf_ocp_Aegis_B_D_LSV_01_armed_F;
    class jmfsb_faction_us_jtf_ocp_Aegis_B_D_LSV_01_AT_F;
    class jmfsb_faction_us_jtf_ocp_APC_Wheeled_01_apc_qav;
    class jmfsb_faction_us_jtf_tna_B_T_MRAP_01_gmg_F;
    class jmfsb_faction_us_jtf_tna_B_T_MRAP_01_hmg_F;
    class jmfsb_faction_us_jtf_tna_B_T_LSV_01_armed_F;
    class jmfsb_faction_us_jtf_tna_B_T_LSV_01_AT_F;
    class jmfsb_faction_us_jtf_tna_B_T_APC_Wheeled_01_apc_QAV;
    class jmfsb_faction_us_jtf_wdl_B_W_MRAP_01_gmg_F;
    class jmfsb_faction_us_jtf_wdl_B_W_MRAP_01_hmg_F;
    class jmfsb_faction_us_jtf_wdl_B_W_LSV_01_armed_F;
    class jmfsb_faction_us_jtf_wdl_B_W_LSV_01_AT_F;
    class jmfsb_faction_us_jtf_wdl_APC_Wheeled_01_apc_qav;

    // --- desert ---------------------------------------------------------------
    class GVAR(des_MRAP_gmg_mortar): B_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(des_MRAP_gmg_rocket): B_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(des_MRAP_hmg_mortar): B_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(des_MRAP_hmg_rocket): B_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(des_LSV_armed_mortar): jmfsb_faction_us_jtf_des_Aegis_B_D_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(des_LSV_armed_rocket): jmfsb_faction_us_jtf_des_Aegis_B_D_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(des_LSV_AT_mortar): jmfsb_faction_us_jtf_des_Aegis_B_D_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(des_LSV_AT_rocket): jmfsb_faction_us_jtf_des_Aegis_B_D_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(des_APC_mortar): jmfsb_faction_us_jtf_des_APC_Wheeled_01_apc_qav {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(des_APC_rocket): jmfsb_faction_us_jtf_des_APC_Wheeled_01_apc_qav {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_des";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };

    // --- OCP ---------------------------------------------------------------
    class GVAR(ocp_MRAP_gmg_mortar): B_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(ocp_MRAP_gmg_rocket): B_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(ocp_MRAP_hmg_mortar): B_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(ocp_MRAP_hmg_rocket): B_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(ocp_LSV_armed_mortar): jmfsb_faction_us_jtf_ocp_Aegis_B_D_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(ocp_LSV_armed_rocket): jmfsb_faction_us_jtf_ocp_Aegis_B_D_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(ocp_LSV_AT_mortar): jmfsb_faction_us_jtf_ocp_Aegis_B_D_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(ocp_LSV_AT_rocket): jmfsb_faction_us_jtf_ocp_Aegis_B_D_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(ocp_APC_mortar): jmfsb_faction_us_jtf_ocp_APC_Wheeled_01_apc_qav {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(ocp_APC_rocket): jmfsb_faction_us_jtf_ocp_APC_Wheeled_01_apc_qav {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_ocp";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };

    // --- tropic ---------------------------------------------------------------
    class GVAR(tna_MRAP_gmg_mortar): jmfsb_faction_us_jtf_tna_B_T_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(tna_MRAP_gmg_rocket): jmfsb_faction_us_jtf_tna_B_T_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(tna_MRAP_hmg_mortar): jmfsb_faction_us_jtf_tna_B_T_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(tna_MRAP_hmg_rocket): jmfsb_faction_us_jtf_tna_B_T_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(tna_LSV_armed_mortar): jmfsb_faction_us_jtf_tna_B_T_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(tna_LSV_armed_rocket): jmfsb_faction_us_jtf_tna_B_T_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(tna_LSV_AT_mortar): jmfsb_faction_us_jtf_tna_B_T_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(tna_LSV_AT_rocket): jmfsb_faction_us_jtf_tna_B_T_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(tna_APC_mortar): jmfsb_faction_us_jtf_tna_B_T_APC_Wheeled_01_apc_QAV {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(tna_APC_rocket): jmfsb_faction_us_jtf_tna_B_T_APC_Wheeled_01_apc_QAV {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_tna";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };

    // --- woodland ---------------------------------------------------------------
    class GVAR(wdl_MRAP_gmg_mortar): jmfsb_faction_us_jtf_wdl_B_W_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(wdl_MRAP_gmg_rocket): jmfsb_faction_us_jtf_wdl_B_W_MRAP_01_gmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (GMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(wdl_MRAP_hmg_mortar): jmfsb_faction_us_jtf_wdl_B_W_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(wdl_MRAP_hmg_rocket): jmfsb_faction_us_jtf_wdl_B_W_MRAP_01_hmg_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "M-ATV (HMG) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(wdl_LSV_armed_mortar): jmfsb_faction_us_jtf_wdl_B_W_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(wdl_LSV_armed_rocket): jmfsb_faction_us_jtf_wdl_B_W_LSV_01_armed_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (XM312) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(wdl_LSV_AT_mortar): jmfsb_faction_us_jtf_wdl_B_W_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(wdl_LSV_AT_rocket): jmfsb_faction_us_jtf_wdl_B_W_LSV_01_AT_F {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "Polaris DAGOR (Mini-Spike AT) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
    class GVAR(wdl_APC_mortar): jmfsb_faction_us_jtf_wdl_APC_Wheeled_01_apc_qav {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Mortar Carrier";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"B_Mortar_01_F"};
    };
    class GVAR(wdl_APC_rocket): jmfsb_faction_us_jtf_wdl_APC_Wheeled_01_apc_qav {
        scope = 2;
        scopeCurator = 2;
        author = QAUTHOR;
        displayName = "AMV-7 Marshall (APC) - Rocket Artillery";
        side = 1;
        faction = "jmfsb_faction_us_jtf_wdl";
        GVAR(weapons)[] = {"GX_B_HUNTER_SP_LAUNCHER", "B_Mortar_01_F"};
    };
};
