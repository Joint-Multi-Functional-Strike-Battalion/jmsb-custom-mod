#include "script_component.hpp"
/*
 * Author: JMSB
 * RADIO - CALLS (docs/DESIGN_VOICE.md, "Calls"): the group adds and the search
 * across the top; VON CHANNEL SLOTS and CONTACTS on the left; the LIVE CALL
 * and CALLBACKS on the right (FUNC(appRadioContacts), FUNC(appRadioLive)).
 *
 * A CALL IS ONE CUSTOM CHANNEL, up to CALL_SIZE_MAX people, eight calls at
 * once server-wide. A group add rings everyone of that group in reach into the
 * live call, or opens a call with them when there is none (FUNC(radioDial)),
 * and stops when the call is full. A leader with the right to (RTO, admin -
 * RADIO_RIGHTS "C2 / A2G, calls, bump") can make the next call FLASH, which may
 * bump the oldest ROUTINE call when every slot is taken.
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

// VON CHANNEL SLOTS: C2 and A2G hold custom 1 and 2 for good; CALL 1-8 the
// rest, filled while a call holds them (jmfsb_voice_fnc_callSlots).
private _slotsH = _rowH * 5;
([_body, [_x0, _top, _leftW, _slotsH], "VON CHANNEL SLOTS", "SERVER-WIDE"] call FUNC(appPagePanel)) params ["_sl", "_st", "_sw"];
private _cells = VON_FIXED_CUSTOM apply {[str (_x select 1), _x select 0, true]};
private _used = count _cells;
{
    _x params [["_slot", 0, [0]], ["_callId", "", [""]]];
    private _busy = _callId isNotEqualTo "";
    if (_busy) then {_used = _used + 1};
    _cells pushBack [str (_slot + count VON_FIXED_CUSTOM), [format ["CALL %1", _slot], ""] select !_busy, _busy];
} forEach (_ctx get "slots");
private _cellW = (_sw - 2 * _pad) / (VON_CUSTOM_COUNT max 1);
private _ground = ["ground"] call EFUNC(tacpad,theme);
{
    _x params ["_n", "_label", "_busy"];
    private _cell = [_sl + _pad + _forEachIndex * _cellW, _st + _padY, _cellW - _pad, _rowH * 1.8];
    if (_busy) then {
        [_body, _cell, _ink] call EFUNC(tacpad,drawFill);
    } else {
        [_body, _cell, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    };
    _cell params ["_cx", "_cy", "_cw"];
    [_body, [_cx, _cy, _cw, _rowH * 0.9], _n, [_muted, _ground] select _busy, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);
    [_body, [_cx, _cy + _rowH * 0.9, _cw, _rowH * 0.9], _label, [_muted, _ground] select _busy, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);
} forEach (_cells select [0, VON_CUSTOM_COUNT]);
[
    _body, [_sl + _pad, _st + _padY + _rowH * 2, _sw - 2 * _pad, _rowH],
    format ["%1 of %2 custom channels used - %3 calls free", _used, VON_CUSTOM_COUNT, VON_CUSTOM_COUNT - _used], _muted, TEXT_LABEL
] call EFUNC(tacpad,drawText);

[_body, [_x0, _top + _slotsH + _padY, _leftW, _h - _slotsH - _padY], _ctx] call FUNC(appRadioContacts);
[_body, [_rightX, _top, _rightW, _h], _ctx] call FUNC(appRadioLive);
