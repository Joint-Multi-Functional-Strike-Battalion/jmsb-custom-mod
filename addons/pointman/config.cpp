#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // The tacpad draws the page, maptools reads the grids and draws the
        // legs, devices carries the phone's status cell and the tablet bar,
        // tacpad_apps the tile; messaging says what happened. EW is read when
        // it is there (the GPS fix) and never required.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "jmfsb_maptools",
            "jmfsb_devices",
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
