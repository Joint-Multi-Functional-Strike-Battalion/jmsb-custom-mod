#include "script_component.hpp"
/*
 * Author: YonV
 * THE ELEVATION PROFILE of the route: the ground's height sampled at
 * PROFILE_BARS even steps from the first waypoint to the last - from the GPS
 * fix to the only waypoint when there is just one - with the total climb and
 * descent, the length, the lowest and highest point, and which bar each
 * waypoint falls on. The page draws it as a strip of bars (FUNC(app)).
 *
 * Terrain only (getTerrainHeightASL): a building on the line is not a hill.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [] with nothing to profile, else <ARRAY>
 * 0: Heights ASL, one per bar <ARRAY>
 * 1: Route length m <NUMBER>
 * 2: Total climb m <NUMBER>
 * 3: Total descent m <NUMBER>
 * 4: Lowest height <NUMBER>
 * 5: Highest height <NUMBER>
 * 6: Bar index of each waypoint, in order <ARRAY>
 *
 * Example:
 * ([] call jmfsb_pointman_fnc_profile) params ["_heights", "_length", "_climb", "_descent"]
 *
 * Public: No
 */

private _points = GVAR(waypoints) apply {[_x] call FUNC(wpPos)};
if (count _points < 2) then {
    private _here = [] call FUNC(gpsPos);
    if (_here isNotEqualTo []) then {_points = [[_here select 0, _here select 1, 0]] + _points};
};
if (count _points < 2) exitWith {[]};

private _legs = [];
private _length = 0;
for "_i" from 1 to (count _points - 1) do {
    private _d = (_points select (_i - 1)) distance2D (_points select _i);
    _legs pushBack _d;
    _length = _length + _d;
};
if (_length <= 0) exitWith {[]};

private _step = _length / (PROFILE_BARS - 1);
private _heights = [];
private _marks = [0];
private _leg = 0;
private _into = 0;
for "_b" from 0 to (PROFILE_BARS - 1) do {
    private _s = _b * _step;
    while {_leg < (count _legs - 1) && {_s > _into + (_legs select _leg)}} do {
        _into = _into + (_legs select _leg);
        _leg = _leg + 1;
        _marks pushBack _b;
    };
    private _from = _points select _leg;
    private _to = _points select (_leg + 1);
    private _len = _legs select _leg;
    private _k = if (_len > 0) then {((_s - _into) / _len) min 1 max 0} else {0};
    _heights pushBack (getTerrainHeightASL (_from vectorAdd ((_to vectorDiff _from) vectorMultiply _k)));
};
_marks pushBack (PROFILE_BARS - 1);

private _climb = 0;
private _descent = 0;
{
    if (_forEachIndex > 0) then {
        private _d = _x - (_heights select (_forEachIndex - 1));
        if (_d > 0) then {_climb = _climb + _d} else {_descent = _descent - _d};
    };
} forEach _heights;

[_heights, _length, _climb, _descent, selectMin _heights, selectMax _heights, _marks]
