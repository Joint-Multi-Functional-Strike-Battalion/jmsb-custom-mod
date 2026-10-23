#include "script_component.hpp"
/*
 * Author: JMSB
 * HACK - NODES IN REACH: node, type, range, security and RF quality, one row
 * each (FUNC(appHackNodes)). A suite device's row is a button that selects it
 * through the suite (jmfsb_hacking_fnc_tabletSelectDevice) - refused while a
 * hack runs, as the suite refuses it. Out of the suite's range reads in the
 * accent; an RF node the suite has no way into reads NO ACCESS.
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
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appHackList
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rows = _ctx get "rows";
private _session = _ctx get "session";
private _rowH = _ctx get "rowH";
private _selected = _session getOrDefault ["device", objNull];
private _running = _session getOrDefault ["running", false];

private _out = {(_x select 0) >= 0 && {(_x select 4) > (_x select 5)}} count _rows;
([_body, _rect, "NODES IN REACH", format ["%1 - %2 OUT", count _rows, _out]] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _tint = ["accentTint"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;

// NODE TYPE RANGE SECURITY RF, as shares of the panel.
private _cols = [0, 0.34, 0.52, 0.66, 0.8];
private _heads = ["NODE", "TYPE", "RANGE", "SECURITY", "RF"];
private _cx = _cols apply {_left + _pad + _x * (_w - 2 * _pad)};
private _cw = [];
{
    _cw pushBack ((_cx param [_forEachIndex + 1, _left + _w - _pad]) - _x - _pad * 0.5);
} forEach _cx;

{
    [_body, [_x, _top, _cw select _forEachIndex, _rowH], _heads select _forEachIndex, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach _cx;
private _y = _top + _rowH;
[_body, [_left, _y, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

if (_rows isEqualTo []) then {
    [_body, [_left + _pad, _y + _rowH * 0.2, _w - 2 * _pad, _rowH], "Nothing in reach.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};

private _fit = floor ((_h - _rowH) / _rowH) max 0;
{
    if (_forEachIndex >= _fit) then {break};
    _x params ["_slot", "_obj", "_node", "_type", "_dist", "_range", "_security", "_q"];
    private _ry = _y + _forEachIndex * _rowH;
    private _access = _slot >= 0;
    private _reach = _access && _dist <= _range;

    if (_access && _obj isEqualTo _selected) then {
        [_body, [_left, _ry, _w, _rowH], _tint] call EFUNC(tacpad,drawFill);
    };
    [_body, [_cx select 0, _ry, _cw select 0, _rowH], _node, ([_dim, _ink] select _access), TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_cx select 1, _ry, _cw select 1, _rowH], _type, _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
    [
        _body, [_cx select 2, _ry, _cw select 2, _rowH], format ["%1 M", round _dist],
        ([_ink, _accent] select (_access && !_reach)), TEXT_LABEL, _access && !_reach
    ] call EFUNC(tacpad,drawText);
    [
        _body, [_cx select 3, _ry, _cw select 3, _rowH],
        ["NO ACCESS", _security] select _access,
        ([_dim, _ink] select _access), TEXT_LABEL
    ] call EFUNC(tacpad,drawText);
    [_body, [_cx select 4, _ry, _cw select 4, _rowH], _q] call FUNC(appPageBar);
    [_body, [_left, _ry + _rowH - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    if (_access && {!_running}) then {
        private _hit = [_body, [_left, _ry, _w, _rowH], {
            params ["_ctrl"];
            [_ctrl getVariable [QGVAR(pageData), -1]] call EFUNC(hacking,tabletSelectDevice);
            {["hack"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(pageData), _slot];
    };
} forEach _rows;
