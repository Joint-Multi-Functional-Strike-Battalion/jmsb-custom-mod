#include "script_component.hpp"
/*
 * Author: JMSB
 * One virtual round arrives: the shell class itself, spawned high over its
 * impact point on the descending branch of its arc, moving - so it is heard
 * coming in and lands like a fired round, with the class's own effects.
 *
 * THE DESCENT. The round appears VA_DESCENT_TIME seconds before impact, at
 * the vacuum arc's descent angle and a real shell's terminal speed, coming
 * from the battery's side. A low-angle descent a ridge would block comes in
 * at the high angle instead - a real battery would have fired high there.
 *
 * Illumination is a flare released over the target. A submunition round
 * (smoke, cluster, guided) is opened at its own triggerDistance above the
 * ground by script, because a spawned round has no aim point for the
 * engine's fuze to measure against.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Ammo class <STRING>
 * 2: Impact point, ATL <ARRAY>
 * 3: Descent angle (deg) <NUMBER>
 * 4: High-angle fallback (deg) <NUMBER>
 * 5: Bearing, battery to target (deg) <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, "Sh_155mm_AMOS", _impact, 70, 70, 45] call jmfsb_support_fires_fnc_virtualRound
 *
 * Public: No
 */

params ["_logic", "_cls", "_impact", "_angle", "_steep", "_dir"];

private _ammo = configFile >> "CfgAmmo";

if (_cls isKindOf ["FlareCore", _ammo]) exitWith {
    private _at = [_impact select 0, _impact select 1, VA_ILLUM_HEIGHT];
    private _flare = createVehicle [_cls, _at, [], 0, "CAN_COLLIDE"];
    _flare setPosATL _at;
    _flare setVelocity [0, 0, VA_ILLUM_FALL];
};

private _ground = AGLToASL [_impact select 0, _impact select 1, 0];
private _speed = VA_IMPACT_SPEED min (_logic getVariable [QGVAR(muzzleVelocity), VA_IMPACT_SPEED]);
private _heading = [sin _dir, cos _dir, 0];

// Where the round is VA_DESCENT_TIME before impact on a descent at this
// angle, and how it is moving there.
private _solve = {
    params ["_a"];
    private _t = VA_DESCENT_TIME;
    private _vh = _speed * cos _a;
    private _vz = _speed * sin _a;
    private _rise = _vz * _t - 0.5 * GRAVITY * _t * _t;
    if (_rise < VA_MIN_SPAWN_AGL) then {
        _vz = (VA_MIN_SPAWN_AGL + 0.5 * GRAVITY * _t * _t) / _t;
        _rise = VA_MIN_SPAWN_AGL;
    };
    [
        (_ground vectorAdd (_heading vectorMultiply (-_vh * _t))) vectorAdd [0, 0, _rise],
        (_heading vectorMultiply _vh) vectorAdd [0, 0, GRAVITY * _t - _vz]
    ]
};

private _path = [_angle] call _solve;
if (_steep isNotEqualTo _angle && {terrainIntersectASL [_path select 0, _ground vectorAdd [0, 0, 2]]}) then {
    _path = [_steep] call _solve;
};
_path params ["_from", "_vel"];

private _round = createVehicle [_cls, ASLToAGL _from, [], 0, "CAN_COLLIDE"];
_round setPosASL _from;
_round setVectorDir _vel;
_round setVelocity _vel;

if (_cls isKindOf ["SubmunitionCore", _ammo]) then {
    private _fuze = getNumber (_ammo >> _cls >> "triggerDistance");
    if (_fuze > 0) then {
        [{
            params ["_round", "_fuze"];
            isNull _round || {((getPosATL _round) select 2) <= _fuze}
        }, {
            params ["_round"];
            if (!isNull _round) then {triggerAmmo _round};
        }, [_round, _fuze]] call CBA_fnc_waitUntilAndExecute;
    };
};
