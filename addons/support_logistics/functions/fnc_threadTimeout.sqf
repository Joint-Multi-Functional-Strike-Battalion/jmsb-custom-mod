#include "script_component.hpp"
/*
 * Author: YonV
 * Server: nobody answered PACKAGE AWAY - CONFIRM RECEIPT for 5 min (D9, user
 * 2026-11-01; the support core's prompt calls this, DESIGN_SUPPORT_MESSAGING
 * 5.4 and step 7). The aircraft has gone already: the thread is closed with
 * what was delivered, NO RESPONSE.
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["logi:0", "T0042"] call jmfsb_support_logistics_fnc_threadTimeout
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("threadTimeout: refused - remote call from machine %1",remoteExecutedOwner);
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};
private _job = _logic getVariable [QGVAR(threadJob), createHashMap];
if ((_job getOrDefault ["thread", ""]) isNotEqualTo _threadId) exitWith {};

[_logic, "CLOSED", format ["%1 - %2", _job getOrDefault ["line", ""], SAID_SILENT], _threadId] call FUNC(threadState);
_logic setVariable [QGVAR(threadJob), nil];
