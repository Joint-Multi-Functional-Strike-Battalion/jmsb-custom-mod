class CfgWeapons {
    class Aegis_NVG_IVAS_01_blk_F;
    class Aegis_NVG_IVAS_01_grn_F;
    class Aegis_NVG_IVAS_01_tan_F;
    class Aegis_NV_G_scrimNet_black_F;
    class Aegis_NV_G_scrimNet_olive_F;
    class Aegis_NV_G_scrimNet_sand_F;
    class Aegis_NV_G_scrimNet_under_black_F;
    class Aegis_NV_G_scrimNet_under_olive_F;
    class Aegis_NV_G_scrimNet_under_sand_F;

    // IVAS - Aegis ships it with the empty reticle already (full screen) and a
    // white-hot-only thermal channel; the JMSB version adds black-hot and ECOTI.
    class EGVAR(nvg,Aegis_NVG_IVAS_01_blk_F): Aegis_NVG_IVAS_01_blk_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] IVAS (Black)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class EGVAR(nvg,Aegis_NVG_IVAS_01_grn_F): Aegis_NVG_IVAS_01_grn_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] IVAS (Green)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class EGVAR(nvg,Aegis_NVG_IVAS_01_tan_F): Aegis_NVG_IVAS_01_tan_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] IVAS (Tan)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };

    // SCRIM NETS - Aegis puts these in the NVG SLOT (they inherit NVGoggles) so a
    // net can be worn over or under the helmet, but as a pure look: vision
    // "Normal" only. The JMSB version is the same net with a full-screen NVG and
    // TI channel and ECOTI built in, so wearing the net no longer costs the
    // wearer his night vision.
    class EGVAR(nvg,Aegis_NV_G_scrimNet_black_F): Aegis_NV_G_scrimNet_black_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Scrim Net (Black)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class EGVAR(nvg,Aegis_NV_G_scrimNet_olive_F): Aegis_NV_G_scrimNet_olive_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Scrim Net (Olive)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class EGVAR(nvg,Aegis_NV_G_scrimNet_sand_F): Aegis_NV_G_scrimNet_sand_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Scrim Net (Sand)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class EGVAR(nvg,Aegis_NV_G_scrimNet_under_black_F): Aegis_NV_G_scrimNet_under_black_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Scrim Net (Under Helmet, Black)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class EGVAR(nvg,Aegis_NV_G_scrimNet_under_olive_F): Aegis_NV_G_scrimNet_under_olive_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Scrim Net (Under Helmet, Olive)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
    class EGVAR(nvg,Aegis_NV_G_scrimNet_under_sand_F): Aegis_NV_G_scrimNet_under_sand_F {
        scope = 2;
        scopeArsenal = 2;
        author = QAUTHOR;
        displayName = "[JMSB] Scrim Net (Under Helmet, Sand)";
        modelOptics = "\A3\weapons_f\reticle\optics_empty.p3d";
        ACE_nightvision_border = "";
        ACE_nightvision_eyeCups = 0;
        EGVAR(nvg,fullScreen) = 1;
        visionMode[] = {"Normal", "NVG", "TI"};
        thermalMode[] = {0, 1};
        EGVAR(ecoti,enabled) = 1;
    };
};
