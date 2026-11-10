#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_structItems

Description:
    THE SECTION AS THE EDITOR SEES IT: a hashmap of id => record.

    Most sections already are that - ranks, skills, roles - and come back
    untouched. The ones that are not get a view built here, so the editor,
    the list, the field boxes and the server's door all keep working on the
    one shape they know (user, 2026-09-09: "the game ui and web ui need to
    have the same fuctions same edits").

    ONE RECORD IS A LIST OF ONE. The welcome screen is a title, a subtitle and
    the text - not a list of anything - so it is handed over as a single item
    whose id is "welcome". FUNC(adminStructure) puts it back the same way.

    THE STRUCTURE IS NOT CHANGED. This is a view: whatever reads the welcome
    to draw it - FUNC(welcomeShow) - still reads GVAR(structure) >> "welcome"
    as the record it has always been.

Parameters:
    0: Section <STRING> - a BASE section, not a screen (see FUNC(structBase))

Returns:
    id => record <HASHMAP>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_base", "", [""]]];

private _raw = GVAR(structure) getOrDefault [_base, createHashMap];
if !(_raw isEqualType createHashMap) exitWith {createHashMap};

switch (_base) do {
    case "welcome": {createHashMapFromArray [["welcome", _raw]]};

    // A LIST-SHAPED SECTION is {lists: {name: [class, ...]}} - the arsenal and
    // the vehicle spawner. Each list becomes an item whose id is its name and
    // whose one field is CLASSES, so the editor's list on the left is the list
    // of lists and the box on the right is what is in the one picked.
    case "arsenal": {
        private _out = createHashMap;
        {
            if (_y isEqualType []) then {
                _out set [_x, createHashMapFromArray [["name", ""], ["classes", _y]]];
            };
        } forEach (_raw getOrDefault ["lists", createHashMap]);
        _out
    };

    // A CODE-SHAPED SECTION is {code: "<sqf>"} - a literal array with no logic
    // in it, which is why the website edits it as cards rather than as text.
    // Same here: compile it, and hand each top-level entry to the editor as an
    // item. LOGISTICS is crate -> contents, one "classname count" per line.
    case "logistics": {
        private _out = createHashMap;
        private _tree = [];
        private _text = _raw getOrDefault ["code", ""];
        if (_text isEqualType "" && _text isNotEqualTo "") then {
            private _c = call compile ([_text] call FUNC(stripComments));
            if !(_c isEqualType []) then {_c = []};
            _tree = _c;
        };
        {
            if (_x isEqualType [] && count _x >= 2) then {
                private _lines = [];
                {
                    if (_x isEqualType [] && count _x >= 2) then {
                        _lines pushBack format ["%1 %2", _x # 0, _x # 1];
                    };
                } forEach (_x # 1);
                _out set [str (_x # 0), createHashMapFromArray [["name", ""], ["contents", _lines]]];
            };
        } forEach _tree;
        _out
    };

    // PYLONS is vehicle -> presets, one "preset: mag, mag" per line.
    case "pylons": {
        private _out = createHashMap;
        private _tree = [];
        private _text = _raw getOrDefault ["code", ""];
        if (_text isEqualType "" && _text isNotEqualTo "") then {
            private _c = call compile ([_text] call FUNC(stripComments));
            if !(_c isEqualType []) then {_c = []};
            _tree = _c;
        };
        {
            if (_x isEqualType [] && count _x >= 2) then {
                private _lines = [];
                {
                    if (_x isEqualType [] && count _x >= 2) then {
                        private _mags = _x # 1;
                        if !(_mags isEqualType []) then {_mags = []};
                        _lines pushBack format ["%1: %2", _x # 0, _mags joinString ", "];
                    };
                } forEach (_x # 1);
                _out set [str (_x # 0), createHashMapFromArray [["name", ""], ["presets", _lines]]];
            };
        } forEach _tree;
        _out
    };

    // THE UNIT'S SETTINGS, which are a flat key -> value map rather than
    // id -> record. Each becomes an item whose one field is VALUE, the same
    // shape the promotion weights already use.
    //
    // THE SERVER'S OWN THREE ARE NOT OFFERED. unitId, serverId and sync say
    // where the database is and who this server is; a database cannot tell a
    // server where the database is, so they stay in the mission's file.
    case "settings": {
        private _help = createHashMapFromArray [
            ["autoSlot", "1 puts a man with a role into its slot on spawn; 0 leaves him where he is"],
            ["slotMatch", "role: any free slot with his role | slot: only the group his record names"],
            ["arsenalMode", "what adds to the common arsenal - role: the role's lists | skills: the arsenal:<name> skill effects (qual_<name> lists) | both"],
            ["savedLoadouts", "kept loadouts per player per role; 0 turns them off"],
            ["autoPromote", "1 promotes a man the moment he is over the points for the next rank; 0 lists him on the dashboard for a human to do it"],
            ["newPlayers", "auto: a record is seeded the moment somebody first connects | apply: they fill in an application in the tacpad's PAC app and an admin accepts them"]
        ];
        private _out = createHashMap;
        {
            private _v = GVAR(settings) getOrDefault [_x, ""];
            if (_v isEqualType "") then {_v = _v} else {_v = str _v};
            _out set [_x, createHashMapFromArray [["name", _help get _x], ["value", _v]]];
        } forEach ["autoSlot", "slotMatch", "arsenalMode", "savedLoadouts", "autoPromote", "newPlayers"];
        _out
    };

    default {_raw};
};
