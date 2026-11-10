#include "script_component.hpp"
/*
 * Author: YonV
 * RADIO - CALLS on the voice server (Mumble or LiveKit): every call on the
 * server, as many as there are, one row each - its CALL net, LIVE or
 * RINGING, how many are in it - in a list that scrolls inside the panel. The
 * header says how many ("1 CALL", "3 CALLS").
 *
 * NO LIMIT TO THE NUMBER OF CALLS (user, 2026-11-01: "on the radio calls tab
 * there should be no limit to the # of calls"): the voice server counts no
 * channels, so there is no strip of a fixed size to fill (jmfsb_voice_fnc_
 * srvSlot). Game VON keeps its eight-slot strip (FUNC(appRadioCalls)).
 *
 * The board is rebuilt on every change; FUNC(appRadio) reads where this list
 * was scrolled to before it goes, and it is put back here.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appRadio)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioCallList
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _calls = (_ctx get "slots") select {(_x param [1, ""]) isNotEqualTo ""};
private _count = count _calls;
private _head = format ["%1 %2", _count, ["CALLS", "CALL"] select (_count isEqualTo 1)];
([_body, _rect, "ALL CALLS", _head] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

uiNamespace setVariable [QGVAR(radioCallsList), controlNull];
if (_calls isEqualTo []) exitWith {
    [_body, [_left + _pad, _top + _rowH * 0.5, _w - 2 * _pad, _rowH], "No calls on the server.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};

// The tacpad's own scrolling group, inside the panel under its rule.
private _list = (ctrlParent _body) ctrlCreate [QEGVAR(tacpad,body), -1, _body];
_list ctrlSetPosition [_left, _top, _w, _h];
_list ctrlSetBackgroundColor [0, 0, 0, 0];
_list ctrlCommit 0;
uiNamespace setVariable [QGVAR(radioCallsList), _list];

private _step = _rowH * CALLS_ROW_LINES;
{
    _x params [["_slot", 0, [0]], "", ["_members", 0, [0]], ["_live", false, [false]]];
    private _ry = _forEachIndex * _step;
    private _cy = _ry + (_step - _rowH) * 0.5;
    [_list, [_pad, _cy, _w * 0.3, _rowH], format ["CALL %1", _slot], _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_list, [_w * 0.32, _cy, _w * 0.28, _rowH], ["RINGING", "LIVE"] select _live, [_muted, _ink] select _live, TEXT_BODY] call EFUNC(tacpad,drawText);
    [_list, [_w * 0.6, _cy, _w * 0.32, _rowH], format ["%1 %2", _members, ["MEMBERS", "MEMBER"] select (_members isEqualTo 1)], _muted, TEXT_BODY] call EFUNC(tacpad,drawText);
    [_list, [0, _ry + _step - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _calls;

private _scroll = uiNamespace getVariable [QGVAR(radioCallsScroll), 0];
if (_scroll > 0) then {_list ctrlSetScrollValues [_scroll, -1]};
