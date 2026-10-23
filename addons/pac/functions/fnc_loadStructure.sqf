#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_loadStructure

Description:
    Compiles the mission's CfgGFA_PAC into hashmaps, once, and hashes it.

    THE MISSION IS THE SEED. Ranks, skills, awards, statuses, roles, nets,
    the ORBAT, the report deck, the schemes and OPORDs are read from the
    mission's own config here; what the unit keeps in its database (or edited
    in game, in the profile) goes over them at boot (FUNC(structureAdopt),
    FUNC(boot)). A mission that keeps everything in the database carries
    three settings and nothing else, and every section here comes up empty.

    IT IS READ ONCE. A config walk per lookup would be a config walk per roster
    row per redraw; the sections become hashmaps here and every consumer reads
    those. A mission cannot change its own config mid-mission, so once is right.

    MISSING IS NOT BROKEN. A mission with no CfgGFA_PAC at all gets empty
    sections and a warning, and every surface built on this shows nothing rather
    than throwing. A unit that has not written its structure yet should be able
    to load the mod.

    THE HASH IS THE VERSION. FUNC(structureHash) turns the compiled sections
    into one number the live tile shows and the delta tool compares - "why is
    this server different" is answerable by reading two tiles.

Parameters:
    None

Returns:
    Structure hash <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

private _cfg = missionConfigFile >> "CfgGFA_PAC";

GVAR(structure) = createHashMap;
GVAR(settings) = createHashMap;

if !(isClass _cfg) exitWith {
    WARNING("no CfgGFA_PAC in the mission - TAC//PAC has no structure to show");
    GVAR(structureHash) = 0;
    0
};

// ---- settings --------------------------------------------------------------
// Read as declared types, with the handoff's own defaults. settings is the one
// section that is never synced and never pulled: unitId, serverId and sync mode
// have to be in the local file or nothing can bootstrap.
private _s = _cfg >> "settings";
{
    _x params ["_key", "_default"];
    private _entry = _s >> _key;

    private _value = switch (true) do {
        case (!isClass _s || {!isText _entry && {!isNumber _entry} && {!isArray _entry}}): {_default};
        case (isNumber _entry): {getNumber _entry};
        case (isArray _entry): {getArray _entry};
        default {getText _entry};
    };

    GVAR(settings) set [_key, _value];
} forEach [
    ["unitId", ""], ["serverId", ""], ["schemaVersion", PAC_SCHEMA],
    ["autoSlot", 1], ["slotMatch", "role"], ["arsenalMode", "both"],
    ["savedLoadouts", 3], ["currentOpord", ""], ["opWindows", []],
    ["sync", "off"]
];

