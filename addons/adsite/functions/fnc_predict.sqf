#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Where a round will come down and when - computed ONCE, as it is fired.
 * Wind- and drag-free; the protected radius absorbs what that misses.
 *
 *   a guided missile with a target   straight to the target, at its top speed
 *   everything else                  a ballistic arc from its launch velocity -
 *                                    a rocket's or missile's at least its top
 *                                    speed, since it has a motor - landing on
 *                                    the terrain (refined ADS_PREDICT_PASSES
 *                                    times for the ground height there)
 *
 * Arguments:
 * 0: Launch position, ASL <ARRAY>
 * 1: Launch velocity <ARRAY>
 * 2: [family, speed] (FUNC(family)) <ARRAY>
 * 3: Target position ASL, or [] <ARRAY>
 *
 * Return Value:
 * [impact ASL, seconds to impact, model, velocity used], or [] if it never comes down <ARRAY>
 *
 * Example:
 * [getPosASL _p, velocity _p, [1, 200], []] call jmfsb_adsite_fnc_predict
 *
 * Public: No
 */

params [["_p0", [], [[]]], ["_v", [], [[]]], ["_info", [], [[]]], ["_target", [], [[]]]];

_info params ["_family", "_speedCfg"];
private _speed = vectorMagnitude _v;

if (_target isNotEqualTo []) exitWith {
    private _tti = (_p0 vectorDistance _target) / ((_speed max _speedCfg) max 1);
    [_target, _tti, MODEL_LINEAR, _v]
};

if (_speed < 1) exitWith {[]};
if (_family in [FAM_ROCKET, FAM_MISSILE]) then {
    _v = (vectorNormalized _v) vectorMultiply (_speed max _speedCfg);
};

_v params ["_vx", "_vy", "_vz"];
_p0 params ["_x0", "_y0", "_z0"];

private _ground = (getTerrainHeightASL [_x0, _y0]) max 0;
private _out = [];
for "_i" from 1 to ADS_PREDICT_PASSES do {
    private _disc = _vz * _vz + 2 * ADS_GRAVITY * (_z0 - _ground);
    if (_disc < 0) exitWith { _out = [] };
    private _t = (_vz + sqrt _disc) / ADS_GRAVITY;
    private _x1 = _x0 + _vx * _t;
    private _y1 = _y0 + _vy * _t;
    _out = [[_x1, _y1, _ground], _t, MODEL_BALLISTIC, _v];
    _ground = (getTerrainHeightASL [_x1, _y1]) max 0;
};
_out
