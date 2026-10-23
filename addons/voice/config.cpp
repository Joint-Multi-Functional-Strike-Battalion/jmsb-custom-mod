#include "script_component.hpp"

// VOICE: nets, calls, callbacks and radio sounds on top of RF. The audio is
// carried by a voice adapter (adapter_von: Arma 3 VON). docs/DESIGN_VOICE.md.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_rf",
            "jmfsb_notify",
            "cba_main",
            "cba_xeh",
            "cba_settings"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
