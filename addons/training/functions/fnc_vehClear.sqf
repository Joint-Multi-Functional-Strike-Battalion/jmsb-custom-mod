#include "script_component.hpp"
/*
 * Author: YonV
 * DESPAWN for a vehicle range: its vehicles, their wrecks, their crews and any
 * crewman dead outside, gone; the range marked stopped. Server only - the
 * app's DESPAWN, the module's despawn timer and a new SPAWN call it.
 *
 * Arguments:
 * 0: Range key <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["vr_1200_3400"] call jmfsb_training_fnc_vehClear
 *
 * Public: No
 */

params [["_key", "", [""]]];

if (!isServer || _key isEqualTo "") exitWith {};

private _gone = 0;
{
    if ((_x getVariable [QGVAR(range), ""]) isEqualTo _key) then {
        {deleteVehicle _x} forEach crew _x;
        deleteVehicle _x;
        _gone = _gone + 1;
    };
} forEach (vehicles + allDead);
{
    if ((_x getVariable [QGVAR(range), ""]) isEqualTo _key) then {deleteVehicle _x};
} forEach (allUnits + allDeadMen);

if ((([_key] call FUNC(vehState)) # 0) isEqualTo "live") then {[_key, "stopped"] call FUNC(vehState)};
if (_gone > 0) then {INFO_2("vehicle range %1 despawned: %2 vehicles",_key,_gone)};