// ---- the collections -------------------------------------------------------
// Every section is the same shape - a collection of classes, each becoming one
// hashmap keyed by its own class name, which IS the stable id the handoff says
// player data references. A name is a display string and may change; the class
// name is the contract.
{
    _x params ["_section", "_fields"];

    private _out = createHashMap;

    {
        private _entry = _x;
        private _id = configName _entry;
        private _rec = createHashMapFromArray [["id", _id]];

        {
            _x params ["_field", "_kind"];
            private _c = _entry >> _field;

            // A ROLE DECLARED HERE IS AN ENRICHMENT of its Dynamic_Roles class
            // (a gate, a whitelist): only what it actually writes is read, so
            // the class's own nets and loadout are not blanked by defaults
            // before FUNC(rolesFromMission) can fill them.
            if (_section isEqualTo "roles" && {isNull _c}) then {continue};

            _rec set [_field, switch (_kind) do {
                case "n": {getNumber _c};
                case "a": {getArray _c};
                default {getText _c};
            }];
        } forEach _fields;

        _out set [_id, _rec];
    } forEach ("true" configClasses (_cfg >> _section));

    GVAR(structure) set [_section, _out];
} forEach (["ranks", "skills", "awards", "statuses", "admins", "roles", "promotion", "trainings"] apply {
    // name first, then FUNC(structFields)'s [field, kind] - the one table
    [_x, [["name", "t"]] + (([_x] call FUNC(structFields)) apply {[_x # 0, _x # 1]})]
});

// ---- the report deck (JMFSBFR_Templates) as data ---------------------------
// Each template in the shape jmfsb_messaging_fnc_registerTemplate takes -
// title, short, lines, options - so the database copy registers without a
// second conversion. Mirrors messaging's FUNC(loadTemplates) field by field.
private _deck = createHashMap;
{
    private _tCfg = _x;
    private _options = [];
    {
        if (isText (_tCfg >> _x)) then {_options pushBack [_x, getText (_tCfg >> _x)]};
    } forEach ["kind", "priority", "subject", "transitionsTo", "senderMustBe", "reportable", "broadcast", "routing", "anchor"];
    {
        if (isArray (_tCfg >> _x)) then {_options pushBack [_x, getArray (_tCfg >> _x)]};
    } forEach ["replyableWith", "allowedFrom"];
    private _lines = [];
    {
        private _lCfg = _tCfg >> "Lines" >> _x;
        if !(isClass _lCfg) then {continue};
        private _fields = [];
        {
            private _fCfg = _x;
            private _fo = [];
            {if (isNumber (_fCfg >> _x)) then {_fo pushBack [_x, getNumber (_fCfg >> _x) > 0]}} forEach ["required", "noCur"];
            {if (isNumber (_fCfg >> _x)) then {_fo pushBack [_x, getNumber (_fCfg >> _x)]}} forEach ["min", "max"];
            {if (isText (_fCfg >> _x)) then {_fo pushBack [_x, getText (_fCfg >> _x)]}} forEach ["exclusive", "autoFill", "source"];
            if (isArray (_fCfg >> "choices")) then {_fo pushBack ["choices", getArray (_fCfg >> "choices")]};
            _fields pushBack [getText (_fCfg >> "prefix"), getText (_fCfg >> "hint"), getText (_fCfg >> "type"), _fo];
        } forEach (configProperties [_lCfg >> "Fields", "isClass _x", false]);
        _lines pushBack [getText (_lCfg >> "name"), getText (_lCfg >> "label"), _fields];
    } forEach (getArray (_tCfg >> "lineOrder"));
    _deck set [configName _tCfg, createHashMapFromArray [["id", configName _tCfg], ["title", getText (_tCfg >> "title")], ["short", getText (_tCfg >> "short")], ["lines", _lines], ["options", _options]]];
} forEach (configProperties [missionConfigFile >> "JMFSBFR_Templates", "isClass _x", false]);
GVAR(structure) set ["templates", _deck];

// ---- the tacpad colour schemes (JMFSBFR_TacpadSchemes) as data --------------
private _schemes = createHashMap;
{
    _schemes set [configName _x, createHashMapFromArray [["id", configName _x], ["name", getText (_x >> "name")], ["ground", getText (_x >> "ground")], ["ink", getText (_x >> "ink")], ["accent", getText (_x >> "accent")]]];
} forEach ("true" configClasses (missionConfigFile >> "JMFSBFR_TacpadSchemes"));
GVAR(structure) set ["schemes", _schemes];

// ---- ORBAT: the squads and their slots, the platoon tabs -------------------
// Kept in the structure so a unit can hold it in the database and change a
// squad's slots without a mission update. The group system reads it through
// jmfsb_groups_fnc_orbat; the mission's Dynamic_Groups is the seed.
private _orbat = createHashMap;
_orbat set ["groups", (getArray (missionConfigFile >> "Dynamic_Groups" >> "group_setup")) apply {[_x # 0, _x # 1, _x param [2, "true"]]}];
private _platoons = [];
{
    _platoons pushBack [configName _x, getText (_x >> "name"), getText (_x >> "callsign"), getText (_x >> "net"), getArray (_x >> "squads")];
} forEach (configProperties [missionConfigFile >> "Dynamic_Groups" >> "Platoons", "isClass _x", true]);
_orbat set ["platoons", _platoons];
// NO RadioNets CLASS (user, 2026-09-09: ACRE's tab configures ACRE radios, the
// radio plan's own tab everything else - today the net plan for game voice).
// A squad's channel or net is the radio plan's business and nothing else decides it.
_orbat set ["faction", getText (missionConfigFile >> "Dynamic_Groups" >> "faction_name")];
GVAR(structure) set ["orbat", _orbat];

// ---- the nets (JMFSBFR_Nets) as data ---------------------------------------
// {id -> {id, name, order}}: the id is the net's name on the rail and the
// radio, name its description, order its place in the list. Read through
// jmfsb_messaging_fnc_netNames.
private _nets = createHashMap;
{
    private _id = if (_x isEqualType []) then {_x param [0, ""]} else {_x};
    private _desc = if (_x isEqualType []) then {_x param [1, ""]} else {""};
    if (_id isEqualType "" && _id isNotEqualTo "") then {
        if !(_desc isEqualType "") then {_desc = ""};
        _nets set [_id, createHashMapFromArray [["id", _id], ["name", _desc], ["order", _forEachIndex]]];
    };
} forEach (getArray (missionConfigFile >> "JMFSBFR_Nets" >> "nets"));
GVAR(structure) set ["nets", _nets];

// ---- the radio plan --------------------------------------------------------
// Empty here: config_radio.hpp is SQF the mission runs at ITS preInit, after
// this. The server reads the globals it set at boot (FUNC(radioFromMission))
// and every machine writes the structure's plan back out (FUNC(radioApply)).
GVAR(structure) set ["radio", createHashMap];

// ---- roles: every Dynamic_Roles role, whole, without a second list --------
// Shared with the service path - see FUNC(rolesFromMission).
[] call FUNC(rolesFromMission);

// ---- OPORDs ----------------------------------------------------------------
// Their own loader, because an OPORD is six nested sections rather than a flat
// record - see FUNC(record) for the shape a viewer gets handed. History is
// whatever files are in the collection: there is no archive flag and no delete,
// a removed file simply stops being listed and the id it left behind reads as
// archived wherever it is still referenced.
private _opords = createHashMap;
{
    private _o = _x;
    private _id = configName _o;

    private _sections = createHashMap;
    {
        _x params ["_name", "_fields"];
        private _sec = _o >> _name;
        private _rec = createHashMap;
        {
            _x params ["_field", "_kind"];
            private _c = _sec >> _field;
            _rec set [_field, switch (_kind) do {
                case "n": {getNumber _c};
                case "a": {getArray _c};
                default {getText _c};
            }];
        } forEach _fields;
        _sections set [_name, _rec];
    } forEach [
        ["header",         [["id","t"], ["title","t"], ["date","t"], ["campaign","t"], ["release","t"],
                            ["distribution","t"], ["mapImage","t"], ["markers","a"]]],
        ["situation",      [["overview","t"], ["enemy","t"], ["enemyFactions","a"],
                            ["friendly","t"], ["civilTerrain","t"]]],
        ["mission",        [["mission","t"], ["execution","t"]]],
        ["adminLogistics", [["admin","t"], ["logistics","t"], ["special","t"],
                            ["armaConsiderations","t"]]],
        ["commandSignal",  [["signal","t"], ["command","t"]]],
        ["roe",            [["roeText","t"], ["clarifications","a"]]]
    ];

    // attachments are a collection inside situation - {callsign, assets[]}
    private _att = [];
    {
        _att pushBack createHashMapFromArray [
            ["callsign", getText (_x >> "callsign")],
            ["assets", getArray (_x >> "assets")]
        ];
    } forEach ("true" configClasses (_o >> "situation" >> "attachments"));
    (_sections get "situation") set ["attachments", _att];

    _sections set ["id", _id];
    _opords set [_id, _sections];
} forEach ("true" configClasses (_cfg >> "opords"));

GVAR(structure) set ["opords", _opords];

// ---- WHAT THIS MISSION'S FILES FEED ---------------------------------------
// Recorded here, which is the last moment the config's own contribution stands
// alone: FUNC(boot) merges the profile's in-game edits over it at 2/6 and the
// service's documents at 3/6, and after that there is no telling a file's rank
// from a document's.
//
// HERE AND NOT IN FUNC(boot), because boot exits early on a client
// (`if (!isServer) exitWith`) and the section menu this feeds is drawn on a
// client. This function runs on every machine, from XEH_postInit.
//
// Without a database, a section on this list has no editable screen: the game
// cannot write config\, so an editor for one could only save into the profile
// and be overruled by the file at the next start. FUNC(fileFed) is that test.
// "radio" is on the list for completeness; it has no screen of its own.
GVAR(fromMission) = [];
{
    private _v = GVAR(structure) getOrDefault [_x, createHashMap];
    private _has = if (_x isEqualTo "orbat") then {
        count (_v getOrDefault ["groups", []]) > 0
    } else {
        count _v > 0
    };
    if (_has) then {GVAR(fromMission) pushBack _x};
} forEach ["ranks", "skills", "awards", "statuses", "promotion", "trainings",
           "traits", "admins", "roles", "nets", "radio", "templates", "schemes",
           "motorpool", "cosmetics", "arsenal", "logistics", "pylons", "skill",
           "orbat", "welcome", "opords"];

GVAR(structureHash) = [] call FUNC(structureHash);

INFO_3("structure: %1 rank(s), %2 skill(s), %3 OPORD(s)",
    count (GVAR(structure) get "ranks"),
    count (GVAR(structure) get "skills"),
    count _opords);
INFO_2("structure hash %1, unit '%2'",GVAR(structureHash),GVAR(settings) get "unitId");

GVAR(structureHash)
