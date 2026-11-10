#include "script_component.hpp"
/*
 * Author: YonV
 * What a training area is, for the trainer and for the spawner (user,
 * 2026-11-07: "intel or analysis on the training area"): its size, the
 * buildings in it, the building positions a man can stand in, how many men it
 * holds, and the number each density puts there. Worked out off the terrain
 * once per area and kept - the terrain does not change.
 *
 * HOW MANY, PER TYPE:
 *     cqb     a share of the building positions (CQB_SHARE)
 *     city    a share of the positions (CITY_SHARE), plus street patrols
 *     patrol  teams of TEAM_SIZE (PATROL_TEAMS)
 *     base    a share of the positions (BASE_SHARE), plus statics and vehicles
 * Every count is held to MIN_MEN..MAX_MEN and to what the area holds.
 *
 * Arguments:
 * 0: Area marker <STRING>
 *
 * Return Value:
 * [type, areaM2, radius, buildings, positions, capacity, [light, medium, heavy] men,
 *  [light, medium, heavy] statics, [light, medium, heavy] vehicles], [] for no such area <ARRAY>
 *
 * Example:
 * ["ta_cqb_house1"] call jmfsb_training_fnc_areaIntel
 *
 * Public: No
 */

params [["_marker", "", [""]]];

if (isNil QGVAR(intel)) then {GVAR(intel) = createHashMap};
if (_marker in GVAR(intel)) exitWith {GVAR(intel) get _marker};

private _area = ([] call FUNC(areas)) param [([] call FUNC(areas)) findIf {(_x # 0) isEqualTo _marker}, []];
if (_area isEqualTo []) exitWith {[]};
_area params ["", "_type", "", "_centre", "_a", "_b", "_angle", "_rect"];

private _radius = _a max _b;
private _m2 = [pi * _a * _b, 4 * _a * _b] select _rect;
private _buildings = (nearestObjects [_centre, ["House", "Building"], _radius]) select {
    _x inArea [_centre, _a, _b, _angle, _rect] && {(_x buildingPos -1) isNotEqualTo []}
};
private _positions = 0;
{_positions = _positions + count (_x buildingPos -1)} forEach _buildings;
private _capacity = _positions + floor (_m2 / OPEN_GROUND_PER_MAN);

private _fnc_hold = {(round _this) max MIN_MEN min MAX_MEN min (_capacity max MIN_MEN)};
private _men = [];
switch (_type) do {
    case "cqb": {_men = CQB_SHARE apply {(_positions * _x) call _fnc_hold}};
    case "city": {_men = CITY_SHARE apply {((_positions * _x) * (1 + CITY_PATROL_SHARE)) call _fnc_hold}};
    // the guards, plus one perimeter team per density step
    case "base": {
        {_men pushBack ((_positions * _x + TEAM_SIZE * (_forEachIndex + 1)) call _fnc_hold)} forEach BASE_SHARE;
    };
    default {_men = PATROL_TEAMS apply {(_x * TEAM_SIZE) max MIN_MEN min MAX_MEN}};
};
private _statics = [[0, 0, 0], BASE_STATICS] select (_type isEqualTo "base");
private _vehicles = [[0, 0, 0], BASE_VEHICLES] select (_type isEqualTo "base");

private _out = [_type, round _m2, round _radius, count _buildings, _positions, _capacity, _men, _statics, _vehicles];
GVAR(intel) set [_marker, _out];
_out
