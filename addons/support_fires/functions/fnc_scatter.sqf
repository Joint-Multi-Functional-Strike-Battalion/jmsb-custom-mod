#include "script_component.hpp"
/*
 * Author: YonV
 * A random point inside an ellipse laid along the line of fire - a round's own
 * dispersion round its aim point (FUNC(virtualShot)) and a salvo's aiming
 * error (FUNC(fireVirtual)). ELLIPTICAL DISPERSION (user, 2026-11-02, from the
 * Tun Firesupport review): a gun's range error is bigger than its deflection
 * error, so the scatter is long along the gun-target line and narrow across
 * it, not a circle. Uniform over the ellipse.
 *
 * Arguments:
 * 0: Centre <ARRAY>
 * 1: Bearing of the line of fire (deg) <NUMBER>
 * 2: Half-length along the line - the range error (m) <NUMBER>
 * 3: Half-width across it - the deflection error (m) <NUMBER>
 *
 * Return Value:
 * The point, [x, y, 0] <ARRAY>
 *
 * Example:
 * [_aim, 45, 40, 16] call jmfsb_support_fires_fnc_scatter
 *
 * Public: No
 */

params [["_centre", [], [[]]], ["_dir", 0, [0]], ["_along", 0, [0]], ["_across", 0, [0]]];

_centre params [["_cx", 0, [0]], ["_cy", 0, [0]]];
if (_along <= 0 && _across <= 0) exitWith {[_cx, _cy, 0]};

private _r = sqrt random 1;
private _t = random DEG_FULL;
private _a = _along * _r * (cos _t);
private _c = _across * _r * (sin _t);

[
    _cx + _a * (sin _dir) + _c * (sin (_dir + RIGHT_ANGLE)),
    _cy + _a * (cos _dir) + _c * (cos (_dir + RIGHT_ANGLE)),
    0
]
