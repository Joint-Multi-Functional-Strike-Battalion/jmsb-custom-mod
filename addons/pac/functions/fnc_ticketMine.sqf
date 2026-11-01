#include "script_component.hpp"
/*
    File: fnc_ticketMine.sqf
    Author: YonV
    Description: A member's own PAC requests, for the tacpad's PAC tile -
        the ones they raised or that are about them, with the private notes
        taken out, the website's jmfsbd_my_tickets and
        jmfsbd_ticket_for_reader in one. Server only; answers with
        FUNC(ticketMineRecv) on the asker.

    Parameters:
        0: Who <OBJECT>

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]]];

if (!isServer || isNull _caller) exitWith {};
// Only the sender's own requests (review S5).
if !([_caller] call EFUNC(common,senderIs)) exitWith {};
if ((GVAR(settings) getOrDefault ["sync", "off"]) isNotEqualTo "service") exitWith {
    [[], false] remoteExec [QFUNC(ticketMineRecv), owner _caller];
};

[_caller] spawn {
    params ["_caller"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _uid = getPlayerUID _caller;
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
    private _prefix = _unit + ".ticket.";

    ([_prefix, "list"] call FUNC(svcLoad)) params ["_keys", "_status"];
    if (_status isEqualTo "error" || !(_keys isEqualType [])) exitWith {[[], false] remoteExec [QFUNC(ticketMineRecv), owner _caller]};

    private _out = [];
    {
        private _key = _x;
        private _doc = GVAR(docCache) get _key;
        if (isNil "_doc") then {
            ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
            if (_s isEqualTo "ok") then {
                _doc = _d;
                GVAR(docCache) set [_key, _d];
            };
        };
        if (isNil "_doc" || {!(_doc isEqualType createHashMap)}) then {continue};
        if ((_doc getOrDefault ["raisedBy", ""]) isNotEqualTo _uid && {(_doc getOrDefault ["about", ""]) isNotEqualTo _uid}) then {continue};
        private _t = +_doc;
        private _replies = _t getOrDefault ["replies", []];
        if !(_replies isEqualType []) then {_replies = []};
        _t set ["replies", _replies select {_x isEqualType createHashMap && {!(_x getOrDefault ["private", false])}}];
        _out pushBack _t;
    } forEach _keys;
    _out = [_out, "updatedAt", false] call FUNC(docsSort);

    if (isNil QGVAR(ticketKinds) || {count GVAR(ticketKinds) isEqualTo 0}) then {
        ([_unit + ".system.ticketKinds"] call FUNC(svcLoad)) params ["_d", "_s"];
        private _items = if (_s isEqualTo "ok") then {_d getOrDefault ["items", createHashMap]} else {createHashMap};
        if !(_items isEqualType createHashMap) then {_items = createHashMap};
        GVAR(ticketKinds) = _items;
        publicVariable QGVAR(ticketKinds);
    };
    [_out, true] remoteExec [QFUNC(ticketMineRecv), owner _caller];
};
