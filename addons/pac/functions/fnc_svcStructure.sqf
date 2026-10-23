#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_svcStructure

Description:
    Reads the unit's config out of the service, ONE DOCUMENT PER CONFIG
    FILE (and one per role, one per order), and assembles the structure
    document FUNC(structureAdopt) takes:

        <unit>.settings          { section: "settings",  items: {...} }
        <unit>.ranks             { section: "ranks",     items: {id: rank} }
        <unit>.skills / .awards / .statuses / .admins / .nets / .templates /
        <unit>.schemes / .traits - the same shape. "traits" is the unit's own
                                 trait catalogue (2026-09-09): the names that
                                 are NOT the engine's seven, so a role editor
                                 can offer them as a list instead of asking
                                 somebody to type one and get the custom flag
                                 right.
        <unit>.radio             { section: "radio",     items: {key: value} }
                                 - config_radio.hpp's globals by name
        <unit>.orbat             { section: "orbat", faction, side, groups,
                                   platoons }
        <unit>.role.<class>      { section: "role", id, role: {...} }  - the
                                 whole role, config_roles.hpp's shape plus
                                 PAC's gates; {deleted: true} is skipped
        <unit>.opord.<id>        { section: "opord", id, order: {...} }

    Roles and orders are found by listing the service for the
    "<unit>.role." and "<unit>.opord." prefixes, so a new one is a new
    document and nothing else. A database written before roles had their
    own documents holds one "<unit>.roles" document instead; that is read
    when no role documents exist, and the first edit or push writes the
    new shape. A section document that is missing is an empty section;
    the database "has a config" when at least one document exists. Server
    only, scheduled - every read waits its turn (FUNC(svcLoad)).

    EACH KEY IS READ ONCE (2026-10-19). Every read goes through _fnc_fetch,
    which keeps what came back for the rest of this read: the variant loops
    list "<unit>.arsenal." and "<unit>.motorpool." and fetched every key under
    them - including the version the section loop had just read, so a
    mission running arsenal "testing" read its 127 KB twice. A key read
    again is a copy of the first answer.

    EVERY READ IS TIMED into the .rpt (FUNC(bootLog), RPT only): one line per
    document - waited, parsed, size - one per phase, and one summary in the
    boot log itself, so the next slow boot says where its time went.

    NEVER THE WEBSITE'S DOCUMENTS. <unit>.web.* (assets, images - half the
    database by size) belong to the site; nothing here lists or reads them.
    Every key is "<unit>.<section>[.<version>]" or one of the five prefixes
    below (orbat., arsenal., motorpool., role., opord.).

Parameters:
    None

Returns:
    [document for structureAdopt, status] - status "ok" (something found),
    "empty" (nothing in the database), "error" <ARRAY>

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {[createHashMap, "error"]};

private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _structure = createHashMap;
private _settings = createHashMap;
private _found = 0;
private _errors = 0;

