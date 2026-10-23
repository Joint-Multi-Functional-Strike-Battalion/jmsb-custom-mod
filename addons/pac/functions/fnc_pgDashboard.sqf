#include "script_component.hpp"
/*
    File: fnc_pgDashboard.sqf
    Author: YonV
    Description: The dashboard - the website's ?page=dashboard, block for
        block: the tiles, NEEDS ATTENTION, PROMOTABLE, THE UNIT, LAST ADMIN
        ACTIONS. Read only; the pages the rows link to are where things
        change.

    Parameters:
        None

    Returns:
        Nothing
*/

GVAR(uiLive) = true;
["Dashboard", ""] call FUNC(uiTitle);

private _sum = missionNamespace getVariable [QGVAR(summary), createHashMap];
private _roster = missionNamespace getVariable [QGVAR(roster), []];
private _structure = GVAR(structure);
private _roles = _structure getOrDefault ["roles", createHashMap];
private _orbat = _structure getOrDefault ["orbat", createHashMap];
private _groups = _orbat getOrDefault ["groups", []];
private _svc = "service" in (_sum getOrDefault ["backend", ""]);

// ---- the tiles ------------------------------------------------------------
private _open = _sum getOrDefault ["ticketsOpen", -1];
private _y = [[
    [count _roster, "on the roster"],
    [_sum getOrDefault ["sessions", 0], "sessions recorded"],
    [_sum getOrDefault ["windows", 0], "windows"],
    [count _roles, "roles"],
    [count (_structure getOrDefault ["opords", createHashMap]), "orders"],
    [[_open, "-"] select (_open < 0), "PAC actions open"]
]] call FUNC(uiTiles);

