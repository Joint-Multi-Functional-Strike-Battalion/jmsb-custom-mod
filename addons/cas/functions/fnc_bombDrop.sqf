#include "script_component.hpp"
/*
 * Author: YonV
 * Flies an unguided bomb to the aim (the pass's Fired handler,
 * FUNC(passBegin)) - the way Simplex Support Services flies its bombs down;
 * its method, no code of it. The free fall from the release is worked out
 * first the way the engine would fly it (air friction times speed squared,
 * gravity, BOMB_SIM_DT s steps) until it meets the ground or the sea; then
 * each frame the bomb is moved along that fall, with the gap between where
 * it ends and the aim closed evenly over the fall - a small, steady
 * correction on top of a real arc, never a jump. The engine detonates it
 * where it meets the ground.
 *
 * A fall that ends more than BOMB_MAX_STEER m from the aim is left to the
 * engine: the solution was no solution, and a bomb dragged that far would
 * not look like one.
 *
 * Arguments:
 * 0: The bomb <OBJECT>
 * 1: The aim, ASL <ARRAY>
 * 2: The bomb's air friction <NUMBER>
 *
 * Return Value:
 * Flown <BOOL>
 *
 * Example:
 * [_projectile, _aimASL, -0.00005] call jmfsb_cas_fnc_bombDrop
 *
 * Public: No
 */

params [["_bomb", objNull, [objNull]], ["_aim", [], [[]]], ["_friction", 0, [0]]];

if (isNull _bomb || count _aim < 3) exitWith {false};

// PositionASL - the placing point - is what setVelocityTransformation moves,
// not the model centre (2026-11-06, see FUNC(passFrame)).
private _pos = getPosASL _bomb;
private _vel = velocity _bomb;
private _gravity = [0, 0, -GRAVITY];
private _path = [_pos];
private _t = 0;
while {_t < BOMB_MAX_S && (_pos select 2) > ((getTerrainHeightASL _pos) max BOMB_SEA_Z)} do {
    private _s = vectorMagnitude _vel;
    _vel = _vel vectorAdd (((_vel vectorMultiply (_friction * _s)) vectorAdd _gravity) vectorMultiply BOMB_SIM_DT);
    _pos = _pos vectorAdd (_vel vectorMultiply BOMB_SIM_DT);
    _path pushBack _pos;
    _t = _t + BOMB_SIM_DT;
};
if (count _path < 3) exitWith {false};

private _gap = _aim vectorDiff _pos;
private _off = vectorMagnitude [_gap select 0, _gap select 1, 0];
if (_off > BOMB_MAX_STEER) exitWith {
    WARNING_3("bomb '%1' would fall %2 m from the aim at %3 - left to the engine",typeOf _bomb,round _off,mapGridPosition _aim);
    false
};
INFO_4("bomb '%1' steered %2 m onto the aim at %3 over %4 s",typeOf _bomb,round _off,mapGridPosition _aim,round _t);

[{
    params ["_args", "_handle"];
    _args params ["_bomb", "_path", "_total", "_gap", "_since"];
    if (isNull _bomb) exitWith {[_handle] call CBA_fnc_removePerFrameHandler};
    private _t = CBA_missionTime - _since;
    if (_t >= _total) exitWith {[_handle] call CBA_fnc_removePerFrameHandler};
    private _last = (count _path) - 1;
    private _i = (floor (_t / BOMB_SIM_DT)) min (_last - 1);
    private _f = ((_t / BOMB_SIM_DT) - _i) min 1;
    private _a = _path select _i;
    private _b = _path select (_i + 1);
    private _share = _t / _total;
    private _pos = (_a vectorAdd ((_b vectorDiff _a) vectorMultiply _f)) vectorAdd (_gap vectorMultiply _share);
    private _vel = ((_b vectorDiff _a) vectorMultiply (1 / BOMB_SIM_DT)) vectorAdd (_gap vectorMultiply (1 / _total));
    private _dir = vectorNormalized _vel;
    private _right = _dir vectorCrossProduct [0, 0, 1];
    private _up = [0, 1, 0];
    if (vectorMagnitude _right > PASS_FRAME_MIN) then {_up = (vectorNormalized _right) vectorCrossProduct _dir};
    _bomb setVelocityTransformation [_pos, _pos, _vel, _vel, _dir, _dir, _up, _up, 1];
    _bomb setVelocity _vel;
}, 0, [_bomb, _path, _t, _gap, CBA_missionTime]] call CBA_fnc_addPerFrameHandler;

true
