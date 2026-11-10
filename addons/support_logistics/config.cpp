#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        // The old JMSB - Logistics Drop keeps its class name (user,
        // 2026-11-01: it moved here from support_air, and missions that
        // placed it must still load) - see CfgVehicles.hpp.
        units[] = {
            QGVAR(module),
            QGVAR(moduleCatalog),
            "jmfsb_support_air_moduleLogistics"
        };
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_support is the core this addon is a provider of.
        // jmfsb_support_air flies the same aircraft the same way: its
        // waypoint, removal and flight-time helpers are used, not copied, and
        // it must load first so the moved Logistics Drop class is defined
        // here only. jmfsb_cas writes the ETA the way every board line does.
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_messaging",
            "jmfsb_support",
            "jmfsb_support_air",
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
