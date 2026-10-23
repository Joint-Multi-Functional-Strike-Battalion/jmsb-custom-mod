#include "script_component.hpp"
/*
 * Author: JMSB
 * Who holds this drone: the player linked to it through FUNC(uavControl) - the
 * drone's public jmfsb_devices_uavOperator, while that man is alive and still
 * in the game - else a vanilla UAV terminal still connected to it (a mission or
 * a generated faction loadout that kept one), else nobody.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 *
 * Return Value:
 * Operator, objNull for none <OBJECT>
 *
 * Example:
 * private _op = [_uav] call jmfsb_devices_fnc_uavOperator
 *
 * Public: Yes
 */

params [["_uav", objNull, [objNull]]];

if (isNull _uav) exitWith {objNull};

private _operator = _uav getVariable [QGVAR(uavOperator), objNull];
if (alive _operator && {_operator in allPlayers}) exitWith {_operator};

// UAVControl is [unit, seat] or [unit, seat, unit, seat]; the units only.
private _terminal = ((UAVControl _uav) select {_x isEqualType objNull}) - [objNull];
_terminal param [0, objNull]
