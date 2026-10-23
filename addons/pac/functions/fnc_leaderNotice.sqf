#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_leaderNotice

Description:
    The moment a player takes a leader slot, tells them their METT-TC is
    owed. Called from the groups addon at the end of its role setup, with
    whether this was a respawn.

    A LEADER SLOT IS ONE THAT SETS isLeader - the mission's own flag, the
    one the role's customVariables carry and every net tag reads. Not
    `leader group`: the group system hands leadership to whoever joined
    last, and a rifleman who is technically the leader of a two-man group
    for a moment is not a man who owes an estimate.

    ONCE, ON TAKING THE SLOT. A respawn is the same man in the same slot
    and gets nothing.

    A NOTICE, NOT AN OPEN. This used to open the TAC//MSG compose on the
    METT-TC as well; it no longer does (user, 2026-10-21: "for leaders lets
    stop the auto open tac//msg"). The leader files it from TAC//MSG when
    they are ready.

Parameters:
    0: Was this a respawn <BOOL>

Returns:
    Whether the notice was given <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_isRespawn", false, [false]]];

if (!hasInterface || _isRespawn) exitWith {false};
if ((player getVariable ["isLeader", false]) isNotEqualTo true) exitWith {false};

private _opordId = GVAR(settings) getOrDefault ["currentOpord", ""];
private _against = "";
if (_opordId isNotEqualTo "") then {
    private _hdr = ((GVAR(structure) getOrDefault ["opords", createHashMap]) getOrDefault [_opordId, createHashMap]) getOrDefault ["header", createHashMap];
    _against = format [" against %1", _hdr getOrDefault ["title", _opordId]];
};

["TAC//PAC", format ["You hold a leader slot. File your METT-TC%1 from TAC//MSG.", _against], [0.780, 0.510, 0.129, 1]] call EFUNC(notify,notify);

true
