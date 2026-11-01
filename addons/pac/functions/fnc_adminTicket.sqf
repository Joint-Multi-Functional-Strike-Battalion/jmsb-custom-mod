#include "script_component.hpp"
/*
    File: fnc_adminTicket.sqf
    Author: YonV
    Description: An admin adds to a PAC action - a reply, a private note, a
        state change - the website's jmfsbd_ticket_reply, on the server.
        The ticket is read (cache or database), the reply appended, the
        document written, and the whole list sent back to the admin.

    Parameters:
        0: The admin <OBJECT>
        1: Ticket id <STRING>
        2: Reply text <STRING> - may be "" when only the state changes
        3: New state <STRING> - "" to leave it
        4: Private <BOOL>

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_id", "", [""]], ["_text", "", [""]], ["_status", "", [""]], ["_private", false, [false]]];

if (!isServer || isNull _caller || _id isEqualTo "") exitWith {};
if !([_caller] call FUNC(isAdminCaller)) exitWith {WARNING_1("adminTicket refused: %1 is not an admin",name _caller)};
if (_text isEqualTo "" && _status isEqualTo "") exitWith {};
if (_status isNotEqualTo "" && {!(_status in ["open", "accepted", "declined", "closed"])}) exitWith {};

[_caller, _id, _text, _status, _private] spawn {
    params ["_caller", "_id", "_text", "_status", "_private"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _key = _unit + ".ticket." + _id;
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
    private _fnc_tell = {
        params ["_msg", "_bad"];
        ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };

    private _t = GVAR(docCache) get _key;
    if (isNil "_t") then {
        ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
        if (_s isNotEqualTo "ok") exitWith {};
        _t = _d;
    };
    if (isNil "_t" || {!(_t isEqualType createHashMap)}) exitWith {["No such PAC action.", true] call _fnc_tell};

    private _now = [] call FUNC(stamp);
    private _replies = _t getOrDefault ["replies", []];
    if !(_replies isEqualType []) then {_replies = []};
    private _reply = createHashMapFromArray [
        ["at", _now], ["byUid", getPlayerUID _caller], ["byName", name _caller],
        ["text", _text select [0, 8000]], ["private", _private]
    ];
    if (_status isNotEqualTo "") then {_reply set ["status", _status]};
    _replies pushBack _reply;
    _t set ["replies", _replies];
    _t set ["updatedAt", _now];
    if (_status isNotEqualTo "") then {
        _t set ["status", _status];
        _t set ["decidedBy", getPlayerUID _caller];
        _t set ["decidedAt", _now];
    };
    _t deleteAt "_id";

    if !([_key, [_t, ""] call FUNC(toJson)] call FUNC(svcSave)) exitWith {["The database did not take the reply.", true] call _fnc_tell};
    GVAR(docCache) set [_key, _t];
    [getPlayerUID _caller, name _caller, "ticket", _t getOrDefault ["raisedBy", ""], format ["%1: %2%3", _id, [_text select [0, 80], "(private note)"] select _private, ["", format [" - marked %1", _status]] select (_status isNotEqualTo "")]] call FUNC(logAction);

    // the whole list back, from the cache, so the page redraws with it
    private _prefix = _unit + ".ticket.";
    private _all = (keys GVAR(docCache)) select {(_x select [0, count _prefix]) isEqualTo _prefix};
    private _docs = _all apply {GVAR(docCache) get _x};
    _docs = [_docs, "updatedAt", false] call FUNC(docsSort);
    GVAR(ticketsOpen) = count (_docs select {(_x getOrDefault ["status", "open"]) isEqualTo "open"});
    ["tickets", _docs] remoteExec [QFUNC(uiRecv), owner _caller];
    [] call FUNC(publish);
    [format ["%1 updated.", _id], false] call _fnc_tell;
};
