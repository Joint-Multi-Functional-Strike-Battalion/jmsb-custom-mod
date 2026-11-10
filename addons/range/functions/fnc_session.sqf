#include "..\script_component.hpp"
/*
 * Author: YonV
 * One beat of the run on the shooter's machine (per-frame handler, TICK).
 *
 *   countdown   a beep a second, then the start sound and the first target
 *   timed       one target up at a time, the next as soon as it is hit or
 *               its exposure is up, until the duration runs out
 *   set number  the same, until the set number of targets have been shown
 *   rampage     every target up at once, until all are down or the
 *               duration (the limit) runs out
 *
 * Stopped from a controller, or the shooter dead: no score.
 *
 * Arguments:
 * 0: Unused
 * 1: Handler id <NUMBER>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["", "_handle"];

private _s = GVAR(session);
if (count _s isEqualTo 0) exitWith {[_handle] call CBA_fnc_removePerFrameHandler};

private _range = _s get "range";
private _now = CBA_missionTime;
private _run = _range getVariable [QGVAR(run), []];

if (_run isEqualTo [] || {(_run select 0) isNotEqualTo player} || {!alive player}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [false] call FUNC(finish);
};

private _cfg = _range getVariable [QGVAR(cfg), createHashMap];
private _source = (_cfg getOrDefault ["controllers", [player]]) param [0, player];
private _targets = _s get "targets";
private _mode = _s get "mode";

if ((_s get "phase") isEqualTo "countdown") exitWith {
    private _left = (_s get "t0") + (_s get "countdown") - _now;
    if (_left > 0) exitWith {
        private _sec = ceil _left;
        if (_sec isNotEqualTo (_s get "beep")) then {
            _s set ["beep", _sec];
            [QGVAR(say), [_source, SOUND_COUNT]] call CBA_fnc_globalEvent;
        };
    };
    _s set ["phase", "run"];
    _s set ["startAt", _now];
    _s set ["endAt", _now + (_s get "duration")];
    _s set ["nextAt", _now];
    [QGVAR(say), [_source, SOUND_START]] call CBA_fnc_globalEvent;
    if (_mode isEqualTo MODE_RAMPAGE) then {
        {
            _x setVariable [QGVAR(hit), false];
            [_x, TARGET_UP] call FUNC(setTarget);
        } forEach _targets;
        _s set ["shown", count _targets];
    };
};

if (_mode isEqualTo MODE_RAMPAGE) exitWith {
    if ((_targets findIf {!(_x getVariable [QGVAR(hit), true])}) < 0 || {_now >= (_s get "endAt")}) then {
        [_handle] call CBA_fnc_removePerFrameHandler;
        [true] call FUNC(finish);
    };
};

if (_mode isEqualTo MODE_TIMED && {_now >= (_s get "endAt")}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [true] call FUNC(finish);
};

private _cur = _s get "current";
if (_now < (_s get "nextAt") && {isNull _cur || {!(_cur getVariable [QGVAR(hit), true])}}) exitWith {};

if (!isNull _cur) then {
    _cur setVariable [QGVAR(hit), true];
    [_cur, TARGET_DOWN] call FUNC(setTarget);
};

if (_mode isEqualTo MODE_COUNT && {(_s get "shown") >= (_s get "count")}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [true] call FUNC(finish);
};

private _pool = _targets - [_cur];
if (_pool isEqualTo []) then {_pool = _targets};
private _next = selectRandom _pool;
_next setVariable [QGVAR(hit), false];
[_next, TARGET_UP] call FUNC(setTarget);
_s set ["current", _next];
_s set ["shown", (_s get "shown") + 1];
_s set ["nextAt", _now + (_s get "exposure")];
