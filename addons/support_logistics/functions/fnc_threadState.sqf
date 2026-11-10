#include "script_component.hpp"
/*
 * Author: YonV
 * Server: moves the logistics asset's support thread (EFUNC(support,state))
 * under the module's call sign, at the delivery's natural points: launched
 * (IN_PROGRESS), never launched (DECLINED), every item accounted for -
 * delivered or lost (CLOSED, with what was delivered and where). An asset
 * nobody filed a thread to says nothing (2026-11-01).
 *
 * WHICH THREAD (step 7, 2026-11-01): the one named; else the one a delivery
 * tasked by message flies for (QGVAR(threadJob), FUNC(srvThread)); else the
 * asset's open thread (a delivery the board ordered).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: State - "IN_PROGRESS", "CLOSED", "DECLINED" <STRING>
 * 2: What the asset says, without the call sign <STRING> (optional, default "")
 * 3: The thread <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "DECLINED", "could not launch"] call jmfsb_support_logistics_fnc_threadState
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_state", "", [""]], ["_said", "", [""]], ["_threadId", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};

if (_threadId isEqualTo "") then {
    _threadId = (_logic getVariable [QGVAR(threadJob), createHashMap]) getOrDefault ["thread", ""];
};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _state,
    _said,
    _logic getVariable [QGVAR(callsign), DEF_CALLSIGN],
    false,
    _threadId
] call EFUNC(support,state);
