#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a thread's strike order written onto the drone's run (2026-11-09,
 * the CAS flow of docs/DESIGN_MESSAGE_TEMPLATES.md) - from FUNC(srvThread)
 * and every re-task in the thread (FUNC(threadReply): a new CAS REQUEST, a
 * FRAGO). The run waits for its READBACK again ("rb" RB_ASKED), the IN
 * question is asked afresh, and the order's TYPE OF CONTROL and TOT go with
 * it - read by FUNC(runTick), which asks IN over the grid once the READBACK
 * is CORRECT and does not begin the pass before the TOT.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Thread id <STRING>
 * 2: The order (EFUNC(support,readOrder), kind strike) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "T0042", _order] call jmfsb_cas_fnc_runOrder
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_threadId", "", [""]], ["_order", createHashMap, [createHashMap]]];

if (isNull _logic) exitWith {};
private _run = _logic getVariable [QGVAR(run), createHashMap];
_logic setVariable [QGVAR(run), _run];

private _leaveAt = [_order getOrDefault ["tot", ""]] call FUNC(totTime);
{_run set _x} forEach [
    ["rb", RB_ASKED],
    ["inAsked", false],
    ["moved", false],
    ["control", _order getOrDefault ["control", 0]],
    ["leaveAt", [-1, _leaveAt - TOT_DIVE_LEAD] select (_leaveAt >= 0)],
    ["remarks", _order getOrDefault ["remarks", ""]],
    ["engaged", false]
];
_logic setVariable [QGVAR(cleared), false];
INFO_3("%1 order in thread %2 - control %3, readback asked",_logic getVariable [ARR_2(QGVAR(callsign),"CAS")],_threadId,_run get "control");
