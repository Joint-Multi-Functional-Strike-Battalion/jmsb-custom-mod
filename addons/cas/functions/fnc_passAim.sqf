#include "script_component.hpp"
/*
 * Author: YonV
 * The pitch that puts a round on the aim from where the airframe is now
 * (FUNC(passFrame)) - the pass's solution. A seeker round takes the line of
 * sight. A shell or a bomb is flown the way the engine flies it: from a
 * guessed elevation at its muzzle speed plus the airframe's (a bomb at the
 * airframe's alone), air friction times speed squared and gravity each
 * PASS_SIM_DT s, until it falls through the aim's height; the elevation is
 * corrected by the secant of the range error, PASS_AIM_ITER times at most,
 * until the range is within PASS_AIM_TOL_M m. The first guess is the line of
 * sight, the second PASS_AIM_PROBE deg above it, and none goes more than
 * PASS_AIM_SPAN deg above it. No solution: the line of sight.
 *
 * Arguments:
 * 0: Where the airframe is, ASL <ARRAY>
 * 1: Its speed, m/s <NUMBER>
 * 2: The aim, ASL <ARRAY>
 * 3: The round's muzzle speed, m/s - 0 for a bomb <NUMBER>
 * 4: Its air friction <NUMBER>
 * 5: Its time to live, s <NUMBER>
 * 6: Its kind - "guided", "bomb", "shell" <STRING>
 *
 * Return Value:
 * Pitch, degrees - negative is down <NUMBER>
 *
 * Example:
 * [getPosASL _veh, 140, _aimASL, 0, -0.00005, 60, "bomb"] call jmfsb_cas_fnc_passAim
 *
 * Public: No
 */

params [
    ["_pos", [], [[]]],
    ["_speed", 0, [0]],
    ["_aim", [], [[]]],
    ["_initSpeed", 0, [0]],
    ["_friction", 0, [0]],
    ["_ttl", PASS_SIM_MAX_S, [0]],
    ["_kind", KIND_SHELL, [""]]
];

if (count _pos < 3 || count _aim < 3) exitWith {0};

private _d2 = [(_aim select 0) - (_pos select 0), (_aim select 1) - (_pos select 1), 0];
_d2 = vectorMagnitude _d2;
private _dz = (_aim select 2) - (_pos select 2);
private _los = _dz atan2 _d2;
if (_kind isEqualTo KIND_GUIDED) exitWith {_los};

private _v0 = _speed + _initSpeed;
if (_v0 <= 0) exitWith {_los};
_ttl = (_ttl max PASS_SIM_DT) min PASS_SIM_MAX_S;

// How far along the ground a round fired at this elevation gets before it
// falls through the aim's height; where it ends when it never does.
private _fnc_range = {
    params ["_elev"];
    private _vx = _v0 * cos _elev;
    private _vz = _v0 * sin _elev;
    private _px = 0;
    private _pz = 0;
    private _t = 0;
    private _lastPx = 0;
    private _lastPz = 0;
    private _crossed = false;
    while {_t < _ttl && !_crossed} do {
        _lastPx = _px;
        _lastPz = _pz;
        private _s = sqrt (_vx * _vx + _vz * _vz);
        _vx = _vx + _friction * _s * _vx * PASS_SIM_DT;
        _vz = _vz + (_friction * _s * _vz - GRAVITY) * PASS_SIM_DT;
        _px = _px + _vx * PASS_SIM_DT;
        _pz = _pz + _vz * PASS_SIM_DT;
        _t = _t + PASS_SIM_DT;
        _crossed = _pz <= _dz && _lastPz > _dz;
    };
    if (!_crossed) exitWith {_px};
    private _f = (_lastPz - _dz) / ((_lastPz - _pz) max PASS_FRAME_MIN);
    _lastPx + (_px - _lastPx) * _f
};

private _low = _los - PASS_AIM_PROBE;
private _high = _los + PASS_AIM_SPAN;
private _e0 = _los;
private _r0 = [_e0] call _fnc_range;
private _e1 = _los + PASS_AIM_PROBE;
private _r1 = [_e1] call _fnc_range;
private _best = _e0;
private _bestErr = abs (_r0 - _d2);
if (abs (_r1 - _d2) < _bestErr) then {
    _best = _e1;
    _bestErr = abs (_r1 - _d2);
};

for "_i" from 1 to PASS_AIM_ITER do {
    if (_bestErr < PASS_AIM_TOL_M) exitWith {};
    private _slope = (_r1 - _r0) / (_e1 - _e0);
    if (abs (_e1 - _e0) < PASS_FRAME_MIN || abs _slope < PASS_FRAME_MIN) exitWith {};
    private _e2 = ((_e1 + (_d2 - _r1) / _slope) max _low) min _high;
    private _r2 = [_e2] call _fnc_range;
    _e0 = _e1;
    _r0 = _r1;
    _e1 = _e2;
    _r1 = _r2;
    if (abs (_r2 - _d2) < _bestErr) then {
        _best = _e2;
        _bestErr = abs (_r2 - _d2);
    };
};

_best
