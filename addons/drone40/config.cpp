#include "script_component.hpp"

// DRONE40 RELAY / DECOY / JAMMER. Three more rounds for the GX Drones mod's
// Drone40, loaded in every launcher GX's own rounds load in. Skipped when GX
// is not loaded.
class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(B_relay), QGVAR(O_relay), QGVAR(I_relay),
            QGVAR(B_decoy), QGVAR(O_decoy), QGVAR(I_decoy),
            QGVAR(B_jammer), QGVAR(O_jammer), QGVAR(I_jammer)
        };
        weapons[] = {};
        magazines[] = {DRONE40_MAGAZINES};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "jmfsb_main",
            "jmfsb_rf",
            "cba_xeh",
            "gx_drones_uav_drone40"
        };
        skipWhenMissingDependencies = 1;
        author = QAUTHOR;
        authors[] = {"JMSB"};
        authorUrl = URL;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgAmmo.hpp"
#include "CfgMagazines.hpp"
#include "CfgMagazineWells.hpp"
#include "CfgWeapons.hpp"
#include "CfgVehicles.hpp"
