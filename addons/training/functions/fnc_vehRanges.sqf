#include "script_component.hpp"
/*
 * Author: YonV
 * The vehicle ranges: every JMSB - Vehicle Range module the mission places
 * (user, 2026-11-07). The module's own area is the range; its arguments are
 * the vehicles, the direction, how many, how fast and when they despawn.
 * Read once per machine. A range's key is its grid position, so every machine
 * names it the same way (FUNC(vehState) publishes by key). The first eight
 * fields are a training area's (FUNC(areas)), so FUNC(showArea) draws either.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Ranges [[key, "vehicles", name, centre, a, b, angle, rectangle, settings], ...] -
 * settings is [classes, direction index, count, speed km/h, despawn minutes] <ARRAY>
 *
 * Example:
 * [] call jmfsb_training_fnc_vehRanges
 *
 * Public: No
 */

if (!isNil QGVAR(ranges)) exitWith {GVAR(ranges)};

private _out = [];
{
    private _centre = getPosATL _x;
    (_x getVariable ["objectArea", [AREA_DEFAULT_SIZE, AREA_DEFAULT_SIZE, 0, true]]) params [["_a", AREA_DEFAULT_SIZE], ["_b", AREA_DEFAULT_SIZE], ["_angle", 0], ["_rect", true]];
    private _name = _x getVariable ["name", ""];
    if (_name isEqualTo "") then {_name = format ["RANGE %1", mapGridPosition _x]};
    private _classes = ((_x getVariable ["vehicles", ""]) splitString ", ") select {isClass (configFile >> "CfgVehicles" >> _x)};
    if (_classes isEqualTo []) then {WARNING_1("vehicle range '%1' names no vehicle class that is loaded",_name)};
    _out pushBack [
        format ["vr_%1_%2", round (_centre # 0), round (_centre # 1)], "vehicles", _name, _centre, _a, _b, _angle, _rect,
        [
            _classes,
            (round (_x getVariable ["direction", 0])) max 0 min (count VR_DIRECTIONS - 1),
            (round (_x getVariable ["count", VR_DEFAULT_COUNT])) max 1 min VR_MAX_COUNT,
            (_x getVariable ["speed", VR_DEFAULT_SPEED]) max VR_SPEED_STEP min VR_MAX_SPEED,
            (_x getVariable ["despawn", 0]) max 0
        ]
    ];
} forEach (allMissionObjects QGVAR(moduleVehicles));

private _keys = _out apply {[toLower (_x # 2), _x # 0]};
{_x pushBack _forEachIndex} forEach _keys;
_keys sort true;
_out = _keys apply {_out select (_x # 2)};
GVAR(ranges) = _out;
INFO_1("vehicle ranges: %1",_out apply {_x # 2});

_out
