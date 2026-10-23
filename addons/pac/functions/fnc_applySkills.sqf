#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_applySkills

Description:
    Applies a player's PAC skills to their unit, as the effects each skill
    declares in the structure.

    A SKILL IS A NAME FOR A SET OF EFFECTS. The handoff lists what an effect can
    be: an ACE medic, engineer or EOD class; a custom trait such as isISR or
    isJFO; and arbitrary setVariable pairs for anything else. So an effect is a string in one of three shapes -

        "medic:1"                ACE medical class  (0 none, 1 CLS, 2 medic)
        "engineer:2"             ACE engineer class (0, 1, 2)
        "eod:1"                  ACE explosives
        "trait:isISR"            a unit variable set true, broadcast
        "var:someName=someValue" any setVariable, value compiled if it is
                                 true/false/number, kept as a string otherwise
        "arsenal:marksman"       a qualification arsenal: the document
                                 <unit>.arsenal.qual_MARKSMAN is added to the
                                 man's arsenal (jmfsb_groups_fnc_buildArsenal)

    - and this is the one place that knows what those shapes mean.

    CLEARED FIRST, THEN APPLIED. Every variable this function has ever set on
    the unit is set back to nil before the new set goes on, so a skill taken
    away actually goes away. The list of what it set is kept on the unit for
    that purpose - the same trick FUNC(setupPlayer) plays with
    YMF_myCustomVariables, and for the same reason.

    NO SKILLS IS NO SKILLS. A player nobody has
    assigned anything to arrives with the ACE classes at 0 and no traits, and
    that is the handoff's DECIDED answer, not an oversight. Assigning is the
    admin panel's job.

    LOCAL TO THE UNIT. setUnitTrait needs the unit local, so this is
    remoteExec'd to the owner.

    THE ROLE'S SKILLS AND THE MAN'S SKILLS AT ONCE. What is applied is the
    man's own PAC skills PLUS the skills his current role grants (the role's
    defaultSkills - "Skills it grants" on the role page), so a role can hand
    out what the job needs while a man's own qualifications go with him from
    role to role. Taking another role takes the old role's grants away.

Parameters:
    0: The unit <OBJECT>
    1: skillIds <ARRAY of STRING>

Returns:
    How many effects were applied <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]], ["_skillIds", [], [[]]]];

if (isNull _unit || {!local _unit}) exitWith {0};

// the role's grants on top of the man's own - a copy, the roster row is shared
_skillIds = +_skillIds;
private _roleId = _unit getVariable ["YMF_role", ""];
private _role = createHashMap;
if (_roleId isNotEqualTo "") then {
    _role = (GVAR(structure) getOrDefault ["roles", createHashMap]) getOrDefault [_roleId, createHashMap];
    if (_role isEqualType createHashMap) then {
        {
            if (_x isEqualType "" && _x isNotEqualTo "") then {_skillIds pushBackUnique _x};
        } forEach (_role getOrDefault ["defaultSkills", []]);
    };
};

// AND THIS MISSION'S SESSION SKILLS from the admin panel (FUNC(sessionSkills)):
// kept on the server by Steam id until the mission ends, never stored. A
// "skill:<id>" entry is held like any other skill - effects, arsenal, tag;
// anything else is a bare effect applied after the skills.
private _sessionEffects = [];
{
    if (_x select [0, 6] isEqualTo "skill:") then {
        _skillIds pushBackUnique (_x select [6]);
    } else {
        _sessionEffects pushBack _x;
    };
} forEach (((missionNamespace getVariable [QGVAR(session), createHashMap]) getOrDefault [getPlayerUID _unit, []])
    + (_unit getVariable [QGVAR(tempEffects), []]));

// ---- clear what we set last time -------------------------------------------
{
    _unit setVariable [_x, nil, true];
} forEach (_unit getVariable [QGVAR(setVars), []]);
{
    _unit setUnitTrait [_x, false];
} forEach (_unit getVariable [QGVAR(setTraits), []]);

_unit setVariable ["ace_medical_medicClass", 0, true];
_unit setVariable ["ACE_IsEngineer", 0, true];
_unit setVariable ["ACE_isEOD", false, true];
_unit setUnitTrait ["Medic", false];
_unit setUnitTrait ["Engineer", false];
_unit setUnitTrait ["ExplosiveSpecialist", false];

private _setVars = [];
private _setTraits = [];
private _quals = [];
private _applied = 0;
private _skills = GVAR(structure) getOrDefault ["skills", createHashMap];

