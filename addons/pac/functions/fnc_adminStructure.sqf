#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminStructure

Description:
    The one door through which the STRUCTURE is edited in-game - ranks,
    skills, awards, statuses, nets, roles and the admin list - by an admin, on the
    server, checked the way FUNC(adminSet) checks. The mission's config was
    the only source before; a unit that keeps its config in the database
    needs to change a rank without a mission update, and needs it to stick.

    ONE ITEM AT A TIME. "set" writes a whole record under an id (new or
    existing) and "remove" deletes one; ids are the class-name rule - lower
    case, letters, digits, underscore - because they are what every player
    record points at. A removed id becomes an orphan on the records that
    hold it, flagged, never dropped, like a config rename.

    IT STICKS EVERYWHERE THE STORE DOES. After the change the section is
    persisted (FUNC(structurePersist)) - to the service as the section's own
    document when the database is the source, and always to the local
    copies - the hash is recomputed, and the structure goes back out to
    every client.

    ADMINS ARE A SECTION. <unit>.admins holds {uid: {name, addedBy,
    addedAt}}; the console's isAdmin reads it beside the mission's list. An
    admin cannot remove themself - the last way in must not be closable
    from inside.

Parameters:
    0: Caller <OBJECT>
    1: Section <STRING> - "ranks" | "skills" | "awards" | "statuses" | "admins" | "roles" | "nets" | "promotion" | "trainings"
    2: Op <STRING> - "set" | "remove"
    3: Id <STRING>
    4: Record <HASHMAP> (set only) - the section's fields

Returns:
    Whether the change was made <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_section", "", [""]], ["_op", "", [""]], ["_id", "", [""]], ["_rec", createHashMap, [createHashMap]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {
    WARNING_2("adminStructure refused: %1 is not an admin (%2)",name _caller,_section);
    false
};
if !(_section in ["ranks", "skills", "awards", "statuses", "admins", "roles", "nets", "promotion", "trainings", "traits", "schemes", "motorpool", "cosmetics", "welcome", "arsenal", "logistics", "pylons", "settings"]) exitWith {false};

// THE SAME RULE THE MENU DRAWS, enforced. A section this mission's config// folder feeds has no editable screen when there is no database, and a save
// that reached here anyway would be written to the profile and then silently
// overruled by the file at the next mission start.
if ([_section] call FUNC(fileFed)) exitWith {
    WARNING_2("adminStructure refused: %1 comes from this mission's config folder and there is no database (%2)",_section,name _caller);
    false
};

