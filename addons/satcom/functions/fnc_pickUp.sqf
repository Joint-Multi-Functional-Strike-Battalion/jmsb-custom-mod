#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_satcom_fnc_pickUp

Description:
    Packs the mast back into an item.

Parameters:
    _unit   : OBJECT - the player.
    _target : OBJECT - the mast.

Author:
    JMSB
---------------------------------------------------------------------------- */
params ["_unit", "_target"];

if !([_unit, _target] call FUNC(canPickUp)) exitWith {};

if (stance _unit isEqualTo "STAND") then {
    [_unit, "AmovPercMstpSrasWrflDnon_diary"] call ace_common_fnc_doAnimation;
};

[{
    params ["_unit", "_target"];
    // Re-checked: the mast can be blown up, or somebody else can grab it, during
    // the kneel-down.
    if (isNull _target) exitWith {};
    _unit addItem QGVAR(item);
    deleteVehicle _target;
}, [_unit, _target], SATCOM_PLACE_TIME] call CBA_fnc_waitAndExecute;
