#include "script_component.hpp"
/*
 * Author: JMSB
 * RADIO - CALLS, the CONTACTS panel: everyone the voice API lists, with the
 * role tags it gives them, whether he is in reach on DATA, and what can be done:
 *
 *   ON CALL     already on the player's call
 *   + ADD       rings him into the live call (only while there is one)
 *   CALL        rings him on a call of their own, or into the live one
 *   CALL BACK   out of reach, or busy on another call: the server holds the
 *               request and rings both when they can reach each other and a
 *               slot is free (jmfsb_voice_fnc_callBack)
 *
 * The search on the bar filters by name or callsign. People on the call come
 * first, then those in reach, then the rest; as many as the panel holds.
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
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioContacts
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _live = (_ctx get "calls") select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};
private _callId = (_live param [0, []]) param [0, ""];
// Only the call's owner invites (user, 2026-10-20) - FUNC(radioCanAdd).
private _canAdd = [] call FUNC(radioCanAdd);
private _onCall = (_live param [0, []]) param [2, []];

private _find = toUpper trim (uiNamespace getVariable [QGVAR(radioFind), ""]);
private _me = call CBA_fnc_currentUnit;
private _rows = (_ctx get "contacts") select {
    _x params [["_unit", objNull, [objNull]], ["_name", "", [""]], ["_callsign", "", [""]]];
    !isNull _unit && _unit isNotEqualTo _me && {_find isEqualTo "" || {(toUpper _name find _find) >= 0} || {(toUpper _callsign find _find) >= 0}}
};
// Sort: on the call, then in reach, then the rest; by name inside each.
_rows = _rows apply {
    _x params ["_unit", "_name", "", "", ["_reach", false, [false]]];
    [[2, [1, 0] select _reach] select !(_unit in _onCall), toUpper _name, _x]
};
_rows sort true;
_rows = _rows apply {_x select 2};

([_body, _rect, "CONTACTS", ["REACH ON DATA", format ["%1 MATCH", count _rows]] select (_find isNotEqualTo "")] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

if (_rows isEqualTo []) exitWith {
    [_body, [_left + _pad, _top + _rowH * 0.5, _w - 2 * _pad, _rowH], ["Nobody to call.", "Nobody matches the search."] select (_find isNotEqualTo ""), _dim, TEXT_TITLE] call EFUNC(tacpad,drawText);
};

[_body, [_left + _pad, _top, _w * 0.5, _rowH], "CONTACT", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_left + _w * 0.5, _top, _w * 0.15, _rowH], "REACH", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_left, _top + _rowH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _step = _rowH * 1.5;
private _fits = floor ((_h - _rowH * 2.5) / _step) max 1;
private _btnW = _w * 0.13;
private _act1 = _left + _w * 0.68;
private _act2 = _act1 + _btnW + _pad;

{
    _x params [["_unit", objNull, [objNull]], ["_name", "", [""]], ["_callsign", "", [""]], ["_tags", [], [[]]], ["_reach", false, [false]], ["_busy", false, [false]]];
    private _ry = _top + _rowH * 1.2 + _forEachIndex * _step;
    private _cy = _ry + (_step - _rowH) * 0.5;
    private _mine = _unit in _onCall;

    private _who = toUpper ([_name, _callsign] select (_callsign isNotEqualTo ""));
    if (_tags isNotEqualTo []) then {_who = format ["%1 %2 %3", _who, MIDDOT_TEXT, _tags joinString " "]};
    [_body, [_left + _pad, _cy, _w * 0.48, _rowH], _who, _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);

    private _reachWord = switch (true) do {
        case (!_reach): {"NO ROUTE"};
        case (_busy && !_mine): {"BUSY"};
        default {"REACH"};
    };
    [_body, [_left + _w * 0.5, _cy, _w * 0.16, _rowH], _reachWord, ([_ink, _accent] select (_reachWord isNotEqualTo "REACH")), TEXT_LABEL, true] call EFUNC(tacpad,drawText);

    private _fnc_press = {
        params ["_ctrl"];
        (_ctrl getVariable [QGVAR(pageData), []]) params [["_what", ""], ["_who", objNull]];
        switch (_what) do {
            case "add";
            case "call": {[[_who], [CALL_ROUTINE, CALL_FLASH] select (uiNamespace getVariable [QGVAR(radioFlash), false])] call FUNC(radioDial)};
            case "back": {[_who] call EFUNC(voice,callBack)};
        };
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    };

    switch (true) do {
        case (_mine): {
            [_body, [_act1, _cy, _btnW, _rowH], "ON CALL", _ink, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);
        };
        case (!_reach || _busy): {
            [_body, [_act1, _cy, _btnW, _rowH], "CALL BACK", "line", _fnc_press, ["back", _unit]] call FUNC(appPageButton);
        };
        case (_callId isNotEqualTo "" && !_canAdd): {
            [_body, [_act1, _cy, _btnW, _rowH], "OWNER ADDS", _muted, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);
        };
        default {
            if (_callId isNotEqualTo "") then {
                [_body, [_act1, _cy, _btnW, _rowH], "+ ADD", "fill", _fnc_press, ["add", _unit]] call FUNC(appPageButton);
            };
            [_body, [[_act1, _act2] select (_callId isNotEqualTo ""), _cy, _btnW, _rowH], "CALL", "line", _fnc_press, ["call", _unit]] call FUNC(appPageButton);
        };
    };

    [_body, [_left, _ry + _step - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach (_rows select [0, _fits]);

private _more = (count _rows) - _fits;
private _footY = _top + _rowH * 1.2 + ((count _rows) min _fits) * _step + _rowH * 0.3;
[
    _body, [_left + _pad, _footY, _w - 2 * _pad, _rowH],
    format ["%1While a call is live, + ADD rings that person into it. ADD TO CALL on the map or the squad list is not built.", ["", format ["+%1 more - search to narrow. ", _more]] select (_more > 0)],
    _muted, TEXT_LABEL
] call EFUNC(tacpad,drawText);
