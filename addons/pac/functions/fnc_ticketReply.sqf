#include "script_component.hpp"
/*
    File: fnc_ticketReply.sqf
    Author: YonV
    Description: A member adds to their own PAC request from the tacpad's PAC
        tile - the website's jmfsbd_ticket_reply as a member may use it: a
        reply, never a state change, never a private note. Only the person
        who raised it or the person it is about may; the server checks, not
        the tile. Answers with FUNC(ticketMine), so the tile redraws with the
        reply on it.

    Parameters:
        0: Who <OBJECT>
        1: Ticket id <STRING>
        2: Text <STRING>

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_id", "", [""]], ["_text", "", [""]]];

if (!isServer || isNull _caller || _id isEqualTo "") exitWith {};
// A reply goes in the sender's own name only (review S5).
if !([_caller] call EFUNC(common,senderIs)) exitWith {};
_text = trim _text;
if (_text isEqualTo "") exitWith {};
if ((GVAR(settings) getOrDefault ["sync", "off"]) isNotEqualTo "service") exitWith {
    ["TAC//PAC", "PAC requests need the database, and this server has none.", [0.831, 0.267, 0.267, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

[_caller, _id, _text] spawn {
    params ["_caller", "_id", "_text"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _key = _unit + ".ticket." + _id;
    private _uid = getPlayerUID _caller;
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
    private _fnc_tell = {
        params ["_msg", "_bad"];
        ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };

    private _t = GVAR(docCache) get _key;
    if (isNil "_t") then {
        ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
        if (_s isEqualTo "ok") then {_t = _d};
    };
    if (isNil "_t" || {!(_t isEqualType createHashMap)}) exitWith {["No such request.", true] call _fnc_tell};
    if ((_t getOrDefault ["raisedBy", ""]) isNotEqualTo _uid && {(_t getOrDefault ["about", ""]) isNotEqualTo _uid}) exitWith {
        WARNING_2("ticketReply refused: %1 is not on %2",name _caller,_id);
        ["That is not yours to reply to.", true] call _fnc_tell;
    };

    private _now = [] call FUNC(stamp);
    private _replies = _t getOrDefault ["replies", []];
    if !(_replies isEqualType []) then {_replies = []};
    _replies pushBack (createHashMapFromArray [
        ["at", _now], ["byUid", _uid], ["byName", name _caller], ["text", _text select [0, 8000]], ["private", false]
    ]);
    _t set ["replies", _replies];
    _t set ["updatedAt", _now];
    _t deleteAt "_id";

    if !([_key, [_t, ""] call FUNC(toJson)] call FUNC(svcSave)) exitWith {["The database did not take the reply.", true] call _fnc_tell};
    GVAR(docCache) set [_key, _t];
    [_uid, name _caller, "ticket", _t getOrDefault ["about", ""], format ["%1: replied - %2", _id, _text select [0, 80]]] call FUNC(logAction);
    [format ["Reply added to %1.", _id], false] call _fnc_tell;
    [_caller] call FUNC(ticketMine);
};
