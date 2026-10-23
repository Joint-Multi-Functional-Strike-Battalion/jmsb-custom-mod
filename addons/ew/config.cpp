#include "script_component.hpp"

// EW: direction finding, tracks, jamming (barrage / spot / sweep / GPS),
// GPS spoofing and decoys, on top of the RF core (docs/DESIGN_EW.md). The
// RF registry, link budget and hooks are jmfsb_rf's; this addon is rules.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {QGVAR(jammerPack)};
        weapons[] = {QGVAR(receiver)};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_common",
            "jmfsb_notify",
            "jmfsb_rf",
            "jmfsb_tacpad",
            "jmfsb_tacpad_apps",
            "cba_xeh",
            "cba_settings",
            "cba_jr",
            "A3_Weapons_F",
            "A3_Supplies_F_Enoch_Bags"
        };
        skipWhenMissingDependencies = 1;
        authorUrl = URL;
        author = QAUTHOR;
        authors[] = {"JMSB"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
#include "CfgWeapons.hpp"
