#include "script_component.hpp"

// THE TFAR ADAPTER: jmfsb_voice's "tfar" adapter and TFAR's side of RF's
// backend seam. Loads only with TFAR standalone; without it the PBO is skipped
// and voice is VON (docs/DESIGN_VOICE.md).
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_rf",
            "jmfsb_voice",
            "cba_xeh",
            "cba_settings",
            "tfar_core"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
