#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_notify: the full-slots note. jmfsb_devices: the panel and the
        // F-keys hang on its walking view (optional at run time, read guarded).
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "cba_settings",
            "cba_keybinding"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {""};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
