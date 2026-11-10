#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_messaging feeds the reader and jmfsb_hacking feeds two of the
        // tiles, but neither is required: a panel whose source is absent draws
        // its rest state and says so, rather than refusing to load.
        // jmfsb_support is: the reader names a support asset's box by its
        // call sign, and the support core's delivery receipts land on the
        // notify rail.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_tacpad",
            "jmfsb_support",
            "cba_xeh"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"