private _fnc_tell = {
    params ["_msg", "_bad"];
    ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

// An id is a class name: [a-z0-9_], not empty. A ROLE's id is its
// Dynamic_Roles class and keeps its case (teamleadBanshee); an admin's is a
// Steam id.
// A LIST'S id is its NAME - "Weapons", "ground" - and keeps its case.
// UPPER CASE IS ALLOWED where the ids are classnames or camelCase names:
// roles, arsenal lists, cosmetics and pylons (vehicle classes), logistics
// crates, traits (variable names), nets, motorpool headings - and the
// settings, whose keys are autoSlot, slotMatch, savedLoadouts, autoPromote
// (2026-09-09: the settings editor refused every one of its own ids).
private _upperOk = _section in ["roles", "arsenal", "cosmetics", "pylons", "logistics", "traits", "motorpool", "settings", "schemes"];
private _idOk = _id isNotEqualTo "" && {(toArray _id) findIf {!(_x in [95] || {_x >= 48 && _x <= 57} || {_x >= 97 && _x <= 122} || {_upperOk && {_x >= 65 && _x <= 90}})} < 0};
if (_section isEqualTo "admins") then {_idOk = _id isNotEqualTo "" && {(toArray _id) findIf {!(_x >= 48 && _x <= 57)} < 0}};
// A NET's id is its name on the rail and the radio plan - "C2.reports",
// "GROUND 1", "FIRES.cas" - so letters of either case, digits, dot, space,
// hyphen and underscore.
if (_section isEqualTo "nets") then {_idOk = _id isNotEqualTo "" && {(toArray _id) findIf {!(_x in [95, 46, 32, 45] || {_x >= 48 && _x <= 57} || {_x >= 97 && _x <= 122} || {_x >= 65 && _x <= 90})} < 0}};
if (!_idOk) exitWith {[format ["'%1' is not a valid id (letters, digits, underscore; a Steam id for admins).", _id], true] call _fnc_tell; false};

// The section as the editor sees it - see FUNC(structItems). For everything
// but the welcome screen that IS the structure's own hashmap.
// A VARIANT (2026-09-09): a platoon's, a squad's, a role's or a named
// version of the arsenal or the motorpool - <unit>.arsenal.<v> /
// <unit>.motorpool.<v> - edited in place under the structure's variants
// rather than the mission's own lists. The record says which.
private _variant = _rec getOrDefault ["variant", ""];
if !(_variant isEqualType "") then {_variant = ""};
_rec deleteAt "variant";
if (_variant isNotEqualTo "" && {!(_section in ["arsenal", "motorpool"])}) exitWith {false};
if (_section isEqualTo "arsenal" && _variant isNotEqualTo "") exitWith {
    private _ars = +(GVAR(structure) getOrDefault ["arsenal", createHashMap]);
    private _variants = _ars getOrDefault ["variants", createHashMap];
    if !(_variants isEqualType createHashMap) then {_variants = createHashMap};
    private _lists = +(_variants getOrDefault [_variant, createHashMap]);
    if !(_lists isEqualType createHashMap) then {_lists = createHashMap};
    if (_op isEqualTo "remove") then {
        _lists deleteAt _id;
    } else {
        private _classes = _rec getOrDefault ["classes", []];
        if (_classes isEqualType "") then {_classes = ((_classes splitString ",") apply {trim _x}) select {_x isNotEqualTo ""}};
        if !(_classes isEqualType []) then {_classes = []};
        _lists set [_id, _classes select {_x isEqualType ""}];
    };
    _variants set [_variant, _lists];
    _ars set ["variants", _variants];
    GVAR(structure) set ["arsenal", _ars];
    [getPlayerUID _caller, name _caller, "structure", "", format ["%1 arsenal.%2 list '%3'", ["set", "removed"] select (_op isEqualTo "remove"), _variant, _id]] call FUNC(logAction);
    ["arsenal", _variant] call FUNC(structurePersist);
    [format ["Arsenal %1: list %2 %3.", _variant, _id, ["saved", "removed"] select (_op isEqualTo "remove")], false] call _fnc_tell;
    true
};

private _items = if (_section isEqualTo "motorpool" && _variant isNotEqualTo "") then {
    private _v = (GVAR(structure) getOrDefault ["motorpoolVariants", createHashMap]) getOrDefault [_variant, createHashMap];
    if (_v isEqualType createHashMap) then {+_v} else {createHashMap}
} else {
    [_section] call FUNC(structItems)
};
private _fields = [["name", "t"]] + (([_section] call FUNC(structFields)) apply {[_x # 0, _x # 1]});
private _ok = true;

switch (_op) do {
    case "set": {
        // MERGE OVER WHAT IS THERE. The editor sends the fields it shows; a
        // role's default loadout and slotTag are not among them and must not
        // be wiped by a save that only changed its rank gate.
        private _clean = +(_items getOrDefault [_id, createHashMap]);
        _clean set ["id", _id];
        {
            _x params ["_field", "_kind"];
            if !(_field in _rec) then {
                if !(_field in _clean) then {_clean set [_field, switch (_kind) do {case "a": {[]}; case "n": {0}; default {""}}]};
                continue;
            };
            private _v = _rec get _field;
            switch (_kind) do {
                case "a": {
                    // A ROLE'S ARRAYS ARE NOT ALL FLAT. nets and tiles are
                    // pairs, traits and variables triples, the loadout nested -
                    // splitting any of those on commas gives a role with a net
                    // called "[C2", which is a net nobody is on and nothing
                    // says so. FUNC(roleFieldParse) reads what
                    // FUNC(roleFieldText) wrote; the old rows go in so a row's
                    // third value (a trait's custom flag, a variable's global
                    // flag) survives somebody editing the list.
                    if (_v isEqualType "" && _section isEqualTo "roles") then {
                        _v = [_field, _v, _clean getOrDefault [_field, []]] call FUNC(roleFieldParse);
                    };
                    if (_v isEqualType "") then {_v = ((_v splitString ",") apply {trim _x}) select {_x isNotEqualTo ""}};
                    if !(_v isEqualType []) then {_v = []};
                };
                case "n": {
                    if (_v isEqualType "") then {_v = parseNumber _v};
                    if !(_v isEqualType 0) then {_v = 0};
                };
                default {
                    if !(_v isEqualType "") then {_v = str _v};
                };
            };
            _clean set [_field, _v];
        } forEach _fields;
        if (_section isEqualTo "traits") then {
            // bool or number, nothing else - a kind the role editor does not
            // know how to draw is a trait nobody can set.
            private _kindV = toLower (_clean getOrDefault ["kind", "bool"]);
            _clean set ["kind", ["bool", "number"] select (_kindV isEqualTo "number")];
            if ((_clean getOrDefault ["label", ""]) isEqualTo "") then {_clean set ["label", _id]};
        };
        if (_section isEqualTo "ranks" && {!((toUpper (_clean get "armaRank")) in ARMA_RANKS)}) exitWith {
            ["armaRank must be one of PRIVATE CORPORAL SERGEANT LIEUTENANT CAPTAIN MAJOR COLONEL.", true] call _fnc_tell;
        };
        // THE RUNG GOES TO THE PROMOTION DOCUMENT, not onto the rank. That is
        // where a mission's config_pac.hpp declares it and where the website
        // reads and writes it, so putting it on the rank would be a second,
        // disagreeing copy.
        if (_section isEqualTo "ranks") then {
            private _pts = _clean getOrDefault ["points", 0];
            if (_pts isEqualType "") then {_pts = parseNumber _pts};
            if !(_pts isEqualType 0) then {_pts = 0};
            _clean deleteAt "points";
            private _promo = +(["promotion"] call FUNC(structItems));
            private _rung = +(_promo getOrDefault ["rank_" + _id, createHashMap]);
            _rung set ["value", _pts];
            if ((_rung getOrDefault ["name", ""]) isEqualTo "") then {
                _rung set ["name", _clean getOrDefault ["name", _id]];
            };
            _promo set ["rank_" + _id, _rung];
            GVAR(structure) set ["promotion", _promo];
            ["promotion"] call FUNC(structurePersist);
        };
        if (_section isEqualTo "roles") then {
            private _mr = _clean getOrDefault ["minRank", ""];
            private _bad = (_clean getOrDefault ["requiredSkills", []]) select {!(_x in (GVAR(structure) getOrDefault ["skills", createHashMap]))};
            if (_mr isNotEqualTo "" && {!(_mr in (GVAR(structure) getOrDefault ["ranks", createHashMap]))}) then {
                [format ["MIN RANK '%1' is not a rank id in the structure.", _mr], true] call _fnc_tell;
                _ok = false;
            };
            if (_bad isNotEqualTo []) then {
                [format ["REQUIRED SKILLS %1 are not skill ids in the structure.", _bad], true] call _fnc_tell;
                _ok = false;
            };
            if ((_clean getOrDefault ["name", ""]) isEqualTo "") then {
                private _fromMission = if (!isNil "jmfsb_groups_fnc_roleFromConfig") then {([_id] call jmfsb_groups_fnc_roleFromConfig) getOrDefault ["name", ""]} else {""};
                _clean set ["name", [_fromMission, _id] select (_fromMission isEqualTo "")];
            };
            if ((_clean getOrDefault ["slotTag", ""]) isEqualTo "") then {_clean set ["slotTag", _id]};
        };
        if (!_ok) exitWith {};
        if (_section isEqualTo "admins") then {
            _clean set ["addedBy", name _caller];
            _clean set ["addedAt", [] call FUNC(stamp)];
        };
        _items set [_id, _clean];
    };
    case "remove": {
        if (_section isEqualTo "admins" && {_id isEqualTo getPlayerUID _caller}) exitWith {["You cannot remove yourself from the admin list.", true] call _fnc_tell};
        if !(_id in _items) exitWith {[format ["No '%1' in %2.", _id, _section], true] call _fnc_tell};
        _items deleteAt _id;
    };
    default {};
};
if (!_ok) exitWith {false};
if (_section isEqualTo "motorpool" && _variant isNotEqualTo "") exitWith {
    private _variants = +(GVAR(structure) getOrDefault ["motorpoolVariants", createHashMap]);
    if !(_variants isEqualType createHashMap) then {_variants = createHashMap};
    _variants set [_variant, _items];
    GVAR(structure) set ["motorpoolVariants", _variants];
    [getPlayerUID _caller, name _caller, "structure", "", format ["%1 motorpool.%2 '%3'", ["set", "removed"] select (_op isEqualTo "remove"), _variant, _id]] call FUNC(logAction);
    ["motorpool", _variant] call FUNC(structurePersist);
    [format ["Motorpool %1: %2 %3.", _variant, _id, ["saved", "removed"] select (_op isEqualTo "remove")], false] call _fnc_tell;
    true
};
// ONE RECORD, NOT A LIST. The welcome screen is handed to the editor as a
// list of one (see FUNC(structItems)) and goes back as the record it is, so
// FUNC(welcomeShow) reads exactly what it has always read.
if (_section isEqualTo "welcome") then {
    private _w = +(_items getOrDefault ["welcome", createHashMap]);
    _w deleteAt "id";
    GVAR(structure) set ["welcome", _w];
} else {
    if (_section isEqualTo "arsenal") then {
        // Back into {lists: {name: [...]}}, which is what FUNC(cfgLists) reads
        // and what the document holds.
        private _rec = +(GVAR(structure) getOrDefault [_section, createHashMap]);
        private _l = createHashMap;
        {
            private _v = _y getOrDefault ["classes", []];
            if (_v isEqualType []) then {_l set [_x, _v]};
        } forEach _items;
        _rec set ["lists", _l];
        GVAR(structure) set [_section, _rec];
    } else {
        if (_section isEqualTo "settings") then {
            // STRAIGHT INTO GVAR(settings), not the structure - that is where
            // every reader looks. A number stays a number: autoSlot is tested
            // with isEqualTo 0 and a "0" string would never match it.
            {
                private _v = _y getOrDefault ["value", ""];
                private _num = parseNumber _v;
                if (str _num isEqualTo _v) then {_v = _num};
                GVAR(settings) set [_x, _v];
            } forEach _items;
            ["settings"] call FUNC(structurePersist);
        } else {
        if (_section in ["logistics", "pylons"]) then {
            // BACK INTO THE BLOCK OF SQF the document holds - the same literal
            // a mission's config_logistics.sqf / config_pylons.sqf returns.
            // FUNC(structItems) took it apart; this puts it together, and the
            // two have to stay each other's inverse.
            private _tree = [];
            {
                private _id = _x;
                private _rows = [];
                if (_section isEqualTo "logistics") then {
                    {
                        private _parts = (_x splitString " ") select {_x isNotEqualTo ""};
                        if (count _parts >= 2) then {
                            _rows pushBack [_parts # 0, parseNumber (_parts # 1)];
                        };
                    } forEach (_y getOrDefault ["contents", []]);
                } else {
                    {
                        private _at = _x find ":";
                        if (_at > -1) then {
                            private _pName = trim (_x select [0, _at]);
                            private _mags = ((_x select [_at + 1]) splitString ",") apply {trim _x};
                            _mags = _mags select {_x isNotEqualTo ""};
                            if (_pName isNotEqualTo "") then {_rows pushBack [_pName, _mags]};
                        };
                    } forEach (_y getOrDefault ["presets", []]);
                };
                if (_rows isNotEqualTo []) then {_tree pushBack [_id, _rows]};
            } forEach _items;
            GVAR(structure) set [_section, createHashMapFromArray [["code", str _tree]]];
        } else {
            GVAR(structure) set [_section, _items];
        };
        };
    };
};
// A role removed in the editor is a mission role back at the mission's own
// (when the mission still declares it), not a hole in the slot table; a role
// the mission never declared is simply gone. The rest of every role - nets,
// loadout, tiles - rides along untouched under the three gate fields.
if (_section isEqualTo "roles") then {[] call FUNC(rolesFromMission)};
// The server's admin list follows the admins section at once (review S1/S5).
if (_section isEqualTo "admins") then {[] call FUNC(adminsPublish)};

[getPlayerUID _caller, name _caller, "structure", "", format ["%1 %2 '%3'", ["set", "removed"] select (_op isEqualTo "remove"), _section, _id]] call FUNC(logAction);
[_section, _id] call FUNC(structurePersist);

INFO_4("%1 %2 %3 '%4' in the structure",name _caller,_op,_section,_id);
[format ["%1: %2 '%3'.", _section, ["set", "removed"] select (_op isEqualTo "remove"), _id], false] call _fnc_tell;
true
