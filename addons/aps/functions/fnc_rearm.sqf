#include "script_component.hpp"
/*
 * Author: YonV
 * Reloads a vehicle's launchers to full (server) and tells its crew.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];
if (isNull _veh) exitWith {};

private _max = _veh getVariable [QGVAR(ammoMax), 0];
if (_max <= 0) exitWith {};
if (([_veh] call FUNC(charges)) >= 2 * _max) exitWith {};

_veh setVariable [QGVAR(ammoL), _max, true];
_veh setVariable [QGVAR(ammoR), _max, true];
[_veh, -1, "REARMED"] remoteExec [QFUNC(report), [0, -2] select isDedicatedServer];
if (GVAR(debug)) then { INFO_1("%1 rearmed",typeOf _veh) };
