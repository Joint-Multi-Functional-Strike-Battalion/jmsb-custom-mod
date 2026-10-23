#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            "jmfsb_moduleFiresArtillery",
            "jmfsb_moduleFiresVirtual",
            "jmfsb_moduleFiresCruise",
            "jmfsb_moduleFiresLoiter"
        };
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_support is the core this addon is a provider of; it brings
        // jmfsb_messaging, which says SPLASH on the requester's screen.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_support"
        };
        authorUrl = "https://github.com/Joint-Multi-Functional-Strike-Battalion/";
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
