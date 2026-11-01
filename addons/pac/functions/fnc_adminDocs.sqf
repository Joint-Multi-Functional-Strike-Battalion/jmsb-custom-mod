#include "script_component.hpp"
/*
    File: fnc_adminDocs.sqf
    Author: YonV
    Description: Read documents from the database for an admin's screen.
        Server only, answered by remoteExec to FUNC(uiRecv) on the asker.

        THE ONE ROAD FROM A CLIENT TO THE DATABASE. FUNC(svcLoad) runs on
        the server and nowhere else; a page that needs the tickets, the
        applications, the document list, one document, the request kinds or
        the order definition asks here, by name, and the answer comes back
        under that name.

        ONE FETCH EACH, THEN THE CACHE. The extension answers one document
        per round trip (about a second and a half each - see the boot's
        role read), so what has been read is kept in GVAR(docCache) and a
        prefix list only fetches the keys not yet in it. REFRESH on a page
        passes "fresh" and the cache for that prefix is dropped first.

    Parameters:
        0: The admin asking <OBJECT>
        1: What <STRING> - "tickets" | "applications" | "questions" |
           "ticketKinds" | "docs" | "doc:<key>" | "opordDef"
        2: Arguments <ARRAY> (optional) - ["fresh"] to bypass the cache

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_what", "", [""]], ["_args", [], [[]]]];

if (!isServer || isNull _caller || _what isEqualTo "") exitWith {};
if !([_caller] call FUNC(isAdminCaller)) exitWith {
    WARNING_2("adminDocs refused: %1 is not an admin (%2)",name _caller,_what);
};
if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};

[_caller, _what, _args] spawn {
    params ["_caller", "_what", "_args"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _fresh = "fresh" in _args;
    private _fnc_tell = {
        params ["_msg"];
        ["TAC//PAC", _msg, [0.831, 0.267, 0.267, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };
    private _fnc_reply = {
        params ["_name", "_payload"];
        [_name, _payload] remoteExec [QFUNC(uiRecv), owner _caller];
    };

    // every document under a prefix, as an array of hashmaps, cached by key
    private _fnc_prefix = {
        params ["_prefix"];
        if (_fresh) then {{if ((_x select [0, count _prefix]) isEqualTo _prefix) then {GVAR(docCache) deleteAt _x}} forEach (keys GVAR(docCache))};
        ([_prefix, "list"] call FUNC(svcLoad)) params ["_keys", "_status"];
        if (_status isEqualTo "error" || !(_keys isEqualType [])) exitWith {[[], false]};
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
            if (!isNil "_doc" && {_doc isEqualType createHashMap}) then {_out pushBack _doc};
        } forEach _keys;
        [_out, true]
    };
    private _fnc_one = {
        params ["_key"];
        if (_fresh) then {GVAR(docCache) deleteAt _key};
        private _doc = GVAR(docCache) get _key;
        if (isNil "_doc") then {
            ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
            if (_s isEqualTo "ok") then {
                _doc = _d;
                GVAR(docCache) set [_key, _d];
            } else {_doc = createHashMap};
        };
        _doc
    };

    switch (true) do {
        case (_what isEqualTo "tickets"): {
            ([_unit + ".ticket."] call _fnc_prefix) params ["_docs", "_ok"];
            if (!_ok) exitWith {["The database did not answer the ticket list."] call _fnc_tell};
            _docs = [_docs, "updatedAt", false] call FUNC(docsSort);
            GVAR(ticketsOpen) = count (_docs select {(_x getOrDefault ["status", "open"]) isEqualTo "open"});
            ["tickets", _docs] call _fnc_reply;
            [] call FUNC(publish);
        };
        case (_what isEqualTo "applications"): {
            ([_unit + ".application."] call _fnc_prefix) params ["_docs", "_ok"];
            if (!_ok) exitWith {["The database did not answer the application list."] call _fnc_tell};
            _docs = [_docs, "submittedAt", false] call FUNC(docsSort);
            GVAR(applicationsNew) = count (_docs select {(_x getOrDefault ["status", "new"]) isEqualTo "new"});
            ["applications", _docs] call _fnc_reply;
            [] call FUNC(publish);
        };
        case (_what isEqualTo "questions"): {
            ["questions", [_fresh] call FUNC(questionsLoad)] call _fnc_reply;
        };
        case (_what isEqualTo "ticketKinds"): {
            private _doc = [_unit + ".system.ticketKinds"] call _fnc_one;
            private _items = _doc getOrDefault ["items", createHashMap];
            if !(_items isEqualType createHashMap) then {_items = createHashMap};
            GVAR(ticketKinds) = _items;
            publicVariable QGVAR(ticketKinds);
            ["ticketKinds", _items] call _fnc_reply;
        };
        case (_what isEqualTo "opordDef"): {
            private _doc = [_unit + ".system.opord"] call _fnc_one;
            private _rows = _doc getOrDefault ["fields", []];
            if !(_rows isEqualType []) then {_rows = []};
            GVAR(opordDef) = _rows;
            publicVariable QGVAR(opordDef);
            ["opordDef", _rows] call _fnc_reply;
        };
        case (_what isEqualTo "docs"): {
            ([_unit, "list"] call FUNC(svcLoad)) params ["_keys", "_status"];
            if (_status isEqualTo "error" || !(_keys isEqualType [])) exitWith {["The database did not answer the document list."] call _fnc_tell};
            GVAR(docsCount) = count _keys;
            ["docs", _keys] call _fnc_reply;
            [] call FUNC(publish);
        };
        case ((_what select [0, 4]) isEqualTo "doc:"): {
            private _key = _what select [4];
            private _doc = [_key] call _fnc_one;
            [_what, [_doc, "    "] call FUNC(toJson)] call _fnc_reply;
        };
        default {
            WARNING_1("adminDocs: nothing called '%1'",_what);
        };
    };
};
