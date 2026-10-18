class CfgWeapons {
    class Default {};
    class Binocular: Default {};
    class NVGoggles;

    ///////////////////////
    // class rhsusf_ANPVS_14: NVGoggles {
    //     modelOptics="";
    //     ace_nightvision_bluRadius=-1;
    //     ace_nightvision_border=QPATHTOF(data\single.paa);
    // };
    // class rhsusf_ANPVS_15: rhsusf_ANPVS_14 {
    //     modelOptics="";
    //     ace_nightvision_bluRadius=-1;
    //     ace_nightvision_border=QPATHTOF(data\bi.paa);
    // };
    // class rhs_1PN138: NVGoggles {
    //     modelOptics="";
    //     ace_nightvision_bluRadius=-1;
    //     ace_nightvision_border=QPATHTOF(data\single.paa);
    // };
    class O_NVGoggles_hex_F: NVGoggles {
        modelOptics="";
        ace_nightvision_bluRadius=-1;
        ace_nightvision_border=QPATHTOF(data\quad.paa);
    };
    class ACE_NVG_Biocular: NVGoggles {
        modelOptics="";
        ace_nightvision_bluRadius=-1;
        ace_nightvision_border=QPATHTOF(data\single.paa);
    };
    class ACE_NVG_Monocular: NVGoggles {
        modelOptics="";
        ace_nightvision_bluRadius=-1;
        ace_nightvision_border=QPATHTOF(data\single.paa);
    };
    class ACE_NVG_Binocular: NVGoggles {
        modelOptics="";
        ace_nightvision_bluRadius=-1;
        ace_nightvision_border=QPATHTOF(data\bi.paa);
    };
    class ACE_NVG_Quadocular: NVGoggles {
        modelOptics="";
        ace_nightvision_bluRadius=-1;
        ace_nightvision_border=QPATHTOF(data\quad.paa);
    };
    ///////////////////////
    class NVGogglesB_blk_F;
    class NVGoggles_OPFOR;
    class NVGoggles_INDEP;
    class NVGogglesB_grn_F;
    class NVGogglesB_gry_F;
    class NVGoggles_tna_F;
    class O_NVGoggles_urb_F;
    class ACE_NVG_Wide;

    class GVAR(anvgTI_blk): NVGogglesB_blk_F {
        displayName = "[JMSB] ADV NVG TI";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(anvgTI_gry): NVGogglesB_gry_F {
        displayName = "[JMSB] ADV NVG TI (Grey)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(anvgTI_grn): NVGogglesB_grn_F {
        displayName = "[JMSB] ADV NVG TI (green)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(nvg5TI_blk): NVGoggles_OPFOR {
        displayName = "[JMSB] NVG v5 TI";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(nvg5TI_brn): NVGoggles {
        displayName = "[JMSB] NVG v5 TI (Brown)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(nvg5TI_grn): NVGoggles_INDEP {
        displayName = "[JMSB] NVG v5 TI (Green)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(anvg_blk): NVGogglesB_blk_F {
        displayName = "[JMSB] ADV NVG";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(anvg_gry): NVGogglesB_gry_F {
        displayName = "[JMSB] ADV NVG (Grey)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(anvg_grn): NVGogglesB_grn_F {
        displayName = "[JMSB] ADV NVG (green)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(nvg5_blk): NVGoggles_OPFOR {
        displayName = "[JMSB] NVG v5";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(nvg5_brn): NVGoggles {
        displayName = "[JMSB] NVG v5 (Brown)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };
    class GVAR(nvg5_grn): NVGoggles_INDEP {
        displayName = "[JMSB] NVG v5 (Green)";
        visionMode[]= {"Normal","NVG","TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightVision_blur = 0;
        ACE_nightvision_bluRadius = 0;
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        ACE_nightVision_grain = 0;
        ACE_nightvision_generation = 4;
        ACE_nightVision_radBlur = 0;
    };

    // --- JMSB VERSIONS OF EVERY OTHER NVG IN THE ARSENAL ----------------------
    //
    // (user, 2026-10-15: "every NVG in the arsenal needs a JMSB version that is
    // full screen and has ECOTI".) Each inherits the original - same model, same
    // picture, same generation and phosphor - and changes only what the wearer
    // sees:
    //
    //   FULL SCREEN  modelOptics is the empty reticle, so neither the engine's
    //                tube picture nor ACE's mask is drawn (ACE only draws its
    //                border/eyecups when modelOptics is ""); border and eyecups
    //                are cleared as well so nothing can bring them back.
    //   ECOTI        a thermal channel (NVG key: Normal > NVG > TI white-hot >
    //                black-hot) and jmfsb_ecoti's clip-on overlay in NVG mode.
    //
    // Named jmfsb_nvg_<original>. The Reaction Forces Ti Goggles are moved out to
    // compatibility/cdlc_rf by tools/cdlc_split.py; the Aegis ones live in
    // compatibility/aegis_nvg. The EF LP NVGs (lpnvg*) are in compatibility/cdlc_ef.

    class GVAR(NVGoggles): NVGoggles {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] NV Goggles (Gen3, Brown)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class GVAR(NVGoggles_OPFOR): NVGoggles_OPFOR {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] NV Goggles (Gen3, Black)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class GVAR(NVGoggles_INDEP): NVGoggles_INDEP {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] NV Goggles (Gen3, Green)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class GVAR(NVGoggles_tna_F): NVGoggles_tna_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] NV Goggles (Tropic)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class GVAR(O_NVGoggles_hex_F): O_NVGoggles_hex_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Compact NVG (Hex)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class GVAR(O_NVGoggles_urb_F): O_NVGoggles_urb_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Compact NVG (Urban)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class GVAR(ACE_NVG_Wide): ACE_NVG_Wide {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] NV Goggles (Wide, Brown)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        GVAR(fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };

    // The Reaction Forces Ti Goggles (jmfsb_nvg_TiGoggles_RF, _grn_RF, _tan_RF)
    // were written here the same way; tools/cdlc_split.py moved them to
    // compatibility/cdlc_rf and keeps them in tools/cdlc_split.json from now on.
};


