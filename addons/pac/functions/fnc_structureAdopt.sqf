#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_structureAdopt

Description:
    Makes a structure document - {structure: {ranks, skills, awards,
    statuses, roles, opords, ...}} as the service assembles it, pac_sync.py
    pull writes it and STRUCTURE OUT exports it - THE structure, on the
    server, in place of whatever the mission's config compiled. Called by
    the boot (service) and FUNC(structureImport) (clipboard).

    THE DATABASE WINS, THE MISSION IS THE SEED. A mission whose CfgGFA_PAC
    carries only settings gets everything from here; a mission that still
    carries the sections is what pushes a first document up when the
    database has none (FUNC(boot)). The six sections every database has
    are required; the ORBAT, the nets, the radio plan, the report deck and
    the schemes ride along when the document has them and the mission's
    stay otherwise. Roles the mission still declares in Dynamic_Roles are
    merged back in after adoption, fields the document lacks filled from
    the class (FUNC(rolesFromMission)).

    The hash is recomputed so the tile and the delta tool describe what is
    actually loaded.

Parameters:
    0: The document <HASHMAP>

Returns:
    Whether it was adopted <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_doc", createHashMap, [createHashMap]]];

if (!isServer) exitWith {false};

private _s = _doc getOrDefault ["structure", createHashMap];
if !(_s isEqualType createHashMap) exitWith {false};

private _out = createHashMap;
{
    private _v = _s getOrDefault [_x, createHashMap];
    if !(_v isEqualType createHashMap) exitWith {_out = createHashMap};
    _out set [_x, _v];
} forEach ["ranks", "skills", "awards", "statuses", "roles", "opords"];
if (count _out isNotEqualTo 6) exitWith {false};

// the ORBAT rides along when the document has one; else the mission's stays
private _orbat = _s getOrDefault ["orbat", createHashMap];
_out set ["orbat", [GVAR(structure) getOrDefault ["orbat", createHashMap], _orbat] select (_orbat isEqualType createHashMap && {(_orbat getOrDefault ["groups", []]) isNotEqualTo []})];

// the same for the sections a database may not hold yet
{
    private _v = _s getOrDefault [_x, createHashMap];
    _out set [_x, [GVAR(structure) getOrDefault [_x, createHashMap], _v] select (_v isEqualType createHashMap && {count _v > 0})];
// EVERY SECTION THE SERVICE FETCHES, or the document is read and then thrown
// away on its way through here - which is what happened to cosmetics,
// logistics, pylons and the skill block. The list comes off the same table the
// fetch does, so adding a section is one edit in FUNC(svcSections), not two.
} forEach (((([] call FUNC(svcSections)) select {(_x # 0) isNotEqualTo "settings" && (_x # 0) isNotEqualTo "admins"}) apply {_x # 0})
    + ["welcome", "motorpoolVariants"]);
// THE VERSION LIST IS AN ARRAY OF IDS, not a section: the rule above wants a
// hashmap and handed the ORBAT page an empty one instead ("select: Type
// HashMap, expected Array", 2026-09-10 - the ORBAT would not open).
private _versions = _s getOrDefault ["orbatVersions", []];
if !(_versions isEqualType []) then {_versions = GVAR(structure) getOrDefault ["orbatVersions", []]};
if !(_versions isEqualType []) then {_versions = []};
_out set ["orbatVersions", _versions];

GVAR(structure) = _out;
[] call FUNC(adminsPublish);

// ALL THE CONFIG MOVES, bar three: the settings in the document override the
// mission's, except unitId, serverId and sync - those say where to look and
// which server this is, and a database cannot tell a server that.
private _settings = _doc getOrDefault ["settings", createHashMap];
if (_settings isEqualType createHashMap) then {
    private _missionSettings = missionConfigFile >> "CfgGFA_PAC" >> "settings";
    private _versionSettings = ((([] call FUNC(svcSections)) apply {_x # 2}) select {_x isNotEqualTo ""})
        + ["currentOrbat", "currentWelcome", "currentOpord"];
    {
        if (_x in ["unitId", "serverId", "sync"]) then {continue};

        // WHICH VERSION A MISSION RUNS IS THE MISSION'S TO SAY (2026-09-09).
        // currentOrbat, currentArsenal, currentWelcome and currentOpord name
        // which of the unit's several orders of battle, arsenals, briefings and
        // orders this mission uses - and that is per MISSION, not per unit. The
        // database's value is the DEFAULT, for a mission that does not care;
        // a mission that declares one in its own CfgGFA_PAC keeps it.
        //
        // Only when the mission actually declares the property. A missing one
        // is not a choice, and the default has to win in that case or the
        // setting would be unusable from the website.
        // Every "which version" setting there is, from the same table the
        // fetch uses, plus the two that are fetched by name.
        if ((_x in _versionSettings)
            && {isText (_missionSettings >> _x)}
            && {(getText (_missionSettings >> _x)) isNotEqualTo ""}) then {
            continue;
        };

        GVAR(settings) set [_x, _y];
    } forEach _settings;
};

[] call FUNC(rolesFromMission);
GVAR(structureHash) = [] call FUNC(structureHash);

// THE MISSION CONFIGS THE DATABASE CARRIES, NOW THAT IT IS HERE (2026-09-09).
// EFUNC(init,missionConfigsReady) falls back to <unit>.logistics, .pylons and
// .skill for anything the mission did not hand over itself - but at preInit,
// when it is first called, the structure has not arrived and there is nothing
// to fall back TO, so a mission with no config\ folder got empty databases and
// no explanation. This is the moment the data exists, so this is where it is
// asked again. It is idempotent: a mission that DID ship those files built them
// already and this finds the work done.
if (!isNil QEFUNC(init,missionConfigsReady)) then {
    if (call EFUNC(init,missionConfigsReady)) then {
        INFO("mission configs built from the database - the mission shipped none");
    };
};

INFO_4("structure adopted from the service: %1 rank(s), %2 skill(s), %3 role(s), %4 OPORD(s)",count (_out get "ranks"),count (_out get "skills"),count (_out get "roles"),count (_out get "opords"));

true
