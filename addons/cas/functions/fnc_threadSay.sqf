#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the drone says or asks one thing in the thread it strikes for
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4, step 5) - the support core's CAS
 * words (EFUNC(support,casPrompt)) under the module's call sign, with D9's
 * end FUNC(threadTimeout): no answer for 5 min - it leaves.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Thread id <STRING>
 * 2: What: "in", "off", "reattack", "tasking", "bingo" <STRING>
 * 3: Its values <ARRAY> (optional, default [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _threadId, "off", []] call jmfsb_cas_fnc_threadSay
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_threadId", "", [""]], ["_what", "", [""]], ["_values", [], [[]]]];

if (!isServer || isNull _logic || _threadId isEqualTo "") exitWith {};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _threadId,
    _what,
    _values,
    _logic getVariable [QGVAR(callsign), "CAS"],
    {_this call FUNC(threadTimeout)}
] call EFUNC(support,casPrompt);
