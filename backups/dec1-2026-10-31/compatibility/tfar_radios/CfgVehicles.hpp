// THE RADIO BAGS AS TFAR LONG RANGE SETS, with the 1268 build's values. The
// two bases carry them for every bag of ours built on them (the Multicam,
// Snow, Woodland and solid radio packs, the RT-1523G kitbags, the MPU5
// manpack); the uniform bags that inherit vanilla's base carry their own. NATO
// bags take the RT-1523G dialog and the west code, CSAT / RU ones the Bussole
// and the east code, as before. Under TFAR (and ACRE) a man pack is a set;
// under game voice it is not (user, 2026-10-21) - jmfsb_rf_fnc_carriedSets
// reads nothing off the back.
#define TFAR_LR_WEST \
    tf_dialog = "rt1523g_radio_dialog"; \
    tf_dialogUpdate = "call TFAR_fnc_updateLRDialogToChannel;"; \
    tf_encryptionCode = "tf_west_radio_code"; \
    tf_hasLRradio = 1; \
    tf_range = 20000; \
    tf_subtype = "digital_lr";

#define TFAR_LR_EAST \
    tf_dialog = "bussole_radio_dialog"; \
    tf_dialogUpdate = "call TFAR_fnc_updateLRDialogToChannel;"; \
    tf_encryptionCode = "tf_east_radio_code"; \
    tf_hasLRradio = 1; \
    tf_range = 20000; \
    tf_subtype = "digital_lr";

class CfgVehicles {
    class B_Kitbag_Base;
    class B_RadioBag_01_base_F;

    class EGVAR(backpack,TFAR_rt1523g_kitbag): B_Kitbag_Base {
        TFAR_LR_WEST
    };
    class EGVAR(backpack,RadioBag_01_Base): B_RadioBag_01_base_F {
        TFAR_LR_WEST
    };

    class EGVAR(uniform,B_RadioBag_01_oicamo_F): B_RadioBag_01_base_F {
        TFAR_LR_EAST
    };
    class EGVAR(uniform,B_RadioBag_01_jungle_F): B_RadioBag_01_base_F {
        TFAR_LR_WEST
    };
    class EGVAR(uniform,B_RadioBag_01_commando_F): B_RadioBag_01_base_F {
        TFAR_LR_WEST
    };
    class EGVAR(uniform,B_RadioBag_01_coyote_F): B_RadioBag_01_base_F {
        TFAR_LR_WEST
    };

    class EGVAR(uniform_ru,B_RadioBag_01_taiga_F): B_RadioBag_01_base_F {
        TFAR_LR_EAST
    };
    class EGVAR(uniform_ru,B_RadioBag_01_arid_F): B_RadioBag_01_base_F {
        TFAR_LR_EAST
    };
};
