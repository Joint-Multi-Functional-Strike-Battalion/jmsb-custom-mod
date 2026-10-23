#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(moduleCAS),
            QGVAR(moduleTransport),
            QGVAR(moduleLogistics),
            QGVAR(moduleQRF)
        };
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_support is the core this addon is a provider of. jmfsb_cas
        // owns the strike itself - terminal guidance, the stores read and the
        // release - and the CAS module here flies its runs through those
        // rather than a second copy of them. jmfsb_messaging says what
        // happens to the side.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_messaging",
            "jmfsb_support",
            "jmfsb_cas",
            "cba_xeh"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgEden.hpp"
#include "CfgVehicles.hpp"
