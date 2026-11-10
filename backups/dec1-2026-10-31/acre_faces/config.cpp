#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // HARD dependencies on purpose - see RadioFaces.hpp. These are
        // merge-overrides of ACRE's own dialog classes, so this PBO has to load
        // after ACRE's or ACRE wins and the faces are stock. Naming them is what
        // orders the load; skipWhenMissingDependencies is what keeps an
        // ACRE-less server loading anyway, by dropping this PBO whole.
        requiredAddons[] = {
            "jmfsb_main",
            "acre_sys_prc148",
            "acre_sys_prc152"
        };
        skipWhenMissingDependencies = 1;
        authorUrl = URL;
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "RadioFaces.hpp"
