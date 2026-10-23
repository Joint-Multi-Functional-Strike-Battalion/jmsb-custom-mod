#include "script_component.hpp"
/*
 * Author: JMSB
 * What the small devices' RADIO app shows on its open tab, and what its soft
 * keys say (docs/DESIGN_VOICE.md, "Phone and side RADIO app"). Pure read of
 * the voice API: FUNC(radioDraw) draws it and FUNC(radioKey) acts on it, so
 * the keys always act on the row the player can see.
 *
 *   NETS    one row per net he is on: name, ear, link, state, who talks.
 *           F1 MUTE - F2 EAR - F3 SET ACTIVE - F4 BACK
 *   CALLS   the live call over the contacts (on the call, in reach, the rest)
 *           and the group chips. F1 ADD - F2 CALL - F3 GROUP + - F4 HANG UP
 *           (BACK with no call). GROUP + moves the cursor onto the chips.
 *   MANAGE  leaders, RTO and admin only: the nets. Its ADD / REMOVE / REKEY
 *           are not built (the voice API has no call for them), so F1-F3 are
 *           left blank rather than drawn as keys that do nothing; F4 BACK.
 * A RINGING call turns F1 / F4 into ACCEPT / DECLINE on every tab.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <HASHMAP>: header <STRING>, heads [[label, at]] <ARRAY>, rows - each
 * [name, tag, [[text, tone, at], ...], data] <ARRAY>, chips [label, ...]
 * <ARRAY>, keys - four [label, live] <ARRAY>, ring call id <STRING>, live
 * call id <STRING>
 *
 * Example:
 * private _view = [] call jmfsb_devices_fnc_radioRows
 *
 * Public: No
 */

private _me = call CBA_fnc_currentUnit;
private _calls = [] call EFUNC(voice,calls);
private _ring = _calls select {(_x param [1, ""]) isEqualTo CALL_RINGING};
private _live = _calls select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};
private _liveId = (_live param [0, []]) param [0, ""];
// Only the call's owner invites (user, 2026-10-20).
private _canAdd = [] call EFUNC(tacpad_apps,radioCanAdd);
private _members = (_live param [0, []]) param [2, []];
private _fnc_names = {
    params ["_units"];
    toUpper (((_units select {!isNull _x && _x isNotEqualTo _me}) apply {name _x}) joinString ", ")
};

private _header = "";
private _heads = [];
private _rows = [];
private _chips = [];
private _keys = [];

