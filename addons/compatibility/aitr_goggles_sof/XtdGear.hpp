// ACE3 Arsenal Extended: the 6 SOF AiTR goggles as ONE model (user, 2026-10-17)
// - style and colour are switches, and every switch stays on a JMSB AiTR goggle,
// never back to a SOF original. Hand-kept: tools/gen_aitr_goggles.py writes the
// other three files here and leaves this one alone.
class XtdGearModels {
    class CfgWeapons {
        class EGVAR(nvg,aitr_sof) {
            label = "[JMSB] AiTR Goggles (SOF)";
            options[] = {"style", "camo"};
            class style {
                label = "Style";
                alwaysSelectable = 1;
                values[] = {"goggles", "twill"};
                class goggles {
                    label = "Tactical Goggles";
                };
                class twill {
                    label = "Twill Balaclava";
                };
            };
            class camo {
                label = "Colour";
                alwaysSelectable = 1;
                values[] = {"blk", "rgr", "snd", "khk", "oli"};
                class blk {
                    label = "Black";
                    image = "z\aceax\addons\gearinfo\data\camo\blk.paa";
                };
                class rgr {
                    label = "Green";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
                class snd {
                    label = "Sand";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class khk {
                    label = "Khaki";
                    image = "z\aceax\addons\gearinfo\data\camo\khk.paa";
                };
                class oli {
                    label = "Olive";
                    image = "z\aceax\addons\gearinfo\data\camo\sage.paa";
                };
            };
        };
    };
};

#define AITR_SOF(SRC,STYLE,CAMO) \
    class EGVAR(nvg,SRC) { \
        model = QEGVAR(nvg,aitr_sof); \
        style = #STYLE; \
        camo = #CAMO; \
    }

class XtdGearInfos {
    class CfgWeapons {
        AITR_SOF(SOF_G_TacticalGoggles_blk,goggles,blk);
        AITR_SOF(SOF_G_TacticalGoggles_rgr,goggles,rgr);
        AITR_SOF(SOF_G_TacticalGoggles_snd,goggles,snd);
        AITR_SOF(SOF_G_TwillBalaclava_Goggles_blk,twill,blk);
        AITR_SOF(SOF_G_TwillBalaclava_Goggles_khk,twill,khk);
        AITR_SOF(SOF_G_TwillBalaclava_Goggles_oli,twill,oli);
    };
};
