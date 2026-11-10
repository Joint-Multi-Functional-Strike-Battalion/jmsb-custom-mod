#include "script_component.hpp"
/*
 * Author: YonV
 * Where one round of a fire mission is aimed, by the sheaf type (Simplex's
 * four, and a call for fire's linear target) - before the battery's own
 * dispersion is added (FUNC(virtualShot)). The sheaf size is the half-width
 * of the square the support page draws round the target; "along" is the line
 * of fire, battery to target.
 *
 *   converged - a random point inside the sheaf radius, per round
 *   parallel  - each gun on its own point, side by side across the line of
 *               fire over the sheaf's width
 *   box       - a random point anywhere in the square, per round
 *   creeping  - each gun in its own lane across the square; its rounds walk
 *               from the near edge to the far edge, one step per round
 *
 * A CALL FOR FIRE'S TARGET SHAPE (user, 2026-11-02; FUNC(threadShape)) gives
 * an attitude and a length:
 *
 *   linear    - the guns spread along a line of that length at that attitude
 *               (none: across the line of fire), centred on the target; each
 *               gun covers its own stretch, its rounds spread over it
 *   creeping  - a WALK: the guns side by side across it, the sheaf their
 *               half-width; the rounds step from the target that far along
 *               the attitude (none: away from the guns), one step per round
 *               of the whole mission - the round index counts every volley
 *
 * Arguments:
 * 0: Target position <ARRAY>
 * 1: Bearing of the line of fire (deg) <NUMBER>
 * 2: Sheaf type, SHEAF_* <NUMBER>
 * 3: Sheaf size (m) <NUMBER>
 * 4: Gun index, from 0 <NUMBER>
 * 5: Guns firing <NUMBER>
 * 6: Round index, from 0 - a creeping walk's counts the whole mission <NUMBER>
 * 7: Rounds per gun - a creeping walk's, of the whole mission <NUMBER>
 * 8: Attitude (deg), -1 none <NUMBER> (optional, default -1)
 * 9: Length of a linear target or a creeping walk (m), 0 none <NUMBER> (optional, default 0)
 *
 * Return Value:
 * Aim point, ATL <ARRAY>
 *
 * Example:
 * [_target, 45, 3, 100, 0, 4, 2, 6] call jmfsb_support_fires_fnc_aimPoint
 *
 * Public: No
 */

params ["_target", "_dir", "_type", "_sheaf", "_gun", "_guns", "_round", "_rounds", ["_attitude", -1, [0]], ["_length", 0, [0]]];

if (_sheaf <= 0 && _length <= 0) exitWith {[_target select 0, _target select 1, 0]};

if (_type isEqualTo SHEAF_CONVERGED) exitWith {
    _target getPos [_sheaf * sqrt random 1, random DEG_FULL]
};

// The axis the offsets are measured on: the line of fire, or the card's
// attitude - a linear target's runs square to the line of fire without one.
private _axis = _dir;
if (_attitude >= 0) then {_axis = _attitude};
if (_type isEqualTo SHEAF_LINEAR && _attitude < 0) then {_axis = _dir + RIGHT_ANGLE};

private _lane = -_sheaf + (_gun + 0.5) * (2 * _sheaf / (1 max _guns));
private _walk = _type isEqualTo SHEAF_CREEPING && _length > 0;

private _offset = switch (true) do {
    case (_type isEqualTo SHEAF_LINEAR): {
        [0, -_length / 2 + (_gun + (_round + 0.5) / (1 max _rounds)) * (_length / (1 max _guns))]
    };
    case (_walk): {[_lane, _length * _round / (1 max (_rounds - 1))]};
    case (_type isEqualTo SHEAF_PARALLEL): {[_lane, 0]};
    case (_type isEqualTo SHEAF_BOX): {[_sheaf * (random 2 - 1), _sheaf * (random 2 - 1)]};
    case (_type isEqualTo SHEAF_CREEPING): {[_lane, -_sheaf + (_round + 0.5) * (2 * _sheaf / (1 max _rounds))]};
    default {[0, 0]};
};
_offset params ["_across", "_along"];

[
    (_target select 0) + _along * (sin _axis) + _across * (sin (_axis + RIGHT_ANGLE)),
    (_target select 1) + _along * (cos _axis) + _across * (cos (_axis + RIGHT_ANGLE)),
    0
]
