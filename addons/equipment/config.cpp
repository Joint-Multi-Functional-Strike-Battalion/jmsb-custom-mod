#include "script_component.hpp"

class CfgPatches {
    class ADDON {

        author = QAUTHOR;
        name = COMPONENT_NAME;
        units[] = {
            QGVAR(Item_Vector_Designator),
            QGVAR(Item_Vector_Designator_NVG),
            QGVAR(Item_vest_rebreather),
            QGVAR(Item_Wetsuit)
        };
        weapons[] = {
            QGVAR(Vector_Designator),
            QGVAR(Vector_Designator_NVG),
            QGVAR(rebreather),
            QGVAR(Wetsuit)
        };
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "A3_Ui_F",
            "cba_main",
            "cba_xeh",
            "jmfsb_main",
            "jmfsb_medbags",
            "jmfsb_notify",
            "ace_vector",
            "ace_fortify",
            "A3_Weapons_F",
            "cba_jr",
            "ace_xm157"
        };
        VERSION_CONFIG;
        authors[] = {"YonV"};
    };
};

class CfgFunctions {
    #include "CfgFunctions.hpp"
};
#include "CfgEventHandlers.hpp"
#include "CfgVehicles.hpp"
#include "CfgWeapons.hpp"
#include "XtdGear.hpp"
#include "RscInGameUI.hpp"
#include "CfgMagazines.hpp"
#include "ACEX_Fortify_Presets.hpp"
