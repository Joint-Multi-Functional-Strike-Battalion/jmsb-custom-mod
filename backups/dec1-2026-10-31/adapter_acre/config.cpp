#include "script_component.hpp"

// THE ACRE ADAPTER: jmfsb_voice's "acre" adapter and ACRE's side of RF's
// backend seam. Loads only with ACRE2; without it the PBO is skipped.
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
            "acre_main"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
