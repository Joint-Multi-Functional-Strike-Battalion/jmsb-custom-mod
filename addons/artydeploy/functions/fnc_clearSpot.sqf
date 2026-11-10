#include "script_component.hpp"
/*
 * Author: YonV
 * Server: takes a marked spot's baseplate away without deploying - the driver
 * changed his mind, or wants to move.
 *
 * Sent by remoteExec. The driver named must be the sender's own unit and
 * still that carrier's driver with a spot marked (review S6: any client could
 * clear any carrier's spot).
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 * 1: The driver <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, player] remoteExecCall ["jmfsb_artydeploy_fnc_clearSpot", 2]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (!isServer || {isNull _veh}) exitWith {};
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("clearSpot: refused - machine %1 named %2",remoteExecutedOwner,_unit);
};
if !([_veh, _unit, ACT_CLEAR] call FUNC(canAct)) exitWith {};

private _plate = _veh getVariable [QGVAR(plate), objNull];
if (!isNull _plate) then {deleteVehicle _plate};
_veh setVariable [QGVAR(plate), objNull, true];
_veh setVariable [QGVAR(spotAt), nil, true];
