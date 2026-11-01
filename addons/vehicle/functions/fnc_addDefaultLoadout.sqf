#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This function apply a default loadouts to a selected vehicle.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * nothing
 *
 * Example:
 * [_vehicle] call jmfsb_vehicle_fnc_addDefaultLoadout;
 *
 * Public: No
 */
params [["_vehicle", objNull, [objNull]]];

if (!isServer) exitWith {};
if (!isNil{_vehicle getVariable QEGVAR(VehicleFunc,DefaultPylon)}) exitWith {SHOW_WARNING_2("VehicleDefaultLoadout","Vehicle loadouts already applied for %1. [%2].",_vehicle,typeOf _vehicle);};
if (!(_vehicle call EFUNC(systems,isValidFaction))) exitWith {};

TRACE_INFO_2("VehicleDefaultLoadout","Applying vehicle loadout to %1 [%2].",_vehicle,typeOf _vehicle);

// Default pylon applied
private _pylon = [];

{
    if (_vehicle isKindOf _x) exitWith {
        _pylon = [_x, "default"] call EFUNC(vehicle,getPylonLoadout);
        TRACE_INFO_3("VehicleDefaultLoadout","Vehicle %1 [%2] applied have loadout %3.",_vehicle,typeOf _vehicle,_pylon);
        [_vehicle, "default", _pylon] call EFUNC(vehicle,applyLoadout);
    };
} forEach (keys EGVAR(init,PYLONS));

if (count _pylon == 0) then {
    // a quadbike or a truck has no pylons: nothing to apply is the normal
    // case for most vehicles, not a fault, so it is not a warning
    TRACE_INFO_2("VehicleDefaultLoadout","Vehicle %1 [%2] has no loadout setup.",_vehicle,typeOf _vehicle);
} else {
    _vehicle setVariable ["ace_rearm_scriptedLoadout", true, true];
};

_vehicle setVariable [QEGVAR(VehicleFunc,DefaultPylon), true, true];
