#include "script_component.hpp"
/*
    File: fnc_adminTemplate.sqf
    Author: YonV
    Description: Write a report-deck template - the website's
        ?page=template_edit, on the server. The record is the tacpad's
        registerTemplate shape, {id, title, short, lines, options}, checked
        for that shape and stored whole in the structure's "templates";
        FUNC(structurePersist) writes <unit>.templates and every machine
        re-registers the deck.

    Parameters:
        0: The admin <OBJECT>
        1: Op <STRING> - "set" | "remove"
        2: Template id <STRING>
        3: The template <HASHMAP>

    Returns:
        Nothing
*/

params [["_caller", objNull, [objNull]], ["_op", "set", [""]], ["_id", "", [""]], ["_rec", createHashMap, [createHashMap]]];

if (!isServer || isNull _caller || _id isEqualTo "") exitWith {};
if !([_caller] call FUNC(isAdminCaller)) exitWith {WARNING_1("adminTemplate refused: %1 is not an admin",name _caller)};
if (GVAR(readOnly)) exitWith {};
private _fnc_tell = {
    params ["_msg", "_bad"];
    ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};
if (["templates"] call FUNC(fileFed)) exitWith {["The deck comes from the mission's config folder and there is no database - the game cannot write it.", true] call _fnc_tell};
if ((toArray _id) findIf {!(_x isEqualTo 95 || {_x >= 48 && _x <= 57} || {_x >= 97 && _x <= 122})} >= 0) exitWith {["A template id is lower case letters, digits and underscore.", true] call _fnc_tell};

private _items = GVAR(structure) getOrDefault ["templates", createHashMap];
if !(_items isEqualType createHashMap) then {_items = createHashMap};

if (_op isEqualTo "remove") then {
    if !(_id in _items) exitWith {[format ["No template %1.", _id], true] call _fnc_tell};
    _items deleteAt _id;
} else {
    // the shape, and nothing outside it
    private _lines = _rec getOrDefault ["lines", []];
    if !(_lines isEqualType []) then {_lines = []};
    _lines = _lines select {_x isEqualType [] && {count _x >= 2}};
    _lines = _lines apply {
        private _fields = _x param [2, []];
        if !(_fields isEqualType []) then {_fields = []};
        _fields = (_fields select {_x isEqualType [] && {count _x >= 3}}) apply {
            private _opts = _x param [3, []];
            if !(_opts isEqualType []) then {_opts = []};
            [_x # 0, _x # 1, _x # 2, _opts select {_x isEqualType [] && {count _x >= 2}}]
        };
        [_x # 0, _x # 1, _fields]
    };
    private _options = _rec getOrDefault ["options", []];
    if !(_options isEqualType []) then {_options = []};
    _options = _options select {_x isEqualType [] && {count _x >= 2 && {(_x # 0) isEqualType ""}}};
    private _clean = createHashMapFromArray [
        ["id", _id],
        ["title", _rec getOrDefault ["title", _id]],
        ["short", _rec getOrDefault ["short", ""]],
        ["lines", _lines],
        ["options", _options]
    ];
    _items set [_id, _clean];
};

GVAR(structure) set ["templates", _items];
[getPlayerUID _caller, name _caller, "structure", "", format ["template %1 %2", _id, ["set", "removed"] select (_op isEqualTo "remove")]] call FUNC(logAction);
["templates"] call FUNC(structurePersist);
[format ["Template %1 %2 - the deck re-registers everywhere.", _id, ["saved", "removed"] select (_op isEqualTo "remove")], false] call _fnc_tell;
