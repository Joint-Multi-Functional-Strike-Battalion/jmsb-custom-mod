class XtdGearModels {
    class CfgVehicles {
        // Standard backpack line — one model per bag (each is a physically
        // different bag), distinguished by camo only.
        class GVAR(jmfsb_StdAssaultPack) {
            label = "Assault Pack";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland", "Solid_CoyoteBrown", "Solid_Olive", "Solid_Ranger_Green", "Solid_White", "OCP"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Solid_CoyoteBrown {
                    label = "BRN";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Solid_Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Solid_Ranger_Green {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Solid_White {
                    label = "White";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                // THE VANILLA MTP BAG, WHICH ax_vanillaocp RE-SKINS TO OCP (user, 2026-10-19):
                // one camo of this group rather than a vanilla group of its own, so the
                // arsenal shows one bag with OCP beside MC.
                class OCP {
                    label = "OCP";
                    image = "z\aceax\addons\gearinfo\data\camo\ocp.paa";
                };
            };
        };

        class GVAR(jmfsb_StdAssaultPackEnhanced) {
            label = "Assault Pack Enhanced";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland", "Solid_CoyoteBrown", "Solid_Olive", "Solid_Ranger_Green", "Solid_White"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Solid_CoyoteBrown {
                    label = "BRN";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Solid_Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Solid_Ranger_Green {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Solid_White {
                    label = "White";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
            };
        };

        class GVAR(jmfsb_StdCarryall) {
            label = "Carryall";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland", "Solid_CoyoteBrown", "Solid_Olive", "Solid_Ranger_Green", "Solid_White", "OCP"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Solid_CoyoteBrown {
                    label = "BRN";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Solid_Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Solid_Ranger_Green {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Solid_White {
                    label = "White";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                // THE VANILLA MTP BAG, WHICH ax_vanillaocp RE-SKINS TO OCP (user, 2026-10-19):
                // one camo of this group rather than a vanilla group of its own, so the
                // arsenal shows one bag with OCP beside MC.
                class OCP {
                    label = "OCP";
                    image = "z\aceax\addons\gearinfo\data\camo\ocp.paa";
                };
            };
        };

        class GVAR(jmfsb_StdKitbag) {
            label = "Kitbag";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland", "Solid_CoyoteBrown", "Solid_Olive", "Solid_Ranger_Green", "Solid_White", "OCP"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Solid_CoyoteBrown {
                    label = "BRN";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Solid_Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Solid_Ranger_Green {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Solid_White {
                    label = "White";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                // THE VANILLA MTP BAG, WHICH ax_vanillaocp RE-SKINS TO OCP (user, 2026-10-19):
                // one camo of this group rather than a vanilla group of its own, so the
                // arsenal shows one bag with OCP beside MC.
                class OCP {
                    label = "OCP";
                    image = "z\aceax\addons\gearinfo\data\camo\ocp.paa";
                };
            };
        };

        class GVAR(jmfsb_StdTacticalPack) {
            label = "Tactical Pack";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland", "Solid_CoyoteBrown", "Solid_Olive", "Solid_Ranger_Green", "Solid_White", "OCP"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Solid_CoyoteBrown {
                    label = "BRN";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Solid_Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Solid_Ranger_Green {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Solid_White {
                    label = "White";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                // THE VANILLA MTP BAG, WHICH ax_vanillaocp RE-SKINS TO OCP (user, 2026-10-19):
                // one camo of this group rather than a vanilla group of its own, so the
                // arsenal shows one bag with OCP beside MC.
                class OCP {
                    label = "OCP";
                    image = "z\aceax\addons\gearinfo\data\camo\ocp.paa";
                };
            };
        };

        // Field backpack line — Field Pack and Bergen are different bags.
        class GVAR(jmfsb_StdFieldPack) {
            label = "Field Pack";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
            };
        };

        class GVAR(jmfsb_StdBergen) {
            label = "Bergen";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland", "OCP"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                // THE VANILLA MTP BAG, WHICH ax_vanillaocp RE-SKINS TO OCP (user, 2026-10-19):
                // one camo of this group rather than a vanilla group of its own, so the
                // arsenal shows one bag with OCP beside MC.
                class OCP {
                    label = "OCP";
                    image = "z\aceax\addons\gearinfo\data\camo\ocp.paa";
                };
            };
        };

        class jmfsb_backpack_medic_kitbag {
            label = "Medic Kitbag";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"MTP", "COY", "RGR", "WHT", "GRN", "SAGE", "TAN"};

                class MTP {
                    label = "MTP";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class COY {
                    label = "COY";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class RGR {
                    label = "RGR";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class WHT {
                    label = "WHT";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class GRN {
                    label = "GRN";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class SAGE {
                    label = "SAGE";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class TAN {
                    label = "TAN";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
            };
        };

        class jmfsb_backpack_radiobag {
            label = "Radio Bag";
            options[] = {"camo"};

            class camo {
                alwaysSelectable = 1;
                values[] = {"Multicam", "Multicam_Snow", "Multicam_Woodland", "Solid_CoyoteBrown", "Solid_Olive", "Solid_Ranger_Green", "Solid_Tan", "Solid_White", "OCP"};

                class Multicam {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Multicam_Snow {
                    label = "MCS";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                class Multicam_Woodland {
                    label = "MCW";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Solid_CoyoteBrown {
                    label = "BRN";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Solid_Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Solid_Ranger_Green {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Solid_Tan {
                    label = "Tan";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Solid_White {
                    label = "White";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
                // THE VANILLA MTP BAG, WHICH ax_vanillaocp RE-SKINS TO OCP (user, 2026-10-19):
                // one camo of this group rather than a vanilla group of its own, so the
                // arsenal shows one bag with OCP beside MC.
                class OCP {
                    label = "OCP";
                    image = "z\aceax\addons\gearinfo\data\camo\ocp.paa";
                };
            };
        };
            class GVAR(jmfsb_AssaultPack) {
            label = "AssaultPack";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MC", "Desert", "Tropic", "Black", "Coyote", "Khaki", "Ranger", "Sage", "Woodland", "AAF", "EAF", "Hex"};
                class MC {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Desert {
                    label = "Desert";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Tropic {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\mct.paa";
                };
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Khaki {
                    label = "Khaki";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Ranger {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Sage {
                    label = "Sage";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Woodland {
                    label = "Woodland";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class AAF {
                    label = "AAF Digi";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class EAF {
                    label = "Arid";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
            };
        };
        class GVAR(jmfsb_AssaultPackSpec) {
            label = "AssaultPackSpec";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MC", "Desert", "Coyote", "Black", "Ranger", "Woodland"};
                class MC {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Desert {
                    label = "Desert";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Ranger {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Woodland {
                    label = "Woodland";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
            };
        };
        class GVAR(jmfsb_Bergen) {
            label = "Bergen";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MC", "Tropic", "Woodland", "AAF", "Hex"};
                class MC {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Tropic {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\mct.paa";
                };
                class Woodland {
                    label = "Woodland";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class AAF {
                    label = "AAF Digi";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
            };
        };
        class GVAR(jmfsb_Carryall) {
            label = "Carryall";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MC", "Desert", "Tropic", "Woodland", "Olive", "Black", "Coyote", "Green", "Khaki", "EAF", "Hex", "GHEX", "UHEX", "THEX"};
                class MC {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Desert {
                    label = "Desert";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Tropic {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\mct.paa";
                };
                class Woodland {
                    label = "Woodland";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Khaki {
                    label = "Khaki";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class EAF {
                    label = "Arid";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
                class GHEX {
                    label = "Grn Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_tna.paa";
                };
                class UHEX {
                    label = "Urb Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_ou.paa";
                };
                class THEX {
                    label = "Taiga";
                    image = "z\aceax\compats\ACEandBI\data\camo\rus_taiga.paa";
                };
            };
        };
        class GVAR(jmfsb_Static_GMG_01) {
            label = "Static GMG 01";
            options[] = {"type", "color"};
            class type {
                alwaysSelectable = 1;
                values[] = {"autonomous ", "Weapon", "High"};
                class autonomous  {
                    label = "autonomous ";
                };
                class Weapon {
                    label = "Weapon";
                };
                class High {
                    label = "High";
                };
            };
            class color {
                alwaysSelectable = 1;
                values[] = {"Default", "Green"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_Static_HMG_01) {
            label = "Static HMG 01";
            options[] = {"type", "color"};
            class type {
                alwaysSelectable = 1;
                values[] = {"autonomous ", "Weapon", "Support", "SupportHigh", "High"};
                class autonomous  {
                    label = "autonomous ";
                };
                class Weapon {
                    label = "Weapon";
                };
                class Support {
                    label = "Support";
                };
                class SupportHigh {
                    label = "Supp Hi";
                };
                class High {
                    label = "High";
                };
            };
            class color {
                alwaysSelectable = 1;
                values[] = {"Default", "Green"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_Static_HMG_02) {
            label = "Static HMG 02";
            options[] = {"type", "color"};
            class type {
                alwaysSelectable = 1;
                values[] = {"Weapon", "High", "Support", "SupportHigh"};
                class Weapon {
                    label = "Weapon";
                };
                class High {
                    label = "High";
                };
                class Support {
                    label = "Support";
                };
                class SupportHigh {
                    label = "Supp Hi";
                };
            };
            class color {
                alwaysSelectable = 1;
                values[] = {"Default", "Green"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_DuffleBag) {
            label = "DuffleBag";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MTP", "Olive"};
                class MTP {
                    label = "MTP";
                    image = "z\aceax\addons\gearinfo\data\camo\mtp.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_Static_Mortar_01) {
            label = "Static Mortar 01";
            options[] = {"type", "color"};
            class type {
                alwaysSelectable = 1;
                values[] = {"Support", "Weapon"};
                class Support {
                    label = "Support";
                };
                class Weapon {
                    label = "Weapon";
                };
            };
            class color {
                alwaysSelectable = 1;
                values[] = {"Default", "Green"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_patrolBackpack) {
            label = "patrolBackpack";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MC", "MCU", "Woodland", "Tropic", "Green", "Coyote", "RUArid"};
                class MC {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class MCU {
                    label = "MCU";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Woodland {
                    label = "Woodland";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Tropic {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\mct.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class RUArid {
                    label = "RU Arid";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
            };
        };
        class GVAR(jmfsb_RadioBag) {
            label = "RadioBag";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MTP", "Tropic", "Woodland", "Desert", "Black", "AAF", "EAF", "Hex", "GHEX", "UHEX"};
                class MTP {
                    label = "MTP";
                    image = "z\aceax\addons\gearinfo\data\camo\mtp.paa";
                };
                class Tropic {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\mct.paa";
                };
                class Woodland {
                    label = "Woodland";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Desert {
                    label = "Desert";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class AAF {
                    label = "AAF Digi";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class EAF {
                    label = "Arid";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
                class GHEX {
                    label = "Grn Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_tna.paa";
                };
                class UHEX {
                    label = "Urb Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_ou.paa";
                };
            };
        };
        class GVAR(jmfsb_RallyPoint) {
            label = "RallyPoint";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Default", "Green"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_Static_AA_01) {
            label = "Static AA 01";
            options[] = {"type", "color"};
            class type {
                alwaysSelectable = 1;
                values[] = {"Weapon"};
                class Weapon {
                    label = "Weapon";
                };
            };
            class color {
                alwaysSelectable = 1;
                values[] = {"Default", "Green"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_Static_AT_01) {
            label = "Static AT 01";
            options[] = {"type", "color"};
            class type {
                alwaysSelectable = 1;
                values[] = {"Weapon"};
                class Weapon {
                    label = "Weapon";
                };
            };
            class color {
                alwaysSelectable = 1;
                values[] = {"Default", "Green"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_TacticalPack) {
            label = "TacticalPack";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MC", "Tropic", "Ranger", "Coyote", "Black", "Hex", "Olive"};
                class MC {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Tropic {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\mct.paa";
                };
                class Ranger {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_Designator_01) {
            label = "Designator 01";
            options[] = {"faction"};
            class faction {
                alwaysSelectable = 1;
                values[] = {"NATO", "NATO_T", "NATO_W", "IND", "IND_I", "IND_E"};
                class NATO {
                    label = "NATO";
                };
                class NATO_T {
                    label = "NATO-T";
                };
                class NATO_W {
                    label = "NATO-W";
                };
                class IND {
                    label = "AAF";
                };
                class IND_I {
                    label = "AAF-I";
                };
                class IND_E {
                    label = "AAF-E";
                };
            };
        };
        class GVAR(jmfsb_Kitbag) {
            label = "Kitbag";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"MC", "Desert", "Khaki", "Coyote", "Tropic", "Woodland", "Ranger", "Sage", "Tan"};
                class MC {
                    label = "MC";
                    image = "z\aceax\addons\gearinfo\data\camo\mc.paa";
                };
                class Desert {
                    label = "Desert";
                    image = "z\aceax\addons\gearinfo\data\camo\mcd.paa";
                };
                class Khaki {
                    label = "Khaki";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Tropic {
                    label = "Tropic";
                    image = "z\aceax\addons\gearinfo\data\camo\mct.paa";
                };
                class Woodland {
                    label = "Woodland";
                    image = "z\aceax\addons\gearinfo\data\camo\mcw.paa";
                };
                class Ranger {
                    label = "Ranger";
                    image = "z\aceax\addons\gearinfo\data\camo\rgr.paa";
                };
                class Sage {
                    label = "Sage";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Tan {
                    label = "Tan";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
            };
        };
        class GVAR(jmfsb_Designator_02) {
            label = "Designator 02";
            options[] = {"faction"};
            class faction {
                alwaysSelectable = 1;
                values[] = {"CSAT_T", "CSAT", "CSAT_R"};
                class CSAT_T {
                    label = "CSAT-T";
                };
                class CSAT {
                    label = "CSAT";
                };
                class CSAT_R {
                    label = "CSAT-R";
                };
            };
        };
        class GVAR(jmfsb_UAV_06) {
            label = "UAV 06";
            options[] = {"type"};
            class type {
                alwaysSelectable = 1;
                values[] = {"Standard", "Medical"};
                class Standard {
                    label = "Standard";
                };
                class Medical {
                    label = "Medical";
                };
            };
        };
        class GVAR(jmfsb_UAV_01) {
            label = "UAV 01";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Default", "Coyote"};
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
            };
        };
        class GVAR(jmfsb_UGV_02) {
            label = "UGV 02";
            options[] = {"type"};
            class type {
                alwaysSelectable = 1;
                values[] = {"Demining", "Science"};
                class Demining {
                    label = "Demining";
                };
                class Science {
                    label = "Science";
                };
            };
        };
        class GVAR(jmfsb_gunbag) {
            label = "gunbag";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Tan", "Default"};
                class Tan {
                    label = "Tan";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Default {
                    label = "Default";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
            };
        };
        class GVAR(jmfsb_Parachute) {
            label = "Parachute";
            options[] = {"type"};
            class type {
                alwaysSelectable = 1;
                values[] = {"NonSteer", "Standard"};
                class NonSteer {
                    label = "Non-Steer";
                };
                class Standard {
                    label = "Standard";
                };
            };
        };
        class GVAR(jmfsb_FieldPack) {
            label = "FieldPack";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Black", "Coyote", "Green", "Khaki", "Olive", "Hex", "GHEX", "UHEX", "THEX"};
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Khaki {
                    label = "Khaki";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
                class GHEX {
                    label = "Grn Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_tna.paa";
                };
                class UHEX {
                    label = "Urb Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_ou.paa";
                };
                class THEX {
                    label = "Taiga";
                    image = "z\aceax\compats\ACEandBI\data\camo\rus_taiga.paa";
                };
            };
        };
        class GVAR(jmfsb_EverydayPack) {
            label = "Everyday Backpack";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Astra", "Black", "Vrana", "IDAP"};
                class Astra {
                    label = "Astra";
                    image = "z\aceax\addons\gearinfo\data\camo\gry.paa";
                };
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Vrana {
                    label = "Vrana";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class IDAP {
                    label = "IDAP";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
            };
        };
        class GVAR(jmfsb_SportsPack) {
            label = "Sports Backpack";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Blue", "Green", "Red"};
                class Blue {
                    label = "Blue";
                    image = "z\aceax\addons\gearinfo\data\camo\gry.paa";
                };
                class Green {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Red {
                    label = "Red";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
            };
        };
        class GVAR(jmfsb_LegStrapBag) {
            label = "Leg Strap Bag";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Black", "Coyote", "Olive"};
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
        class GVAR(jmfsb_MessengerBag) {
            label = "Messenger Bag";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Black", "Coyote", "Gray", "Olive", "IDAP"};
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Coyote {
                    label = "Coyote";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Gray {
                    label = "Gray";
                    image = "z\aceax\addons\gearinfo\data\camo\gry.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class IDAP {
                    label = "IDAP";
                    image = "z\aceax\addons\gearinfo\data\camo\wht.paa";
                };
            };
        };
        class GVAR(jmfsb_ViperHarness) {
            label = "Viper Harness";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Black", "Khaki", "Olive", "Hex", "GHEX"};
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Khaki {
                    label = "Khaki";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
                class GHEX {
                    label = "Grn Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_tna.paa";
                };
            };
        };
        class GVAR(jmfsb_ViperLightHarness) {
            label = "Viper Light Harness";
            options[] = {"camo"};
            class camo {
                alwaysSelectable = 1;
                values[] = {"Black", "Khaki", "Olive", "Hex", "GHEX"};
                class Black {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class Khaki {
                    label = "Khaki";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class Olive {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class Hex {
                    label = "Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat.paa";
                };
                class GHEX {
                    label = "Grn Hex";
                    image = "z\aceax\addons\gearinfo\data\camo\csat_tna.paa";
                };
            };
        };
    };
};

class XtdGearInfos {
    class CfgVehicles {
        #include "XtdGearInfos_Bags.hpp"
        // ----- Assault Pack -----
        class GVAR(AssaultPack_Multicam) {
            model = QGVAR(jmfsb_StdAssaultPack);
            camo = "Multicam";
        };
        class GVAR(AssaultPack_Multicam_Snow) {
            model = QGVAR(jmfsb_StdAssaultPack);
            camo = "Multicam_Snow";
        };
        class GVAR(AssaultPack_Multicam_Woodland) {
            model = QGVAR(jmfsb_StdAssaultPack);
            camo = "Multicam_Woodland";
        };
        class GVAR(AssaultPack_Solid_CoyoteBrown) {
            model = QGVAR(jmfsb_StdAssaultPack);
            camo = "Solid_CoyoteBrown";
        };
        class GVAR(AssaultPack_Solid_Olive) {
            model = QGVAR(jmfsb_StdAssaultPack);
            camo = "Solid_Olive";
        };
        class GVAR(AssaultPack_Solid_Ranger_Green) {
            model = QGVAR(jmfsb_StdAssaultPack);
            camo = "Solid_Ranger_Green";
        };
        class GVAR(AssaultPack_Solid_White) {
            model = QGVAR(jmfsb_StdAssaultPack);
            camo = "Solid_White";
        };

        // ----- Assault Pack Enhanced -----
        class GVAR(AssaultPackEnhanced_Multicam) {
            model = QGVAR(jmfsb_StdAssaultPackEnhanced);
            camo = "Multicam";
        };
        class GVAR(AssaultPackEnhanced_Multicam_Snow) {
            model = QGVAR(jmfsb_StdAssaultPackEnhanced);
            camo = "Multicam_Snow";
        };
        class GVAR(AssaultPackEnhanced_Multicam_Woodland) {
            model = QGVAR(jmfsb_StdAssaultPackEnhanced);
            camo = "Multicam_Woodland";
        };
        class GVAR(AssaultPackEnhanced_Solid_CoyoteBrown) {
            model = QGVAR(jmfsb_StdAssaultPackEnhanced);
            camo = "Solid_CoyoteBrown";
        };
        class GVAR(AssaultPackEnhanced_Solid_Olive) {
            model = QGVAR(jmfsb_StdAssaultPackEnhanced);
            camo = "Solid_Olive";
        };
        class GVAR(AssaultPackEnhanced_Solid_Ranger_Green) {
            model = QGVAR(jmfsb_StdAssaultPackEnhanced);
            camo = "Solid_Ranger_Green";
        };
        class GVAR(AssaultPackEnhanced_Solid_White) {
            model = QGVAR(jmfsb_StdAssaultPackEnhanced);
            camo = "Solid_White";
        };

        // ----- Carryall -----
        class GVAR(Carryall_Multicam) {
            model = QGVAR(jmfsb_StdCarryall);
            camo = "Multicam";
        };
        class GVAR(Carryall_Multicam_Snow) {
            model = QGVAR(jmfsb_StdCarryall);
            camo = "Multicam_Snow";
        };
        class GVAR(Carryall_Multicam_Woodland) {
            model = QGVAR(jmfsb_StdCarryall);
            camo = "Multicam_Woodland";
        };
        class GVAR(Carryall_Solid_CoyoteBrown) {
            model = QGVAR(jmfsb_StdCarryall);
            camo = "Solid_CoyoteBrown";
        };
        class GVAR(Carryall_Solid_Olive) {
            model = QGVAR(jmfsb_StdCarryall);
            camo = "Solid_Olive";
        };
        class GVAR(Carryall_Solid_Ranger_Green) {
            model = QGVAR(jmfsb_StdCarryall);
            camo = "Solid_Ranger_Green";
        };
        class GVAR(Carryall_Solid_White) {
            model = QGVAR(jmfsb_StdCarryall);
            camo = "Solid_White";
        };

        // ----- Kitbag -----
        class GVAR(Kitbag_Multicam) {
            model = QGVAR(jmfsb_StdKitbag);
            camo = "Multicam";
        };
        class GVAR(Kitbag_Multicam_Snow) {
            model = QGVAR(jmfsb_StdKitbag);
            camo = "Multicam_Snow";
        };
        class GVAR(Kitbag_Multicam_Woodland) {
            model = QGVAR(jmfsb_StdKitbag);
            camo = "Multicam_Woodland";
        };
        class GVAR(Kitbag_Solid_CoyoteBrown) {
            model = QGVAR(jmfsb_StdKitbag);
            camo = "Solid_CoyoteBrown";
        };
        class GVAR(Kitbag_Solid_Olive) {
            model = QGVAR(jmfsb_StdKitbag);
            camo = "Solid_Olive";
        };
        class GVAR(Kitbag_Solid_Ranger_Green) {
            model = QGVAR(jmfsb_StdKitbag);
            camo = "Solid_Ranger_Green";
        };
        class GVAR(Kitbag_Solid_White) {
            model = QGVAR(jmfsb_StdKitbag);
            camo = "Solid_White";
        };

        // ----- Tactical Pack -----
        class GVAR(TacticalPack_Multicam) {
            model = QGVAR(jmfsb_StdTacticalPack);
            camo = "Multicam";
        };
        class GVAR(TacticalPack_Multicam_Snow) {
            model = QGVAR(jmfsb_StdTacticalPack);
            camo = "Multicam_Snow";
        };
        class GVAR(TacticalPack_Multicam_Woodland) {
            model = QGVAR(jmfsb_StdTacticalPack);
            camo = "Multicam_Woodland";
        };
        class GVAR(TacticalPack_Solid_CoyoteBrown) {
            model = QGVAR(jmfsb_StdTacticalPack);
            camo = "Solid_CoyoteBrown";
        };
        class GVAR(TacticalPack_Solid_Olive) {
            model = QGVAR(jmfsb_StdTacticalPack);
            camo = "Solid_Olive";
        };
        class GVAR(TacticalPack_Solid_Ranger_Green) {
            model = QGVAR(jmfsb_StdTacticalPack);
            camo = "Solid_Ranger_Green";
        };
        class GVAR(TacticalPack_Solid_White) {
            model = QGVAR(jmfsb_StdTacticalPack);
            camo = "Solid_White";
        };

        // ----- Field Pack -----
        class GVAR(FieldPack_Multicam) {
            model = QGVAR(jmfsb_StdFieldPack);
            camo = "Multicam";
        };
        class GVAR(FieldPack_Multicam_Snow) {
            model = QGVAR(jmfsb_StdFieldPack);
            camo = "Multicam_Snow";
        };
        class GVAR(FieldPack_Multicam_Woodland) {
            model = QGVAR(jmfsb_StdFieldPack);
            camo = "Multicam_Woodland";
        };

        // ----- Bergen -----
        class GVAR(Bergen_Multicam) {
            model = QGVAR(jmfsb_StdBergen);
            camo = "Multicam";
        };
        class GVAR(Bergen_Multicam_Snow) {
            model = QGVAR(jmfsb_StdBergen);
            camo = "Multicam_Snow";
        };
        class GVAR(Bergen_Multicam_Woodland) {
            model = QGVAR(jmfsb_StdBergen);
            camo = "Multicam_Woodland";
        };
        class GVAR(Backpack_Kitbag_Medic_Coyote) {
            model = "jmfsb_backpack_medic_kitbag";
            camo = "COY";
        };
        class GVAR(Backpack_Kitbag_Medic_Green) {
            model = "jmfsb_backpack_medic_kitbag";
            camo = "GRN";
        };
        class GVAR(Backpack_Kitbag_Medic_MTP) {
            model = "jmfsb_backpack_medic_kitbag";
            camo = "MTP";
        };
        class GVAR(Backpack_Kitbag_Medic_RGR) {
            model = "jmfsb_backpack_medic_kitbag";
            camo = "RGR";
        };
        class GVAR(Backpack_Kitbag_Medic_Sage) {
            model = "jmfsb_backpack_medic_kitbag";
            camo = "SAGE";
        };
        class GVAR(Backpack_Kitbag_Medic_Tan) {
            model = "jmfsb_backpack_medic_kitbag";
            camo = "TAN";
        };
        class GVAR(Backpack_Kitbag_Medic_White) {
            model = "jmfsb_backpack_medic_kitbag";
            camo = "WHT";
        };

        class GVAR(B_RadioBag_01_Multicam) {
            model = "jmfsb_backpack_radiobag";
            camo = "Multicam";
        };
        class GVAR(B_RadioBag_01_Multicam_Snow) {
            model = "jmfsb_backpack_radiobag";
            camo = "Multicam_Snow";
        };
        class GVAR(B_RadioBag_01_Multicam_Woodland) {
            model = "jmfsb_backpack_radiobag";
            camo = "Multicam_Woodland";
        };
        class GVAR(B_RadioBag_01_Solid_CoyoteBrown) {
            model = "jmfsb_backpack_radiobag";
            camo = "Solid_CoyoteBrown";
        };
        class GVAR(B_RadioBag_01_Solid_Olive) {
            model = "jmfsb_backpack_radiobag";
            camo = "Solid_Olive";
        };
        class GVAR(B_RadioBag_01_Solid_Ranger_Green) {
            model = "jmfsb_backpack_radiobag";
            camo = "Solid_Ranger_Green";
        };
        class GVAR(B_RadioBag_01_Solid_Tan) {
            model = "jmfsb_backpack_radiobag";
            camo = "Solid_Tan";
        };
        class GVAR(B_RadioBag_01_Solid_White) {
            model = "jmfsb_backpack_radiobag";
            camo = "Solid_White";
        };
    };
};
