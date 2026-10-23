#include "script_component.hpp"
/*
 * Author: JMSB
 * The replacement for a lost synced aircraft, built on the stand the first
 * one stood on, facing the same way, crewed as the mission maker crewed it
 * (FUNC(restoreCrew)) and adopted as the asset (FUNC(adopt)). Run on the
 * server when the module's Respawn Delay is up (FUNC(lost)).
 *
 * The stand is cleared first: a wreck on it is removed, and so is an old
 * airframe that is still alive but cannot fly (a transport written off by
 * its watch) - unless a player is aboard it.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft it replaces <OBJECT>
 *
 * Return Value:
 * The replacement <OBJECT>
 *
 * Example:
 * [_logic, _old] call jmfsb_support_air_fnc_respawn
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_old", objNull, [objNull]]];

if (isNull _logic || {!isServer} || {_logic getVariable [QGVAR(dead), false]}) exitWith {objNull};

private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _cls = _logic getVariable [QGVAR(cls), ""];

if (!isNull _old && {(crew _old) findIf {isPlayer _x} < 0} && {!alive _old || {_old distance2D _home < STAND_CLEAR} || {!canMove _old}}) then {
    _old setVariable [QGVAR(owner), objNull, true];
    [_old] call FUNC(sweep);
};

private _veh = createVehicle [_cls, [0, 0, 0], [], 0, "CAN_COLLIDE"];
if (isNull _veh) exitWith {
    WARNING_2("%1: the replacement '%2' could not be built",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_cls);
    objNull
};
_veh setDir (_logic getVariable [QGVAR(homeDir), 0]);
_veh setPosASL (_logic getVariable [QGVAR(homeASL), AGLToASL _home]);

[_logic, _veh] call FUNC(restoreCrew);
[_logic, _veh] call FUNC(adopt);
_logic setVariable [QGVAR(respawnAt), 0, true];

[_logic, "replacement aircraft is on the stand", "normal"] call FUNC(say);

_veh
