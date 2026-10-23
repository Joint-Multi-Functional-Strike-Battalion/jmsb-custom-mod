#include "script_component.hpp"
/*
 * Author: JMSB
 * Where one round of a fire mission is aimed, by the sheaf type (Simplex's
 * four) - before the battery's own dispersion is added (FUNC(virtualShot)).
 * The sheaf size is the half-width of the square the support page draws
 * round the target; "along" is the line of fire, battery to target.
 *
 *   converged - a random point inside the sheaf radius, per round
 *   parallel  - each gun on its own point, side by side across the line of
 *               fire over the sheaf's width
 *   box       - a random point anywhere in the square, per round
 *   creeping  - each gun in its own lane across the square; its rounds walk
 *               from the near edge to the far edge, one step per round
 *
 * Arguments:
 * 0: Target position <ARRAY>
 * 1: Bearing of the line of fire (deg) <NUMBER>
 * 2: Sheaf type, SHEAF_* <NUMBER>
 * 3: Sheaf size (m) <NUMBER>
 * 4: Gun index, from 0 <NUMBER>
 * 5: Guns firing <NUMBER>
 * 6: Round index within the gun's volley, from 0 <NUMBER>
 * 7: Rounds per gun <NUMBER>
 *
 * Return Value:
 * Aim point, ATL <ARRAY>
 *
 * Example:
 * [_target, 45, 3, 100, 0, 4, 2, 6] call jmfsb_support_fires_fnc_aimPoint
 *
 * Public: No
 */

params ["_target", "_dir", "_type", "_sheaf", "_gun", "_guns", "_round", "_rounds"];

if (_sheaf <= 0) exitWith {[_target select 0, _target select 1, 0]};

if (_type isEqualTo SHEAF_CONVERGED) exitWith {
    _target getPos [_sheaf * sqrt random 1, random 360]
};

private _lane = -_sheaf + (_gun + 0.5) * (2 * _sheaf / (1 max _guns));

private _offset = switch (_type) do {
    case SHEAF_PARALLEL: {[_lane, 0]};
    case SHEAF_BOX: {[_sheaf * (random 2 - 1), _sheaf * (random 2 - 1)]};
    case SHEAF_CREEPING: {[_lane, -_sheaf + (_round + 0.5) * (2 * _sheaf / (1 max _rounds))]};
    default {[0, 0]};
};
_offset params ["_across", "_along"];

[
    (_target select 0) + _along * (sin _dir) + _across * (sin (_dir + 90)),
    (_target select 1) + _along * (cos _dir) + _across * (cos (_dir + 90)),
    0
]
