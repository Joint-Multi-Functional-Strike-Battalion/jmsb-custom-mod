#include "script_component.hpp"
/*
 * Author: YonV
 * Installs a TRACK_TICK proximity check for a programmable-airburst shell.
 * Detonates when a UAV or soft ground target enters the proximity radius.
 * Self-removes on round expiry, detonation, or once the round has flown past
 * its effective range (mirrors fnc_trackAD.sqf from the anti-drone module).
 *
 * Applies the faction performance gradient (GVAR(greenFraction)/GVAR(redFraction),
 * gated by GVAR(factionScaling)) and the counter-UAS effectiveness ceiling
 * (GVAR(cuasCeiling)) to the trigger/lethal radius and max damage, based on the
 * firing vehicle's side. Effective range is a physical property of the shell's
 * flight and is not scaled by either setting.
 *
 * Arguments:
 * 0: Projectile <OBJECT>
 * 1: Ammo class name <STRING>
 * 2: Firing unit/vehicle <OBJECT>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [
    ["_proj", objNull, [objNull]],
    ["_ammo", "",      [""]],
    ["_firer", objNull, [objNull]]
];

(GVAR(params) getOrDefault [_ammo, [10, 7, 0.6, 2000]]) params ["_prox", "_lethal", "_dmg", "_range"];

private _fraction = 1;
if (GVAR(factionScaling)) then {
    _fraction = switch (side _firer) do {
        case west: { 1 };
        case independent: { GVAR(greenFraction) };
        case east: { GVAR(redFraction) };
        default { 1 };
    };
};

_prox = _prox * _fraction * GVAR(cuasCeiling);
_lethal = _lethal * _fraction * GVAR(cuasCeiling);
_dmg = (_dmg * _fraction * GVAR(cuasCeiling)) min 1;

private _origin = getPosASL _proj;

[{
    params ["_args", "_h"];
    _args params ["_proj", "_prox", "_lethal", "_dmg", "_origin", "_range", "_lastPos"];

    if (isNull _proj) exitWith {
        _h call CBA_fnc_removePerFrameHandler;
    };

    private _curPos = getPosASL _proj;

    if ((_origin distance _curPos) > _range) exitWith {
        _h call CBA_fnc_removePerFrameHandler;
    };

    // Swept proximity test. These rounds fly at 1050-1176 m/s, so at 60 fps they
    // cover ~18 m between frames while the trigger radius is only 10-12 m - a
    // point-sphere check at the frame position steps clean over targets. Test the
    // whole segment flown since the last frame, and burst at the closest point of
    // approach rather than wherever the round sits when the check finally fires
    // (which can be a frame's travel past the target, outside _lethal entirely).
    private _seg = _curPos vectorDiff _lastPos;
    private _segLen2 = _seg vectorDotProduct _seg;
    private _mid = _lastPos vectorAdd (_seg vectorMultiply 0.5);
    private _search = (sqrt _segLen2) / 2 + _prox;

    private _best = -1;
    private _burstPos = _curPos;

    {
        private _p = getPosASL _x;
        private _t = if (_segLen2 > 0) then {
            0 max ((((_p vectorDiff _lastPos) vectorDotProduct _seg) / _segLen2) min 1)
        } else {
            0
        };
        private _closest = _lastPos vectorAdd (_seg vectorMultiply _t);
        private _d = _closest distance _p;
        if (_d <= _prox && {_best < 0 || _d < _best}) then {
            _best = _d;
            _burstPos = _closest;
        };
    } forEach (((ASLToAGL _mid) nearEntities [["Air", "UAV", "CAManBase"], _search]) select {
        unitIsUAV _x || {_x isKindOf "CAManBase"}
    });

    if (_best >= 0) exitWith {
        [_proj, _lethal, _dmg, _burstPos] call FUNC(detonateShell);
        _h call CBA_fnc_removePerFrameHandler;
    };

    _args set [6, _curPos];
}, TRACK_TICK, [_proj, _prox, _lethal, _dmg, _origin, _range, _origin]] call CBA_fnc_addPerFrameHandler;
