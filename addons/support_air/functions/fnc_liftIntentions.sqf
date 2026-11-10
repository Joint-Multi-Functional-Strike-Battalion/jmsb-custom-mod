#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a transport asks STATE INTENTIONS in its thread (docs/DESIGN_MESSAGE_
 * TEMPLATES.md, 2026-11-09) - after an ABORT, a MOVE's time up, a paradrop
 * the requester would not drop. The support core's ASKS
 * (EFUNC(support,askIntentions)): MOVE, HOLD, FRAGO, RTB, and here EXECUTE -
 * carry on with the order it had - and the transport starters, the next
 * tasking filed in the thread. No answer for the core's PROMPT_END: home
 * (FUNC(threadTimeout)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Thread id <STRING>
 * 2: What it says first - ABORTED, HOLDING - "" for nothing <STRING> (optional, default "")
 * 3: Offer EXECUTE (carry on) <BOOL> (optional, default true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "T0042", "ABORTED"] call jmfsb_support_air_fnc_liftIntentions
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_threadId", "", [""]], ["_first", "", [""]], ["_carryOn", true, [true]]];

if (!isServer || {isNull _logic} || _threadId isEqualTo "") exitWith {};

private _more = [ANSWERS_STARTERS, [ANSWERS_CARRY_ON, ANSWERS_STARTERS] joinString ","] select _carryOn;
[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _threadId,
    _logic getVariable [QGVAR(callsign), "AIR"],
    _first,
    _more,
    {_this call FUNC(threadTimeout)}
] call EFUNC(support,askIntentions);
