#include "script_component.hpp"
/*
 * Author: JMSB
 * MANAGE's MEMBERS panel for one of the RTO nets (user, 2026-10-22: "allow
 * rtos to add custom channels"): its squads as tick chips, then every contact
 * as a tick row - a man on it through his squad is ticked dim, by the squad's
 * chip, not his own - and APPLY, which sends both lists to the voice server
 * (jmfsb_voice_fnc_netMembers); RESET drops the draft. Without the right to
 * manage the same is drawn with no press.
 *
 * The draft is [net id, squads, uids] in uiNamespace (QGVAR(radioMembersDraft))
 * and part of the board's redraw key; it starts from the net as published
 * whenever the picked net changes.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Rectangle [x, y, w, h], relative to the body <ARRAY>
 * 2: The board's context (FUNC(appRadio)) <HASHMAP>
 * 3: The net's row, as jmfsb_voice_fnc_customList gives it <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, [_left, _top, _w, _h], _ctx, _row] call jmfsb_tacpad_apps_fnc_radioMembersPanel
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]], ["_row", [], [[]]]];

if (isNull _body || _row isEqualTo []) exitWith {};
_rect params ["_left", "_top", "_w", "_h"];
_row params ["_id", "", "_squadsNow", "_uidsNow"];
private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _me = call CBA_fnc_currentUnit;
private _canManage = !isNil QEFUNC(voice,canManageNets) && {[_me] call EFUNC(voice,canManageNets)};
private _noPress = {};

// The draft, started afresh when the pick moved to another net.
private _draft = uiNamespace getVariable [QGVAR(radioMembersDraft), []];
if ((_draft param [0, ""]) isNotEqualTo _id) then {
    _draft = [_id, +_squadsNow, +_uidsNow];
    uiNamespace setVariable [QGVAR(radioMembersDraft), _draft];
};
private _squads = _draft select DRAFT_COL_SQUADS;
private _uids = _draft select DRAFT_COL_UIDS;

// ------------------------------------------------------------- squads ----
private _ry = _top;
[_body, [_left + _pad, _ry, _w, _rowH], "SQUADS ON IT", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH * 1.1;
private _all = [_ctx getOrDefault ["contacts", []]] call FUNC(radioSquads);
private _chipW = _w * CUSTOM_CHIP_K;
private _perRow = floor (_w / (_chipW + _pad)) max 1;
private _rows = (ceil ((count _all) / _perRow)) min CUSTOM_CHIP_ROWS_MAX;
{
    if (_forEachIndex >= _rows * _perRow) then {break};
    private _cx = _left + (_forEachIndex mod _perRow) * (_chipW + _pad);
    private _cy = _ry + (floor (_forEachIndex / _perRow)) * _rowH * 1.1;
    [_body, [_cx, _cy, _chipW, _rowH], _x, _x in _squads, !_canManage, [_noPress, {
        params ["_ctrl"];
        [DRAFT_COL_SQUADS, _ctrl getVariable [QGVAR(pageData), ""]] call FUNC(radioMembersToggle);
    }] select _canManage, _x] call FUNC(radioTick);
} forEach _all;
_ry = _ry + _rows * _rowH * 1.1 + _pad;

// ------------------------------------------------------------- people ----
[_body, [_left + _pad, _ry, _w * 0.6, _rowH], "PEOPLE ON IT", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_left + _w * 0.62, _ry, _w * 0.36, _rowH], "DIM = THROUGH THE SQUAD", _muted, TEXT_LABEL, true, "right", true] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH * 1.1;

private _people = [[_me, name _me, groupId group _me]] + ((_ctx getOrDefault ["contacts", []]) apply {[_x param [0, objNull], _x param [1, ""], _x param [2, ""]]});
_people = _people select {!isNull (_x select 0)};
_people sort true;
private _footY = _top + _h - _rowH * 1.4;
private _fits = floor ((_footY - _pad - _ry) / (_rowH * 1.1)) max 0;
{
    _x params ["_unit", "_name", "_callsign"];
    private _uid = getPlayerUID _unit;
    private _viaSquad = (toUpper trim _callsign) in _squads;
    private _own = _uid in _uids;
    [_body, [_left + _pad, _ry + _forEachIndex * _rowH * 1.1, _w - 2 * _pad, _rowH],
        format ["%1  %2  %3", toUpper _name, MIDDOT_TEXT, toUpper _callsign],
        _own || _viaSquad, (_viaSquad && !_own) || !_canManage,
        [_noPress, {
            params ["_ctrl"];
            [DRAFT_COL_UIDS, _ctrl getVariable [QGVAR(pageData), ""]] call FUNC(radioMembersToggle);
        }] select _canManage, _uid
    ] call FUNC(radioTick);
} forEach (_people select [0, _fits]);
if (count _people > _fits) then {
    [_body, [_left + _pad, _ry + _fits * _rowH * 1.1, _w, _rowH], format ["+%1 MORE", count _people - _fits], _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
};

if (!_canManage) exitWith {};

// -------------------------------------------------------- APPLY / RESET ----
private _changed = !(_squads isEqualTo _squadsNow && _uids isEqualTo _uidsNow);
[_body, [_left + _pad, _footY, _w * 0.3, _rowH * 1.2], "APPLY", "fill", [{}, {
    private _d = uiNamespace getVariable [QGVAR(radioMembersDraft), []];
    if (_d isEqualTo []) exitWith {};
    [_d select 0, _d select DRAFT_COL_SQUADS, _d select DRAFT_COL_UIDS] call EFUNC(voice,netMembers);
    {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] select _changed] call FUNC(appPageButton);
[_body, [_left + _pad + _w * 0.32, _footY, _w * 0.3, _rowH * 1.2], "RESET", "line", [{}, {
    uiNamespace setVariable [QGVAR(radioMembersDraft), nil];
    {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] select _changed] call FUNC(appPageButton);
