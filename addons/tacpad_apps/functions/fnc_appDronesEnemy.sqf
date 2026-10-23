#include "script_component.hpp"
/*
 * Author: JMSB
 * DRONES - ENEMY: what is unmanned and hostile in the air, and where. Every
 * value is EFUNC(hacking,scannerRead)'s cache - the same sweep the tile and the
 * handset read, so no two surfaces can disagree about the air. Without the
 * intrusion suite or a receiver it says which.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appDrones)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appDronesEnemy
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rowH = _ctx get "rowH";

private _loaded = !isNil QEFUNC(hacking,scannerRead);
private _receiver = _loaded && {[player] call EFUNC(hacking,hasScanner)};
private _read = if (_receiver) then {[] call EFUNC(hacking,scannerRead)} else {[]};
_read params [["_state", 0], ["_dist", 0], ["_dir", 0], "", "", "", "", ["_tag", ""]];

([_body, _rect, "ENEMY", ["NO RECEIVER", "RECEIVER SWEEP"] select _receiver] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _amber = ["swatchYellow"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _level = 0 max (_state min 2);
private _colour = [_ink, _amber, _accent] select _level;
private _headline = switch (true) do {
    case (!_loaded): {"INTRUSION SUITE NOT LOADED"};
    case (!_receiver): {"NO RECEIVER"};
    default {["NO AIR CONTACT", "CONTACT - INSIDE 2 KM", "CONTACT - INSIDE 1 KM"] select _level};
};
[_body, [_left + _pad, _top + _padY, _w - 2 * _pad, _rowH * 1.6], _headline, _colour, TEXT_TITLE, true] call EFUNC(tacpad,drawText);

private _y = _top + _padY * 2 + _rowH * 1.6;
[_body, [_left + _pad, _y, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

if (_state <= 0) exitWith {
    [_body, [_left + _pad, _y, _w - 2 * _pad, _rowH], "Nothing unmanned and hostile heard.", _muted, TEXT_BODY] call EFUNC(tacpad,drawText);
};

private _rows = [
    ["BEARING", format ["%1 DEG", [round _dir, DRONES_BRG_DIGITS] call CBA_fnc_formatNumber]],
    ["RANGE", format ["%1 M", round _dist]],
    ["GRID", mapGridPosition ((getPosATL player) getPos [_dist, _dir])]
];
if (_tag isNotEqualTo "") then {_rows pushBack ["AIRFRAME", toUpper _tag]};

{
    _x params ["_label", "_value"];
    private _ry = _y + _forEachIndex * _rowH;
    [_body, [_left + _pad, _ry, _w * 0.3, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_left + _w * 0.3, _ry, _w * 0.7 - _pad, _rowH], _value, _colour, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
    [_body, [_left + _pad, _ry + _rowH - RULE_THIN * pixelH, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _rows;
