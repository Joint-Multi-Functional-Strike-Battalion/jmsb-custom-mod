#include "script_component.hpp"
/*
    File: fnc_ticketRaise.sqf
    Author: YonV
    Description: A member raises a PAC request from the tacpad's PAC tile -
        the website's jmfsbd_ticket_raise, on the server. Anybody playing
        may; the raiser is who asked, never who they claim. The document is
        <unit>.ticket.TKT-nnnnn, the shape the website reads.

    Parameters:
        0: Who <OBJECT>
        1: Kind <STRING> - one of <unit>.system.ticketKinds
        2: Subject <STRING>
        3: Body <STRING>
        4: About <STRING> - a uid, or ""

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_kind", "", [""]], ["_subject", "", [""]], ["_body", "", [""]], ["_about", "", [""]]];

if (!isServer || isNull _caller) exitWith {};
// A request is raised in the sender's own name only (review S5).
if !([_caller] call EFUNC(common,senderIs)) exitWith {};
if ((GVAR(settings) getOrDefault ["sync", "off"]) isNotEqualTo "service") exitWith {
    ["TAC//PAC", "PAC requests need the database, and this server has none.", [0.831, 0.267, 0.267, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

[_caller, _kind, _subject, _body, _about] spawn {
    params ["_caller", "_kind", "_subject", "_body", "_about"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
    private _fnc_tell = {
        params ["_msg", "_bad"];
        ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };

    // the kinds, if nobody has read them yet
    if (isNil QGVAR(ticketKinds) || {count GVAR(ticketKinds) isEqualTo 0}) then {
        ([_unit + ".system.ticketKinds"] call FUNC(svcLoad)) params ["_d", "_s"];
        private _items = if (_s isEqualTo "ok") then {_d getOrDefault ["items", createHashMap]} else {createHashMap};
        if !(_items isEqualType createHashMap) then {_items = createHashMap};
        GVAR(ticketKinds) = _items;
        publicVariable QGVAR(ticketKinds);
    };
    if !(_kind in GVAR(ticketKinds)) exitWith {["Pick what kind of request this is.", true] call _fnc_tell};
    _subject = trim _subject;
    if (_subject isEqualTo "") exitWith {["Give it a one-line subject.", true] call _fnc_tell};
    if (_about isNotEqualTo "" && {(toArray _about) findIf {!(_x >= 48 && _x <= 57)} >= 0}) then {_about = ""};

    // the next id: TKT-nnnnn, one past the highest there is
    ([_unit + ".ticket.", "list"] call FUNC(svcLoad)) params ["_keys", "_status"];
    if (_status isEqualTo "error") exitWith {["The database did not answer - try again in a moment.", true] call _fnc_tell};
    private _max = 0;
    if (_keys isEqualType []) then {
        {
            private _at = _x find "TKT-";
            if (_at >= 0) then {_max = _max max (parseNumber (_x select [_at + 4]))};
        } forEach _keys;
    };
    private _n = str (_max + 1);
    while {count _n < 5} do {_n = "0" + _n};
    private _id = "TKT-" + _n;

    private _uid = getPlayerUID _caller;
    private _now = [] call FUNC(stamp);
    private _doc = createHashMapFromArray [
        ["section", "ticket"], ["id", _id], ["kind", _kind], ["subject", _subject select [0, 200]],
        ["raisedBy", _uid], ["raisedByName", name _caller], ["about", _about], ["status", "open"],
        ["createdAt", _now], ["updatedAt", _now],
        ["replies", [createHashMapFromArray [["at", _now], ["byUid", _uid], ["byName", name _caller], ["text", (trim _body) select [0, 8000]]]]]
    ];
    private _key = _unit + ".ticket." + _id;
    if !([_key, [_doc, ""] call FUNC(toJson)] call FUNC(svcSave)) exitWith {["The database did not take it.", true] call _fnc_tell};
    GVAR(docCache) set [_key, _doc];
    GVAR(ticketsOpen) = (GVAR(ticketsOpen) max 0) + 1;
    [_uid, name _caller, "ticket", _about, format ["%1 raised: %2 - %3", _id, _kind, _subject select [0, 80]]] call FUNC(logAction);
    [] call FUNC(publish);
    [format ["%1 raised - an admin will see it under PAC actions.", _id], false] call _fnc_tell;
    [_caller] call FUNC(ticketMine);
};
