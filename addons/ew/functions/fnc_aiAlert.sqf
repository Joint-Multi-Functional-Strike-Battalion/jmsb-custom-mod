#include "script_component.hpp"
/*
 * Author: JMSB
 * Where the group is local: an AI group has been told of a DF fix (BASIC's
 * "alert nearby groups, look toward the bearing"). It goes AWARE unless it
 * is already in COMBAT, and its men watch the fix for AI_WATCH_S, then stop.
 * Raised by FUNC(aiReact) with CBA_fnc_targetEvent on the leader, since a
 * group's behaviour and its men's watch are set where they are local.
 *
 * Arguments:
 * 0: Group <GROUP>
 * 1: The fix, AGL <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [QGVAR(aiAlert), [_group, _at], leader _group] call CBA_fnc_targetEvent
 *
 * Public: No
 */

params [["_group", grpNull, [grpNull]], ["_at", [], [[]]]];

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
