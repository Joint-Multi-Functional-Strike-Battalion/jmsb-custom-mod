#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_messaging answers the tasking tag gate (EFUNC(messaging,tagMatch)).
        // Nothing here names an asset kind or a provider: providers depend on
        // this addon, never the reverse.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_messaging",
            "cba_xeh"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
