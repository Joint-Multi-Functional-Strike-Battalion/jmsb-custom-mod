#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_tacpad(_apps): the app and its tile. jmfsb_notify: the
        // crossing prompts. Map TOOLS, messaging, ECOTI and the watch are
        // read guarded.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "cba_settings"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {""};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
