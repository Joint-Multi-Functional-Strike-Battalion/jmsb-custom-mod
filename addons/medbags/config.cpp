#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        author = QAUTHOR;
        name = COMPONENT_NAME;
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "A3_Props_F_Orange",
            "jmfsb_common"
        };
        units[] = {
            QGVAR(Item_FirstAid),
            QGVAR(Item_Fluid),
            QGVAR(Item_MedicKit),
            QGVAR(Item_DrugKit),
            QGVAR(Item_Trauma),
            QGVAR(Item_Mopp_MTP),
            QGVAR(Item_Mopp_Tropic),
            QGVAR(Item_Mopp_Wdl)
        };
        weapons[] = {
            QGVAR(FirstAid),
            QGVAR(Fluid),
            QGVAR(MedicKit),
            QGVAR(DrugKit),
            QGVAR(Trauma),
            QGVAR(Mopp_MTP),
            QGVAR(Mopp_Tropic),
            QGVAR(Mopp_Wdl)
        };
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgSounds.hpp"
#include "CfgVehicles.hpp"
#include "CfgWeapons.hpp"
