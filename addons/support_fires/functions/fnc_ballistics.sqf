#include "script_component.hpp"
/*
 * Author: YonV
 * The time-of-flight model of a virtual battery: a vacuum arc from the
 * battery to the target. Arma flies artillery shells without drag, so the
 * vacuum arc is the arc a real gun's round would fly.
 *
 * THE ARC IS SOLVED THROUGH THE TARGET'S HEIGHT (2026-11-05; the method
 * Simplex Support Services' artillery solver uses, written here afresh): for
 * a charge's speed v, the two tubes that put the round d metres out and h
 * metres up are the roots of the trajectory through that point,
 *
 *   tan(elev) = (v^2 +/- sqrt(v^4 - g (g d^2 + 2 h v^2))) / (g d)
 *
 * the + root the high arc, the - root the flat one; no real root, the charge
 * does not reach. The time of flight is d over the horizontal speed, and the
 * descent is the arc's slope at the target - steeper than the tube when the
 * target lies below the guns, flatter when above. On level ground it is the
 * tube's elevation, as before.
 *
 * HIGH ANGLE is fired on the lowest charge (VA_CHARGES, shares of the muzzle
 * velocity) whose high arc has the tube at or under VA_MAX_ELEV - the
 * shortest high-angle flight there is, as a real battery and Simplex's solver
 * pick it. A target so close that even the lowest charge would need a steeper
 * tube is inside the battery's minimum range.
 *
 * LOW ANGLE is the full charge's flat solution. Its high-angle fallback (for a
 * descent a ridge would block, FUNC(virtualRound)) is the high-angle answer
 * above, or the full charge's own high arc when there is none.
 *
 * Arguments:
 * 0: Distance, battery to target (m) <NUMBER>
 * 1: Muzzle velocity at full charge (m/s) <NUMBER>
 * 2: High angle <BOOL>
 * 3: The target's height over the battery (m), RISE(origin, target) <NUMBER> (optional, default 0)
 *
 * Return Value:
 * [descent angle at the target (deg), time of flight (s), high-angle descent fallback (deg)], [] when it cannot reach <ARRAY>
 *
 * Example:
 * [12000, 810, true, -120] call jmfsb_support_fires_fnc_ballistics
 *
 * Public: No
 */

params [["_dist", 0, [0]], ["_mv", 0, [0]], ["_high", true, [true]], ["_rise", 0, [0]]];

if (_mv <= 0) exitWith {[]};
_dist = _dist max BALL_MIN_DIST;

// One charge's arc onto the target: [tube elevation, descent at the target,
// time of flight], [] when that charge does not reach.
private _fnc_arc = {
    params ["_v", "_steep"];
    private _disc = _v ^ 4 - GRAVITY * (GRAVITY * _dist ^ 2 + 2 * _rise * _v ^ 2);
    if (_disc < 0) exitWith {[]};
    private _root = [-(sqrt _disc), sqrt _disc] select _steep;
    private _elev = atan ((_v ^ 2 + _root) / (GRAVITY * _dist));
    private _vh = _v * cos _elev;
    private _tof = _dist / _vh;
    // The vertical speed at the target, negative coming down.
    private _vz = _v * sin _elev - GRAVITY * _tof;
    [_elev, atan ((abs _vz) / _vh), _tof]
};

// The high-angle solution on the lowest charge that serves.
private _steep = [];
{
    private _arc = [_x * _mv, true] call _fnc_arc;
    if (_arc isNotEqualTo [] && {(_arc select 0) <= VA_MAX_ELEV}) exitWith {
        _steep = [_arc select 1, _arc select 2, _arc select 1];
    };
} forEach VA_CHARGES;

if (_high) exitWith {_steep};

private _flat = [_mv, false] call _fnc_arc;
if (_flat isEqualTo []) exitWith {[]};

private _fallback = _steep param [0, -1];
if (_fallback < 0) then {_fallback = ([_mv, true] call _fnc_arc) select 1};
[_flat select 1, _flat select 2, _fallback]
