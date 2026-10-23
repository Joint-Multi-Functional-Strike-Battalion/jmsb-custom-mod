#include "script_component.hpp"
/*
    File: fnc_applySubmit.sqf
    Author: YonV
    Description: A player sends their application from the tacpad - the
        website's jmfsbd_application_submit, on the server: the document is
        <unit>.application.<steamId>, the id is the asker's own and never
        posted, a decided application is not overwritten, the required
        questions must be answered. An admin accepts it under APPLICATIONS,
        which seeds the record and puts them on the roster.

    Parameters:
        0: Who <OBJECT>
        1: Answers <HASHMAP> - question id -> answer (text, or an ARRAY of
           skill ids for a "skills" question)

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_answers", createHashMap, [createHashMap]]];

if (!isServer || isNull _caller) exitWith {};
if ((GVAR(settings) getOrDefault ["sync", "off"]) isNotEqualTo "service") exitWith {
    ["TAC//PAC", "Applications need the database, and this server has none.", [0.831, 0.267, 0.267, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

[_caller, _answers] spawn {
    params ["_caller", "_answers"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _uid = getPlayerUID _caller;
    private _key = _unit + ".application." + _uid;
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
    private _fnc_tell = {
        params ["_msg", "_bad"];
        ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };

    private _questions = [] call FUNC(questionsLoad);
    // only the questions asked, as text, and every required one answered; a
    // "skills" question's answer is the list of ticked skill ids, kept only
    // where the unit still has the skill, and required means one ticked
    private _clean = createHashMap;
    private _missing = [];
    {
        private _qid = _x getOrDefault ["id", ""];
        private _a = _answers getOrDefault [_qid, ""];
        if ((toLower (_x getOrDefault ["type", "text"])) isEqualTo "skills") then {
            if !(_a isEqualType []) then {_a = []};
            _a = _a arrayIntersect ((_x getOrDefault ["choices", []]) apply {_x # 0});
            if (_a isEqualTo []) then {_a = ""} else {_clean set [_qid, _a]};
        } else {
            if !(_a isEqualType "") then {_a = str _a};
            _a = trim _a;
            if (_a isNotEqualTo "") then {_clean set [_qid, _a select [0, 4000]]};
        };
        if (_a isEqualTo "" && {(_x getOrDefault ["required", false]) in [true, 1, "1", "true"]}) then {_missing pushBack (_x getOrDefault ["label", _qid])};
    } forEach _questions;
    if (_missing isNotEqualTo []) exitWith {[format ["Still needed: %1.", _missing joinString ", "], true] call _fnc_tell};

    ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
    private _existing = [createHashMap, _d] select (_s isEqualTo "ok" && {_d isEqualType createHashMap});
    if (count _existing > 0 && {(_existing getOrDefault ["status", "new"]) isNotEqualTo "new"}) exitWith {
        ["Your application has already been decided - ask an admin if you want it reopened.", true] call _fnc_tell;
        [_existing] remoteExec [QFUNC(applyRecv), owner _caller];
    };

    private _now = [] call FUNC(stamp);
    private _doc = createHashMapFromArray [
        ["section", "application"], ["steamId", _uid], ["name", name _caller],
        ["answers", _clean], ["status", "new"],
        ["submittedAt", [_now, _existing getOrDefault ["submittedAt", _now]] select (count _existing > 0)]
    ];
    if (count _existing > 0) then {_doc set ["updatedAt", _now]};
    if !([_key, [_doc, ""] call FUNC(toJson)] call FUNC(svcSave)) exitWith {["The database did not take it - try again in a moment.", true] call _fnc_tell};
    GVAR(docCache) set [_key, _doc];
    if (count _existing isEqualTo 0) then {GVAR(applicationsNew) = (GVAR(applicationsNew) max 0) + 1};
    [_uid, name _caller, "application", _uid, ["application updated", "application sent"] select (count _existing isEqualTo 0)] call FUNC(logAction);
    [] call FUNC(publish);
    [["Your application is updated.", "Your application is in - an admin will see it under APPLICATIONS."] select (count _existing isEqualTo 0), false] call _fnc_tell;
    [_doc] remoteExec [QFUNC(applyRecv), owner _caller];
};
