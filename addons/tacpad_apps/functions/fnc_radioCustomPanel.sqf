#include "script_component.hpp"
/*
 * Author: JMSB
 * The RTO NETS block under MANAGE's NETS panel (user, 2026-10-22: "allow rtos
 * to add custom channels"): the nets the voice server holds, each with REMOVE
 * for an RTO or admin, then the ADD NET form - a name box, the squads to put
 * on it as tick chips, CREATE. Who is on a net by name is set on the MEMBERS
 * panel once it exists (FUNC(radioMembersPanel)). The form sits at the bottom
 * of the block; when room is short the list above it gives way, not the form.
 *
 * The draft - the typed name and the ticked squads - lives in uiNamespace
 * (QGVAR(radioNewName), QGVAR(radioNewSquads)) and is part of the board's
 * redraw key, so a redraw keeps it; the name box is a real RscEdit, as the
 * CALLS tab's FIND box is, because the board has no keyboard of its own.
 *
 * On a TFAR or ACRE night, or without the voice API, the block only says so.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Rectangle [x, y, w, h], relative to the body <ARRAY>
 * 2: The board's context (FUNC(appRadio)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, [_left, _top, _w, _h], _ctx] call jmfsb_tacpad_apps_fnc_radioCustomPanel
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

if (isNull _body) exitWith {};
_rect params ["_left", "_top", "_w", "_h"];
private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _custom = _ctx getOrDefault ["custom", []];
private _max = missionNamespace getVariable [QEGVAR(voice,customNetsMax), CUSTOM_NETS_MAX_DEFAULT];
private _me = call CBA_fnc_currentUnit;
private _canManage = !isNil QEFUNC(voice,canManageNets) && {[_me] call EFUNC(voice,canManageNets)};
private _bottom = _top + _h;

[_body, [_left, _top, _w * 0.6, _rowH], format ["RTO NETS  %1 / %2", count _custom, _max], _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_left, _top + _rowH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
private _ry = _top + _rowH * 1.2;

if ((_ctx getOrDefault ["external", false]) || {!(_ctx getOrDefault ["voice", false])}) exitWith {
    [_body, [_left, _ry, _w, _rowH * 2], "RTO nets are game voice only - not on a TFAR or ACRE night.", _dim, TEXT_LABEL] call EFUNC(tacpad,drawText);
};

// THE ADD NET FORM IS ANCHORED AT THE BOTTOM of the block, its height known
// before the nets are listed, so when room is short the list gives way and
// the form never drops off (user, 2026-10-23: "the net was created then the
// create went away" - the first net also tripped on _x, the loop's element,
// standing in for the rectangle's left; the rectangle is _left / _top now).
private _form = _canManage && {count _custom < _max};
private _squads = [_ctx getOrDefault ["contacts", []]] call FUNC(radioSquads);
private _barH = _rowH * 1.3;
private _chipW = _w * CUSTOM_CHIP_K;
private _perRow = floor (_w / (_chipW + _pad)) max 1;
private _chipRows = (ceil ((count _squads) / _perRow)) min CUSTOM_CHIP_ROWS_MAX;
private _room = _chipRows * _perRow;
private _moreRows = parseNumber (count _squads > _room);
private _formH = [0, _barH + _pad + (_chipRows + _moreRows) * _rowH * 1.1] select _form;
private _listBottom = _bottom - _formH;

// ----------------------------------------------------------- the nets ----
private _shown = 0;
{
    _x params ["_id", "_name", "_squadsOn", "_uids", "", "_owner"];
    if (_shown >= CUSTOM_LIST_MAX || {_ry + _rowH > _listBottom}) then {break};
    [
        _body, [_left, _ry, _w * 0.74, _rowH],
        format ["%1  %2  BY %3  %2  %4 SQUADS, %5 PLAYERS", toUpper _name, MIDDOT_TEXT, toUpper _owner, count _squadsOn, count _uids],
        _ink, TEXT_LABEL, true
    ] call EFUNC(tacpad,drawText);
    if (_canManage) then {
        [_body, [_left + _w * 0.76, _ry, _w * 0.24 - _pad, _rowH], "REMOVE", "line", {
            params ["_ctrl"];
            [_ctrl getVariable [QGVAR(pageData), ""]] call EFUNC(voice,netRemove);
            {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, _id] call FUNC(appPageButton);
    };
    _ry = _ry + _rowH * 1.1;
    _shown = _shown + 1;
} forEach _custom;
if (count _custom > _shown && {_ry + _rowH <= _listBottom}) then {
    [_body, [_left, _ry, _w, _rowH], format ["+%1 MORE - PICK ONE ON NETS ABOVE", count _custom - _shown], _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
    _ry = _ry + _rowH * 1.1;
};
if (_custom isEqualTo [] && {_ry + _rowH <= _listBottom}) then {
    [_body, [_left, _ry, _w, _rowH], "NONE YET", _dim, TEXT_LABEL] call EFUNC(tacpad,drawText);
    _ry = _ry + _rowH * 1.1;
};
if (_canManage && {count _custom >= _max} && {_ry + _rowH <= _listBottom}) then {
    [_body, [_left, _ry, _w, _rowH], format ["NO ROOM FOR ANOTHER: %1 AT ONCE", _max], _dim, TEXT_LABEL] call EFUNC(tacpad,drawText);
};
if (!_form) exitWith {};

// ------------------------------------------------------------ ADD NET ----
_ry = (_bottom - _formH) max _ry;
[_body, [_left, _ry, _w * 0.14, _barH], "ADD NET", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
private _boxX = _left + _w * 0.14;
private _boxW = _w * 0.42;
[_body, [_boxX, _ry, _boxW, _barH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
private _box = (ctrlParent _body) ctrlCreate ["RscEdit", -1, _body];
_box ctrlSetPosition [_boxX + _pad, _ry, _boxW - 2 * _pad, _barH];
_box ctrlSetBackgroundColor [0, 0, 0, 0];
_box ctrlSetTextColor _ink;
_box ctrlSetFontHeight (_rowH * 0.72);
_box ctrlSetText (uiNamespace getVariable [QGVAR(radioNewName), ""]);
_box ctrlSetTooltip format ["A name of %1 letters, digits, spaces or dashes at most - it is what the chip shows.", CUSTOM_NAME_MAX];
_box ctrlCommit 0;
_box ctrlAddEventHandler ["KeyUp", {
    params ["_ctrl"];
    uiNamespace setVariable [QGVAR(radioNewName), ctrlText _ctrl];
    false
}];
[_body, [_boxX + _boxW + _pad, _ry, _w * 0.2, _barH], "CREATE", "fill", {
    private _name = uiNamespace getVariable [QGVAR(radioNewName), ""];
    private _squads = uiNamespace getVariable [QGVAR(radioNewSquads), []];
    if ([_name, _squads, []] call EFUNC(voice,netAdd)) then {
        uiNamespace setVariable [QGVAR(radioNewName), ""];
        uiNamespace setVariable [QGVAR(radioNewSquads), []];
    };
    {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call FUNC(appPageButton);
_ry = _ry + _barH + _pad;

// The squads to put on it: tick chips, CUSTOM_CHIP_ROWS_MAX rows at most.
private _ticked = uiNamespace getVariable [QGVAR(radioNewSquads), []];
{
    if (_forEachIndex >= _room) then {break};
    private _cx = _left + (_forEachIndex mod _perRow) * (_chipW + _pad);
    private _cy = _ry + (floor (_forEachIndex / _perRow)) * _rowH * 1.1;
    [_body, [_cx, _cy, _chipW, _rowH], _x, _x in _ticked, false, {
        params ["_ctrl"];
        private _squad = _ctrl getVariable [QGVAR(pageData), ""];
        private _now = uiNamespace getVariable [QGVAR(radioNewSquads), []];
        uiNamespace setVariable [QGVAR(radioNewSquads), [_now + [_squad], _now - [_squad]] select (_squad in _now)];
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _x] call FUNC(radioTick);
} forEach _squads;
if (_moreRows > 0) then {
    [_body, [_left, _ry + _chipRows * _rowH * 1.1, _w, _rowH], format ["+%1 MORE SQUADS - ADD THEM ON MEMBERS ONCE IT EXISTS", count _squads - _room], _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
};
