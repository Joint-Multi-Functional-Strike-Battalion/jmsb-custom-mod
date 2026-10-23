class CfgVehicles {
    // External class reference START
    class B_AssaultPack_rgr;
    class B_AssaultPack_Kerry;
    class B_Bergen_mcamo_F;
    class B_Carryall_cbr;
    class B_FieldPack_oli;
    class B_Kitbag_rgr;
    class B_TacticalPack_blk;
    class B_Kitbag_Base;
    class B_RadioBag_01_base_F;
    // External class reference  END

    class GVAR(AssaultPack_Multicam): B_AssaultPack_rgr {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_multicam_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Multicam_ca.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPackEnhanced_Multicam): B_AssaultPack_Kerry {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack (Enhanced)";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_multicam_co.paa),
            QPATHTOF(data\vests_Multicam_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Multicam_ca.paa);
        MACRO_ITEM_COMMON
        model="\A3\Characters_F_EPA\BLUFOR\backpack_kerry.p3d";
    };
    class GVAR(Carryall_Multicam): B_Carryall_cbr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 480;
        displayName="[JMSB] Carryall Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_tortila_Multicam_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Tortila_Multicam.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Kitbag_Multicam): B_Kitbag_rgr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 420;
        displayName="[JMSB] Kitbag";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_fast_Multicam_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Kitbag_Multicam.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(TacticalPack_Multicam): B_TacticalPack_blk {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        displayName="[JMSB] Tactical Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_small_Multicam_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Small_Multicam.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPack_Multicam_Snow): B_AssaultPack_rgr {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_multicam_snow_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Multicam_Snow_ca.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPackEnhanced_Multicam_Snow): B_AssaultPack_Kerry {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack (Enhanced)";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_multicam_snow_co.paa),
            QPATHTOEF(vests,data\vests_mcam_snow_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Multicam_Snow_ca.paa);
        MACRO_ITEM_COMMON
        model="\A3\Characters_F_EPA\BLUFOR\backpack_kerry.p3d";
    };
    class GVAR(Carryall_Multicam_Snow): B_Carryall_cbr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 480;
        displayName="[JMSB] Carryall Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_tortila_Multicam_Snow_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Tortila_Multicam_Snow.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Kitbag_Multicam_Snow): B_Kitbag_rgr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 420;
        displayName="[JMSB] Kitbag";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_fast_Multicam_Snow_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Kitbag_Multicam_Snow.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(TacticalPack_Multicam_Snow): B_TacticalPack_blk {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        displayName="[JMSB] Tactical Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_small_Multicam_Snow_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Small_Multicam_Snow.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPack_Multicam_Woodland): B_AssaultPack_rgr {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_multicam_woodland_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Multicam_Woodland_ca.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPackEnhanced_Multicam_Woodland): B_AssaultPack_Kerry {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack (Enhanced)";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_multicam_woodland_co.paa),
            QPATHTOF(data\vests_Multicam_Woodland_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Multicam_Woodland_ca.paa);
        MACRO_ITEM_COMMON
        model="\A3\Characters_F_EPA\BLUFOR\backpack_kerry.p3d";
    };
    class GVAR(Carryall_Multicam_Woodland): B_Carryall_cbr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 480;
        displayName="[JMSB] Carryall Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_tortila_Multicam_Woodland_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Tortila_Multicam_Woodland.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Kitbag_Multicam_Woodland): B_Kitbag_rgr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 420;
        displayName="[JMSB] Kitbag";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_fast_Multicam_Woodland_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Kitbag_Multicam_Woodland.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(TacticalPack_Multicam_Woodland): B_TacticalPack_blk {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        displayName="[JMSB] Tactical Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_small_Multicam_Woodland_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Small_Multicam_Woodland.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPack_Solid_CoyoteBrown): B_AssaultPack_rgr {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_coyotebrown_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_CoyoteBrown_ca.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPackEnhanced_Solid_CoyoteBrown): B_AssaultPack_Kerry {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack (Enhanced)";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_coyotebrown_co.paa),
            QPATHTOF(data\vests_Solid_CoyoteBrown_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_CoyoteBrown_ca.paa);
        MACRO_ITEM_COMMON
        model="\A3\Characters_F_EPA\BLUFOR\backpack_kerry.p3d";
    };
    class GVAR(Carryall_Solid_CoyoteBrown): B_Carryall_cbr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 480;
        displayName="[JMSB] Carryall Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_tortila_Solid_CoyoteBrown_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Tortila_Solid_CoyoteBrown.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Kitbag_Solid_CoyoteBrown): B_Kitbag_rgr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 420;
        displayName="[JMSB] Kitbag";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_fast_Solid_CoyoteBrown_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_CoyoteBrown.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(TacticalPack_Solid_CoyoteBrown): B_TacticalPack_blk {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        displayName="[JMSB] Tactical Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_small_Solid_CoyoteBrown_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Small_Solid_CoyoteBrown.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPack_Solid_Ranger_Green): B_AssaultPack_rgr {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_ranger_green_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_Ranger_Green_ca.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPackEnhanced_Solid_Ranger_Green): B_AssaultPack_Kerry {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack (Enhanced)";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_ranger_green_co.paa),
            QPATHTOF(data\vests_Solid_Ranger_Green_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_Ranger_Green_ca.paa);
        MACRO_ITEM_COMMON
        model="\A3\Characters_F_EPA\BLUFOR\backpack_kerry.p3d";
    };
    class GVAR(Carryall_Solid_Ranger_Green): B_Carryall_cbr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 480;
        displayName="[JMSB] Carryall Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_tortila_Solid_Ranger_Green_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Tortila_Solid_Ranger_Green.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Kitbag_Solid_Ranger_Green): B_Kitbag_rgr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 420;
        displayName="[JMSB] Kitbag";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_fast_Solid_Ranger_Green_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_Ranger_Green.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(TacticalPack_Solid_Ranger_Green): B_TacticalPack_blk {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        displayName="[JMSB] Tactical Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_small_Solid_Ranger_Green_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Small_Solid_Ranger_Green.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPack_Solid_Olive): B_AssaultPack_rgr {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_olive_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_Olive_ca.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPackEnhanced_Solid_Olive): B_AssaultPack_Kerry {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack (Enhanced)";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_olive_co.paa),
            QPATHTOF(data\vests_Solid_Olive_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_Olive_ca.paa);
        MACRO_ITEM_COMMON
        model="\A3\Characters_F_EPA\BLUFOR\backpack_kerry.p3d";
    };
    class GVAR(Carryall_Solid_Olive): B_Carryall_cbr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 480;
        displayName="[JMSB] Carryall Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_tortila_Solid_Olive_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Tortila_Solid_Olive.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Kitbag_Solid_Olive): B_Kitbag_rgr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 420;
        displayName="[JMSB] Kitbag";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_fast_Solid_Olive_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_Olive.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(TacticalPack_Solid_Olive): B_TacticalPack_blk {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        displayName="[JMSB] Tactical Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_small_Solid_Olive_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Small_Solid_Olive.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPack_Solid_White): B_AssaultPack_rgr {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_white_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_White_ca.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(AssaultPackEnhanced_Solid_White): B_AssaultPack_Kerry {
        author = QAUTHOR;
        
        maximumLoad = 240;
        displayName="[JMSB] Assault Pack (Enhanced)";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_compact_solid_white_co.paa),
            QPATHTOF(data\vests_Solid_White_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_AssaultPack_Solid_White_ca.paa);
        MACRO_ITEM_COMMON
        model="\A3\Characters_F_EPA\BLUFOR\backpack_kerry.p3d";
    };
    class GVAR(Carryall_Solid_White): B_Carryall_cbr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 480;
        displayName="[JMSB] Carryall Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_tortila_Solid_White_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Tortila_Solid_White.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Kitbag_Solid_White): B_Kitbag_rgr {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 420;
        displayName="[JMSB] Kitbag";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_fast_Solid_White_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_White.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(TacticalPack_Solid_White): B_TacticalPack_blk {
        author = QAUTHOR;
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        displayName="[JMSB] Tactical Backpack";
        hiddenSelectionsTextures[]= {
            QPATHTOF(data\backpack_small_Solid_White_co.paa)
        };
        picture=QPATHTOF(data\ui\icon_B_C_Small_Solid_White.paa);
        MACRO_ITEM_COMMON
    };
    class GVAR(Backpack_Kitbag_Medic_White): B_Kitbag_Base {
        MACRO_ITEM_COMMON
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        author = "Bohemia Interactive, GilleeDoo, JoramD";
        displayName="[JMSB] Kitbag Medic";
        picture = QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_White.paa);
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_kitbag_medic_white_co.paa)
        };
    };
    class GVAR(Backpack_Kitbag_Medic_Coyote): B_Kitbag_Base {
        MACRO_ITEM_COMMON
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        author = "Bohemia Interactive, GilleeDoo, JoramD";
        displayName="[JMSB] Kitbag Medic";
        picture = QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_CoyoteBrown.paa);
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_kitbag_medic_coyote_co.paa)
        };
    };
    class GVAR(Backpack_Kitbag_Medic_MTP): B_Kitbag_Base {
        MACRO_ITEM_COMMON
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        author = "Bohemia Interactive, GilleeDoo, JoramD";
        displayName="[JMSB] Kitbag Medic";
        picture = QPATHTOF(data\ui\icon_B_C_Kitbag_Multicam.paa);
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_kitbag_medic_mtp_co.paa)
        };
    };
    class GVAR(Backpack_Kitbag_Medic_Green): B_Kitbag_Base {
        MACRO_ITEM_COMMON
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        author = "Bohemia Interactive, GilleeDoo, JoramD";
        displayName="[JMSB] Kitbag Medic";
        picture = QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_Olive.paa);
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_kitbag_medic_green_co.paa)
        };
    };
    class GVAR(Backpack_Kitbag_Medic_Sage): B_Kitbag_Base {
        MACRO_ITEM_COMMON
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        author = "Bohemia Interactive, GilleeDoo, JoramD";
        displayName="[JMSB] Kitbag Medic";
        picture = QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_Olive.paa);
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_kitbag_medic_sage_co.paa)
        };
    };
    class GVAR(Backpack_Kitbag_Medic_Tan): B_Kitbag_Base {
        MACRO_ITEM_COMMON
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        author = "Bohemia Interactive, GilleeDoo, JoramD";
        displayName="[JMSB] Kitbag Medic";
        picture = QPATHTOF(data\ui\icon_B_C_Kitbag_Solid_Ranger_Green.paa);
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_kitbag_medic_tan_co.paa)
        };
    };
    class GVAR(Backpack_Kitbag_Medic_RGR): B_Kitbag_Base {
        MACRO_ITEM_COMMON
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 360;
        author = "Bohemia Interactive, GilleeDoo, Tyrone";
        displayName="[JMSB] Kitbag Medic";
        picture = QPATHTOF(data\ui\backpack_kitbag_medic_rgr_ca.paa);
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_kitbag_medic_rgr_co.paa)
        };
    };

    //Start radios
    // RADIO BAGS ARE BAGS. No man packs (user, 2026-10-21): none of these is a
    // radio set any more - no jmfsb_rf_profile, and jmfsb_rf_fnc_carriedSets
    // reads nothing off the back. The class names are kept - TFAR_rt1523g_kitbag
    // too - because old loadouts and missions name them.
    class GVAR(TFAR_rt1523g_kitbag): B_Kitbag_Base {
        author = "NemesisRE";
        model = "\A3\weapons_f\Ammoboxes\bags\Backpack_Fast";
        hiddenSelections[]=
        {
            "Camo"
        };
        maximumLoad = 240;
        mass = 130;
        scope = 0;
        scopeCurator = 0;
        scopeArsenal = 0;
    };
    class GVAR(kitbag_khaki_west): GVAR(TFAR_rt1523g_kitbag) {
        displayName = "[JMSB] RT-1523G Kitbag (Green)";
        hiddenSelections[]=
        {
            "Camo"
        };
        hiddenSelectionsTextures[] = {"\A3\weapons_f\ammoboxes\bags\data\backpack_fast_rgr_co.paa"};
        MACRO_ITEM_COMMON
    };
    class GVAR(kitbag_coyote_west): GVAR(TFAR_rt1523g_kitbag) {
        displayName = "[JMSB] RT-1523G Kitbag (Coyote)";
        hiddenSelections[]=
        {
            "Camo"
        };
        hiddenSelectionsTextures[] = {"\A3\weapons_f\ammoboxes\bags\data\backpack_fast_cbr_co.paa"};
        MACRO_ITEM_COMMON
    };
    class GVAR(kitbag_winter_west): GVAR(TFAR_rt1523g_kitbag) {
        displayName = "[JMSB] RT-1523G Kitbag (Winter)";
        hiddenSelections[]=
        {
            "Camo"
        };
        hiddenSelectionsTextures[] = {QPATHTOF(data\textures\kitbag_wte.paa)};
        MACRO_ITEM_COMMON
    };
    class GVAR(kitbag_black_west): GVAR(TFAR_rt1523g_kitbag) {
        displayName = "[JMSB] RT-1523G Kitbag (Black)";
        hiddenSelections[]=
        {
            "Camo"
        };
        hiddenSelectionsTextures[] = {"\a3\weapons_f\ammoboxes\bags\data\backpack_fast_blk_co.paa"};
        MACRO_ITEM_COMMON
    };
    // For older Missions
    class GVAR(talon_kitbag_khaki): GVAR(kitbag_khaki_west) {
        scope = 1;
        scopeCurator = 1;
        scopeArsenal = 1;
    };
    class GVAR(talon_kitbag_coyote): GVAR(kitbag_coyote_west) {
        scope = 1;
        scopeCurator = 1;
        scopeArsenal = 1;
    };
    class GVAR(talon_kitbag_winter): GVAR(kitbag_winter_west) {
        scope = 1;
        scopeCurator = 1;
        scopeArsenal = 1;
    };
    // MODIFIED ENOCH RADIOBAGS
    // RADIOBAG 01 BASE
    class GVAR(RadioBag_01_Base): B_RadioBag_01_base_F {
        scope = 1;
        scopeArsenal = 0;
        scopeCurator = 0;
        author = QAUTHOR;
        // maximumLoad = 80;
        // mass = 160;
        maximumLoad = 180;
        mass = 101.2;
        transportMaxBackpacks = 1;
        transportMaxMagazines = 30;
        transportMaxWeapons = 1;
        class TransportItems {};
        class TransportMagazines {};
        class TransportWeapons {};
        isBackpack = 1;
        // class TransportItems {
        //     MACRO_ADDITEM(ACRE_PRC117F,1);
        // };
    };
    class GVAR(B_RadioBag_01_Multicam): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](Multicam) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Multicam_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Multicam_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    };
    class GVAR(B_RadioBag_01_Multicam_Snow): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](Multicam Snow) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Multicam_Snow_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Multicam_Snow_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    };
    class GVAR(B_RadioBag_01_Multicam_Woodland): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](Multicam Woodland) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Multicam_Woodland_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Multicam_Woodland_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    };
    class GVAR(B_RadioBag_01_Solid_CoyoteBrown): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](CoyoteBrown) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Solid_CoyoteBrown_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Solid_CoyoteBrown_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    };
    class GVAR(B_RadioBag_01_Solid_Olive): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](Olive) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Solid_Olive_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Solid_Olive_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    };
    class GVAR(B_RadioBag_01_Solid_Ranger_Green): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](Ranger Green) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Solid_Ranger_Green_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Solid_Ranger_Green_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    };
    class GVAR(B_RadioBag_01_Solid_Tan): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](Tan) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Solid_Tan_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Solid_Tan_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    };
    class GVAR(B_RadioBag_01_Solid_White): GVAR(RadioBag_01_Base) {
        author = QAUTHOR;
        displayName = "[JMSB](White) Radio Pack";
        hiddenSelectionsTextures[] = {QPATHTOF(data\B_radiobag_Solid_White_CO.paa)};
        picture = QPATHTOF(data\UI\icon_B_C_UAV_Solid_White_ca.paa);
        hiddenSelections[] = {"Camo1"};
        MACRO_ITEM_COMMON
    }; 
    //End radios 

    class GVAR(FieldPack_Multicam): B_FieldPack_oli {
        author = QAUTHOR;
        hiddenSelections[] = {"Camo"};
        maximumLoad = 300;
        displayName = "[JMSB] (Multicam) Field Pack";
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_gorod_Multicam_co.paa)
        };
        picture = QPATHTOF(data\ui\icon_B_C_Gorod_Multicam_ca.paa);
        MACRO_ITEM_COMMON
    };

    class GVAR(Bergen_Multicam): B_Bergen_mcamo_F {
        author = QAUTHOR;
        hiddenSelections[] = {"camo"};
        maximumLoad = 600;
        displayName = "[JMSB] (Multicam) Bergen Backpack";
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\Bergen_Multicam_co.paa)
        };
        picture = QPATHTOF(data\ui\Icon_B_Bergen_Multicam_CA.paa);
        MACRO_ITEM_COMMON
    };

    class GVAR(FieldPack_Multicam_Snow): B_FieldPack_oli {
        author = QAUTHOR;
        hiddenSelections[] = {"Camo"};
        maximumLoad = 300;
        displayName = "[JMSB] (Multicam Snow) Field Pack";
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_gorod_Multicam_Snow_co.paa)
        };
        picture = QPATHTOF(data\ui\icon_B_C_Gorod_Multicam_Snow_ca.paa);
        MACRO_ITEM_COMMON
    };

    class GVAR(Bergen_Multicam_Snow): B_Bergen_mcamo_F {
        author = QAUTHOR;
        hiddenSelections[] = {"camo"};
        maximumLoad = 600;
        displayName = "[JMSB] (Multicam Snow) Bergen Backpack";
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\Bergen_Multicam_Snow_co.paa)
        };
        picture = QPATHTOF(data\ui\Icon_B_Bergen_Multicam_Snow_CA.paa);
        MACRO_ITEM_COMMON
    };

    class GVAR(FieldPack_Multicam_Woodland): B_FieldPack_oli {
        author = QAUTHOR;
        hiddenSelections[] = {"Camo"};
        maximumLoad = 300;
        displayName = "[JMSB] (Multicam Woodland) Field Pack";
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\backpack_gorod_A3_Multicam_Woodland_co.paa)
        };
        picture = QPATHTOF(data\ui\icon_B_C_Gorod_A3_Multicam_Woodland_ca.paa);
        MACRO_ITEM_COMMON
    };

    class GVAR(Bergen_Multicam_Woodland): B_Bergen_mcamo_F {
        author = QAUTHOR;
        hiddenSelections[] = {"camo"};
        maximumLoad = 600;
        displayName = "[JMSB] (Multicam Woodland) Bergen Backpack";
        hiddenSelectionsTextures[] = {
            QPATHTOF(data\Bergen_A3_Multicam_Woodland_co.paa)
        };
        picture = QPATHTOF(data\ui\Icon_B_Bergen_A3_Multicam_Woodland_CA.paa);
        MACRO_ITEM_COMMON
    };







#include "acp_ocp.hpp"
};
