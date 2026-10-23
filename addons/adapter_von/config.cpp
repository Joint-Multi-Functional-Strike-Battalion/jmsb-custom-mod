#include "script_component.hpp"

// THE VON ADAPTER: jmfsb_voice's default voice backend, Arma 3's own VON.
// Channels, membership, per-speaker volume and talking detection.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_voice",
            "cba_main",
            "cba_xeh",
            "cba_settings",
            "A3_Ui_F"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "RscDisplayVoiceChat.hpp"
