#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // ACRE2 is a SOFT dependency: without it there is nothing to route and
        // every ACRE call is guarded at runtime. jmfsb_jamming is not required
        // either - its jam level is read by name if it is there (see
        // fnc_signal) and this addon takes over the one custom signal function
        // ACRE allows, so the two never fight for it.
        requiredAddons[] = {
            "jmfsb_main",
            "cba_xeh",
            "cba_settings"
        };
        skipWhenMissingDependencies = 1;
        authorUrl = URL;
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
