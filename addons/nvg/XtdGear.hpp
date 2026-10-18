class XtdGearModels {
    class CfgWeapons {
        class anvg {
            options[] = { "camo", "ti"};
            label = "Adv NVG";
            class camo {
                alwaysSelectable = 1;
                values[] = { "blk", "gry", "grn"};
                class blk {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class gry {
                    label = "Grey";
                    image = "z\aceax\addons\gearinfo\data\camo\gry.paa";
                };
                class grn {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
            class ti {
                label = "Thermal";
                alwaysSelectable = 1;
                values[] = { "yes", "no"};
            };
        };
        class nvg5 {
            options[] = { "camo", "ti"};
            label = "NVG v5";
            class camo {
                alwaysSelectable = 1;
                values[] = { "blk", "brn", "grn"};
                class blk {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class brn {
                    label = "Brown";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class grn {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
            class ti {
                label = "Thermal";
                alwaysSelectable = 1;
                values[] = { "yes", "no"};
            };
        };
        class nivas {
            options[] = { "camo", "ti"};
            label = "IVAS";
            class camo {
                alwaysSelectable = 1;
                values[] = { "blk", "gry", "mud", "olive", "tan", "wht", "grn"};
                class blk {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class gry {
                    label = "Grey";
                    image = "z\aceax\addons\gearinfo\data\camo\gry.paa";
                };
                class olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class tan {
                    label = "Tan";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class wht {
                    label = "White";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class mud {
                    label = "Mud";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class grn {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
            class ti {
                label = "Thermal";
                alwaysSelectable = 1;
                values[] = { "yes", "no"};
            };
        };
        class lpnvg {
            options[] = { "camo", "ti"};
            label = "LP NVG";
            class camo {
                alwaysSelectable = 1;
                values[] = { "blk", "tan"};
                class blk {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class tan {
                    label = "Tan";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
            };
            class ti {
                label = "Thermal";
                alwaysSelectable = 1;
                values[] = { "yes", "no"};
            };
        };
        class tigoggles {
            options[] = { "camo"};
            label = "Ti Goggles";
            class camo {
                alwaysSelectable = 1;
                values[] = { "blk", "grn", "tan"};
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

        // The JMSB full-screen ECOTI versions of the vanilla, ACE and Reaction
        // Forces goggles (see CfgWeapons.hpp), grouped the way ACE3 Arsenal
        // Extended groups their originals - in models of their own, so the
        // arsenal's camo switch moves between JMSB versions and never back to an
        // original.
        class GVAR(gen3) {
            options[] = {"camo"};
            label = "[JMSB] NVG (Gen3)";
            class camo {
                alwaysSelectable = 1;
                values[] = {"BLK", "SND", "OLI", "TRP"};
                class BLK {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class SND {
                    label = "Brown";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class OLI {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class TRP {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\tropic.paa";
                };
            };
        };
        class GVAR(compact) {
            options[] = {"camo"};
            label = "[JMSB] Compact NVG";
            class camo {
                alwaysSelectable = 1;
                values[] = {"HEX", "UHEX"};
                class HEX {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
                class UHEX {
                    label = "Urban Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_ou.paa";
                };
            };
        };
        class GVAR(tigoggles) {
            options[] = {"camo"};
            label = "[JMSB] Ti Goggles";
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
    };
};

class XtdGearInfos {
    class CfgWeapons {
        class GVAR(anvg_blk) {
            model = "anvg";
            camo = "blk";
            ti = "no";
        };
        class GVAR(anvg_gry) {
            model = "anvg";
            camo = "gry";
            ti = "no";
        };
        class GVAR(anvg_grn) {
            model = "anvg";
            camo = "grn";
            ti = "no";
        };
        class GVAR(nvg5_blk) {
            model = "nvg5";
            camo = "blk";
            ti = "no";
        };
        class GVAR(nvg5_brn) {
            model = "nvg5";
            camo = "brn";
            ti = "no";
        };
        class GVAR(nvg5_grn) {
            model = "nvg5";
            camo = "grn";
            ti = "no";
        };

        class GVAR(anvgTI_blk) {
            model = "anvg";
            camo = "blk";
            ti = "yes";
        };
        class GVAR(anvgTI_gry) {
            model = "anvg";
            camo = "gry";
            ti = "yes";
        };
        class GVAR(anvgTI_grn) {
            model = "anvg";
            camo = "grn";
            ti = "yes";
        };
        class GVAR(nvg5TI_blk) {
            model = "nvg5";
            camo = "blk";
            ti = "yes";
        };
        class GVAR(nvg5TI_brn) {
            model = "nvg5";
            camo = "brn";
            ti = "yes";
        };
        class GVAR(nvg5TI_grn) {
            model = "nvg5";
            camo = "grn";
            ti = "yes";
        };

        class TIOW_IVAS_Black {
            model = "nivas";
            camo = "blk";
            ti = "no";
        };
        class TIOW_IVAS_BlackTI {
            model = "nivas";
            camo = "blk";
            ti = "yes";
        };
        class TIOW_IVAS_Grey {
            model = "nivas";
            camo = "gry";
            ti = "no";
        };
        class TIOW_IVAS_GreyTI {
            model = "nivas";
            camo = "gry";
            ti = "yes";
        };
        class TIOW_IVAS_Mud {
            model = "nivas";
            camo = "mud";
            ti = "no";
        };
        class TIOW_IVAS_MudTI {
            model = "nivas";
            camo = "mud";
            ti = "yes";
        };
        class TIOW_IVAS_Olive {
            model = "nivas";
            camo = "olive";
            ti = "no";
        };
        class TIOW_IVAS_OliveTI {
            model = "nivas";
            camo = "olive";
            ti = "yes";
        };
        class TIOW_IVAS_Tan {
            model = "nivas";
            camo = "tan";
            ti = "no";
        };
        class TIOW_IVAS_TanTI {
            model = "nivas";
            camo = "tan";
            ti = "yes";
        };
        class TIOW_IVAS_White {
            model = "nivas";
            camo = "wht";
            ti = "no";
        };
        class TIOW_IVAS_WhiteTI {
            model = "nivas";
            camo = "wht";
            ti = "yes";
        };

        // Aegis IVAS
        class Aegis_NVG_IVAS_01_blk_F {
            model = "nivas";
            camo = "blk";
            ti = "no";
        };
        class Aegis_NVG_IVAS_01_grn_F {
            model = "nivas";
            camo = "grn";
            ti = "no";
        };
        class Aegis_NVG_IVAS_01_tan_F {
            model = "nivas";
            camo = "tan";
            ti = "no";
        };

        // LP NVG (EF): the jmfsb ones and EF's own are in compatibility/cdlc_ef.
        // Ti Goggles (RF): RF's own are in compatibility/cdlc_rf.

        // JMSB full-screen ECOTI versions (CfgWeapons.hpp)
        class GVAR(NVGoggles_OPFOR) {
            model = QGVAR(gen3);
            camo = "BLK";
        };
        class GVAR(NVGoggles) {
            model = QGVAR(gen3);
            camo = "SND";
        };
        class GVAR(NVGoggles_INDEP) {
            model = QGVAR(gen3);
            camo = "OLI";
        };
        class GVAR(NVGoggles_tna_F) {
            model = QGVAR(gen3);
            camo = "TRP";
        };
        class GVAR(O_NVGoggles_hex_F) {
            model = QGVAR(compact);
            camo = "HEX";
        };
        class GVAR(O_NVGoggles_urb_F) {
            model = QGVAR(compact);
            camo = "UHEX";
        };

        // The JMSB Ti Goggles' entries (model GVAR(tigoggles)) are in
        // compatibility/cdlc_rf with the goggles - see CfgWeapons.hpp.
    };
};
