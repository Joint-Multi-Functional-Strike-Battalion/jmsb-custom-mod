#include "script_component.hpp"
/*
 * Author: YonV
 * Fills a training area with the enemy the trainer picked (user, 2026-11-07).
 * Server only, raised from TAC//TRAINING. What is already in the area is
 * cleared first. How many comes from the area's analysis and the density
 * (FUNC(areaIntel)); what they do comes from the area's type:
 *
 *     cqb     on building positions, still - they turn and shoot, some low;
 *             CQB_MOVER_SHARE of them move to another room once shots are near
 *     city    teams garrison the buildings (CBA_fnc_taskDefend), a share walk
 *             the streets, out to the patrol radius past the area if one is set
 *     patrol  teams patrol the area, out to the patrol radius past it
 *     base    guards still on building positions, a team holding the centre,
 *             perimeter teams out to the patrol radius, the faction's static
 *             weapons and armed vehicles, crewed, on open flat ground
 *
 * Every group is announced on the mod's spawn bus (common groupSpawned), as
 * the garrison spawner does. The area's live state - spawned, killed, first
 * shot, cleared - is FUNC(areaState)'s.
 *
 * Arguments:
 * 0: Area marker <STRING>
 * 1: Faction class <STRING>
 * 2: Density index 0 light, 1 medium, 2 heavy <NUMBER>
 * 3: Patrol radius past the area, m <NUMBER>
 * 4: Trainer's name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ta_city_north", "OPF_F", 1, 200, "Sgt Smith"] call jmfsb_training_fnc_areaSpawn
 *
 * Public: No
 */

params [["_marker", "", [""]], ["_faction", "", [""]], ["_density", 1, [0]], ["_patrolOut", 0, [0]], ["_by", "", [""]]];

if (!isServer) exitWith {};

