#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // ACE medical and ACM are read when they are there and never required:
        // without them the app says MEDICAL SYSTEM NOT LOADED rather than the
        // PBO refusing to load.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "cba_xeh"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
