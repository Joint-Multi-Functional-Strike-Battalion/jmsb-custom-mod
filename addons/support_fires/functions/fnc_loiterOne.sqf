#include "script_component.hpp"
/*
 * Author: JMSB
 * Launches one loitering munition from the site and starts its hunt
 * (FUNC(loiterTick)).
 *
 * A REAL AIR VEHICLE, crewed by its own UAV AI on the players' side, flying
 * to the area on a waypoint at the loiter altitude - so it is seen, heard and
 * shot at like any other drone. A munition recalled before it left is never
 * launched and never spent.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: Search radius (m) <NUMBER>
 * 3: Enemy side <SIDE>
 * 4: Mission token <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, _pos, 400, east, 1] call jmfsb_support_fires_fnc_loiterOne
 *
 * Public: No
 */

params ["_logic", "_target", "_radius", "_enemy", "_token"];

if (isNull _logic || {(_logic getVariable [QGVAR(token), -1]) isNotEqualTo _token}) exitWith {};
if ((_logic getVariable [QGVAR(abort), false]) || {(_logic getVariable [QGVAR(left), 0]) < 1}) exitWith {
    [_logic, _token] call FUNC(sortieDone);
};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _side = _logic getVariable [QGVAR(side), west];
private _alt = _logic getVariable [QGVAR(altitude), 150];

private _from = (getPosATL _logic) vectorAdd [0, 0, LM_SPAWN_HEIGHT];
private _uav = createVehicle [_cls, _from, [], 0, "FLY"];
if (isNull _uav) exitWith {
    WARNING_1("'%1' could not be created - munition not launched",_cls);
    [_logic, _token, "launch failure"] call FUNC(sortieDone);
};
_logic setVariable [QGVAR(left), (_logic getVariable [QGVAR(left), 1]) - 1, true];

_uav setDir (_from getDir _target);
_uav setPosATL _from;
createVehicleCrew _uav;

// The airframe's own crew may be built for another side (there is no OPFOR
// Switchblade); the munition is the players', so its crew is put on their side.
private _grp = group ((crew _uav) param [0, objNull]);
if (side _grp isNotEqualTo _side) then {
    _grp = createGroup [_side, true];
    (crew _uav) joinSilent _grp;
};
_grp setBehaviourStrong "CARELESS";
_grp setCombatMode "BLUE";
_uav flyInHeight _alt;

private _wp = _grp addWaypoint [_target, 0];
_wp setWaypointType "MOVE";

[QGVAR(say), [_logic, "munition launched", "normal"]] call CBA_fnc_globalEvent;

[LINKFUNC(loiterTick), LM_TICK, [
    _uav, _logic, _target, _radius, _token, _enemy,
    _logic getVariable [QGVAR(rule), RULE_BOTH],
    _logic getVariable [QGVAR(warhead), LM_WARHEAD_DEF],
    "transit", CBA_missionTime + LM_TRANSIT_MAX, 0, objNull
]] call CBA_fnc_addPerFrameHandler;
