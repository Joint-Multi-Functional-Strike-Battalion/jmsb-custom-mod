#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a support aircraft just made with "FLY" where it is to start, at its
 * flight level, engines on and flying (user, 2026-11-02: "all support aircraft
 * needs to be virtual till tasked, then they spawn in at alt over the support
 * module location"): level, on its heading, a plane at SPAWN_PLANE_SHARE of
 * its top speed so it does not stall, a helicopter at SPAWN_HELI_MS m/s, told
 * to hold the height (flyInHeight, above the ground).
 *
 * CLEAR OF OTHER AIRCRAFT. Two modules on one spot tasked together, or a
 * relief made where another is still flying, must not be made inside each
 * other: when another aircraft is within SPAWN_SEP m of the point, the nearest
 * clear point on rings SPAWN_SEP m apart (SPAWN_SEP_BEARING deg steps, out to
 * SPAWN_SEP_RINGS rings) is taken; none clear, it is stacked SPAWN_SEP m
 * higher for each ring searched. The RPT says when it moved.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Where, [x, y] or [x, y, z] - the height is the next argument <ARRAY>
 * 2: Height above the terrain, m <NUMBER>
 * 3: Heading <NUMBER>
 *
 * Return Value:
 * Where it was put, ATL <ARRAY>
 *
 * Example:
 * [_veh, getPosATL _logic, 4000, 90] call jmfsb_support_fnc_spawnAirborne
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_at", [], [[]]], ["_height", NOE_HEIGHT, [0]], ["_dir", 0, [0]]];

if (isNull _veh || {count _at < 2}) exitWith {[]};

// Another aircraft this close to a point - the one being placed aside.
private _fnc_clear = {
    params ["_p"];
    ((ASLToAGL (ATLToASL _p)) nearEntities [["Air"], SPAWN_SEP]) findIf {_x isNotEqualTo _veh} < 0
};

private _start = [_at select 0, _at select 1, _height];
if !([_start] call _fnc_clear) then {
    private _found = [];
    for "_ring" from 1 to SPAWN_SEP_RINGS do {
        for "_bearing" from 0 to (SPAWN_FULL_CIRCLE - SPAWN_SEP_BEARING) step SPAWN_SEP_BEARING do {
            private _p = _start getPos [_ring * SPAWN_SEP, _bearing];
            _p set [2, _height];
            if ([_p] call _fnc_clear) exitWith {_found = _p};
        };
        if (_found isNotEqualTo []) exitWith {};
    };
    if (_found isEqualTo []) then {
        _found = [_start select 0, _start select 1, _height + SPAWN_SEP * SPAWN_SEP_RINGS];
    };
    INFO_3("'%1' made %2 m from %3 - another aircraft was there",typeOf _veh,round (_start distance _found),mapGridPosition _start);
    _start = _found;
};

_veh setDir _dir;
_veh setPosATL _start;
_veh setVectorUp [0, 0, 1];
_veh engineOn true;
private _ms = if (_veh isKindOf "Plane") then {
    SPAWN_PLANE_SHARE * getNumber (configOf _veh >> "maxSpeed") / SPAWN_KMH_PER_MS
} else {
    SPAWN_HELI_MS
};
_veh setVelocityModelSpace [0, _ms, 0];
_veh flyInHeight (_start select 2);

_start
