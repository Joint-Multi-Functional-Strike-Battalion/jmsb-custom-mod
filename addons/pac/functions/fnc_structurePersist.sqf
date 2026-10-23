#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_structurePersist

Description:
    Makes an in-game structure edit stick, everywhere the store does, and
    puts the new structure in front of every client. Server only.

        profile   GVAR(structureEdited) - the edited sections - goes into the
                  profile with the next save, and boot step 2 lays them over
                  the mission's config. For roles the profile keeps ONLY the
                  roles edited in game, by id; the mission's own fill the
                  rest at boot, so a role edited in a file is not frozen by
                  an unrelated edit made in game. "settings" is kept under
                  "_settings" (the three that say which server this is and
                  where it looks are never kept).
        service   the section's own document when the database is the
                  source (svcUp) - so the next boot, on any server, reads
                  what was edited:
                    <unit>.<section>       {section, items}   ranks, skills,
                                           awards, statuses, admins (+ ids),
                                           nets, radio, templates, schemes,
                                           settings
                    <unit>.role.<id>       {section: "role", id, role}  one
                                           document per role; a removed role
                                           is a tombstone {deleted: true},
                                           because the extension has no
                                           delete verb - the reader skips it
                    <unit>.orbat           {section, faction, side, groups,
                                           platoons}
        clients   GVAR(structureSvc) and GVAR(settingsSvc) republished; the
                  hash recomputed and published with the summary.

Parameters:
    0: Section <STRING> - a structure section, or "settings"
    1: Id <STRING> (optional) - roles only: persist this one role

Returns:
    Nothing

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_section", "", [""]], ["_id", "", [""]]];

if (!isServer || _section isEqualTo "") exitWith {};

private _items = GVAR(structure) getOrDefault [_section, createHashMap];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _now = [] call FUNC(stamp);

private _fnc_doc = {
    params ["_key", "_doc"];
    _doc set ["exportedAt", _now];
    _doc set ["from", "edited in game"];
    [_key, [_doc, ""] call FUNC(toJson)] call FUNC(svcSave);
};

private _fnc_roleDoc = {
    params ["_rid"];
    private _doc = if (_rid in _items) then {
        createHashMapFromArray [["section", "role"], ["id", _rid], ["role", _items get _rid]]
    } else {
        createHashMapFromArray [["section", "role"], ["id", _rid], ["deleted", true]]
    };
    [_unit + ".role." + _rid, _doc] call _fnc_doc;
};

