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
        // The ALiVE names here are PATCHES_ALIVE in common's
        // script_component.hpp - config needs literals, so keep the two in
        // step (user, 2026-11-02: "use the alive main pbo names").
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
