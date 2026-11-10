#include "script_component.hpp"
/*
 * Author: YonV
 * Whether two segments cross, in 2D - the player's last second of movement
 * against one leg of a line.
 *
 * Arguments:
 * 0: A start <ARRAY>
 * 1: A end <ARRAY>
 * 2: B start <ARRAY>
 * 3: B end <ARRAY>
 *
 * Return Value:
 * Cross <BOOL>
 *
 * Example:
 * [_was, _now, _p1, _p2] call jmfsb_c2_fnc_intersects
 *
 * Public: No
 */

params ["_a", "_b", "_c", "_d"];

private _fnc_side = {
    params ["_p", "_q", "_r"];
    ((_q # 0) - (_p # 0)) * ((_r # 1) - (_p # 1)) - ((_q # 1) - (_p # 1)) * ((_r # 0) - (_p # 0))
};
private _d1 = [_c, _d, _a] call _fnc_side;
private _d2 = [_c, _d, _b] call _fnc_side;
private _d3 = [_a, _b, _c] call _fnc_side;
private _d4 = [_a, _b, _d] call _fnc_side;
(_d1 * _d2 < 0) && (_d3 * _d4 < 0)
