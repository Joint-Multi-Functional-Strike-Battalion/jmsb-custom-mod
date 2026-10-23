#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminOrbat

Description:
    The one door through which the ORBAT is edited in game - the squads
    and their slots, the platoon tabs and the
    faction's name - by an admin, on the server, checked the way
    FUNC(adminSet) checks. The ORBAT is the structure's "orbat" section
    (the <unit>.orbat document with the service); after the edit the live
    slot table is rebuilt from it (jmfsb_groups_fnc_orbatApply - nobody
    seated is thrown out), it is persisted (FUNC(structurePersist)), logged
    and sent to every client.

        squad     key = the squad's name as it is now ("" for a new one);
                  record {name, roles (array of role classes, or a comma
                  string), condition, position (1-based; 0 = leave)}.
                  Role classes must be roles the structure has. ORDER IS
                  THE SR RADIO CHANNEL ORDER, so position is a real edit.
        platoon   key = the tab id; record {name, callsign, net, squads}
        radioNet  key = the net id; record {net, squads}
        faction   record {name, side} - side is WEST | EAST | GUER | CIV

    And the two that write the RADIO section rather than the ORBAT, because
    that is where the mod reads a channel from:

        squadRadio    key = the squad's name; record {acre, tfarSw, tfarLr}
                      (tfarSw / tfarLr: the net plan's slots, names kept).
                      An empty value drops the squad's row, which puts it back
                      on the plan's fallback.
        platoonRadio  key = the platoon id; record {lr} - its long range
                      channel, empty for the plan default.
        radio         key = a jmfsbFR_radio_* key (FUNC(radioKeys)); record
                      {value} - the whole value, of the default's type
                      (2026-09-09: the ACRE tables and the net plan's settings pages).
    And three more on the ORBAT itself (2026-09-09, the one-dialog PAC):
        runs          record {netsVersion, radioVersion, arsenalVersion,
                      motorpoolVersion} - which versions this order of
                      battle runs; the boot folds them into current<Name>.
        newVersion    key = the name; writes <unit>.orbat.<name> as a copy of
                      what the mission runs, and lists it.
        squad         also keeps a 4th element, the squad's KIND (inf, air,
                      armor ...) - record {type}.
        radio         key = a jmfsbFR_radio_* key (FUNC(radioKeys)); record
                      {value} - the whole value, of the default's type
                      (2026-09-09: the ACRE tables and the net plan's settings pages).
    And three more on the ORBAT itself (2026-09-09, the one-dialog PAC):
        runs          record {netsVersion, radioVersion, arsenalVersion,
                      motorpoolVersion} - which versions this order of
                      battle runs; the boot folds them into current<Name>.
        newVersion    key = the name; writes <unit>.orbat.<name> as a copy of
                      what the mission runs, and lists it.
        squad         also keeps a 4th element, the squad's KIND (inf, air,
                      armor ...) - record {type}.
        radio         key = a jmfsbFR_radio_* key (FUNC(radioKeys)); record
                      {value} - the whole value, of the default's type
                      (2026-09-09: the ACRE tables and the net plan's settings pages).
    And three more on the ORBAT itself (2026-09-09, the one-dialog PAC):
        runs          record {netsVersion, radioVersion, arsenalVersion,
                      motorpoolVersion} - which versions this order of
                      battle runs; the boot folds them into current<Name>.
        newVersion    key = the name; writes <unit>.orbat.<name> as a copy of
                      what the mission runs, and lists it.
        squad         also keeps a 4th element, the squad's KIND (inf, air,
                      armor ...) - record {type}.
        radio         key = a jmfsbFR_radio_* key (FUNC(radioKeys)); record
                      {value} - the whole value, of the default's type
                      (2026-09-09: the ACRE tables and the net plan's settings pages).
    And three more on the ORBAT itself (2026-09-09, the one-dialog PAC):
        runs          record {netsVersion, radioVersion, arsenalVersion,
                      motorpoolVersion} - which versions this order of
                      battle runs; the boot folds them into current<Name>.
        newVersion    key = the name; writes <unit>.orbat.<name> as a copy of
                      what the mission runs, and lists it.
        squad         also keeps a 4th element, the squad's KIND (inf, air,
                      armor ...) - record {type}.
        radio         key = a jmfsbFR_radio_* key (FUNC(radioKeys)); record
                      {value} - the whole value, of the default's type
                      (2026-09-09: the ACRE tables and the net plan's settings pages).
    And three more on the ORBAT itself (2026-09-09, the one-dialog PAC):
        runs          record {netsVersion, radioVersion, arsenalVersion,
                      motorpoolVersion} - which versions this order of
                      battle runs; the boot folds them into current<Name>.
        newVersion    key = the name; writes <unit>.orbat.<name> as a copy of
                      what the mission runs, and lists it.
        squad         also keeps a 4th element, the squad's KIND (inf, air,
                      armor ...) - record {type}.
        radio         key = a jmfsbFR_radio_* key (FUNC(radioKeys)); record
                      {value} - the whole value, of the default's type
                      (2026-09-09: the ACRE tables and the net plan's settings pages).
    And three more on the ORBAT itself (2026-09-09, the one-dialog PAC):
        runs          record {netsVersion, radioVersion, arsenalVersion,
                      motorpoolVersion} - which versions this order of
                      battle runs; the boot folds them into current<Name>.
        newVersion    key = the name; writes <unit>.orbat.<name> as a copy of
                      what the mission runs, and lists it.
        squad         also keeps a 4th element, the squad's KIND (inf, air,
                      armor ...) - record {type}.
        radio         key = a jmfsbFR_radio_* key (FUNC(radioKeys)); record
                      {value} - the whole value, of the default's type
                      (2026-09-09: the ACRE tables and the net plan's settings pages).
    And three more on the ORBAT itself (2026-09-09, the one-dialog PAC):
        runs          record {netsVersion, radioVersion, arsenalVersion,
                      motorpoolVersion} - which versions this order of
                      battle runs; the boot folds them into current<Name>.
        newVersion    key = the name; writes <unit>.orbat.<name> as a copy of
                      what the mission runs, and lists it.
        squad         also keeps a 4th element, the squad's KIND (inf, air,
                      armor ...) - record {type}.

Parameters:
    0: Caller <OBJECT>
    1: Kind <STRING> - "squad" | "platoon" | "faction" | "runs" | "newVersion"
                     | "squadRadio" | "platoonRadio" | "radio"
    2: Op <STRING> - "set" | "remove"
    3: Key <STRING>
    4: Record <HASHMAP> (set only)

Returns:
    Whether the change was made <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_kind", "", [""]], ["_op", "", [""]], ["_key", "", [""]], ["_rec", createHashMap, [createHashMap]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call jmfsb_adminpanel_fnc_isAdmin)}) exitWith {
    WARNING_2("adminOrbat refused: %1 is not an admin (%2)",name _caller,_kind);
    false
};
if (GVAR(readOnly)) exitWith {false};