// ---- needs attention ------------------------------------------------------
private _att = [];
private _apps = _sum getOrDefault ["applicationsNew", -1];
if (_apps > 0) then {_att pushBack [[format ["%1 application(s) waiting", _apps], "Somebody applied and nobody has answered"], "applications"]};
if (_open > 0) then {_att pushBack [[format ["%1 PAC action(s) open", _open], "Raised and not yet decided"], "tickets"]};
(_sum getOrDefault ["noDiscord", [0, 0]]) params [["_nd", 0], ["_nm", 0]];
if (_nd > 0) then {_att pushBack [[format ["%1 of %2 operators have no Discord id", _nd, _nm], "The website cannot reach them"], "roster"]};
private _emptySquads = _groups select {(_x param [1, []]) isEqualTo []};
if (_emptySquads isNotEqualTo []) then {_att pushBack [[format ["%1 squad(s) with no roles", count _emptySquads], (_emptySquads apply {_x # 0}) joinString ", "], "orbat:squads"]};
private _noDoc = [];
{{_noDoc pushBackUnique _x} forEach ((_x param [1, []]) select {!(_x in _roles)})} forEach _groups;
if (_noDoc isNotEqualTo []) then {_att pushBack [[format ["%1 role(s) with no document", count _noDoc], _noDoc joinString ", "], "orbat:roles"]};
private _orphans = _sum getOrDefault ["orphans", []];
if (_orphans isNotEqualTo []) then {_att pushBack [[format ["%1 record(s) point at ids the structure no longer has", count _orphans], "Open the roster and re-pick them"], "roster"]};
if ((_sum getOrDefault ["savedAt", ""]) isEqualTo "") then {_att pushBack [["The store has not been written this mission", "It writes on SAVE, or at mission end"], "backup"]};
if (_sum getOrDefault ["readOnly", false]) then {_att pushBack [["The store is READ ONLY", "Nothing an admin changes will be kept"], "backup"]};

private _attRows = _att apply {[_x # 0, _x # 1]};
if (_attRows isEqualTo []) then {_attRows = [[["Nothing waiting", "the store is answering and nothing is orphaned"], "", [0.576, 0.812, 0.447, 1]]]};

private _colW = (PAC_UI_W - 0.016) / 2;
private _rx = PAC_UI_X + _colW + 0.016;
private _half = (PAC_UI_BOTTOM - _y - 0.012) / 2;

[PAC_IDC_LIST, [], [0, 0.52], _attRows, {
    params ["_data"];
    if (_data isEqualTo "") exitWith {};
    private _parts = _data splitString ":";
    private _args = createHashMap;
    if (count _parts > 1) then {_args set ["s", _parts # 1]};
    [_parts # 0, _args] call FUNC(uiGo);
}, _y, _half, format ["Needs attention  %1", count _att], PAC_UI_X, _colW] call FUNC(uiList);

// ---- promotable -----------------------------------------------------------
private _due = _sum getOrDefault ["promotable", []];
private _ranks = _structure getOrDefault ["ranks", createHashMap];
private _fnc_abbrev = {
    private _r = _ranks getOrDefault [_this, createHashMap];
    private _a = _r getOrDefault ["abbrev", ""];
    [_a, toUpper _this] select (_a isEqualTo "")
};
private _dueRows = _due apply {
    _x params ["_name", "_rankId", "_next", "_pts", "_need", ["_uid", ""]];
    [[_name, _rankId call _fnc_abbrev, round _pts, format ["%1 -> %2", _rankId call _fnc_abbrev, _next call _fnc_abbrev]], _uid]
};
if (_dueRows isEqualTo []) then {_dueRows = [[["Nobody is over the points for their next rank", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
// settings autoPromote - the website's "Promote automatically" switch on the promotion page
private _auto = GVAR(settings) getOrDefault ["autoPromote", false];
// BY TYPE, NOT BY SHORT CIRCUIT. `isEqualType 0 && _auto > 0` without braces
// evaluates `> 0` on a BOOL and throws (seen in the .rpt 2026-09-10 02:31);
// with braces the lint objects. A switch on the type does neither.
_auto = switch (typeName _auto) do {
    case "BOOL": {_auto};
    case "SCALAR": {_auto > 0};
    case "STRING": {(toLower _auto) in ["1", "true", "yes"]};
    default {false};
};
[PAC_IDC_LIST2, ["Who", "Rank", "Points", "Due"], [0, 0.40, 0.58, 0.72], _dueRows, {
    params ["_uid"];
    if (_uid isEqualTo "") exitWith {};
    ["player", createHashMapFromArray [["uid", _uid]]] call FUNC(uiGo);
}, _y + _half + 0.012, _half, format ["Promotable  %1   -   automatic promotion is %2 (Configs, Settings, autoPromote)", count _due, ["off", "on"] select _auto], PAC_UI_X, _colW] call FUNC(uiList);

// ---- the unit -------------------------------------------------------------
// The website's key/value table, as lines: the key in grey, the value after it.
private _hash = _sum getOrDefault ["hash", ""];
_hash = if (_hash isEqualType 0) then {_hash toFixed 0} else {str _hash};
private _savedAt = _sum getOrDefault ["savedAt", ""];
private _kv = [
    ["Unit id", GVAR(settings) getOrDefault ["unitId", ""]],
    ["Database", _sum getOrDefault ["backend", "profile"]],
    ["Server id", GVAR(settings) getOrDefault ["serverId", ""]],
    ["Store schema", str PAC_SCHEMA],
    ["Game last wrote the store", [_savedAt, "never this mission"] select (_savedAt isEqualTo "")],
    ["Read only", ["no", "YES"] select (_sum getOrDefault ["readOnly", false])],
    ["Window", [_sum getOrDefault ["windowName", ""], "none open"] select ((_sum getOrDefault ["window", ""]) isEqualTo "")],
    ["Structure hash", _hash],
    ["Mongo docs", [str (_sum getOrDefault ["docs", 0]), "-"] select (!_svc)]
];
private _unitH = 0.028 + (count _kv) * 0.030 + 0.016;
private _kvText = (_kv apply {
    format ["<t color='#8b97a3'>%1</t>   <t color='#e3e9ef'>%2</t>", [_x # 0] call FUNC(uiEsc), [_x # 1] call FUNC(uiEsc)]
}) joinString "<br/>";
private _th = [PAC_IDC_TEXT_HEAD, _rx, _y, _colW, 0.026] call FUNC(uiPlace);
_th ctrlSetStructuredText parseText "<t color='#93cf72' size='0.7'>THE UNIT</t>";
private _txt = [PAC_IDC_TEXT, _rx, _y + 0.028, _colW, _unitH - 0.028] call FUNC(uiPlace);
_txt ctrlSetStructuredText parseText _kvText;

// ---- last admin actions ---------------------------------------------------
// Asked of the server no more than once every fifteen seconds: the answer
// (FUNC(logRecv)) redraws this page, and a page that asked on every redraw
// would never stop asking.
if (diag_tickTime - (missionNamespace getVariable [QGVAR(uiLogAskedAt), -100]) > 15) then {
    GVAR(uiLogAskedAt) = diag_tickTime;
    [player, "", 8] remoteExec [QFUNC(adminLog), 2];
};
private _log = +(missionNamespace getVariable [QGVAR(logRows), []]);
private _logRows = (_log select [0, 8]) apply {
    _x params [["_id", ""], ["_when", ""], "", ["_byName", ""], ["_type", ""], "", ["_target", ""], ["_detail", ""]];
    [[_when select [0, 16], _byName, format ["%1  %2  %3", _type, _target, _detail]], ""]
};
if (_logRows isEqualTo []) then {_logRows = [[["", "", "Nothing logged yet"], "", [0.545, 0.592, 0.639, 1]]]};
private _logY = _y + _unitH + 0.012;
[PAC_IDC_LIST3, ["When", "Who", "What"], [0, 0.22, 0.42], _logRows, {}, _logY, PAC_UI_BOTTOM - _logY, "Last admin actions", _rx, _colW] call FUNC(uiList);

// ---- the actions ----------------------------------------------------------
private _windowOpen = ((_sum getOrDefault ["window", ""]) select [0, 1]) isEqualTo "w";
[[
    ["SAVE THE STORE", {
        ["Write the store to the profile and the database now? This is the one write the game makes on purpose.", {
            [player] remoteExec [QFUNC(adminSave), 2];
            ["Saving ...", false] call FUNC(uiHint);
        }] call FUNC(uiConfirm);
    }],
    [["START A WINDOW", "STOP THE WINDOW"] select _windowOpen, {
        if (((((missionNamespace getVariable [QGVAR(summary), createHashMap]) getOrDefault ["window", ""]) select [0, 1])) isEqualTo "w") then {
            ["Stop the open window? Attendance for it closes now.", {
                [player, "stop", ""] remoteExec [QFUNC(windowSet), 2];
            }] call FUNC(uiConfirm);
        } else {
            ["windowStart"] call FUNC(uiGo);
        };
    }],
    ["ATTENDANCE REPORT", {
        [player, "report", ""] remoteExec [QFUNC(adminText), 2];
        ["The report goes to your clipboard and the .rpt when it arrives.", false] call FUNC(uiHint);
    }]
]] call FUNC(uiButtons);
