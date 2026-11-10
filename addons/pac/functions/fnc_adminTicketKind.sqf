#include "script_component.hpp"
/*
    File: fnc_adminTicketKind.sqf
    Author: YonV
    Description: Add, change or remove a PAC request kind - the website's
        Templates > System > PAC requests, on the server. The list is one
        document, <unit>.system.ticketKinds; the whole of it is written
        back and sent to every machine, so the tacpad's picker is current.

    Parameters:
        0: The admin <OBJECT>
        1: Op <STRING> - "set" | "remove"
        2: Id <STRING>
        3: Label <STRING>
        4: Hint <STRING>

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_op", "set", [""]], ["_id", "", [""]], ["_label", "", [""]], ["_hint", "", [""]]];

if (!isServer || isNull _caller || _id isEqualTo "") exitWith {};
if !([_caller] call FUNC(isAdminCaller)) exitWith {WARNING_1("adminTicketKind refused: %1 is not an admin",name _caller)};

[_caller, _op, _id, _label, _hint] spawn {
    params ["_caller", "_op", "_id", "_label", "_hint"];
    private _unit = GVAR(settings) getOrDefault ["unitId", ""];
    private _key = _unit + ".system.ticketKinds";
    if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
    private _fnc_tell = {
        params ["_msg", "_bad"];
        ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
    };

    ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
    if (_s isEqualTo "error") exitWith {["The database did not answer.", true] call _fnc_tell};
    private _items = _d getOrDefault ["items", createHashMap];
    if !(_items isEqualType createHashMap) then {_items = createHashMap};

    if (_op isEqualTo "remove") then {
        _items deleteAt _id;
    } else {
        if (_label isEqualTo "") then {_label = _id};
        _items set [_id, createHashMapFromArray [["label", _label], ["hint", _hint]]];
    };
    if (count _items isEqualTo 0) exitWith {["With no kinds nobody can raise a request at all - leave at least one.", true] call _fnc_tell};

    private _doc = createHashMapFromArray [["section", "system"], ["id", "ticketKinds"], ["items", _items], ["from", "edited in game"], ["updatedAt", [] call FUNC(stamp)]];
    if !([_key, [_doc, ""] call FUNC(toJson)] call FUNC(svcSave)) exitWith {["The database did not take it.", true] call _fnc_tell};
    GVAR(docCache) set [_key, _doc];
    GVAR(ticketKinds) = _items;
    publicVariable QGVAR(ticketKinds);
    ["ticketKinds", _items] remoteExec [QFUNC(uiRecv), owner _caller];
    [getPlayerUID _caller, name _caller, "system", "", format ["ticket kind %1 %2", _id, ["set", "removed"] select (_op isEqualTo "remove")]] call FUNC(logAction);
    [format ["Request kind %1 %2.", _id, ["saved", "removed"] select (_op isEqualTo "remove")], false] call _fnc_tell;
};
