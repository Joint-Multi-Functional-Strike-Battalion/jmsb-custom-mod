// ACE3 Arsenal Extended: the JMSB Aegis versions in models of their own, so the
// arsenal's switches move between JMSB versions and never back to an original.
class XtdGearModels {
    class CfgWeapons {
        class EGVAR(nvg,ivas) {
            options[] = {"camo"};
            label = "[JMSB] IVAS";
            class camo {
                alwaysSelectable = 1;
                values[] = {"blk", "grn", "tan"};
                class blk {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class grn {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class tan {
                    label = "Tan";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
            };
        };
        class EGVAR(nvg,scrimnet) {
            options[] = {"camo", "wear"};
            label = "[JMSB] Scrim Net";
            class camo {
                alwaysSelectable = 1;
                values[] = {"blk", "olive", "sand"};
                class blk {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class sand {
                    label = "Sand";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
            };
            class wear {
                label = "Worn";
                alwaysSelectable = 1;
                values[] = {"over", "under"};
                class over {
                    label = "Over helmet";
                };
                class under {
                    label = "Under helmet";
                };
            };
        };
    };
};

class XtdGearInfos {
    class CfgWeapons {
        class EGVAR(nvg,Aegis_NVG_IVAS_01_blk_F) {
            model = QEGVAR(nvg,ivas);
            camo = "blk";
        };
        class EGVAR(nvg,Aegis_NVG_IVAS_01_grn_F) {
            model = QEGVAR(nvg,ivas);
            camo = "grn";
        };
        class EGVAR(nvg,Aegis_NVG_IVAS_01_tan_F) {
            model = QEGVAR(nvg,ivas);
            camo = "tan";
        };
        class EGVAR(nvg,Aegis_NV_G_scrimNet_black_F) {
            model = QEGVAR(nvg,scrimnet);
            camo = "blk";
            wear = "over";
        };
        class EGVAR(nvg,Aegis_NV_G_scrimNet_olive_F) {
            model = QEGVAR(nvg,scrimnet);
            camo = "olive";
            wear = "over";
        };
        class EGVAR(nvg,Aegis_NV_G_scrimNet_sand_F) {
            model = QEGVAR(nvg,scrimnet);
            camo = "sand";
            wear = "over";
        };
        class EGVAR(nvg,Aegis_NV_G_scrimNet_under_black_F) {
            model = QEGVAR(nvg,scrimnet);
            camo = "blk";
            wear = "under";
        };
        class EGVAR(nvg,Aegis_NV_G_scrimNet_under_olive_F) {
            model = QEGVAR(nvg,scrimnet);
            camo = "olive";
            wear = "under";
        };
        class EGVAR(nvg,Aegis_NV_G_scrimNet_under_sand_F) {
            model = QEGVAR(nvg,scrimnet);
            camo = "sand";
            wear = "under";
        };
    };
};