switch (true) do {
    case (_section isEqualTo "settings"): {
        private _s = +GVAR(settings);
        {_s deleteAt _x} forEach ["unitId", "serverId", "sync"];
        GVAR(structureEdited) set ["_settings", _s];
        if (GVAR(svcUp)) then {[_unit + ".settings", createHashMapFromArray [["section", "settings"], ["items", _s]]] call _fnc_doc};
    };
    case (_section isEqualTo "roles" && _id isNotEqualTo ""): {
        private _edited = GVAR(structureEdited) getOrDefault ["roles", createHashMap, true];
        if (_id in _items) then {_edited set [_id, _items get _id]} else {_edited deleteAt _id};
        if (GVAR(svcUp)) then {[_id] call _fnc_roleDoc};
    };
    case (_section isEqualTo "roles"): {
        GVAR(structureEdited) set ["roles", _items];
        if (GVAR(svcUp)) then {{[_x] call _fnc_roleDoc} forEach (keys _items)};
    };
    // AN ORDER IS ITS OWN DOCUMENT, <unit>.opord.<id>, the way a role is -
    // and a removed one a tombstone the reader skips (2026-09-09).
    case (_section isEqualTo "opords"): {
        GVAR(structureEdited) set ["opords", _items];
        if (GVAR(svcUp) && _id isNotEqualTo "") then {
            private _doc = if (_id in _items) then {
                createHashMapFromArray [["section", "opord"], ["id", _id], ["order", _items get _id]]
            } else {
                createHashMapFromArray [["section", "opord"], ["id", _id], ["deleted", true]]
            };
            [_unit + ".opord." + _id, _doc] call _fnc_doc;
        };
    };
    // A VARIANT of the arsenal or the motorpool - a platoon's, a squad's, a
    // role's, or a named version - is its own document (2026-09-09).
    case (_section isEqualTo "arsenal" && _id isNotEqualTo ""): {
        private _ars = GVAR(structure) getOrDefault ["arsenal", createHashMap];
        GVAR(structureEdited) set ["arsenal", _ars];
        if (GVAR(svcUp)) then {
            private _lists = (_ars getOrDefault ["variants", createHashMap]) getOrDefault [_id, createHashMap];
            [_unit + ".arsenal." + _id, createHashMapFromArray [["section", "arsenal"], ["id", _id], ["lists", _lists]]] call _fnc_doc;
        };
    };
    case (_section isEqualTo "motorpool" && _id isNotEqualTo ""): {
        private _variants = GVAR(structure) getOrDefault ["motorpoolVariants", createHashMap];
        GVAR(structureEdited) set ["motorpoolVariants", _variants];
        if (GVAR(svcUp)) then {
            [_unit + ".motorpool." + _id, createHashMapFromArray [["section", "motorpool"], ["id", _id], ["items", _variants getOrDefault [_id, createHashMap]]]] call _fnc_doc;
        };
    };
    // A LIST-SHAPED DOCUMENT is {section, lists}, not {section, items}.
    case (_section isEqualTo "arsenal"): {
        GVAR(structureEdited) set [_section, GVAR(structure) getOrDefault [_section, createHashMap]];
        if (GVAR(svcUp)) then {
            [_unit + "." + _section, createHashMapFromArray [
                ["section", _section],
                ["lists", (GVAR(structure) getOrDefault [_section, createHashMap]) getOrDefault ["lists", createHashMap]]
            ]] call _fnc_doc;
        };
    };
    // THE WELCOME SCREEN is {title, subtitle, text} at the top of its own
    // document, not {section, items} - so it is written by name, the way the
    // ORBAT below it is. "lines" is what a welcome written before the text
    // field holds; it is carried through untouched rather than dropped.
    case (_section isEqualTo "welcome"): {
        private _w = GVAR(structure) getOrDefault ["welcome", createHashMap];
        GVAR(structureEdited) set ["welcome", _w];
        if (GVAR(svcUp)) then {
            private _doc = createHashMapFromArray [
                ["section", "welcome"],
                ["title", _w getOrDefault ["title", ""]],
                ["subtitle", _w getOrDefault ["subtitle", ""]],
                ["text", _w getOrDefault ["text", ""]]
            ];
            private _lines = _w getOrDefault ["lines", []];
            if (_lines isEqualType [] && {count _lines > 0}) then {_doc set ["lines", _lines]};
            [_unit + ".welcome", _doc] call _fnc_doc;
        };
    };
    case (_section isEqualTo "orbat"): {
        GVAR(structureEdited) set ["orbat", _items];
        if (GVAR(svcUp)) then {
            [_unit + ".orbat", createHashMapFromArray [
                ["section", "orbat"],
                ["faction", _items getOrDefault ["faction", ""]],
                // WEST | EAST | GUER | CIV - which side the unit fights on
                // (2026-09-09). Written even when empty, so a side cleared in
                // game is cleared in the database rather than lingering.
                ["side", _items getOrDefault ["side", ""]],
                ["groups", _items getOrDefault ["groups", []]],
                // NO radioNets. "Shared radio nets" are not a thing (user,
                // 2026-09-09): radio channels are the ACRE plan and the net plan, and
                // messaging nets are mailboxes. The key is not written, so a
                // document that still carries one loses it on the next save.
                ["platoons", _items getOrDefault ["platoons", []]]
            ]] call _fnc_doc;
        };
    };
    default {
        GVAR(structureEdited) set [_section, _items];
        if (GVAR(svcUp)) then {
            private _doc = createHashMapFromArray [["section", _section], ["items", _items]];
            // The admin list is also written as a plain array, the shape the site edits.
            if (_section isEqualTo "admins") then {
                private _ids = keys _items;
                _ids sort true;
                _doc set ["ids", _ids];
            };
            [_unit + "." + _section, _doc] call _fnc_doc;
        };
    };
};

GVAR(structureHash) = [] call FUNC(structureHash);

[] call FUNC(storeSave);
[] call FUNC(publish);

GVAR(structureSvc) = GVAR(structure);
GVAR(settingsSvc) = GVAR(settings);
publicVariable QGVAR(structureSvc);
publicVariable QGVAR(settingsSvc);
["structure"] call FUNC(hostRefresh);     // the host does not hear its own publicVariable
