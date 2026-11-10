#include "script_component.hpp"
/*
 * Author: YonV
 * A man gets out of the landed jump aircraft (2026-11-09, an RTB with a
 * landing point - FUNC(srvRtbLand)): his JUMP action and leave to jump are
 * taken off, and he is put out - out of his seat, or, standing in the bay,
 * set down on the ground beside the hull. Run where he is local, by
 * remoteExec from the server only (review S7).
 *
 * Arguments:
 * 0: The man <OBJECT>
 * 1: The aircraft <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, _veh] remoteExecCall ["jmfsb_jumpmaster_fnc_unload", _unit]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_veh", objNull, [objNull]]];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("unload: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (!alive _unit || {!local _unit}) exitWith {};

_unit setVariable [QGVAR(mayJump), false];
private _id = _unit getVariable [QGVAR(action), -1];
if (_id >= 0) then {
    _unit removeAction _id;
    _unit setVariable [QGVAR(action), -1];
};

if (!isNull (attachedTo _unit)) then {
    detach _unit;
    private _beside = (getPosATL _veh) getPos [EXIT_SIDE + (sizeOf (typeOf _veh)) / 2, getDir _veh + RTB_EXIT_BEARING];
    _unit setPosATL [_beside select 0, _beside select 1, 0];
};
if (vehicle _unit isNotEqualTo _unit) then {
    unassignVehicle _unit;
    moveOut _unit;
};
