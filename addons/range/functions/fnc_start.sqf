#include "..\script_component.hpp"
/*
 * Author: YonV
 * Starts a run for the player who chose Start - on their machine, where
 * their hits are seen. Claims the range (public, so every controller shows
 * it in use), drops the targets and counts down.
 *
 * Arguments:
 * 0: Range (the module logic) <OBJECT>
 * 1: Shooter <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_range", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _range || {!local _unit}) exitWith {};
if ((_range getVariable [QGVAR(run), []]) isNotEqualTo []) exitWith {};
if (count GVAR(session) > 0) exitWith {
    [NOTE_TITLE, "You are already on a range.", NOTE_BAD] call EFUNC(notify,notify);
};

private _cfg = _range getVariable [QGVAR(cfg), createHashMap];
private _targets = (_cfg get "targets") select {!isNull _x};
private _mode = [_range, "mode"] call FUNC(setting);

_range setVariable [QGVAR(run), [_unit, _mode], true];

GVAR(session) = createHashMapFromArray [
    ["range", _range],
    ["mode", _mode],
    ["duration", [_range, "duration"] call FUNC(setting)],
    ["count", [_range, "count"] call FUNC(setting)],
    ["exposure", [_range, "exposure"] call FUNC(setting)],
    ["targets", _targets],
    ["phase", "countdown"],
    ["t0", CBA_missionTime],
    ["countdown", _cfg get "countdown"],
    ["beep", -1],
    ["hits", 0],
    ["shown", 0],
    ["current", objNull],
    ["nextAt", 0],
    ["startAt", 0],
    ["endAt", 0]
];

{
    _x setVariable [QGVAR(hit), true];
    [_x, TARGET_DOWN] call FUNC(setTarget);
} forEach _targets;

private _detail = [_mode, GVAR(session) get "duration", GVAR(session) get "count",
    GVAR(session) get "exposure", count _targets] call FUNC(detail);
[_unit, format ["%1: %2, %3 - %4. Starting in %5 s.", _cfg get "name", MODE_NAMES select _mode, _detail,
    name _unit, _cfg get "countdown"], NOTE_INFO] call FUNC(tell);

[FUNC(session), TICK, []] call CBA_fnc_addPerFrameHandler;
