#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_loadoutStore

Description:
    Keeps a player's loadout on their PAC record, keyed by the role it was
    saved under. Server only.

    KEYED BY ROLE. The record's loadouts map is {roleKey -> [stamp, loadout]}
    where roleKey is the PAC roleId if the player has one, else the
    Dynamic_Roles role they are slotted as - so a man who plays medic and
    rifleman on different nights keeps one of each.

    CAPPED BY savedLoadouts. A new key past the cap evicts the oldest by its
    stamp, which is why the stamp is kept with the loadout.

    NOT VALIDATED HERE. The handoff says validated against arsenalWhitelist
    ON LOAD, and that is where it happens (FUNC(loadoutSend)) - a whitelist
    can change between the save and the spawn, and the spawn is what has to
    be right.

    THE SENDER MUST BE THE OWNER. This is not an admin door; a player saves
    their own loadout and nobody else's, so the check is that the unit whose
    loadout arrived is the one the message came from.

Parameters:
    0: The unit <OBJECT>
    1: Loadout <ARRAY> - getUnitLoadout

Returns:
    The role key it was stored under, "" if refused <STRING>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]], ["_loadout", [], [[]]]];

if (!isServer || isNull _unit) exitWith {""};
if (remoteExecutedOwner isNotEqualTo (owner _unit) && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    WARNING_2("loadoutStore refused: owner %1 sent a loadout for %2",remoteExecutedOwner,name _unit);
    ""
};
if (GVAR(readOnly)) exitWith {""};

private _cap = GVAR(settings) getOrDefault ["savedLoadouts", 3];
if (_cap isEqualTo 0) exitWith {""};

private _uid = [_unit] call FUNC(uid);
private _rec = [_uid, name _unit] call FUNC(record);

private _key = _rec getOrDefault ["roleId", ""];
if (_key isEqualTo "") then {_key = _unit getVariable ["YMF_role", ""]};
if (_key isEqualTo "") exitWith {
    ["TAC//PAC", "Loadout not kept: you have no role to keep it under.", [0.831, 0.267, 0.267, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _unit];
    ""
};

private _loadouts = _rec getOrDefault ["loadouts", createHashMap];
if !(_loadouts isEqualType createHashMap) then {_loadouts = createHashMap};

if (!(_key in _loadouts) && {count _loadouts >= _cap}) then {
    private _oldest = "";
    private _oldestAt = 0;
    {
        private _at = ([_y param [0, ""]] call FUNC(stampMinutes)) # 0;
        if (_oldest isEqualTo "" || _at < _oldestAt) then {_oldest = _x; _oldestAt = _at};
    } forEach _loadouts;
    _loadouts deleteAt _oldest;
    TRACE_2("loadout cap reached - evicted",_oldest,name _unit);
};

_loadouts set [_key, [[] call FUNC(stamp), _loadout]];
_rec set ["loadouts", _loadouts];
_rec set ["updatedAt", [] call FUNC(stamp)];
GVAR(players) set [_uid, _rec];

[] call FUNC(storeSave);

// THE ROLE'S NAME, NOT ITS KEY (tablet review 2026-11-01, 2.1: "Loadout kept
// for teamleadBanshee"): the key is a class name; the structure's role record
// carries what the player knows it as (FUNC(rolesFromMission) fills it from
// the Dynamic_Roles class's name). A key the structure does not know is
// called what it is to him - his role.
private _roleRec = (GVAR(structure) getOrDefault ["roles", createHashMap]) getOrDefault [_key, createHashMap];
private _roleName = "";
if (_roleRec isEqualType createHashMap) then {_roleName = _roleRec getOrDefault ["name", ""]};
if !(_roleName isEqualType "") then {_roleName = ""};
if (_roleName isEqualTo "") then {_roleName = "your role"};
["TAC//PAC", format ["Loadout kept for %1 (%2 of %3).", _roleName, count _loadouts, _cap], [0.4, 0.702, 0.4, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _unit];

_key