// THE MISSION SAYS WHICH VERSION IT RUNS, AND IT HAS TO SAY SO HERE. The
// settings document's currentOrbat / currentArsenal / ... are the unit's
// defaults; a mission that declares one in its own CfgGFA_PAC wins
// (FUNC(structureAdopt)). But adopt runs AFTER this fetch, and the fetch is
// what reads the version - so the cdev mission asked for orbat "testing" and
// arsenal "testing", the database answered "default" and the common lists,
// and nothing said why (2026-10-18). Overlaid the moment the settings
// document lands, so every section fetched after it reads the mission's.
private _fnc_missionWins = {
    private _missionSettings = missionConfigFile >> "CfgGFA_PAC" >> "settings";
    private _versionSettings = ((([] call FUNC(svcSections)) apply {_x # 2}) select {_x isNotEqualTo ""})
        + ["currentOrbat", "currentWelcome", "currentOpord"];
    {
        if (isText (_missionSettings >> _x) && {(getText (_missionSettings >> _x)) isNotEqualTo ""}) then {
            _settings set [_x, getText (_missionSettings >> _x)];
        };
    } forEach _versionSettings;
};

// ---- EVERY READ, once, and timed --------------------------------------------
// "get|<key>" / "list|<prefix>" -> [document, status]. Only answers are kept:
// an error is asked again by whoever asks next, as before.
private _fetched = createHashMap;
private _stats = [0, 0, 0, 0, 0];   // requests, reused, seconds waiting, seconds parsing, characters
private _fnc_fetch = {
    params ["_fkey", ["_ffn", "get"]];
    private _id = _ffn + "|" + _fkey;
    if (_id in _fetched) exitWith {
        _stats set [1, (_stats # 1) + 1];
        ["3/6", format ["  %1 %2: already read this boot - reused", _ffn, _fkey], true] call FUNC(bootLog);
        (_fetched get _id) params ["_fdoc", "_fstatus"];
        [+_fdoc, _fstatus]
    };
    ([_fkey, _ffn] call FUNC(svcLoad)) params ["_fdoc", "_fstatus", ["_timing", [0, 0, 0]]];
    _timing params ["_wait", "_parse", "_chars"];
    _stats set [0, (_stats # 0) + 1];
    _stats set [2, (_stats # 2) + _wait];
    _stats set [3, (_stats # 3) + _parse];
    _stats set [4, (_stats # 4) + _chars];
    ["3/6", format ["  %1 %2: %3 - %4 chars, waited %5 s, parsed %6 s", _ffn, _fkey, _fstatus, _chars, _wait toFixed 2, _parse toFixed 2], true] call FUNC(bootLog);
    if (_fstatus in ["ok", "empty"]) then {_fetched set [_id, [_fdoc, _fstatus]]};
    [_fdoc, _fstatus]
};

// One .rpt line per phase: what it cost since the last one.
private _readAt = diag_tickTime;
private _phaseAt = _readAt;
private _phaseStats = +_stats;
private _fnc_phase = {
    params ["_name"];
    ["3/6", format ["service read, %1: %2 s - %3 request(s), %4 reused, %5 s waiting, %6 s parsing, %7 chars",
        _name, (diag_tickTime - _phaseAt) toFixed 2,
        (_stats # 0) - (_phaseStats # 0), (_stats # 1) - (_phaseStats # 1),
        ((_stats # 2) - (_phaseStats # 2)) toFixed 2, ((_stats # 3) - (_phaseStats # 3)) toFixed 2,
        (_stats # 4) - (_phaseStats # 4)], true] call FUNC(bootLog);
    _phaseAt = diag_tickTime;
    _phaseStats = +_stats;
};

// ---- every section the database holds, from ONE table --------------------
// FUNC(svcSections) is the contract: section, shape, and the setting a mission
// uses to name which version it runs. A section absent from that table is a
// document nobody reads, which is what had happened to cosmetics, logistics,
// pylons and the skill block until 2026-09-09.
//
// SETTINGS FIRST, because the version settings live in it and every other
// section may be steered by one.
private _fnc_key = {
    params ["_section", "_setting"];
    private _key = _unit + "." + _section;
    if (_setting isEqualTo "") exitWith {_key};
    private _want = _settings getOrDefault [_setting, ""];
    if (_want isEqualType "" && _want isNotEqualTo "") then {
        _key = _unit + "." + _section + "." + _want;
    };
    _key
};

// A named version that is not there falls back to the common document rather
// than leaving the mission without that config at all - and says so, because a
// silent fallback is how a mission runs the wrong arsenal for a month.
private _fnc_load = {
    params ["_section", "_setting"];
    private _key = [_section, _setting] call _fnc_key;
    [_section, "run", 0, 1, _key] call FUNC(bootDoc);
    ([_key] call _fnc_fetch) params ["_doc", "_status"];
    if (_status isNotEqualTo "ok" && _key isNotEqualTo (_unit + "." + _section)) then {
        WARNING_2("%1 names a version that is not there - the common %2 is used",_setting,_section);
        ([_unit + "." + _section] call _fnc_fetch) params ["_doc", "_status"];
    };
    [_section, _status, 1, 1, _key] call FUNC(bootDoc);
    [_doc, _status]
};

// THE BOOT SCREEN'S CHECKLIST (2026-09-10): every document this read will ask
// for, listed up front so the screen shows what is still to come, and ticked
// by FUNC(bootDoc) as each lands. The families (roles, orders, the variants)
// count their members, so the bar moves one document at a time.
GVAR(bootDocs) = [];
{["" + (_x # 0), "wait"] call FUNC(bootDoc)} forEach ([] call FUNC(svcSections));
{[_x, "wait"] call FUNC(bootDoc)} forEach ["orbat", "orbat versions", "welcome", "arsenal versions", "motorpool", "roles", "orders"];

// SETTINGS AND THE ORBAT BEFORE THE REST. The version settings live in the
// settings document, and the ORDER OF BATTLE names two of them itself - its
// messaging nets and its radio plan - so both have to be read before any
// section that a version setting can steer. Getting this order wrong is silent:
// the fetch simply uses the default and nothing says why.
{
    _x params ["_section", "_shape", "_setting"];
    if !(_section in ["settings"]) then {continue};
    ([_section, _setting] call _fnc_load) params ["_doc", "_status"];
    if (_status isEqualTo "ok") then {
        private _items = _doc getOrDefault ["items", createHashMap];
        if (_items isEqualType createHashMap) then {_settings = _items; call _fnc_missionWins};
    };
} forEach ([] call FUNC(svcSections));
["settings"] call _fnc_phase;

["orbat", "run", 0, 1, _unit + ".orbat"] call FUNC(bootDoc);
#include "svcOrbat.inc.sqf"
["orbat", ["ok", "empty"] select (count ((_structure getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []]) isEqualTo 0), 1, 1, ""] call FUNC(bootDoc);
["orbat"] call _fnc_phase;

{
    _x params ["_section", "_shape", "_setting"];
    if (_section isEqualTo "settings") then {continue};
    ([_section, _setting] call _fnc_load) params ["_doc", "_status"];

    switch (_status) do {
        case "ok": {
            switch (_shape) do {
                case "code": {
                    // A block of SQF - logistics, pylons, the AI skill block.
                    private _code = _doc getOrDefault ["code", ""];
                    if (_code isEqualType "" && _code isNotEqualTo "") then {
                        _structure set [_section, createHashMapFromArray [["code", _code]]];
                        _found = _found + 1;
                    };
                };
                case "lists": {
                    private _l = _doc getOrDefault ["lists", createHashMap];
                    if (_l isEqualType createHashMap) then {
                        private _rec = _structure getOrDefault [_section, createHashMap];
                        _rec set ["lists", _l];
                        _structure set [_section, _rec];
                        _found = _found + 1;
                    };
                };
                default {
                    private _items = _doc getOrDefault ["items", createHashMap];
                    if !(_items isEqualType createHashMap) then {_items = createHashMap};
                    // The admin document is edited on the database's own site as
                    // a plain list of Steam ids ("ids"); anyone in that list is
                    // an admin, named or not. The map ("items") carries names
                    // the in-game editor set.
                    if (_section isEqualTo "admins") then {
                        private _ids = _doc getOrDefault ["ids", []];
                        if (_ids isEqualType []) then {
                            {
                                private _uid = if (_x isEqualType "") then {_x} else {str _x};
                                if !(_uid in _items) then {_items set [_uid, createHashMapFromArray [["id", _uid], ["name", ""]]]};
                            } forEach _ids;
                        };
                    };
                    if (_section isEqualTo "settings") then {_settings = _items; call _fnc_missionWins} else {_structure set [_section, _items]};
                    _found = _found + 1;
                };
            };
        };
        case "empty": {
            if (_section isNotEqualTo "settings" && _shape isEqualTo "items") then {
                _structure set [_section, createHashMap];
            };
        };
        default {_errors = _errors + 1};
    };
} forEach ([] call FUNC(svcSections));
["sections"] call _fnc_phase;

// WHICH ORDERS OF BATTLE EXIST. The structure carries the one this mission
// runs; the editors need the names of all of them to offer a choice, and only
// the server can list the database. Ids only - the documents themselves are
// fetched when one is switched to.
private _orbatIds = [];
["orbat versions", "run", 0, 1, _unit + ".orbat.*"] call FUNC(bootDoc);
([_unit + ".orbat.", "list"] call _fnc_fetch) params ["_okeys", "_okstatus"];
["orbat versions", ["ok", "error"] select (_okstatus isEqualTo "error"), 1, 1, format ["%1 listed", [0, count _okeys] select (_okeys isEqualType [])]] call FUNC(bootDoc);
if (_okstatus isNotEqualTo "error" && _okeys isEqualType []) then {
    {
        private _id = _x select [count (_unit + ".orbat."), 99];
        if (_id isNotEqualTo "") then {_orbatIds pushBackUnique _id};
    } forEach _okeys;
};
_orbatIds sort true;
_structure set ["orbatVersions", _orbatIds];

// the WELCOME document - {title, subtitle, lines[]}, not {section, items},
// so it is fetched on its own like the ORBAT. Absent is not an error: a unit
// that has not written one keeps whatever the mission's config says.
// A UNIT KEEPS MORE THAN ONE (2026-09-09). The welcome screen is per MISSION -
// Roomba's briefing is not the framework's - and there is one <unit>.welcome
// document, so until this the only place a mission's own text could live was
// its description.ext. "currentWelcome" names a version, <unit>.welcome.<id>,
// exactly as currentOrbat names an ORBAT.
private _welcomeKey = _unit + ".welcome";
private _wantWelcome = _settings getOrDefault ["currentWelcome", ""];
if (_wantWelcome isEqualType "" && _wantWelcome isNotEqualTo "") then {
    _welcomeKey = _unit + ".welcome." + _wantWelcome;
};
["welcome", "run", 0, 1, _welcomeKey] call FUNC(bootDoc);
([_welcomeKey] call _fnc_fetch) params ["_wdoc", "_wstatus"];
// A named welcome that is not there falls back to the common one rather than
// leaving the mission with no briefing at all - the ORBAT's rule.
if (_wstatus isNotEqualTo "ok" && _welcomeKey isNotEqualTo (_unit + ".welcome")) then {
    WARNING_1("currentWelcome names '%1' and there is no such welcome - the common one is used",_wantWelcome);
    ([_unit + ".welcome"] call _fnc_fetch) params ["_wdoc", "_wstatus"];
};
["welcome", _wstatus, 1, 1, _welcomeKey] call FUNC(bootDoc);
if (_wstatus isEqualTo "error") exitWith {[createHashMap, "error"]};
if (_wstatus isEqualTo "ok") then {
    // THE TEXT OR THE OLD LINES. A welcome written since 2026-09-09 is one
    // block of structured text in "text" - the writer types it the way the
    // panel reads it. The ones written before that are a "lines" array, one
    // record per line with its own size and colour, and they still draw.
    // Either being present is what takes the panel off the mission's config.
    private _wtext = _wdoc getOrDefault ["text", ""];
    if !(_wtext isEqualType "") then {_wtext = ""};
    private _lines = _wdoc getOrDefault ["lines", []];
    if !(_lines isEqualType []) then {_lines = []};
    if (_wtext isNotEqualTo "" || {count _lines > 0}) then {
        _structure set ["welcome", createHashMapFromArray [
            ["title", [_wdoc getOrDefault ["title", ""], ""] select !((_wdoc getOrDefault ["title", ""]) isEqualType "")],
            ["subtitle", [_wdoc getOrDefault ["subtitle", ""], ""] select !((_wdoc getOrDefault ["subtitle", ""]) isEqualType "")],
            ["text", _wtext],
            ["lines", _lines]
        ]];
        _found = _found + 1;
    };
};

["orbat versions and welcome"] call _fnc_phase;

// ---- the NAMED VARIANTS of the list-shaped documents ----------------------
// The loop above fetched each one's common lists (or the version a mission
// named). This lists the "<unit>.<doc>." prefix for the rest, because the
// narrower arsenals are reached by name and nothing hands out that list -
// plt_<PLATOON>, sqd_<SQUAD> and role_<CLASS>, derived from the ids.
{
    private _doc = _x;
    private _rec = _structure getOrDefault [_doc, createHashMap];

    private _variants = createHashMap;
    [_doc + " versions", "run", 0, 1, _unit + "." + _doc + ".*"] call FUNC(bootDoc);
    ([_unit + "." + _doc + ".", "list"] call _fnc_fetch) params ["_vkeys", "_vstatus"];
    if (_vstatus isNotEqualTo "error" && _vkeys isEqualType []) then {
        [_doc + " versions", "run", 0, (count _vkeys) max 1, format ["%1 listed", count _vkeys]] call FUNC(bootDoc);
        {
            [_doc + " versions", "run", _forEachIndex, (count _vkeys) max 1, _x] call FUNC(bootDoc);
            ([_x] call _fnc_fetch) params ["_vdoc", "_vst"];
            if (_vst isEqualTo "ok") then {
                private _vl = _vdoc getOrDefault ["lists", createHashMap];
                private _vid = _vdoc getOrDefault ["id", ""];
                if (_vid isEqualTo "") then {
                    _vid = _x select [count (_unit + "." + _doc + "."), 99];
                };
                if (_vl isEqualType createHashMap && _vid isNotEqualTo "") then {
                    _variants set [_vid, _vl];
                };
            };
        } forEach _vkeys;
    };
    [_doc + " versions", ["ok", "error"] select (_vstatus isEqualTo "error"), count _variants, (count _variants) max 1, format ["%1 read", count _variants]] call FUNC(bootDoc);
    if (count _variants > 0) then {_rec set ["variants", _variants]};

    if (count _rec > 0) then {
        _structure set [_doc, _rec];
    };
// The arsenal is the only list-shaped document left with named versions: the
// radar network is a CBA setting and the vehicle spawner was removed from the
// mod (2026-09-09).
} forEach ["arsenal"];
["arsenal versions"] call _fnc_phase;

// ---- the motorpool's variants (2026-09-09) -------------------------------
// The motorpool is items-shaped, so the loop above - which reads "lists"
// documents - never saw its variants and a platoon's own pool was fetched by
// nobody. <unit>.motorpool.<name> is one pool, and the variant id IS the class
// name the mission used ("MotorPool_Nomad"), the same rule as the arsenal.
private _mpVariants = createHashMap;
["motorpool", "run", 0, 1, _unit + ".motorpool.*"] call FUNC(bootDoc);
([_unit + ".motorpool.", "list"] call _fnc_fetch) params ["_mpKeys", "_mpStatus"];
if (_mpStatus isNotEqualTo "error" && _mpKeys isEqualType []) then {
    ["motorpool", "run", 0, (count _mpKeys) max 1, format ["%1 listed", count _mpKeys]] call FUNC(bootDoc);
    {
        ["motorpool", "run", _forEachIndex, (count _mpKeys) max 1, _x] call FUNC(bootDoc);
        ([_x] call _fnc_fetch) params ["_vdoc", "_vst"];
        if (_vst isEqualTo "ok") then {
            private _vitems = _vdoc getOrDefault ["items", createHashMap];
            private _vid = _vdoc getOrDefault ["id", ""];
            if (_vid isEqualTo "") then {
                _vid = _x select [count (_unit + ".motorpool."), 99];
            };
            if (_vitems isEqualType createHashMap && _vid isNotEqualTo "") then {
                _mpVariants set [_vid, _vitems];
            };
        };
    } forEach _mpKeys;
};
["motorpool", ["ok", "error"] select (_mpStatus isEqualTo "error"), count _mpVariants, (count _mpVariants) max 1, format ["%1 read", count _mpVariants]] call FUNC(bootDoc);
if (count _mpVariants > 0) then {
    _structure set ["motorpoolVariants", _mpVariants];
    _found = _found + 1;
};
["motorpool versions"] call _fnc_phase;

if (_errors > 0) exitWith {[createHashMap, "error"]};

// ---- the roles, one document each ------------------------------------------
private _roles = createHashMap;
["roles", "run", 0, 1, _unit + ".role.*"] call FUNC(bootDoc);
([_unit + ".role.", "list"] call _fnc_fetch) params ["_rkeys", "_rlstatus"];
if (_rlstatus isEqualTo "error") exitWith {["roles", "error", 0, 1, "the list did not come"] call FUNC(bootDoc); [createHashMap, "error"]};
if (_rkeys isEqualType []) then {
    ["roles", "run", 0, (count _rkeys) max 1, format ["%1 listed", count _rkeys]] call FUNC(bootDoc);
    {
        ["roles", "run", _forEachIndex, (count _rkeys) max 1, _x] call FUNC(bootDoc);
        ([_x] call _fnc_fetch) params ["_doc", "_status"];
        if (_status isEqualTo "ok") then {
            if ((_doc getOrDefault ["deleted", false]) isEqualTo true) then {continue};
            private _role = _doc getOrDefault ["role", createHashMap];
            private _id = _doc getOrDefault ["id", ""];
            if (_id isEqualTo "" && {_role isEqualType createHashMap}) then {_id = _role getOrDefault ["id", ""]};
            if (_role isEqualType createHashMap && _id isNotEqualTo "") then {
                _role set ["id", _id];
                _roles set [_id, _role];
                _found = _found + 1;
            };
        };
    } forEach _rkeys;
};
// the shape before roles had documents of their own: <unit>.roles {items}
if (count _roles isEqualTo 0) then {
    ([_unit + ".roles"] call _fnc_fetch) params ["_doc", "_status"];
    if (_status isEqualTo "ok") then {
        private _items = _doc getOrDefault ["items", createHashMap];
        if (_items isEqualType createHashMap) then {
            _roles = _items;
            _found = _found + 1;
        };
    };
};
["roles", ["ok", "empty"] select (count _roles isEqualTo 0), count _roles, (count _roles) max 1, format ["%1 read", count _roles]] call FUNC(bootDoc);
_structure set ["roles", _roles];
["roles"] call _fnc_phase;

// ---- the orders, one document each ----------------------------------------
private _opords = createHashMap;
["orders", "run", 0, 1, _unit + ".opord.*"] call FUNC(bootDoc);
([_unit + ".opord.", "list"] call _fnc_fetch) params ["_keys", "_lstatus"];
if (_lstatus isEqualTo "error") exitWith {["orders", "error", 0, 1, "the list did not come"] call FUNC(bootDoc); [createHashMap, "error"]};
if (_keys isEqualType []) then {
    ["orders", "run", 0, (count _keys) max 1, format ["%1 listed", count _keys]] call FUNC(bootDoc);
    {
        ["orders", "run", _forEachIndex, (count _keys) max 1, _x] call FUNC(bootDoc);
        ([_x] call _fnc_fetch) params ["_doc", "_status"];
        if (_status isEqualTo "ok") then {
            // an order removed in game is a tombstone, as a removed role is
            if ((_doc getOrDefault ["deleted", false]) isEqualTo true) then {continue};
            private _order = _doc getOrDefault ["order", createHashMap];
            private _id = _doc getOrDefault ["id", ""];
            if (_id isEqualTo "") then {_id = _order getOrDefault ["id", ""]};
            if (_order isEqualType createHashMap && _id isNotEqualTo "") then {
                _order set ["id", _id];
                _opords set [_id, _order];
                _found = _found + 1;
            };
        };
    } forEach _keys;
};
["orders", ["ok", "empty"] select (count _opords isEqualTo 0), count _opords, (count _opords) max 1, format ["%1 read", count _opords]] call FUNC(bootDoc);
_structure set ["opords", _opords];
["orders"] call _fnc_phase;

["3/6", format ["service read: %1 s for %2 request(s) and %3 reused - %4 s waiting on the database, %5 s parsing, %6 chars (per document in the .rpt)",
    (diag_tickTime - _readAt) toFixed 2, _stats # 0, _stats # 1, (_stats # 2) toFixed 2, (_stats # 3) toFixed 2, _stats # 4]] call FUNC(bootLog);

if (_found isEqualTo 0) exitWith {[createHashMap, "empty"]};

[createHashMapFromArray [["structure", _structure], ["settings", _settings]], "ok"]
