#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {QGVAR(moduleMark)};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "cba_main",
            "cba_xeh"
        };
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "gui.hpp"
#include "CfgVehicles.hpp"
