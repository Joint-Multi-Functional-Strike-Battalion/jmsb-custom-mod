#include "script_component.hpp"
/*
 * Author: YonV
 * Removes everything TAC//TRAINING spawned in a training area - the men, the
 * dead among them, the crewed statics and vehicles - and marks the area
 * stopped, keeping its after-action numbers. Server only.
 *
 * Arguments:
 * 0: Area marker <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ta_city_north"] call jmfsb_training_fnc_areaClear
 *
 * Public: No
 */

params [["_marker", "", [""]]];

if (!isServer || _marker isEqualTo "") exitWith {};

private _gone = 0;
{
    if ((_x getVariable [QGVAR(area), ""]) isEqualTo _marker) then {
        deleteVehicle _x;
        _gone = _gone + 1;
    };
} forEach (allUnits + allDeadMen);
{
    if ((_x getVariable [QGVAR(area), ""]) isEqualTo _marker) then {
        {deleteVehicle _x} forEach crew _x;
        deleteVehicle _x;
    };
} forEach GVAR(areaVehicles);
GVAR(areaVehicles) = GVAR(areaVehicles) select {!isNull _x};

[_marker, "stopped"] call FUNC(areaState);
if (_gone > 0) then {INFO_2("training area %1 cleared: %2 men",_marker,_gone)};
