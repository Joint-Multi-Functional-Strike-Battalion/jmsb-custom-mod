#include "script_component.hpp"
/*
 * Author: YonV
 * Gets a mailbox, creating it if it does not exist yet. Everything is a
 * mailbox: a player, a group and a shared filing box differ only in how their
 * membership is worked out, so there is one record type and one lookup.
 *
 * An id with no prefix is taken to be a shared mailbox name, so a mission that
 * addresses "HQ" and a mission that addresses "B:HQ" reach the same box.
 *
 * Arguments:
 * 0: Box id or bare name <STRING>
 * 1: Kind - "personal", "group" or "named" <STRING> (optional, derived from the id)
 * 2: Display name <STRING> (optional, derived from the id)
 *
 * Return Value:
 * 0: Normalised box id <STRING>
 * 1: Box <HASHMAP>
 *
 * Example:
 * (["B:HQ"] call jmfsb_messaging_fnc_srvBox) params ["_id", "_box"]
 *
 * Public: No
 */

params [["_id", "", [""]], ["_kind", "", [""]], ["_displayName", "", [""]]];

_id = trim _id;
if (_id == "") exitWith {["", createHashMap]};

private _prefix = _id select [0, 2];
if !(_prefix in ["P:", "G:", "B:"]) then {
    _id = format ["B:%1", _id];
    _prefix = "B:";
};

private _rest = _id select [2];

if (_kind == "") then {
    _kind = switch (_prefix) do {
        case "P:": {"personal"};
        case "G:": {"group"};
        default {"named"};
    };
};

if (_displayName == "") then {
    _displayName = _rest;
};

private _box = GVAR(boxes) getOrDefault [_id, createHashMap];

if (_box isEqualTo createHashMap) then {
    _box = createHashMapFromArray [
        ["id", _id],
        ["kind", _kind],
        ["displayName", _displayName],
        ["roles", []],
        ["uids", []],
        // Only a shared box is worth keeping between missions. A personal box
        // belongs to a player who may never join again, and a group box belongs
        // to a group id that means something different next mission.
        ["retention", ["ephemeral", "archive"] select (_kind == "named")],
        ["forwardToAlive", _kind == "named"],
        ["threads", []]
    ];
    GVAR(boxes) set [_id, _box];
};

[_id, _box]
