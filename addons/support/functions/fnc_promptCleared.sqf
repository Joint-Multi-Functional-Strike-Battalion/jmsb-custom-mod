#include "script_component.hpp"
/*
 * Author: YonV
 * Server: D9's first wait for a CAS strike (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 5.4 and step 5: "after wilco, no CLEARED HOT in
 * 60 s - AWAITING CLEARED HOT"). Started by the provider when it says WILCO
 * to a strike that holds for clearance. PROMPT_CLEARED s later, if the thread
 * is still the asset's and the provider says its strike still waits, the
 * asset asks AWAITING CLEARED HOT - FLASH, answers CLEARED HOT and ABORT -
 * through FUNC(prompt), whose own D9 waits follow (NO RESPONSE - HOLDING at
 * 3 min, the provider's end at 5 min).
 *
 * A newer call for the same thread (a new strike filed in it) replaces the
 * wait.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: Call sign <STRING>
 * 3: What the provider does after the prompt's PROMPT_END s with no answer, [assetId, threadId] <CODE>
 * 4: Whether the strike still waits for CLEARED HOT, [assetId, threadId] -> BOOL <CODE>
 * 5: Offer ALL ATTACK beside CLEARED HOT - a fixed-wing flight with escorts up (user, 2026-11-02) <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_assetId, _threadId, "HOG", {}, {true}] call jmfsb_support_fnc_promptCleared
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_callsign", "", [""]],
    ["_onEnd", {}, [{}]],
    ["_waiting", {false}, [{}]],
    ["_allAttack", false, [false]]
];

if (!isServer || _assetId isEqualTo "" || _threadId isEqualTo "") exitWith {};
// A provider's own call on the server, never a client's.
if (isRemoteExecuted) exitWith {
    WARNING_2("promptCleared: refused - remote call from machine %1 (%2)",remoteExecutedOwner,_assetId);
};

private _seqs = localNamespace getVariable [QGVAR(clearedSeqs), createHashMap];
private _seq = (_seqs getOrDefault [_threadId, 0]) + 1;
_seqs set [_threadId, _seq];
localNamespace setVariable [QGVAR(clearedSeqs), _seqs];

[{
    params ["_assetId", "_threadId", "_callsign", "_onEnd", "_waiting", "_seq", "_allAttack"];
    if (((localNamespace getVariable [QGVAR(clearedSeqs), createHashMap]) getOrDefault [_threadId, 0]) isNotEqualTo _seq) exitWith {};
    if (((localNamespace getVariable [QGVAR(threadAssets), createHashMap]) getOrDefault [_threadId, ""]) isNotEqualTo _assetId) exitWith {};
    if !([_assetId, _threadId] call _waiting) exitWith {};
    INFO_2("thread %1: %2 has no CLEARED HOT - asks for it",_threadId,_assetId);
    [_assetId, _threadId, PROMPT_AWAITING, [ANSWERS_AWAITING, ANSWERS_AWAITING_FW] select _allAttack, _callsign, _onEnd, true, true] call FUNC(prompt);
}, [_assetId, _threadId, _callsign, _onEnd, _waiting, _seq, _allAttack], PROMPT_CLEARED] call CBA_fnc_waitAndExecute;
