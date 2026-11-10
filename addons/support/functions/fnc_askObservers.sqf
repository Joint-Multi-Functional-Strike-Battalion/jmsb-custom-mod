#include "script_component.hpp"
/*
 * Author: YonV
 * Server: puts the asset's question on the phones of the card's observers, or
 * takes it down (user, 2026-11-06: quick answers on numpad 6-9 for the
 * issuer and the observer). The issuer is sent the thread's messages and his
 * phone reads the question off them (jmfsb_tacpad_fnc_askTraffic). The men
 * the Observer line names (FUNC(observer)) may answer (FUNC(srvFollowUp))
 * but are not sent its messages, so they are told here - by remoteExecCall,
 * which the client takes only from the server.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: What is asked, "" to take it down <STRING> (optional, default "")
 * 2: The answers, reply ids comma-separated <STRING> (optional, default "")
 * 3: Call sign <STRING> (optional, default "")
 * 4: FLASH <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["T0007", "ADJUST?", "adjust,ffe,close", "THUNDER", false] call jmfsb_support_fnc_askObservers
 *
 * Public: No
 */

params [
    ["_threadId", "", [""]],
    ["_text", "", [""]],
    ["_answers", "", [""]],
    ["_callsign", "", [""]],
    ["_flash", false, [false]]
];

if (!isServer || isRemoteExecuted || _threadId isEqualTo "") exitWith {};

private _thread = (missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap]) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {};
// The thread's current order (2026-11-09): a call for fire filed into a TIC.
private _root = [_thread] call FUNC(threadOrder);

private _issuerUid = (localNamespace getVariable [QGVAR(threadIssuers), createHashMap]) getOrDefault [_threadId, _thread getOrDefault ["issuerUid", ""]];
private _men = (([_thread, _root] call FUNC(observer)) select 1) select {(getPlayerUID _x) isNotEqualTo _issuerUid};
if (_men isEqualTo []) exitWith {};

[_threadId, _text, _answers, _callsign, _flash, _root getOrDefault ["templateId", _thread getOrDefault ["rootTemplateId", ""]]] remoteExecCall [QEFUNC(tacpad,askLocal), _men];
