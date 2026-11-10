#include "script_component.hpp"
/*
 * Author: YonV
 * A choice the composer fills at runtime, drawn as a drop-down (user,
 * 2026-11-02: "we have pre made crates so the requested items should be a
 * drop down of them"): one cell reading the pick (or PICK ONE), REQ in it when
 * the field is required, framed in the accent while SEND found it empty; a
 * press opens the list under it - the picks, the one picked in ink, and NONE
 * first on an optional field - and pushes the rest of the column down, as the
 * marker list does. One list is open at a time (GVAR(composeMarker) holds the
 * open field's key, the marker list's own).
 *
 * Arguments:
 * 0: The card's body <CONTROL>
 * 1: The field <HASHMAP>
 * 2: [x, y, width] of the cell <ARRAY>
 * 3: The picks, strings (FUNC(composeChoices)) <ARRAY>
 *
 * Return Value:
 * Where the column goes on, y <NUMBER>
 *
 * Example:
 * _cy = [_body, _field, [_cx, _cy, _colW], _picks] call jmfsb_tacpad_fnc_composeDrop
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_field", createHashMap, [createHashMap]], ["_at", [0, 0, 0], [[]], 3], ["_picks", [], [[]]]];

_at params ["_x0", "_y0", "_w"];

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];
private _mute = ["muted"] call FUNC(theme);
private _accentText = ["accentText"] call FUNC(theme);
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H * DROP_ROW_K;
private _btnH = ([TEXT_BODY] call FUNC(textH)) + 2 * _padY;

private _key = _field getOrDefault ["key", ""];
private _required = (_field getOrDefault ["required", false]) isEqualTo true;
private _value = GVAR(composeValues) getOrDefault [_key, ""];
if !(_value isEqualType "") then {_value = str _value};
private _open = GVAR(composeMarker) isEqualTo _key;
private _missing = _key in GVAR(composeMissing) && _value isEqualTo "";

// THE CELL: the pick, or PICK ONE; REQ on its right.
[_body, [_x0, _y0, _w - _pad, _btnH], [_line, _accent] select _missing, [RULE_THIN, RULE_THICK] select _missing] call FUNC(drawFrame);
[
    _body, [_x0 + _pad, _y0, _w * DROP_TEXT_W, _btnH],
    [_value, DROP_EMPTY] select (_value isEqualTo ""),
    [_ink, _mute] select (_value isEqualTo ""), TEXT_BODY, _value isNotEqualTo ""
] call FUNC(drawText);
if (_required) then {
    [_body, [_x0, _y0, _w - 2 * _pad, _btnH], "REQ", [_accentText, _accent] select _missing, CARD_META_SIZE, true, "right"] call FUNC(drawText);
};
private _hit = [_body, [_x0, _y0, _w - _pad, _btnH], {
    params ["_ctrl"];
    [] call FUNC(composeHarvest);
    private _k = _ctrl getVariable [QGVAR(fieldKey), ""];
    GVAR(composeMarker) = [_k, ""] select (GVAR(composeMarker) isEqualTo _k);
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);
_hit setVariable [QGVAR(fieldKey), _key];

private _listY = _y0 + _btnH + _padY;
if (!_open) exitWith {_listY};

// THE LIST: NONE first on an optional field, then the picks.
private _rows = (_picks select [0, DROP_MAX]) apply {[_x, _x]};
if (!_required) then {_rows = [["", DROP_NONE]] + _rows};

{
    _x params ["_pick", "_label"];
    private _ry = _listY + _forEachIndex * _rowH;
    private _on = _pick isEqualTo _value;
    if (_on) then {
        [_body, [_x0, _ry, _w - _pad, _rowH], _ink] call FUNC(drawFill);
    };
    [_body, [_x0 + _pad, _ry, _w - 2 * _pad, _rowH], _label, [_ink, _ground] select _on, TEXT_BODY] call FUNC(drawText);
    [_body, [_x0, _ry + _rowH - RULE_THIN * pixelH, _w - _pad, RULE_THIN * pixelH], _line] call FUNC(drawFill);

    private _hitP = [_body, [_x0, _ry, _w - _pad, _rowH], {
        params ["_ctrl"];
        [] call FUNC(composeHarvest);
        private _k = _ctrl getVariable [QGVAR(fieldKey), ""];
        if (_k isEqualTo "") exitWith {};
        private _p = _ctrl getVariable [QGVAR(choice), ""];
        if (_p isEqualTo "") then {
            GVAR(composeValues) deleteAt _k;
        } else {
            GVAR(composeValues) set [_k, _p];
        };
        GVAR(composeMarker) = "";
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hitP setVariable [QGVAR(fieldKey), _key];
    _hitP setVariable [QGVAR(choice), _pick];
} forEach _rows;

_listY + (count _rows) * _rowH + _padY
