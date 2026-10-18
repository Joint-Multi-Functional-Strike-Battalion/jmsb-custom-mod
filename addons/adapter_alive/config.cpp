#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // ALiVE_main is the anchor: without the ALiVE mod the whole PBO is
        // skipped, and every future consumer's !isNil guard simply gets
        // nothing. That is the graceful-degradation half of rule 4.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "cba_xeh",
            "jmfsb_notify",
            "ALiVE_main",
            "ALiVE_x_lib"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"