private _area = ([] call FUNC(areas)) param [([] call FUNC(areas)) findIf {(_x # 0) isEqualTo _marker}, []];
if (_area isEqualTo []) exitWith {WARNING_1("training area %1 not found",_marker)};
_area params ["", "_type", "_name", "_centre", "_a", "_b", "_angle", "_rect"];
private _shape = [_centre, _a, _b, _angle, _rect];

([_faction] call FUNC(factionClasses)) params [["_side", sideUnknown], ["_men", []], ["_statics", []], ["_vehicles", []]];
if (_men isEqualTo []) exitWith {WARNING_1("training: faction %1 has no riflemen",_faction)};

[_marker] call FUNC(areaClear);

_density = (round _density) max 0 min 2;
([_marker] call FUNC(areaIntel)) params ["", "", "_radius", "", "", "", "_menBy", "_staticsBy", "_vehiclesBy"];
private _count = _menBy # _density;
private _outer = _radius + (_patrolOut max 0);
private _spots = [];
{
    {
        if (_x inArea _shape) then {_spots pushBack _x};
    } forEach (_x buildingPos -1);
} forEach ((nearestObjects [_centre, ["House", "Building"], _radius]) select {_x inArea _shape});
_spots = _spots call BIS_fnc_arrayShuffle;

private _groups = [];
private _units = [];

// A dry point in the area, or the centre.
private _fnc_ground = {
    private _pos = _centre;
    for "_try" from 1 to SPAWN_TRIES do {
        private _p = _centre getPos [_radius * sqrt random 1, random 360];
        if (_p inArea _shape && {!surfaceIsWater _p}) exitWith {_pos = _p};
    };
    _pos
};
// One man into a group, tagged as this area's.
private _fnc_man = {
    params ["_grp", "_pos"];
    private _unit = _grp createUnit [selectRandom _men, _pos, [], 0, "CAN_COLLIDE"];
    _unit setVariable [QGVAR(area), _marker, true];
    _units pushBack _unit;
    _unit
};
private _fnc_group = {
    private _grp = createGroup [_side, true];
    _grp setVariable [QGVAR(area), _marker, true];
    _groups pushBack _grp;
    _grp
};
// N men in teams at one spot each.
private _fnc_teams = {
    params ["_n", "_code"];
    while {_n > 0} do {
        private _grp = call _fnc_group;
        private _at = call _fnc_ground;
        for "_i" from 1 to (_n min TEAM_SIZE) do {[_grp, _at] call _fnc_man};
        _n = _n - TEAM_SIZE;
        [_grp, _centre, _radius, _outer] call _code;
    };
};
// N men still on building positions (open ground when the rooms run out); a
// share of them may move to another room once shots are close.
private _fnc_still = {
    params ["_n", "_movers"];
    private _grp = grpNull;
    for "_i" from 0 to (_n - 1) do {
        if (_i mod TEAM_SIZE isEqualTo 0) then {_grp = call _fnc_group};
        private _pos = _spots param [_i, call _fnc_ground];
        private _unit = [_grp, _pos] call _fnc_man;
        _unit setPosATL _pos;
        _unit setUnitPos selectRandom ["UP", "UP", "MIDDLE"];
        _unit setDir random 360;
        _unit disableAI "PATH";
        if (random 1 < _movers) then {
            _unit setVariable [QGVAR(spots), _spots];
            _unit addEventHandler ["FiredNear", {
                params ["_unit"];
                _unit removeEventHandler ["FiredNear", _thisEventHandler];
                _unit enableAI "PATH";
                _unit doMove (selectRandom (_unit getVariable [QGVAR(spots), [getPosATL _unit]]));
            }];
        };
    };
};
// [group, centre, area radius, patrol radius] - what each team is told to do
private _fnc_patrol = {
    params ["_grp", "_at", "", "_out"];
    [_grp, _at, _out, PATROL_WAYPOINTS, "MOVE", "SAFE", "YELLOW", "LIMITED"] call CBA_fnc_taskPatrol;
};
private _fnc_defend = {
    params ["_grp", "_at", "_r"];
    [_grp, _at, _r, DEFEND_THRESHOLD, DEFAULT_PATROL, DEFAULT_HOLD] call CBA_fnc_taskDefend;
};
// A crewed static or vehicle on flat open ground.
private _fnc_crewed = {
    params ["_class"];
    private _pos = call _fnc_ground;
    private _flat = _pos findEmptyPosition [0, _radius / 2, _class];
    if (_flat isNotEqualTo []) then {_pos = _flat};
    private _veh = createVehicle [_class, _pos, [], 0, "NONE"];
    _veh setDir random 360;
    _veh setVariable [QGVAR(area), _marker, true];
    private _crew = createVehicleCrew _veh;
    _crew setVariable [QGVAR(area), _marker, true];
    {_x setVariable [QGVAR(area), _marker, true]; _units pushBack _x} forEach crew _veh;
    if (!isNull driver _veh) then {(driver _veh) disableAI "PATH"};
    _groups pushBack _crew;
    GVAR(areaVehicles) pushBack _veh;
};

switch (_type) do {
    case "cqb": {[_count, CQB_MOVER_SHARE] call _fnc_still};
    case "city": {
        private _walk = round (_count * CITY_PATROL_SHARE);
        [_count - _walk, _fnc_defend] call _fnc_teams;
        [_walk, _fnc_patrol] call _fnc_teams;
    };
    case "base": {
        private _perimeter = TEAM_SIZE * (_density + 1);
        private _guards = (_count - _perimeter) max 0;
        [_guards min (count _spots), 0] call _fnc_still;
        [(_guards - count _spots) max 0, _fnc_defend] call _fnc_teams;
        [_perimeter, _fnc_patrol] call _fnc_teams;
        if (_statics isNotEqualTo []) then {
            for "_i" from 1 to (_staticsBy # _density) do {[selectRandom _statics] call _fnc_crewed};
        };
        if (_vehicles isNotEqualTo []) then {
            for "_i" from 1 to (_vehiclesBy # _density) do {[selectRandom _vehicles] call _fnc_crewed};
        };
    };
    default {[_count, _fnc_patrol] call _fnc_teams};
};

{
    _x deleteGroupWhenEmpty true;
    [QEGVAR(common,groupSpawned), [_x, [], [false]]] call CBA_fnc_localEvent;
} forEach _groups;
// The first shot near any of them starts the clock (FUNC(areaState)).
{
    _x addEventHandler ["FiredNear", {
        params ["_unit"];
        _unit removeEventHandler ["FiredNear", _thisEventHandler];
        [_unit getVariable [QGVAR(area), ""], "shot"] call FUNC(areaState);
    }];
} forEach _units;

private _factionName = getText (configFile >> "CfgFactionClasses" >> _faction >> "displayName");
[_marker, "spawned", [count _units, [_factionName, _faction] select (_factionName isEqualTo ""), (DENSITIES # _density) # 1, _patrolOut, _by]] call FUNC(areaState);
INFO_5("training area %1 (%2): %3 men of %4 by %5",_name,_type,count _units,_faction,_by);
