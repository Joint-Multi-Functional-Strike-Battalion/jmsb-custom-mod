#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_seedFromUnit

Description:
    Fills an EMPTY rank on a player's record from the Arma rank the mission
    gave them, and seeds their skills once from the slot they took. Server
    only; the player's machine sends the rank on spawn, because rank is
    local to where setRank ran.

    THE SLOT IS NOT THE BILLET. The role a player picks in the role picker
    and the squad it puts them in are what they are doing THIS op; the
    record's roleId and groupId are the billet and squad the unit assigned
    them, set on the PAC page and nowhere else. This function used to copy
    the picked slot into an empty roleId / groupId, and the picker became
    the roster (user, 2026-09-05: "the role I select in the role picker
    should not become my role in PAC and in the db"). It no longer writes
    either. The rank floor stays: a record with no rank shows the structure
    rank that maps to the Arma rank, and an admin's edit wins because this
    only ever writes into an empty field.

Parameters:
    0: The unit <OBJECT>
    1: Arma rank, as `rank` returns it <STRING>
    2: Dynamic_Roles class the unit is slotted as, "" for none <STRING> -
       used for the one-time skills seed only, never written as roleId
    3: The group's name (groupId group) <STRING> - accepted, no longer used

Returns:
    Whether anything was written <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]], ["_armaRank", "", [""]], ["_slot", "", [""]], ["_groupName", "", [""]]];

if (!isServer || isNull _unit || GVAR(readOnly)) exitWith {false};
// The sender seeds only himself, and with the rank the server sees on him, not
// the one he names (review S5).
if !([_unit] call EFUNC(common,senderIs)) exitWith {false};
_armaRank = rank _unit;

private _uid = [_unit] call FUNC(uid);
if (_uid isEqualTo "") exitWith {false};

private _rec = [_uid, name _unit] call FUNC(record);
if (count _rec isEqualTo 0) exitWith {false};

private _changed = false;

if ((_rec getOrDefault ["rankId", ""]) isEqualTo "" && _armaRank isNotEqualTo "") then {
    private _ranks = GVAR(structure) getOrDefault ["ranks", createHashMap];
    private _ids = keys _ranks;
    _ids sort true;
    private _hit = _ids findIf {toUpper ((_ranks get _x) getOrDefault ["armaRank", ""]) isEqualTo toUpper _armaRank};
    if (_hit >= 0) then {
        _rec set ["rankId", _ids # _hit];
        _changed = true;
    };
};

// roleId is NOT seeded from the slot - see the header. The billet is the
// PAC page's to set.

// SKILLS, ONCE, FROM THE ROLE. PAC is the source of truth for skills and the
// roles no longer apply them; the day that switches on, every man would
// arrive with nothing. So the first time a record is seen with a slot, the
// role's traits and customVariables are read and every structure skill whose
// effects the role satisfied is granted. Flagged on the record so an admin
// who later clears a man's skills is not overruled at his next spawn.
if (!(_rec getOrDefault ["skillsSeeded", false]) && _slot isNotEqualTo "") then {
    // The role as the structure holds it - the database's or the mission's,
    // whole (FUNC(rolesFromMission)) - so a unit with no config_roles.hpp
    // seeds exactly as one with.
    private _roleRec = (GVAR(structure) getOrDefault ["roles", createHashMap]) getOrDefault [_slot, createHashMap];
    if !(_roleRec isEqualType createHashMap) then {_roleRec = createHashMap};
    private _has = [];
    {
        if !(_x isEqualType []) then {continue};
        _x params ["_n", ["_v", "false"]];
        // A number (an ACE class) counts when above zero; "true"/"1" as text does.
        if (_v isEqualType 0) then {_v = ["false", "true"] select (_v > 0)};
        if (_v in ["true", "1"]) then {_has pushBackUnique toLower _n};
    } forEach ((_roleRec getOrDefault ["traits", []]) + (_roleRec getOrDefault ["customVariables", []]));

    private _fnc_satisfied = {
        params ["_effect"];
        private _parts = _effect splitString ":";
        if (count _parts < 2) exitWith {false};
        private _val = toLower trim ((_parts select [1]) joinString ":");
        switch (toLower trim (_parts # 0)) do {
            case "medic": {"medic" in _has || "ace_medical_medicclass" in _has};
            case "engineer": {"engineer" in _has || "ace_isengineer" in _has};
            case "eod": {"explosivespecialist" in _has || "ace_iseod" in _has};
            case "trait": {_val in _has};
            case "var": {(trim ((_val splitString "=") # 0)) in _has};
            default {false};
        };
    };

    private _granted = [];
    {
        private _effects = _y getOrDefault ["effects", []];
        if (_effects isNotEqualTo [] && {(_effects findIf {!([_x] call _fnc_satisfied)}) < 0}) then {_granted pushBack _x};
    } forEach (GVAR(structure) getOrDefault ["skills", createHashMap]);
    _granted sort true;

    if ((_rec getOrDefault ["skillIds", []]) isEqualTo []) then {_rec set ["skillIds", _granted]};
    _rec set ["skillsSeeded", true];
    _changed = true;
    INFO_3("%1: skills seeded from role %2: %3",name _unit,_slot,_granted);
};

// groupId is NOT seeded from the slot's squad either - same reason.

if (!_changed) exitWith {false};

_rec set ["updatedAt", [] call FUNC(stamp)];
_rec set ["serverId", GVAR(settings) getOrDefault ["serverId", ""]];
GVAR(players) set [_uid, _rec];

private _rankNow = _rec getOrDefault ["rankId", ""];
private _roleNow = _rec getOrDefault ["roleId", ""];
INFO_3("seeded %1 from the unit: rank %2, role %3",name _unit,_rankNow,_roleNow);

[] call FUNC(storeSave);
[] call FUNC(publish);

true
