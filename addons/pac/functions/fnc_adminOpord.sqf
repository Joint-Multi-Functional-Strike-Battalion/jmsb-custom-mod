#include "script_component.hpp"
/*
    File: fnc_adminOpord.sqf
    Author: YonV
    Description: Write an operation order - the website's ?page=opord, on
        the server: create one, save one section of one, remove one. The
        order lives in the structure's "opords" (and the archive the tacpad
        reads); it is persisted as its own document, <unit>.opord.<id>, the
        shape the boot reads (FUNC(structurePersist) "opords").

    Parameters:
        0: The admin <OBJECT>
        1: Op <STRING> - "create" | "set" | "remove"
        2: Order id <STRING>
        3: Section <STRING> - for "set"; "header" for "create"
        4: Fields <HASHMAP> - the section's fields; for "create", {title}

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_op", "", [""]], ["_id", "", [""]], ["_section", "", [""]], ["_fields", createHashMap, [createHashMap]]];

if (!isServer || isNull _caller || _id isEqualTo "") exitWith {};
if !([_caller] call FUNC(isAdminCaller)) exitWith {WARNING_1("adminOpord refused: %1 is not an admin",name _caller)};
if (GVAR(readOnly)) exitWith {};
if (["opords"] call FUNC(fileFed)) exitWith {
    ["TAC//PAC", "The orders come from the mission's config folder and there is no database - the game cannot write them.", [0.831, 0.267, 0.267, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};
private _fnc_tell = {
    params ["_msg", "_bad"];
    ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};
if ((toArray _id) findIf {!(_x isEqualTo 95 || {_x >= 48 && _x <= 57} || {_x >= 97 && _x <= 122})} >= 0) exitWith {["An order id is lower case letters, digits and underscore.", true] call _fnc_tell};

private _opords = GVAR(structure) getOrDefault ["opords", createHashMap];
if !(_opords isEqualType createHashMap) then {_opords = createHashMap};
private _detail = "";

switch (_op) do {
    case "create": {
        if (_id in _opords) exitWith {[format ["There is already an order %1.", _id], true] call _fnc_tell};
        private _o = createHashMap;
        {_o set [_x # 0, createHashMap]} forEach ([] call FUNC(opordDef));
        _o set ["id", _id];
        private _hdr = _o getOrDefault ["header", createHashMap];
        _hdr set ["id", _id];
        _hdr set ["title", _fields getOrDefault ["title", ""]];
        _o set ["header", _hdr];
        _opords set [_id, _o];
        _detail = format ["order %1 created", _id];
    };
    case "set": {
        if !(_id in _opords) exitWith {[format ["No order %1.", _id], true] call _fnc_tell};
        private _o = _opords get _id;
        private _sec = _o getOrDefault [_section, createHashMap];
        if !(_sec isEqualType createHashMap) then {_sec = createHashMap};
        {
            if (_y isEqualTypeAny ["", []]) then {_sec set [_x, _y]};
        } forEach _fields;
        _o set [_section, _sec];
        _opords set [_id, _o];
        _detail = format ["order %1: %2 written", _id, _section];
    };
    case "remove": {
        if !(_id in _opords) exitWith {[format ["No order %1.", _id], true] call _fnc_tell};
        _opords deleteAt _id;
        _detail = format ["order %1 removed", _id];
    };
    default {};
};
if (_detail isEqualTo "") exitWith {};

GVAR(structure) set ["opords", _opords];
// the archive the tacpad lists from keeps every order ever compiled
if (_op isNotEqualTo "remove") then {
    private _arch = missionNamespace getVariable [QGVAR(opordArchive), createHashMap];
    private _copy = +(_opords get _id);
    _copy set ["archivedAt", [] call FUNC(stamp)];
    _arch set [_id, _copy];
    GVAR(opordArchive) = _arch;
};
[getPlayerUID _caller, name _caller, "opord", "", _detail] call FUNC(logAction);
["opords", _id] call FUNC(structurePersist);
INFO_2("%1: %2",name _caller,_detail);
[_detail + ".", false] call _fnc_tell;
