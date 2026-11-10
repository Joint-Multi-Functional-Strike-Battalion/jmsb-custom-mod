#include "script_component.hpp"
/*
 * Author: YonV
 * The training areas: every JMSB - Training Area module the mission places
 * (user, 2026-11-07: a module with all the choices in it, instead of
 * markers). The module's own area is the area; its arguments are the type,
 * the name and what the app starts with and offers. Read once per machine,
 * by name. An area's key is its grid position, so every machine names it the
 * same way (FUNC(areaState) publishes by key).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Areas [[key, type, name, centre, a, b, angle, rectangle, defaults], ...] - defaults is
 * [faction, density, patrol, factions offered] <ARRAY>
 *
 * Example:
 * [] call jmfsb_training_fnc_areas
 *
 * Public: No
 */

if (!isNil QGVAR(areas)) exitWith {GVAR(areas)};

private _out = [];
{
    private _centre = getPosATL _x;
    (_x getVariable ["objectArea", [AREA_DEFAULT_SIZE, AREA_DEFAULT_SIZE, 0, false]]) params [["_a", AREA_DEFAULT_SIZE], ["_b", AREA_DEFAULT_SIZE], ["_angle", 0], ["_rect", false]];
    private _type = (TA_TYPES param [_x getVariable ["type", 0], TA_TYPES # 0]) # 0;
    private _name = _x getVariable ["name", ""];
    if (_name isEqualTo "") then {_name = format ["AREA %1", mapGridPosition _x]};
    private _offered = ((_x getVariable ["factions", ""]) splitString ", ") select {_x isNotEqualTo ""};
    _out pushBack [
        format ["ta_%1_%2", round (_centre # 0), round (_centre # 1)], _type, _name, _centre, _a, _b, _angle, _rect,
        [_x getVariable ["faction", ""], (_x getVariable ["density", 1]) max 0 min 2, (_x getVariable ["patrol", 0]) max 0 min PATROL_MAX, _offered]
    ];
} forEach (allMissionObjects QGVAR(moduleArea));

// By name, then key; the index takes each area back out.
private _keys = _out apply {[toLower (_x # 2), _x # 0]};
{_x pushBack _forEachIndex} forEach _keys;
_keys sort true;
_out = _keys apply {_out select (_x # 2)};
GVAR(areas) = _out;
INFO_1("training areas: %1",_out apply {_x # 2});

_out
