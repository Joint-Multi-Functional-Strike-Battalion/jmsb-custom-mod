#include "script_component.hpp"
/*
 * Author: JMSB
 * The time-of-flight model of a virtual battery: a vacuum arc from the
 * battery to the target. Arma flies artillery shells without drag, so the
 * vacuum arc is the arc a real gun's round would fly.
 *
 *   range = v^2 sin(2a) / g        time of flight = 2 v sin(a) / g
 *
 * HIGH ANGLE is fired on the lowest charge (VA_CHARGES, shares of the muzzle
 * velocity) that reaches with the tube at or under VA_MAX_ELEV - the shortest
 * high-angle flight there is, as a real battery and Simplex's solver pick it.
 * A target so close that even the lowest charge would need a steeper tube is
 * inside the battery's minimum range.
 *
 * LOW ANGLE is the full charge's flat solution. Its high-angle fallback (for a
 * descent a ridge would block, FUNC(virtualRound)) is the high-angle answer
 * above, or the full charge's steep one when there is none.
 *
 * Arguments:
 * 0: Distance, battery to target (m) <NUMBER>
 * 1: Muzzle velocity at full charge (m/s) <NUMBER>
 * 2: High angle <BOOL>
 *
 * Return Value:
 * [angle used (deg), time of flight (s), high-angle fallback (deg)], [] when it cannot reach <ARRAY>
 *
 * Example:
 * [12000, 810, true] call jmfsb_support_fires_fnc_ballistics
 *
 * Public: No
 */

params [["_dist", 0, [0]], ["_mv", 0, [0]], ["_high", true, [true]]];

if (_mv <= 0) exitWith {[]};

// The high-angle solution on the lowest charge that serves.
private _steep = [];
{
    private _v = _x * _mv;
    private _k = GRAVITY * _dist / (_v * _v);
    private _a = if (_k <= 1) then {90 - 0.5 * asin _k} else {90};
    if (_a <= VA_MAX_ELEV) exitWith {
        _steep = [_a, 2 * _v * (sin _a) / GRAVITY, _a];
    };
} forEach VA_CHARGES;

if (_high) exitWith {_steep};

private _k = GRAVITY * _dist / (_mv * _mv);
if (_k > 1) exitWith {[]};

private _low = 0.5 * asin _k;
[_low, 2 * _mv * (sin _low) / GRAVITY, _steep param [0, 90 - _low]]
