#include "script_component.hpp"
/*
 * Author: YonV
 * The point of a measure's line nearest a position, in 2D - a point measure
 * is its own point; an area's outline is closed.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Points <ARRAY>
 * 2: Closed (an area) <BOOL>
 *
 * Return Value:
 * [nearest [x, y, 0], distance] <ARRAY>
 *
 * Example:
 * [getPos player, _points, false] call jmfsb_c2_fnc_nearest
 *
 * Public: No
 */

params [["_pos", [0, 0, 0], [[]]], ["_points", [], [[]]], ["_closed", false, [false]]];

if (count _points < 2) exitWith {[_points param [0, _pos], _pos distance2D (_points param [0, _pos])]};
private _path = +_points;
if (_closed) then {_path pushBack (_points # 0)};
private _best = [_points # 0, 1e10];
for "_i" from 0 to (count _path - 2) do {
    private _a = _path # _i;
    private _b = _path # (_i + 1);
    private _ab = (_b vectorDiff _a) select [0, 2];
    private _len = _ab vectorDotProduct _ab;
    private _t = if (_len > 0) then {((((_pos vectorDiff _a) select [0, 2]) vectorDotProduct _ab) / _len) max 0 min 1} else {0};
    private _p = [(_a # 0) + (_ab # 0) * _t, (_a # 1) + (_ab # 1) * _t, 0];
    private _d = _pos distance2D _p;
    if (_d < (_best # 1)) then {_best = [_p, _d]};
};
_best
