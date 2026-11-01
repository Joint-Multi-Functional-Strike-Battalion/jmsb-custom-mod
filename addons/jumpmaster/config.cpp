#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // The tacpad draws the page, maptools the path and reads grids,
        // support_air flies the aircraft's waypoints and opens the static
        // line's canopy, messaging says what happened. EW is read when it is
        // there and never required.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "jmfsb_maptools",
            "jmfsb_support_air",
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
