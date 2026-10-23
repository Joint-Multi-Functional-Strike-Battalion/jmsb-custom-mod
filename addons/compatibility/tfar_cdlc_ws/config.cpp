#include "script_component.hpp"

// TFAR AND WESTERN SAHARA LOADED: the WS overlay's radio bag (compatibility
// cdlc_ws, MCU-D) is a TFAR long range set again, with the 1268 build's
// values. Without TFAR it is a plain bag with its jmfsb_rf_profile.
class CfgPatches {
    class SUBADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_compatibility_cdlc_ws",
            "tfar_core",
            "tfar_backpacks"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

class CfgVehicles {
    class B_RadioBag_01_base_F;

    class EGVAR(uniform,B_RadioBag_01_des_lxWS): B_RadioBag_01_base_F {
        tf_dialog = "rt1523g_radio_dialog";
        tf_dialogUpdate = "call TFAR_fnc_updateLRDialogToChannel;";
        tf_encryptionCode = "tf_west_radio_code";
        tf_hasLRradio = 1;
        tf_range = 20000;
        tf_subtype = "digital_lr";
    };
};