private _fnc_effect = {
    params ["_effect"];
    private _parts = _effect splitString ":";
    if (count _parts < 2) exitWith {
        WARNING_1("skill effect '%1' is not kind:value - skipped",_effect);
        false
    };
    private _kind = toLower trim (_parts # 0);
    private _val = trim ((_parts select [1]) joinString ":");
    switch (_kind) do {
        case "medic": {
            private _n = ((parseNumber _val) max 0 min 2) max (_unit getVariable ["ace_medical_medicClass", 0]);
            _unit setVariable ["ace_medical_medicClass", _n, true];
            _unit setUnitTrait ["Medic", _n > 0];
        };
        case "engineer": {
            private _n = ((parseNumber _val) max 0 min 2) max (_unit getVariable ["ACE_IsEngineer", 0]);
            _unit setVariable ["ACE_IsEngineer", _n, true];
            _unit setUnitTrait ["Engineer", _n > 0];
        };
        case "eod": {
            private _on = (parseNumber _val) > 0 || {_unit getVariable ["ACE_isEOD", false]};
            _unit setVariable ["ACE_isEOD", _on, true];
            _unit setUnitTrait ["ExplosiveSpecialist", _on];
        };
        // AN ENGINE TRAIT IS A TRAIT, NOT A VARIABLE. "trait:UAVHacker" (the UAV
        // operator skill) used to land as a variable named UAVHacker, which the
        // engine and jmfsb_devices' drone control (getUnitTrait) never read - a
        // man with the skill could fly nothing (user, 2026-10-21). The engine's
        // own traits go through setUnitTrait; anything else (isJFO, isISR) is
        // the mission flag it always was.
        case "trait": {
            if ((toLower _val) in ENGINE_TRAITS) then {
                _unit setUnitTrait [_val, true];
                _setTraits pushBackUnique _val;
            } else {
                _unit setVariable [_val, true, true];
                _setVars pushBackUnique _val;
            };
        };
        case "arsenal": {
            _quals pushBackUnique toLower _val;
        };
        case "var": {
            private _kv = _val splitString "=";
            if (count _kv < 2) exitWith {
                WARNING_1("skill effect '%1' is var without name=value - skipped",_effect);
                false
            };
            private _name = trim (_kv # 0);
            private _raw = trim ((_kv select [1]) joinString "=");
            private _value = switch (true) do {
                case (_raw isEqualTo "true"): {true};
                case (_raw isEqualTo "false"): {false};
                case (_raw isEqualTo str (parseNumber _raw)): {parseNumber _raw};
                default {_raw};
            };
            _unit setVariable [_name, _value, true];
            _setVars pushBackUnique _name;
        };
        default {
            WARNING_2("skill effect '%1' has unknown kind '%2' - skipped",_effect,_kind);
            false
        };
    };
    true
};

{
    private _skill = _skills getOrDefault [_x, createHashMap];
    if (count _skill isEqualTo 0) then {
        WARNING_1("skill '%1' is not in the structure - skipped",_x);
        continue;
    };
    {
        if ([_x] call _fnc_effect) then {_applied = _applied + 1};
    } forEach (_skill getOrDefault ["effects", []]);
} forEach _skillIds;

// THEN THE SESSION'S BARE EFFECTS on top - what the admin panel applied for
// this mission that is not a whole skill. Never stored.
{
    if ([_x] call _fnc_effect) then {_applied = _applied + 1};
} forEach _sessionEffects;

_unit setVariable [QGVAR(setVars), _setVars];
_unit setVariable [QGVAR(setTraits), _setTraits];

// WHAT HE IS QUALIFIED AS, FOR EVERYBODY ELSE TO SEE (user, 2026-10-07: "a
// medic is seen as a medic"). Arma's own roleDescription is fixed by the slot
// and cannot be changed by script, so the skill abbreviations go on the unit,
// public, most telling first - MED before CLS - and the roster, the
// HUD squad list, the BFT map and the slot menu read them
// (jmfsb_tacpad_fnc_roleShort and the rest).
private _priority = ["medic", "breacher", "sniper", "marksman", "jfo", "eng", "isr", "uav", "cls"];
private _held = _skillIds select {_x in _skills};
_held = (_priority select {_x in _held}) + (_held select {!(_x in _priority)});
private _tags = [];
{
    private _abbrev = (_skills get _x) getOrDefault ["abbrev", ""];
    if (_abbrev isNotEqualTo "") then {_tags pushBackUnique toUpper _abbrev};
} forEach _held;
if (_tags isNotEqualTo (_unit getVariable [QGVAR(skillTags), []])) then {
    _unit setVariable [QGVAR(skillTags), _tags, true];
};
// The ids too, for what keys on a skill rather than shows it - the VON comm
// plan's skill based nets (FUNC(netPlanUnit)).
if (_held isNotEqualTo (_unit getVariable [QGVAR(skillIds), []])) then {
    _unit setVariable [QGVAR(skillIds), _held, true];
};

// THE ARSENAL IS REBUILT ONLY WHEN THE QUALIFICATIONS CHANGED - this runs on
// every roster publish, and rebuilding an arsenal nobody's skills touched is
// work for nothing. A change mid-mission (an admin granting Marksman) reaches
// the arsenal here, with no respawn.
_quals sort true;
if (_quals isNotEqualTo (_unit getVariable [QGVAR(arsenalQuals), []])) then {
    _unit setVariable [QGVAR(arsenalQuals), _quals];
    [QGVAR(arsenalChanged), []] call CBA_fnc_localEvent;
};

TRACE_3("skills applied",name _unit,count _skillIds,_applied);

_applied
