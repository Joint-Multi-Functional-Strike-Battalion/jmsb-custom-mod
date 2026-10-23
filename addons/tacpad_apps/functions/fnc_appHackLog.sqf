#include "script_component.hpp"
/*
 * Author: JMSB
 * HACK - LOG: what the current hack has done, oldest first (FUNC(appHackTrack)
 * writes it). A setback - out of range, aborted - reads in the accent.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appHack)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appHackLog
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rowH = _ctx get "rowH";

([_body, _rect, "LOG", "THIS HACK"] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
private _timeW = (_w - 2 * _pad) * 0.22;

[_body, [_left + _pad, _top, _timeW, _rowH], "TIME", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_left + _pad + _timeW, _top, _w - 2 * _pad - _timeW, _rowH], "LOG", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
private _y = _top + _rowH;
[_body, [_left, _y, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _lines = +GVAR(hackLog);
private _fit = floor ((_h - _rowH) / _rowH) max 0;
if (count _lines > _fit) then {_lines = _lines select [count _lines - _fit, _fit]};

if (_lines isEqualTo []) then {
    [_body, [_left + _pad, _y + _rowH * 0.2, _w - 2 * _pad, _rowH], "No hack run yet.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};

{
    _x params ["_time", "_text", "_alert"];
    private _ry = _y + _forEachIndex * _rowH;
    [_body, [_left + _pad, _ry, _timeW, _rowH], [_time, "HH:MM:SS"] call BIS_fnc_timeToString, _ink, TEXT_LABEL] call EFUNC(tacpad,drawText);
    [_body, [_left + _pad + _timeW, _ry, _w - 2 * _pad - _timeW, _rowH], _text, ([_ink, _accent] select _alert), TEXT_LABEL, _alert] call EFUNC(tacpad,drawText);
    [_body, [_left, _ry + _rowH - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _lines;
