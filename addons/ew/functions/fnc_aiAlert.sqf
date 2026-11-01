#include "script_component.hpp"
/*
 * Author: JMSB
 * Where the group is local: an AI group has been told of a DF fix (BASIC's
 * "alert nearby groups, look toward the bearing"). It goes AWARE unless it
 * is already in COMBAT, and its men watch the fix for AI_WATCH_S, then stop.
 * Sent by FUNC(aiReact) by remoteExec to the leader, since a group's
 * behaviour and its men's watch are set where they are local, and taken only
 * from the server (review R1: it was a CBA event any client could raise to
 * turn any AI group).
 *
 * Arguments:
 * 0: Group <GROUP>
 * 1: The fix, AGL <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_group, _at] remoteExecCall ["jmfsb_ew_fnc_aiAlert", leader _group]
 *
 * Public: No
 */

params [["_group", grpNull, [grpNull]], ["_at", [], [[]]]];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("aiAlert: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _group || _at isEqualTo [] || !alive leader _group) exitWith {};

if ((behaviour leader _group) isNotEqualTo "COMBAT") then {
    _group setBehaviourStrong "AWARE";
};
private _men = (units _group) select {alive _x && local _x && !isPlayer _x};
{
    _x doWatch _at;
} forEach _men;
[{
    {
        if (alive _x) then {_x doWatch objNull};
    } forEach _this;
}, _men, AI_WATCH_S] call CBA_fnc_waitAndExecute;
