#include "script_component.hpp"
/*
 * Author: YonV
 * RADIO - MANAGE (docs/DESIGN_VOICE.md): leaders, RTO and admin only, by the
 * permission table (RADIO_RIGHTS, the player's place from FUNC(radioRole)).
 *
 * BUILT ON WHAT THE VOICE API GIVES, AND NO FURTHER.
 *   NETS     every net the player is on, its VON channel, kind and state. A
 *            row picks the net the MEMBERS panel shows.
 *   MEMBERS  a TEAM net's members are the player's group (VON's Group channel
 *            is the Arma group) and a CALL net's are the call's; each with
 *            whether the voice contacts have him in reach.
 *   WHO CAN  the permission table, the player's own column marked.
 * Not built, given no buttons and not named on the screen - the voice addon's
 * README, "Not built", says it (tablet review 2026-11-01, 2.1): members of
 * C2 / A2G, keys, PACE alternates, temp nets,
 * patches, listen-only, rekey, force PACE, order EMCON, signal plan load and
 * export. (No RTO pull-in: the call's owner invites - user, 2026-10-20.) MANAGE rights themselves are
 * not enforced by the voice addon; the role gate here only decides what the
 * board shows.
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
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioManage
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

_rect params ["_x0", "_y0", "_w0", "_h0"];
private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _tint = ["accentTint"] call EFUNC(tacpad,theme);

private _role = _ctx get "role";
private _rank = RADIO_ROLES find _role;
private _fnc_may = {
    params ["_need"];
    _rank >= (RADIO_ROLES find _need)
};

private _topH = (_h0 - _padY) * PAGE_SPLIT_RIGHT;
private _leftW = (_w0 - _pad) * 0.5;
private _rightX = _x0 + _leftW + _pad;
private _rightW = _w0 - _leftW - _pad;

// ----------------------------------------------------------- WHO CAN ----
// Drawn for everyone: it is what tells a rifleman why the rest is closed.
([_body, [_x0, _y0 + _topH + _padY, _w0, _h0 - _topH - _padY], "WHO CAN", "BY ROLE"] call FUNC(appPagePanel)) params ["_wl", "_wt", "_ww"];
private _colsAt = [0.62, 0.70, 0.78, 0.86];
private _colWords = ["TL", "SL", "RTO", "ADMIN"];
[_body, [_wl + _pad, _wt, _ww * 0.5, _rowH], "ACTION", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
{
    [_body, [_wl + _ww * (_colsAt select _forEachIndex), _wt, _ww * 0.08, _rowH], _x, ([_muted, _accent] select (_x isEqualTo _role)), TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach _colWords;
// EVERY CELL MARKED (tablet review 2026-11-01, 3.10): an ink square where the
// role may (RADIO_ROLES order, FUNC(radioRole)'s scale), a dash where it may
// not. The check mark it drew is not in the tacpad's fonts, so the table read
// as empty - and an empty matrix reads as broken.
private _markW = WHO_CAN_MARK_PX * pixelW;
private _markH = WHO_CAN_MARK_PX * pixelH;
{
    _x params ["_what", "_need"];
    private _ry = _wt + (_forEachIndex + 1) * _rowH * 1.1;
    [_body, [_wl + _pad, _ry, _ww * 0.6, _rowH], _what, _ink, TEXT_BODY] call EFUNC(tacpad,drawText);
    private _needRank = RADIO_ROLES find _need;
    {
        private _cx = _wl + _ww * (_colsAt select _forEachIndex);
        if ((RADIO_ROLES find _x) >= _needRank) then {
            [_body, [_cx, _ry + (_rowH - _markH) * 0.5, _markW, _markH], _ink] call EFUNC(tacpad,drawFill);
        } else {
            [_body, [_cx, _ry, _ww * 0.08, _rowH], WHO_CAN_NO, _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
        };
    } forEach _colWords;
} forEach RADIO_RIGHTS;

if !(["TL"] call _fnc_may) exitWith {
    ([_body, [_x0, _y0, _w0, _topH], "NETS", "LEADERS, RTO AND ADMIN ONLY"] call FUNC(appPagePanel)) params ["_nl", "_nt", "_nw"];
    [_body, [_nl + _pad, _nt + _rowH * 0.5, _nw - 2 * _pad, _rowH], "MANAGE is for team and squad leaders, RTOs and admins.", _dim, TEXT_TITLE] call EFUNC(tacpad,drawText);
};

// -------------------------------------------------------------- NETS ----
private _netsOn = (_ctx get "netState") select {(_x param [2, ""]) isNotEqualTo VOICE_KIND_DIRECT};
// NOTHING PICKED UNTIL THE PLAYER PICKS (tablet review 2026-11-01, 3.10): the
// first net was picked for him, so MEMBERS never said what it is for. A pick
// whose net he has left is dropped.
private _pick = uiNamespace getVariable [QGVAR(radioPick), ""];
if ((_netsOn findIf {(_x select 0) isEqualTo _pick}) < 0) then {
    _pick = "";
};

([_body, [_x0, _y0, _leftW, _topH], "NETS", format ["%1 ON", count _netsOn]] call FUNC(appPagePanel)) params ["_nl", "_nt", "_nw"];
private _cols = [0, 0.24, 0.46, 0.62, 0.80];
private _heads = ["NET", "VON", "KIND", "KEY", "STATE"];
{
    [_body, [_nl + _pad + _x * (_nw - 2 * _pad), _nt, _nw * 0.2, _rowH], _heads select _forEachIndex, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach _cols;
[_body, [_nl, _nt + _rowH, _nw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _step = _rowH * 1.3;
{
    _x params [["_netId", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], "", "", "", ["_reach", false, [false]]];
    private _ry = _nt + _rowH * 1.1 + _forEachIndex * _step;
    private _cy = _ry + (_step - _rowH) * 0.5;
    if (_netId isEqualTo _pick) then {
        [_body, [_nl, _ry, _nw, _step], _tint] call EFUNC(tacpad,drawFill);
    };
    private _cells = [
        toUpper _name,
        [_netId, _ctx get "nets"] call FUNC(radioVon),
        toUpper _kind,
        "--",
        ["NO ROUTE", ["OK", "LIVE"] select (_kind isEqualTo VOICE_KIND_CALL)] select _reach
    ];
    {
        [_body, [_nl + _pad + (_cols select _forEachIndex) * (_nw - 2 * _pad), _cy, _nw * 0.2, _rowH], _x, ([_ink, _accent] select (_forEachIndex isEqualTo 4 && !_reach)), TEXT_BODY, _forEachIndex isEqualTo 0] call EFUNC(tacpad,drawText);
    } forEach _cells;
    private _hit = [_body, [_nl, _ry, _nw, _step], {
        params ["_ctrl"];
        uiNamespace setVariable [QGVAR(radioPick), _ctrl getVariable [QGVAR(pageData), ""]];
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(pageData), _netId];
} forEach _netsOn;

// THE RTO's NETS, under the plan's (user, 2026-10-22: "allow rtos to add
// custom channels"): listed with REMOVE, and the ADD NET form. What is not
// there yet (keys, PACE alternates, patches, signal plan load / export) is the
// voice addon's README's to say, not the screen's (tablet review 2026-11-01).
private _btnY = _nt + _rowH * 1.1 + (count _netsOn) * _step + _padY;
[_body, [_nl + _pad, _btnY, _nw - 2 * _pad, _y0 + _topH - _btnY - _padY], _ctx] call FUNC(radioCustomPanel);

// ----------------------------------------------------------- MEMBERS ----
private _picked = _netsOn select {(_x select 0) isEqualTo _pick};
(_picked param [0, []]) params [["_pickName", "", [""]], ["_pickLabel", "", [""]], ["_pickKind", "", [""]]];
private _me = call CBA_fnc_currentUnit;
private _members = switch (_pickKind) do {
    case VOICE_KIND_TEAM: {units group _me};
    case VOICE_KIND_CALL: {
        private _live = (_ctx get "calls") select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};
        (_live param [0, []]) param [2, []]
    };
    default {[]};
};
private _known = _pickKind in [VOICE_KIND_TEAM, VOICE_KIND_CALL];

// The net's name is the panel's right label, untracked; the tracked title is
// the short word (tablet review 2026-11-01, 2.3).
([_body, [_rightX, _y0, _rightW, _topH], "MEMBERS", toUpper _pickLabel] call FUNC(appPagePanel)) params ["_ml", "_mt", "_mw"];
// THE EMPTY STATE (tablet review 2026-11-01, 3.10): say what the pane is for.
if (_pickName isEqualTo "") exitWith {
    private _hint = ["Pick a net on the left to see and edit its members.", "You are on no net to pick."] select (_netsOn isEqualTo []);
    [_body, [_ml + _pad, _mt + _rowH * 0.5, _mw - 2 * _pad, _rowH], _hint, _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};

// An RTO net's members are the RTO's to set, here (FUNC(radioMembersPanel)).
if (_pickKind isEqualTo VOICE_KIND_CUSTOM) exitWith {
    private _row = (_ctx getOrDefault ["custom", []]) select {(_x select 0) isEqualTo _pickName};
    [_body, [_ml, _mt, _mw, _y0 + _topH - _mt - _padY], _ctx, _row param [0, []]] call FUNC(radioMembersPanel);
};

private _reachOf = createHashMap;
{
    _reachOf set [hashValue (_x param [0, objNull]), _x param [4, false]];
} forEach (_ctx get "contacts");

if (!_known) then {
    [_body, [_ml + _pad, _mt + _rowH * 0.5, _mw - 2 * _pad, _rowH * 2], "This net's members are not listed here. TEAM, CALL and RTO nets list theirs.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
} else {
    [_body, [_ml + _pad, _mt, _mw * 0.6, _rowH], "MEMBER", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_ml + _mw * 0.62, _mt, _mw * 0.3, _rowH], "ROUTE", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    private _fits = floor ((_topH - _rowH * 6) / _rowH) max 1;
    {
        private _ry = _mt + (_forEachIndex + 1) * _rowH * 1.1;
        private _self = _x isEqualTo _me;
        private _reach = _self || {_reachOf getOrDefault [hashValue _x, false]};
        [_body, [_ml + _pad, _ry, _mw * 0.6, _rowH], toUpper name _x, _ink, TEXT_BODY, _self] call EFUNC(tacpad,drawText);
        [_body, [_ml + _mw * 0.62, _ry, _mw * 0.3, _rowH], ["NO ROUTE", "REACH"] select _reach, ([_accent, _ink] select _reach), TEXT_BODY, true] call EFUNC(tacpad,drawText);
    } forEach ((_members select {!isNull _x}) select [0, _fits]);
};

private _actY = _y0 + _topH - _rowH * 2.5;
[
    _body, [_ml + _pad, _actY, _mw - 2 * _pad, _rowH * 2],
    "The call's owner adds people on CALLS; an RTO net's people are set here once it is picked.", _muted, TEXT_LABEL
] call EFUNC(tacpad,drawText);
