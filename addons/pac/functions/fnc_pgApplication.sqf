#include "script_component.hpp"
/*
    File: fnc_pgApplication.sqf
    Author: YonV
    Description: One application - the website's open card: every question
        and its answer, then ACCEPT AND ADD TO ROSTER / NOT THIS TIME, or
        REOPEN once it has been decided.

    Parameters:
        None - reads GVAR(uiArgs): id (the Steam id)

    Returns:
        Nothing
*/

private _id = GVAR(uiArgs) getOrDefault ["id", ""];
if !(["applications"] call FUNC(uiAsk)) exitWith {};
if !(["questions"] call FUNC(uiAsk)) exitWith {};

private _apps = GVAR(uiData) getOrDefault ["applications", []];
private _at = _apps findIf {(_x getOrDefault ["steamId", ""]) isEqualTo _id};
if (_at < 0) exitWith {["Application", "Applications"] call FUNC(uiTitle); ["No such application.", true] call FUNC(uiHint)};
private _app = _apps # _at;
private _status = _app getOrDefault ["status", "new"];

[_app getOrDefault ["name", _id], format ["Applications  -  %1  -  %2  -  submitted %3", _id, toUpper _status, _app getOrDefault ["submittedAt", ""]]] call FUNC(uiTitle);

private _answers = _app getOrDefault ["answers", createHashMap];
if !(_answers isEqualType createHashMap) then {_answers = createHashMap};
// a "skills" answer is a list of skill ids - named off the question's choices, else the structure
private _fnc_text = {
    params ["_a", ["_choices", []]];
    if (_a isEqualType "") exitWith {_a};
    if !(_a isEqualType []) exitWith {str _a};
    private _names = createHashMapFromArray _choices;
    (_a apply {
        private _sid = if (_x isEqualType "") then {_x} else {str _x};
        _names getOrDefault [_sid, ["skills", _sid] call FUNC(lookup)]
    }) joinString ", "
};
private _rows = [];
private _seen = [];
{
    private _qid = _x getOrDefault ["id", ""];
    _seen pushBack _qid;
    private _a = [_answers getOrDefault [_qid, ""], _x getOrDefault ["choices", []]] call _fnc_text;
    _rows pushBack [[_x getOrDefault ["label", _qid], _a], ""];
} forEach (GVAR(uiData) getOrDefault ["questions", []]);
{
    if !(_x in _seen) then {
        private _a = [_answers get _x] call _fnc_text;
        _rows pushBack [[format ["%1 (question removed)", _x], _a], "", [0.545, 0.592, 0.639, 1]];
    };
} forEach (keys _answers);
[PAC_IDC_LIST, ["Question", "Answer"], [0, 0.34], _rows, {}, PAC_UI_TOP, PAC_UI_BOTTOM - PAC_UI_TOP, "What was answered"] call FUNC(uiList);

private _btns = [];
if (_status isEqualTo "new") then {
    _btns pushBack ["ACCEPT, ADD TO ROSTER", {
        [player, GVAR(uiArgs) get "id", "accepted"] remoteExec [QFUNC(adminApplication), 2];
        GVAR(uiWaiting) pushBackUnique "applications";
        ["Accepting ...", false] call FUNC(uiHint);
    }];
    _btns pushBack ["NOT THIS TIME", {
        [player, GVAR(uiArgs) get "id", "rejected"] remoteExec [QFUNC(adminApplication), 2];
        GVAR(uiWaiting) pushBackUnique "applications";
        ["Declining ...", false] call FUNC(uiHint);
    }, true];
} else {
    _btns pushBack ["REOPEN", {
        [player, GVAR(uiArgs) get "id", "new"] remoteExec [QFUNC(adminApplication), 2];
        GVAR(uiWaiting) pushBackUnique "applications";
        ["Reopening ...", false] call FUNC(uiHint);
    }];
};
[_btns] call FUNC(uiButtons);
