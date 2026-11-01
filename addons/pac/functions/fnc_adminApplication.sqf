#include "script_component.hpp"
/*
    File: fnc_adminApplication.sqf
    Author: YonV
    Description: Decide an application - the website's Accept / Not this
        time / Reopen, on the server. Accepting seeds a record for the
        applicant the way a first connect does, so they are on the roster
        before they play.

    Parameters:
        0: The admin <OBJECT>
        1: The applicant's Steam id <STRING>
        2: New status <STRING> - "accepted" | "rejected" | "new"

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_steamId", "", [""]], ["_status", "", [""]]];

if (!isServer || isNull _caller || _steamId isEqualTo "") exitWith {};
if !([_caller] call FUNC(isAdminCaller)) exitWith {WARNING_1("adminApplication refused: %1 is not an admin",name _caller)};
if !(_status in ["accepted", "rejected", "new"]) exitWith {};

[_caller, _steamId, _status] spawn {
    params ["_caller", "_steamId", "_status"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _key = _unit + ".application." + _steamId;
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
    private _fnc_tell = {
        params ["_msg", "_bad"];
        ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };

    private _doc = GVAR(docCache) get _key;
    if (isNil "_doc") then {
        ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
        if (_s isEqualTo "ok") then {_doc = _d};
    };
    if (isNil "_doc" || {!(_doc isEqualType createHashMap)}) exitWith {["No such application.", true] call _fnc_tell};

    private _now = [] call FUNC(stamp);
    _doc set ["status", _status];
    if (_status isEqualTo "new") then {
        _doc deleteAt "decidedAt";
        _doc deleteAt "decidedBy";
    } else {
        _doc set ["decidedAt", _now];
        _doc set ["decidedBy", getPlayerUID _caller];
    };
    _doc deleteAt "_id";
    if !([_key, [_doc, ""] call FUNC(toJson)] call FUNC(svcSave)) exitWith {["The database did not take it.", true] call _fnc_tell};
    GVAR(docCache) set [_key, _doc];

    if (_status isEqualTo "accepted" && {!(_steamId in GVAR(players))}) then {
        [_steamId, _doc getOrDefault ["name", ""]] call FUNC(record);
        [] call FUNC(storeSave);
    };
    [getPlayerUID _caller, name _caller, "application", _steamId, format ["%1 %2", _doc getOrDefault ["name", _steamId], _status]] call FUNC(logAction);

    private _prefix = _unit + ".application.";
    private _docs = ((keys GVAR(docCache)) select {(_x select [0, count _prefix]) isEqualTo _prefix}) apply {GVAR(docCache) get _x};
    _docs = [_docs, "submittedAt", false] call FUNC(docsSort);
    GVAR(applicationsNew) = count (_docs select {(_x getOrDefault ["status", "new"]) isEqualTo "new"});
    ["applications", _docs] remoteExec [QFUNC(uiRecv), owner _caller];
    [] call FUNC(publish);
    [format ["%1: %2.", _doc getOrDefault ["name", _steamId], _status], false] call _fnc_tell;
};
