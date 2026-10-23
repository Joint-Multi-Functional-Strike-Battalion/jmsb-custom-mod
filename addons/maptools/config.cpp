#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_tacpad for the theme tokens every line and label is drawn in
        // and the host map's idc; jmfsb_common for the player-marker helper
        // MARK files its marker through.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_tacpad",
            "cba_xeh"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
