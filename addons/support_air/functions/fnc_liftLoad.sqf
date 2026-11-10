#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the troop load at a pickup (user, 2026-11-02: "troop load, all in"):
 * TROOP LOAD - ALL IN? (allin / abort), with the scroll and ACE action aboard
 * (FUNC(canAllIn), FUNC(srvAllIn)) - no D9, no timeout. A RED insertion
 * merged at the pickup (FUNC(liftReply), user, 2026-11-08) is confirmed
 * first: HOT LZ - CONFIRM, and CONFIRM brings it back here. From
 * FUNC(liftTick) at wheels down, and FUNC(liftReply) when the INSERTION comes
 * to a PICKUP already on the ground.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_liftLoad
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0) exitWith {};
private _threadId = _job get "thread";

if (_job getOrDefault ["hotPending", false]) exitWith {
    _job set ["step", JOB_CONFIRM];
    [_logic, _threadId, PROMPT_HOT, ANSWERS_HOT] call FUNC(threadPrompt);
};

private _veh = _logic getVariable [QGVAR(vehicle), objNull];
_job set ["step", JOB_ALL_IN];
_veh setVariable [QGVAR(allIn), [_threadId, getPlayerUID (_job get "issuer")], true];
[
    // An extraction in its low hover may be sent round again (2026-11-09:
    // "ALL IN / GO AROUND - back out, come in again").
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _threadId, PROMPT_ALL_IN,
    [ANSWERS_ALL_IN, ANSWERS_ALL_IN_HOVER] select ((_job get "task") isEqualTo TASK_EXTRACT),
    _logic getVariable [QGVAR(callsign), "AIR"], {_this call FUNC(threadTimeout)}, false
] call EFUNC(support,prompt);