private _fnc_tell = {
    params ["_msg", "_bad"];
    ["TAC//PAC", _msg, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

private _fnc_text = {
    params ["_field"];
    private _v = _rec getOrDefault [_field, ""];
    if !(_v isEqualType "") then {_v = str _v};
    trim _v
};
private _fnc_list = {
    params ["_field"];
    private _v = _rec getOrDefault [_field, []];
    if (_v isEqualType "") then {_v = (_v splitString ",") apply {trim _x}};
    if !(_v isEqualType []) then {_v = []};
    (_v select {_x isEqualType "" && _x isNotEqualTo ""})
};

// the ORBAT as it is, copied - the edit is made whole or not at all
private _orbat = +(GVAR(structure) getOrDefault ["orbat", createHashMap]);
if !(_orbat isEqualType createHashMap) then {_orbat = createHashMap};
private _groups = _orbat getOrDefault ["groups", []];
private _platoons = _orbat getOrDefault ["platoons", []];
private _detail = "";
private _ok = true;

switch (_kind) do {
    case "faction": {
        private _name = ["name"] call _fnc_text;
        _orbat set ["faction", _name];
        // AND THE SIDE (2026-09-09). A side the engine does not have is a side
        // nothing can be created on and the failure is silent at mission
        // start, so an unrecognised one is simply not written.
        private _side = toUpper (["side"] call _fnc_text);
        if (_side in ["WEST", "EAST", "GUER", "CIV"]) then {
            _orbat set ["side", _side];
        } else {
            if (_side isNotEqualTo "") then {
                [format ["'%1' is not a side. WEST, EAST, GUER or CIV.", _side], true] call _fnc_tell;
                _ok = false;
            };
        };
        _detail = format ["faction '%1', side '%2'", _name, _orbat getOrDefault ["side", ""]];
    };
    case "squad": {
        private _at = _groups findIf {toUpper (_x # 0) isEqualTo toUpper _key};
        if (_op isEqualTo "remove") exitWith {
            if (_at < 0) exitWith {[format ["No squad '%1'.", _key], true] call _fnc_tell; _ok = false};
            _groups deleteAt _at;
            _detail = format ["squad '%1' removed", _key];
        };
        private _name = ["name"] call _fnc_text;
        if (_name isEqualTo "") exitWith {["A squad needs a name.", true] call _fnc_tell; _ok = false};
        private _roles = ["roles"] call _fnc_list;
        if (_roles isEqualTo []) exitWith {["A squad needs at least one slot - a role class per slot, comma-separated.", true] call _fnc_tell; _ok = false};
        private _known = GVAR(structure) getOrDefault ["roles", createHashMap];
        private _bad = _roles select {!(_x in _known)};
        if (_bad isNotEqualTo []) exitWith {[format ["Not roles the structure has: %1", _bad joinString ", "], true] call _fnc_tell; _ok = false};
        private _cond = ["condition"] call _fnc_text;
        if (_cond isEqualTo "") then {_cond = "true"};
        private _dupe = _groups findIf {toUpper (_x # 0) isEqualTo toUpper _name};
        if (_dupe >= 0 && _dupe isNotEqualTo _at) exitWith {[format ["There is already a squad called '%1'.", _name], true] call _fnc_tell; _ok = false};
        // the 4th element is the squad's kind - kept when the edit did not name one
        private _type = ["type"] call _fnc_text;
        if (_type isEqualTo "" && _at >= 0) then {_type = (_groups # _at) param [3, ""]};
        if !(_type isEqualType "") then {_type = ""};
        private _row = [_name, _roles, _cond, _type];
        if (_at >= 0) then {_groups set [_at, _row]} else {_groups pushBack _row; _at = (count _groups) - 1};
        private _pos = _rec getOrDefault ["position", 0];
        if (_pos isEqualType "") then {_pos = parseNumber _pos};
        if !(_pos isEqualType 0) then {_pos = 0};
        if (_pos >= 1 && _pos <= count _groups && (_pos - 1) isNotEqualTo _at) then {
            _groups deleteAt _at;
            _groups = (_groups select [0, _pos - 1]) + [_row] + (_groups select [_pos - 1]);
        };
        _detail = format ["squad '%1': %2 slot(s) [%3], condition %4, position %5", _name, count _roles, _roles joinString " ", _cond, (_groups findIf {(_x # 0) isEqualTo _name}) + 1];
    };
    case "platoon": {
        private _at = _platoons findIf {(_x # 0) isEqualTo _key};
        if (_op isEqualTo "remove") exitWith {
            if (_at < 0) exitWith {[format ["No platoon tab '%1'.", _key], true] call _fnc_tell; _ok = false};
            _platoons deleteAt _at;
            _detail = format ["platoon tab '%1' removed", _key];
        };
        private _id = ["id"] call _fnc_text;
        if (_id isEqualTo "") then {_id = _key};
        if (_id isEqualTo "") exitWith {["A platoon tab needs an id.", true] call _fnc_tell; _ok = false};
        private _row = [_id, ["name"] call _fnc_text, ["callsign"] call _fnc_text, ["net"] call _fnc_text, ["squads"] call _fnc_list];
        if (_at >= 0) then {_platoons set [_at, _row]} else {_platoons pushBack _row};
        _detail = format ["platoon tab '%1': %2 / %3, net %4, squads [%5]", _id, _row # 1, _row # 2, _row # 3, (_row # 4) joinString ", "];
    };
    case "runs": {
        {
            private _v = _rec getOrDefault [_x, ""];
            if !(_v isEqualType "") then {_v = str _v};
            _orbat set [_x, trim _v];
        } forEach ["netsVersion", "radioVersion", "arsenalVersion", "motorpoolVersion"];
        // and this boot's own settings, so a reader that looks there agrees
        {
            _x params ["_from", "_to"];
            GVAR(settings) set [_to, _orbat getOrDefault [_from, ""]];
        } forEach [["netsVersion", "currentNets"], ["radioVersion", "currentRadio"], ["arsenalVersion", "currentArsenal"], ["motorpoolVersion", "currentMotorpool"]];
        _detail = format ["runs nets '%1', radio '%2', arsenal '%3', motorpool '%4'", _orbat getOrDefault ["netsVersion", ""], _orbat getOrDefault ["radioVersion", ""], _orbat getOrDefault ["arsenalVersion", ""], _orbat getOrDefault ["motorpoolVersion", ""]];
    };
    case "newVersion": {
        if (_key isEqualTo "" || {(toArray _key) findIf {!(_x isEqualTo 95 || {_x >= 48 && _x <= 57} || {_x >= 65 && _x <= 90} || {_x >= 97 && _x <= 122})} >= 0}) exitWith {["A version name is letters, digits and underscore.", true] call _fnc_tell; _ok = false};
        if (!GVAR(svcUp)) exitWith {["A named order of battle is a database document, and this server has no database.", true] call _fnc_tell; _ok = false};
        private _unit = GVAR(settings) getOrDefault ["unitId", ""];
        private _doc = createHashMapFromArray [
            ["section", "orbat"], ["faction", _orbat getOrDefault ["faction", ""]], ["side", _orbat getOrDefault ["side", ""]],
            ["groups", _orbat getOrDefault ["groups", []]], ["platoons", _orbat getOrDefault ["platoons", []]],
            ["exportedAt", [] call FUNC(stamp)], ["from", "edited in game"]
        ];
        if !([_unit + ".orbat." + _key, [_doc, ""] call FUNC(toJson)] call FUNC(svcSave)) exitWith {["The database did not take it.", true] call _fnc_tell; _ok = false};
        private _versions = GVAR(structure) getOrDefault ["orbatVersions", []];
        if !(_versions isEqualType []) then {_versions = []};
        _versions pushBackUnique _key;
        _versions sort true;
        GVAR(structure) set ["orbatVersions", _versions];
        GVAR(structureSvc) = GVAR(structure);
        publicVariable QGVAR(structureSvc);
        ["structure"] call FUNC(hostRefresh);
        [getPlayerUID _caller, name _caller, "orbat", _key, format ["order of battle '%1' created", _key]] call FUNC(logAction);
        [format ["Order of battle '%1' written - make it the default to run it.", _key], false] call _fnc_tell;
    };
    case "radio": {
        private _radio = +(GVAR(structure) getOrDefault ["radio", createHashMap]);
        if !(_radio isEqualType createHashMap) then {_radio = createHashMap};
        private _known = [] call FUNC(radioKeys);
        private _at = _known findIf {(_x # 0) isEqualTo _key};
        if (_at < 0) exitWith {[format ["'%1' is not a radio plan key.", _key], true] call _fnc_tell; _ok = false};
        private _default = (_known # _at) # 1;
        private _value = _rec getOrDefault ["value", _default];
        // the default's type, or nothing: a channel table is an array, a radio a string, a power a number
        if (_default isEqualType 0 && _value isEqualType "") then {_value = parseNumber _value};
        // a switch (the VON keys, 2026-10-20): true / false, or "true" / "false" / 1 / 0 from a form
        if (_default isEqualType true && _value isEqualType 0) then {_value = _value != 0};
        if (_default isEqualType true && _value isEqualType "" && {(toLower trim _value) in ["true", "1", "false", "0"]}) then {_value = (toLower trim _value) in ["true", "1"]};
        if !(_value isEqualType _default) exitWith {[format ["%1 takes %2.", _key, switch (true) do {case (_default isEqualType []): {"a list"}; case (_default isEqualType 0): {"a number"}; case (_default isEqualType true): {"true or false"}; default {"text"}}], true] call _fnc_tell; _ok = false};
        _radio set [_key, _value];
        GVAR(structure) set ["radio", _radio];
        if (!isNil QFUNC(radioApply)) then {[_radio] call FUNC(radioApply)};
        ["radio"] call FUNC(structurePersist);
        _detail = format ["radio %1 written", _key];
        [getPlayerUID _caller, name _caller, "orbat", _key, _detail] call FUNC(logAction);
        [format ["Radio: %1.", _detail], false] call _fnc_tell;
    };
    default {
        _ok = false;
    };
    // ---- the channels, which live in the RADIO section, not the ORBAT ----
    // A squad without a radio is half a squad, so they are edited beside it -
    // but the mod reads them from <unit>.radio (srSquadChannel for ACRE,
    // tfarNets for the net plan, lrPlatoonChannel for a platoon's long range), so that
    // is where they are written. The website writes exactly the same rows.
    case "squadRadio";
    case "platoonRadio": {
        private _radio = +(GVAR(structure) getOrDefault ["radio", createHashMap]);
        if !(_radio isEqualType createHashMap) then {_radio = createHashMap};

        // Set one row of a keyed table, or drop it when nothing is given.
        private _fnc_row = {
            params ["_table", "_key", "_values"];
            private _rows = _radio getOrDefault [_table, []];
            if !(_rows isEqualType []) then {_rows = []};
            _rows = _rows select {
                _x isEqualType [] && {toUpper (_x param [0, ""]) isNotEqualTo toUpper _key}
            };
            if (count _values > 0) then {_rows pushBack ([_key] + _values)};
            _radio set [_table, _rows];
        };

        if (_kind isEqualTo "squadRadio") then {
            if (_key isEqualTo "") exitWith {["Pick a squad first.", true] call _fnc_tell; _ok = false};
            private _acre = ["acre"] call _fnc_text;
            ["srSquadChannel", _key, [[], [parseNumber _acre]] select (_acre isNotEqualTo "")] call _fnc_row;

            private _sw = ["tfarSw"] call _fnc_text;
            private _lr = ["tfarLr"] call _fnc_text;
            private _tf = [];
            if (_sw isNotEqualTo "" || _lr isNotEqualTo "") then {
                _tf = [parseNumber _sw, parseNumber _lr];
            };
            ["tfarNets", _key, _tf] call _fnc_row;
            _detail = format ["%1 channels: ACRE %2, nets %3/%4", _key, _acre, _sw, _lr];
        } else {
            if (_key isEqualTo "") exitWith {["Pick a platoon first.", true] call _fnc_tell; _ok = false};
            private _lrCh = ["lr"] call _fnc_text;
            ["lrPlatoonChannel", _key, [[], [parseNumber _lrCh]] select (_lrCh isNotEqualTo "")] call _fnc_row;
            _detail = format ["%1 long range channel %2", _key, [_lrCh, "(the plan default)"] select (_lrCh isEqualTo "")];
        };

        if (!_ok) exitWith {};

        GVAR(structure) set ["radio", _radio];
        // The globals the gear and player code read are written from the
        // section, so a channel changed in game takes effect without a
        // restart - the same call the boot makes.
        if (!isNil QFUNC(radioApply)) then {[_radio] call FUNC(radioApply)};
        ["radio"] call FUNC(structurePersist);
        [getPlayerUID _caller, name _caller, "orbat", _key, _detail] call FUNC(logAction);
        INFO_2("%1 edited the radio plan: %2",name _caller,_detail);
        [format ["Radio: %1.", _detail], false] call _fnc_tell;
    };
};
if (!_ok) exitWith {false};

// A channel edit is done - it wrote the radio section and persisted it, and
// has no business rewriting the ORBAT on the way out.
if (_kind in ["squadRadio", "platoonRadio", "radio", "newVersion"]) exitWith {true};

_orbat set ["groups", _groups];
_orbat set ["platoons", _platoons];
// NO radioNets KEY WRITTEN BACK. "Shared radio nets" are not a thing (user,
// 2026-09-09) - radio channels are the ACRE plan and the net plan, messaging nets
// are mailboxes. An ORBAT document that still carries the old key keeps it
// untouched and unread; nothing writes a new one.
GVAR(structure) set ["orbat", _orbat];

// the live slot table, the platoon tags, the persistence, the log
if (!isNil "jmfsb_groups_fnc_orbatApply") then {[] call jmfsb_groups_fnc_orbatApply};
missionNamespace setVariable ["jmfsb_messaging_platoonTagCache", nil];
[getPlayerUID _caller, name _caller, "orbat", "", _detail] call FUNC(logAction);
["orbat"] call FUNC(structurePersist);

INFO_2("%1 edited the ORBAT: %2",name _caller,_detail);
[format ["ORBAT: %1.", _detail], false] call _fnc_tell;
true
