// ACE3 Arsenal Extended: the 15 JCA AiTR goggles as ONE model (user, 2026-10-17)
// - style, colour and lens are switches, and every switch stays on a JMSB AiTR
// goggle, never back to a JCA original. Hand-kept: tools/gen_aitr_goggles.py
// writes the other three files here and leaves this one alone.
class XtdGearModels {
    class CfgWeapons {
        class EGVAR(nvg,aitr_jca) {
            label = "[JMSB] AiTR Goggles (JCA)";
            options[] = {"style", "camo", "lens"};
            class style {
                label = "Style";
                alwaysSelectable = 1;
                values[] = {"goggles", "shemagh", "balaclava", "facemask"};
                class goggles {
                    label = "Goggles";
                };
                class shemagh {
                    label = "Shemagh";
                };
                class balaclava {
                    label = "Balaclava";
                };
                class facemask {
                    label = "Face Mask";
                };
            };
            class camo {
                label = "Colour";
                alwaysSelectable = 1;
                values[] = {"black", "olive", "sand"};
                class black {
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
            class lens {
                label = "Lens";
                values[] = {"clear", "tinted"};
                class clear {
                    label = "Clear";
                };
                class tinted {
                    label = "Tinted";
                };
            };
        };
    };
};

#define AITR_JCA(SRC,STYLE,CAMO,LENS) \
    class EGVAR(nvg,SRC) { \
        model = QEGVAR(nvg,aitr_jca); \
        style = #STYLE; \
        camo = #CAMO; \
        lens = #LENS; \
    }

class XtdGearInfos {
    class CfgWeapons {
        AITR_JCA(JCA_G_Goggles_01_clear_black_F,goggles,black,clear);
        AITR_JCA(JCA_G_Goggles_01_clear_olive_F,goggles,olive,clear);
        AITR_JCA(JCA_G_Goggles_01_clear_sand_F,goggles,sand,clear);
        AITR_JCA(JCA_G_Goggles_01_tinted_black_F,goggles,black,tinted);
        AITR_JCA(JCA_G_Goggles_01_tinted_olive_F,goggles,olive,tinted);
        AITR_JCA(JCA_G_Goggles_01_tinted_sand_F,goggles,sand,tinted);
        AITR_JCA(JCA_G_shemagh_01_goggles_black_F,shemagh,black,clear);
        AITR_JCA(JCA_G_shemagh_01_goggles_olive_F,shemagh,olive,clear);
        AITR_JCA(JCA_G_shemagh_01_goggles_sand_F,shemagh,sand,clear);
        AITR_JCA(JCA_G_balaclava_01_goggles_black_F,balaclava,black,clear);
        AITR_JCA(JCA_G_balaclava_01_goggles_olive_F,balaclava,olive,clear);
        AITR_JCA(JCA_G_balaclava_01_goggles_sand_F,balaclava,sand,clear);
        AITR_JCA(JCA_G_FaceMask_01_goggles_black_F,facemask,black,clear);
        AITR_JCA(JCA_G_FaceMask_01_goggles_olive_F,facemask,olive,clear);
        AITR_JCA(JCA_G_FaceMask_01_goggles_sand_F,facemask,sand,clear);
    };
};
