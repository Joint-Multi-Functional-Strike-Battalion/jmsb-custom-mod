#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {QGVAR(moduleJump)};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // The support core takes the jump aircraft as an asset and carries
        // the thread (2026-11-02), support_air flies the aircraft's waypoints
        // and opens the static line's canopy, messaging says each man's light,
        // tacpad_apps says who is a squad leader, devices shows the ALT
        // readout. EW is read when it is there and never required. The Jump
        // Aircraft module's class picker is jmfsb_main's (2026-11-02).
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_support",
            "jmfsb_tacpad_apps",
            "jmfsb_support_air",
            "jmfsb_messaging",
            "jmfsb_devices",
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
