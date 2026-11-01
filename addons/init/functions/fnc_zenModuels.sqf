#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A, SPC.Turn.J
 * This function load all JMSB modules. Requires Zen Mod to run propperly. The function will terminate if not.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call jmfsb_init_fnc_zenModuels
 *
 * Public: No
 */

if !(EGVAR(patches,usesZen)) exitWith {};

// ZEN IS LOADED, BUT ITS REGISTER FUNCTION MAY NOT BE COMPILED YET - the same
// guard `patrol_base` and `respawn` carry. Registering into nothing is exactly
// how these twelve went missing from the Zeus module tree.
if (isNil "zen_custom_modules_fnc_register") exitWith {
    INFO("init","zen_custom_modules_fnc_register missing - JMSB Zeus modules NOT registered.");
};

INFO("init","Initializing custom Zen Modules.");

["JMSB AI", "Enable Unit Simulation",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,EnableUnitSimulation);    
    },
    "\A3\ui_f\data\map\vehicleicons\iconManVirtual_ca.paa"
] call zen_custom_modules_fnc_register;


["JMSB Logistics", "Staging Zone",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos]  call EFUNC(zenmodules,createStaging);    
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Logistics", "Add Staging",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos]  call EFUNC(zenmodules,addStaging);    
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Logistics", "Spawn Re-supply Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,CreateSupplyCrate);
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Mission", "Call Endex",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,CallEndex);
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Mission", "Take attendance",
    {
        [] remoteExecCall [QFUNC(srvAttendance), SERVER_OWNER];
        ["Attendance requested from the server"] call zen_common_fnc_showMessage;
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Mission", "Staging Zones",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,stagingZones);
    },
    "\a3\modules_f\data\portraitmodule_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Logistics", "Spawn Field Hospital",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,createFieldHospital);
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Logistics", "Spawn Medical Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,createMedicalCrate);
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB Logistics", "Spawn Starter Crate",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,CreateStarterCrate);
    },
    "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
] call zen_custom_modules_fnc_register;

["JMSB AI", "Set Unit Injury",
    {
        params ["_modulePos", "_objectPos"];
        [_modulePos, _objectPos] call EFUNC(zenmodules,setDamage);
    },
    "\A3\ui_f\data\map\vehicleicons\iconManMedic_ca.paa"
] call zen_custom_modules_fnc_register;

INFO("init","Custom Zen Modules initialization complete");