switch (GVAR(radioTab)) do {
    case "calls": {
        if (_live isNotEqualTo []) then {
            (_live select 0) params ["", "_state", "", "", ["_startedAt", CBA_missionTime, [0]]];
            private _s = floor ((CBA_missionTime - _startedAt) max 0);
            _header = format [
                "CALL %1 %2 %3 on %2 %4",
                [format ["%1:%2", floor (_s / SECONDS_PER_MINUTE), [_s mod SECONDS_PER_MINUTE, 2] call CBA_fnc_formatNumber], "DIALLING"] select (_state isEqualTo CALL_OUTGOING),
                MIDDOT, count _members, [_members] call _fnc_names
            ];
        };
        _heads = [["CONTACT", 0], ["REACH", 0.62], ["", 0.8]];
        private _list = (([] call EFUNC(voice,contacts)) select {!isNull (_x param [0, objNull]) && {(_x select 0) isNotEqualTo _me}}) apply {
            _x params ["_unit", "_name", "", "", ["_reach", false, [false]]];
            [[2, [1, 0] select _reach] select !(_unit in _members), toUpper _name, _x]
        };
        _list sort true;
        {
            (_x select 2) params ["_unit", ["_name", "", [""]], ["_callsign", "", [""]], ["_tags", [], [[]]], ["_reach", false, [false]], ["_busy", false, [false]]];
            private _mine = _unit in _members;
            private _action = switch (true) do {
                case (_mine): {["ON CALL", "ok"]};
                case (!_reach || _busy): {["CALL BACK", "warn"]};
                case (_liveId isNotEqualTo "" && !_canAdd): {["OWNER ADDS", "ink"]};
                case (_liveId isNotEqualTo ""): {["+ ADD", "alert"]};
                default {["CALL", "ink"]};
            };
            _rows pushBack [
                toUpper ([_name, _callsign] select (_callsign isNotEqualTo "")),
                _tags joinString " ",
                [[["NO ROUTE", ["REACH", "BUSY"] select (_busy && !_mine)] select _reach, ["alert", "ok"] select (_reach && !_busy), 0.62], [_action select 0, _action select 1, 0.8]],
                [_unit, _reach && !_busy, _mine]
            ];
        } forEach _list;
        _chips = RADIO_CHIPS apply {_x select 1};
        _keys = [["ADD", _canAdd], ["CALL", _canAdd], ["GROUP +", _canAdd], [["BACK", "HANG UP"] select (_liveId isNotEqualTo ""), true]];
    };
    case "manage": {
        if !(([] call EFUNC(tacpad_apps,radioRole)) in MANAGE_ROLES) exitWith {
            _header = "LEADERS, RTO AND ADMIN ONLY";
            _keys = [["", false], ["", false], ["", false], ["BACK", true]];
        };
        _header = "NOT BUILT: ADD / REMOVE / REKEY";
        _heads = [["NET", 0], ["KIND", 0.45], ["STATE", 0.7]];
        {
            _x params [["_netId", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], "", "", "", ["_reach", false, [false]]];
            if (_kind isEqualTo VOICE_KIND_DIRECT) then {continue};
            _rows pushBack [toUpper _name, "", [[toUpper _kind, "dim", 0.45], [["NO ROUTE", "OK"] select _reach, ["alert", "ok"] select _reach, 0.7]], _netId];
        } forEach ([] call EFUNC(voice,netState));
        _keys = [["", false], ["", false], ["", false], ["BACK", true]];
    };
    default {
        _heads = [["NET", 0], ["EAR", 0.2], ["LINK", 0.32], ["STATE", 0.47], ["TALKING", 0.72]];
        {
            _x params [["_netId", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], ["_active", false, [false]], ["_muted", false, [false]], ["_ear", "B", [""]], ["_reach", false, [false]], ["_talkers", [], [[]]]];
            if (_kind isEqualTo VOICE_KIND_DIRECT) then {continue};
            private _state = switch (true) do {
                case (!_reach): {["NO ROUTE", "alert"]};
                case (_kind isEqualTo VOICE_KIND_CALL): {[format ["LIVE %1 %2", MIDDOT, count _members], "ok"]};
                case (_active): {["ACTIVE", "alert"]};
                case (_muted): {["MUTED", "dim"]};
                default {["MON", "ink"]};
            };
            _rows pushBack [
                toUpper _name,
                ["", "MUTE"] select _muted,
                [
                    [_ear, "ink", 0.2],
                    [["NO ROUTE", "OK"] select _reach, ["alert", "ok"] select _reach, 0.32],
                    [_state select 0, _state select 1, 0.47],
                    [[_talkers apply {_x param [0, objNull]}] call _fnc_names, "alert", 0.72]
                ],
                _netId
            ];
        } forEach ([] call EFUNC(voice,netState));
        _keys = [[["MUTE", "UNMUTE"] select (((_rows param [GVAR(radioCursor), []]) param [1, ""]) isNotEqualTo ""), true], ["EAR", true], ["SET ACTIVE", true], ["BACK", true]];
    };
};

// A ring takes F1 and F4 on every tab.
private _ringId = (_ring param [0, []]) param [0, ""];
if (_ringId isNotEqualTo "") then {
    _header = format ["RINGING %1 %2", MIDDOT, [(_ring select 0) param [2, []]] call _fnc_names];
    _keys set [0, ["ACCEPT", true]];
    _keys set [3, ["DECLINE", true]];
};

createHashMapFromArray [
    ["header", _header],
    ["heads", _heads],
    ["rows", _rows],
    ["chips", _chips],
    ["keys", _keys],
    ["ring", _ringId],
    ["live", _liveId]
]
