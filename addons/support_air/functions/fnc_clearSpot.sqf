#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the nearest spot where a helicopter's rotor turns clear of
 * everything (2026-11-02, the user's RPT 07:37:53: "RAVEN transport cannot
 * fly - canMove false - too damaged to fly (damage 0.00; hit points hithrotor
 * 1.00 ... on the ground ... never hit)" - a rotor strike, and the same
 * write-off the day before). findEmptyPosition fits the body, not the rotor
 * disc: a tree, a lamp post or a hangar's eaves over a pad it called empty.
 *
 * Clear: no tree, building, wall, rock or mission object (CLEAR_TERRAIN_TYPES,
 * CLEAR_OBJECT_KINDS; never a man nor an aircraft in the air - an escort
 * drone overhead) whose top is more than ROTOR_DISC_LOW m
 * above the ground - for an aircraft in the air, its height less that - within
 * the airframe's bounding radius plus ROTOR_MARGIN m; on the ground also no
 * water and no slope steeper than LANDING_FLAT_MIN. The point itself first,
 * then rings CLEAR_STEP m apart out to the search radius, CLEAR_BEARING_STEP
 * deg apart.
 *
 * Arguments:
 * 0: The helicopter <OBJECT>
 * 1: The spot asked for <ARRAY>
 * 2: Its height above the ground there, 0 on the ground <NUMBER>
 * 3: How far out a clear spot is looked for, m <NUMBER>
 * 4: Objects that do not count - a wreck being swept <ARRAY> (optional, default [])
 *
 * Return Value:
 * [the clear spot [x, y, 0] - the point itself when clear, [] when none is,
 *  what blocks the point asked for - class or model names, [] when clear] <ARRAY>
 *
 * Example:
 * [_heli, _lz, 0, 80] call jmfsb_support_air_fnc_clearSpot
 *
 * Public: No
 */

params [
    ["_veh", objNull, [objNull]],
    ["_pos", [], [[]]],
    ["_height", 0, [0]],
    ["_search", 0, [0]],
    ["_ignore", [], [[]]]
];

if (isNull _veh || count _pos < 2) exitWith {[[], []]};

private _radius = ((boundingBoxReal _veh) select 2) + ROTOR_MARGIN;
private _floor = (_height - ROTOR_DISC_LOW) max ROTOR_DISC_LOW;
private _onGround = _height < ROTOR_DISC_LOW;
private _skip = _ignore + [_veh];

// What stands into the rotor's way at one spot.
private _fnc_blockers = {
    params ["_spot"];
    private _top = getTerrainHeightASL _spot + _floor;
    private _near = (nearestTerrainObjects [_spot, CLEAR_TERRAIN_TYPES, _radius, false, true]) + (nearestObjects [_spot, CLEAR_OBJECT_KINDS, _radius]);
    _near select {
        !(_x in _skip)
        && !(_x isKindOf "CAManBase")
        && !(_x isKindOf "Air" && !isTouchingGround _x)
        && ((_x modelToWorldWorld [0, 0, ((boundingBoxReal _x) select 1) select 2]) select 2) > _top
    }
};
private _fnc_fit = {
    params ["_spot"];
    if (([_spot] call _fnc_blockers) isNotEqualTo []) exitWith {false};
    if (!_onGround) exitWith {true};
    !(surfaceIsWater _spot) && ((surfaceNormal _spot) select 2) >= LANDING_FLAT_MIN
};

private _at = [_pos select 0, _pos select 1, 0];
if ([_at] call _fnc_fit) exitWith {[_at, []]};

private _names = ([_at] call _fnc_blockers) apply {
    private _type = typeOf _x;
    [_type, (getModelInfo _x) select 0] select (_type isEqualTo "")
};
if (_names isEqualTo []) then {_names = [["slope", "water"] select (surfaceIsWater _at)]};

private _spot = [];
for "_d" from CLEAR_STEP to _search step CLEAR_STEP do {
    for "_b" from 0 to (CLEAR_FULL_CIRCLE - CLEAR_BEARING_STEP) step CLEAR_BEARING_STEP do {
        private _try = _at getPos [_d, _b];
        _try set [2, 0];
        if ([_try] call _fnc_fit) exitWith {_spot = _try};
    };
    if (_spot isNotEqualTo []) exitWith {};
};

[_spot, _names arrayIntersect _names]
