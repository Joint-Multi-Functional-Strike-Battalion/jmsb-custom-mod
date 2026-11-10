#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a transport or QRF asks the issuer for what it needs next
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4 and step 7) - the support core's
 * prompt (EFUNC(support,prompt)) in the thread the job flies for, under the
 * module's call sign, with D9: silent 3 min - NO RESPONSE - HOLDING; silent 5
 * min - FUNC(threadTimeout) (home, the thread closed).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Thread id <STRING>
 * 2: What it asks, "" for the waits only <STRING>
 * 3: The answers, reply ids comma-separated <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _threadId, "1 MIN - LZ STATUS?", "cold,hot"] call jmfsb_support_air_fnc_threadPrompt
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_threadId", "", [""]], ["_text", "", [""]], ["_answers", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
if (_threadId isEqualTo "") exitWith {};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _threadId,
    _text,
    _answers,
    _logic getVariable [QGVAR(callsign), "AIR"],
    {_this call FUNC(threadTimeout)}
] call EFUNC(support,prompt);
