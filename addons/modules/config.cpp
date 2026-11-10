#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {"jmfsb_modulesafestart", "jmfsb_moduleHealArea", "jmfsb_moduleAiSpawner", "jmfsb_moduleAiHunter", QGVAR(holdAlive)};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        // jmfsb_common: the spawn-scale trim and the groupSpawned bus
        requiredAddons[] = {"jmfsb_main", "jmfsb_common"};
        author = "";
        authors[] = {""};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
#include "CfgFactionClasses.hpp"
