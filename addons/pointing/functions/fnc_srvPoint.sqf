#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a man in a vehicle points (FUNC(keyPressVehicle), by remoteExec).
 * The pointer is the sender himself, in a vehicle that is not a static
 * weapon, and the point is within POINT_DISTANCE; it goes to that vehicle's
 * crew (FUNC(pointed), which takes it only from the server).
 *
 * Review R1: it was the pointed CBA event, so any client could show any man
 * pointing anywhere on anyone's screen.
 *
 * Arguments:
 * 0: Pointed position ASL <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_posASL] remoteExecCall ["jmfsb_pointing_fnc_srvPoint", 2]
 *
 * Public: No
 */

params [["_posASL", [], [[]], 3]];

if (!isServer || {_posASL isEqualTo []}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
private _vehicle = vehicle _unit;
if (isNull _unit || !alive _unit || _vehicle isEqualTo _unit || _vehicle isKindOf "StaticWeapon") exitWith {
    WARNING_1("srvPoint: refused - machine %1 is not in a vehicle",_owner);
};
if ((eyePos _unit) vectorDistance _posASL > POINT_DISTANCE + POINT_SLACK) exitWith {};

[_unit, _posASL] remoteExecCall [QFUNC(pointed), crew _vehicle];
