#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_autoSlot

Description:
    Puts a player into the slot their PAC role names, without the group menu.
    Server only; asked by the player's own machine on first spawn
    (FUNC(applyOnClient)) when the settings say autoSlot.

    A PAC ROLE NAMES A SLOT BY slotTag - the class name of a Dynamic_Roles
    role, which is what every slot in YMF_dynamicGroups is labelled with. A
    role with no slotTag is a role that is not slotted automatically.

    slotMatch DECIDES HOW EXACT. "role" (the handoff's recommendation): the
    first free slot anywhere with that role - tolerant of a squad being
    renumbered or a slot count changing. "slot": the slot must also be in
    the group the record's groupId names, so a man goes to HIS squad or to
    nowhere.

    THE RANK GATE STILL APPLIES. Role_Access restrictions are the groups
    addon's rule and this asks it (canTakeRole) before assigning - PAC
    places people, it does not promote them past the door.

    ALREADY SLOTTED IS LEFT ALONE. A respawn, or a player who picked a slot
    before this ran, keeps what they have.

Parameters:
    0: The unit <OBJECT>

Returns:
    [groupIndex, unitIndex] of the slot taken, [] if none <ARRAY>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]]];

if (!isServer || isNull _unit) exitWith {[]};
// A client slots only himself (review S5).
if !([_unit] call EFUNC(common,senderIs)) exitWith {[]};
if ((GVAR(settings) getOrDefault ["autoSlot", 1]) isEqualTo 0) exitWith {[]};
if (isNil "YMF_dynamicGroups") exitWith {[]};
if ((_unit getVariable ["YMF_oldrole", ""]) isNotEqualTo "") exitWith {[]};

private _uid = [_unit] call FUNC(uid);
private _rec = GVAR(players) getOrDefault [_uid, createHashMap];
private _roleId = _rec getOrDefault ["roleId", ""];
if (_roleId isEqualTo "") exitWith {[]};

private _role = (GVAR(structure) getOrDefault ["roles", createHashMap]) getOrDefault [_roleId, createHashMap];
private _tag = _role getOrDefault ["slotTag", ""];
if (_tag isEqualTo "") exitWith {
    TRACE_2("role has no slotTag - not auto-slotted",_roleId,name _unit);
    []
};

if (!isNil "jmfsb_groups_fnc_canTakeRole" && {!([_unit, _tag] call jmfsb_groups_fnc_canTakeRole)}) exitWith {
    INFO_3("%1 not auto-slotted: the role gate refuses %2 for %3",name _unit,_tag,_roleId);
    []
};

private _exact = (GVAR(settings) getOrDefault ["slotMatch", "role"]) isEqualTo "slot";
private _wantGroup = _rec getOrDefault ["groupId", ""];
private _path = [];

{
    _x params ["_groupName", "_roles", "", "", "_units"];
    if (_exact && {toLower _groupName isNotEqualTo toLower _wantGroup}) then {continue};

    private _gi = _forEachIndex;
    private _ui = -1;
    {
        if (_x isEqualTo _tag && {isNull (_units param [_forEachIndex, objNull])}) exitWith {_ui = _forEachIndex};
    } forEach _roles;

    if (_ui >= 0) exitWith {_path = [_gi, _ui]};
} forEach YMF_dynamicGroups;

if (_path isEqualTo []) exitWith {
    private _where = ["", " in " + _wantGroup] select _exact;
    INFO_3("%1 not auto-slotted: no free %2 slot%3",name _unit,_tag,_where);
    []
};

[_unit, _path, _tag] call jmfsb_groups_fnc_assignPlayer;
INFO_4("%1 auto-slotted as %2 in %3 (%4)",name _unit,_tag,(YMF_dynamicGroups # (_path # 0)) # 0,_roleId);

["TAC//PAC", format ["Slotted as %1 in %2.", _tag, (YMF_dynamicGroups # (_path # 0)) # 0], [0.4, 0.702, 0.4, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _unit];

_path
