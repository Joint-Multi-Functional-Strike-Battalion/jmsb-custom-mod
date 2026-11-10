#include "script_component.hpp"
/*
 * Author: YonV
 * RADIO - CALLS (docs/DESIGN_VOICE.md, "Calls"): the group adds and the search
 * across the top; CALL SLOTS (game VON) or ALL CALLS (the voice server,
 * FUNC(appRadioCallList)) and CONTACTS on the left; the LIVE CALL and
 * CALLBACKS on the right (FUNC(appRadioContacts), FUNC(appRadioLive)).
 *
 * A CALL HOLDS UP TO CALL_SIZE_MAX people. Game VON gives each call a custom
 * channel, so eight calls at once server-wide; the voice server has no limit
 * to the number of calls (user, 2026-11-01). A group add rings everyone of
 * that group in reach into the live call, or opens a call with them when
 * there is none (FUNC(radioDial)),
 * and stops when the call is full. A leader with the right to (RTO, admin -
 * RADIO_RIGHTS "C2 / A2G, calls, bump") can make the next call FLASH, which may
 * bump the oldest ROUTINE call when every slot is taken (game VON only).
 *
 * SEARCH filters CONTACTS by name or callsign. The box keeps what is typed in
 * uiNamespace; FIND (or the board's next redraw once the box loses focus)
 * applies it - the board never redraws under a box being typed in.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Tab rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appRadio)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioCalls
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

_rect params ["_x0", "_y0", "_w0", "_h0"];
private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);

private _canFlash = (RADIO_ROLES find (_ctx get "role")) >= (RADIO_ROLES find "RTO");
if (!_canFlash) then {uiNamespace setVariable [QGVAR(radioFlash), false]};
private _flash = uiNamespace getVariable [QGVAR(radioFlash), false];

// --------------------------------------------------------- the top bar ----
private _barH = _rowH * 1.3;
[_body, [_x0, _y0, _w0 * 0.08, _barH], "ADD GROUP", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
private _bx = _x0 + _w0 * 0.08;
private _btnW = _w0 * 0.085;
{
    _x params ["_id", "_label"];
    [_body, [_bx + _forEachIndex * (_btnW + _pad), _y0, _btnW, _barH], _label, "line", {
        params ["_ctrl"];
        private _live = ([] call EFUNC(voice,calls)) select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};
        private _on = (_live param [0, []]) param [2, []];
        private _units = [_ctrl getVariable [QGVAR(pageData), ""], _on] call FUNC(radioGroup);
        if (_units isEqualTo []) exitWith {
            ["RADIO", "Nobody of that group is in reach.", "normal"] call EFUNC(messaging,notify);
        };
        [_units, [CALL_ROUTINE, CALL_FLASH] select (uiNamespace getVariable [QGVAR(radioFlash), false])] call FUNC(radioDial);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _id] call FUNC(appPageButton);
} forEach RADIO_GROUPS;

private _afterGroups = _bx + (count RADIO_GROUPS) * (_btnW + _pad);
if (_canFlash) then {
    [_body, [_afterGroups, _y0, _btnW, _barH], ["NEXT: ROUTINE", "NEXT: FLASH"] select _flash, ["line", "alarm"] select _flash, {
        uiNamespace setVariable [QGVAR(radioFlash), !(uiNamespace getVariable [QGVAR(radioFlash), false])];
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call FUNC(appPageButton);
};

// The search box, and FIND to apply it.
private _findW = _w0 * 0.05;
private _boxW = _w0 * 0.2;
private _boxX = _x0 + _w0 - _boxW - _findW - _pad;
[_body, [_boxX, _y0, _boxW, _barH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
private _box = (ctrlParent _body) ctrlCreate ["RscEdit", -1, _body];
_box ctrlSetPosition [_boxX + _pad, _y0, _boxW - 2 * _pad, _barH];
_box ctrlSetBackgroundColor [0, 0, 0, 0];
_box ctrlSetTextColor _ink;
_box ctrlSetFontHeight (_rowH * 0.72);
_box ctrlSetText (uiNamespace getVariable [QGVAR(radioFind), ""]);
_box ctrlSetTooltip "Find a contact by name or callsign, then FIND.";
_box ctrlCommit 0;
_box ctrlAddEventHandler ["KeyUp", {
    params ["_ctrl"];
    uiNamespace setVariable [QGVAR(radioFind), ctrlText _ctrl];
    false
}];
[_body, [_boxX + _boxW + _pad, _y0, _findW, _barH], "FIND", "fill", {
    {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call FUNC(appPageButton);

private _top = _y0 + _barH + _padY;
private _h = _h0 - _barH - _padY;
[_body, [_x0, _top - _padY * 0.5, _w0, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

// ------------------------------------------------- the two columns ----
private _leftW = (_w0 - _pad) * PAGE_SPLIT_RADIO;
private _rightX = _x0 + _leftW + _pad;
private _rightW = _w0 - _leftW - _pad;

// THE CALL SLOTS (tablet review 2026-11-01, R8): the strip is the custom
// channels a call can hold, CALL 1-8, each filled while a call holds it
// (jmfsb_voice_fnc_callSlots), and the header counts those. C2 and A2G hold
// custom 1 and 2 for good: they are not call slots, and are said apart under
// the strip as the fixed nets they are. Game VON only: the voice server has
// no limit to the number of calls (user, 2026-11-01), so it lists the calls
// there are instead (FUNC(appRadioCallList)).
private _slotsH = _rowH * 5;
private _slotsRect = [_x0, _top, _leftW, _slotsH];
if (_ctx getOrDefault ["von", true]) then {
    uiNamespace setVariable [QGVAR(radioCallsList), controlNull];
    private _slots = (_ctx get "slots") select [0, CALL_SLOTS];
    private _used = {(_x param [1, ""]) isNotEqualTo ""} count _slots;
    ([_body, _slotsRect, "CALL SLOTS", format ["%1 / %2 IN USE", _used, CALL_SLOTS]] call FUNC(appPagePanel)) params ["_sl", "_st", "_sw"];
    private _cellW = (_sw - 2 * _pad) / (CALL_SLOTS max 1);
    private _ground = ["ground"] call EFUNC(tacpad,theme);
    {
        _x params [["_slot", 0, [0]], ["_callId", "", [""]]];
        private _busy = _callId isNotEqualTo "";
        private _cell = [_sl + _pad + _forEachIndex * _cellW, _st + _padY, _cellW - _pad, _rowH * 1.8];
        if (_busy) then {
            [_body, _cell, _ink] call EFUNC(tacpad,drawFill);
        } else {
            [_body, _cell, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
        };
        _cell params ["_cx", "_cy", "_cw"];
        [_body, [_cx, _cy, _cw, _rowH * 0.9], format ["CALL %1", _slot], [_muted, _ground] select _busy, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);
        // Its state is a value: untracked, at the body size (2.3 / R1).
        [_body, [_cx, _cy + _rowH * 0.9, _cw, _rowH * 0.9], ["FREE", "IN USE"] select _busy, [_muted, _ground] select _busy, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    } forEach _slots;
    [
        _body, [_sl + _pad, _st + _padY + _rowH * 2, _sw - 2 * _pad, _rowH],
        format ["FIXED NETS  %1", (VON_FIXED_CUSTOM apply {format ["%1 on custom %2", _x select 0, _x select 1]}) joinString format ["  %1  ", MIDDOT_TEXT]],
        _muted, TEXT_BODY
    ] call EFUNC(tacpad,drawText);
} else {
    [_body, _slotsRect, _ctx] call FUNC(appRadioCallList);
};

[_body, [_x0, _top + _slotsH + _padY, _leftW, _h - _slotsH - _padY], _ctx] call FUNC(appRadioContacts);
[_body, [_rightX, _top, _rightW, _h], _ctx] call FUNC(appRadioLive);
