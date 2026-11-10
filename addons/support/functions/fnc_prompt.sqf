#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the asset asks for what it needs next (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 5.4 and step 7) - a `prompt` card in the thread it
 * was given: what it asks, and the reply ids offered as answers. A prompt never
 * moves the thread; the answer does (the provider's "reply" hook).
 *
 * D9 (user, 2026-11-01): no answer for PROMPT_HOLD s - it asks again, NO
 * RESPONSE - HOLDING, with the same answers; none for PROMPT_END s - the
 * provider's own end is called, `[assetId, threadId] call onEnd` (an aircraft
 * goes home, a delivery closes). Any follow-up the core passes on in the thread
 * (FUNC(srvFollowUp)), or a newer prompt, ends the wait. A thread that is no
 * longer the asset's ends it too. support_fires keeps its own (step 6).
 *
 * Text "" files nothing and only starts the waits - for a question the asset
 * already asked in another card (a WILCO saying HOT LZ - CONFIRM).
 *
 * FLASH (doc 5.4, step 5, 2026-11-01): a prompt is FLASH only when the asset
 * waits to release (AWAITING CLEARED HOT), to land (I SEE RED SMOKE, READY TO
 * LAND - CLEARED?, FUNC(lzClear), 2026-11-02) or is about to leave (BINGO);
 * the NO RESPONSE repeat is routine.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: What it asks, "" for the waits only <STRING>
 * 3: The answers, reply ids comma-separated <STRING>
 * 4: Call sign <STRING>
 * 5: What it does after PROMPT_END s with no answer, [assetId, threadId] <CODE>
 * 6: Start the waits - false for the NO RESPONSE repeat <BOOL> (optional, default true)
 * 7: FLASH <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_assetId, _threadId, "1 MIN - LZ STATUS?", "cold,hot", "RAVEN", {}] call jmfsb_support_fnc_prompt
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_text", "", [""]],
    ["_answers", "", [""]],
    ["_callsign", "", [""]],
    ["_onEnd", {}, [{}]],
    ["_fresh", true, [true]],
    ["_flash", false, [false]]
];

if (!isServer || _assetId isEqualTo "" || _threadId isEqualTo "") exitWith {};
// A provider's own call on the server, never a client's.
if (isRemoteExecuted) exitWith {
    WARNING_2("prompt: refused - remote call from machine %1 (%2)",remoteExecutedOwner,_assetId);
};

if (_text isNotEqualTo "") then {
    [_assetId, _threadId, CARD_PROMPT, [[PROMPT_TEXT_KEY, _text], [PROMPT_ANSWERS_KEY, _answers]], _callsign, ["", PRIORITY_FLASH] select _flash] call FUNC(fileCard);
    // The observer's phone too (2026-11-06, numpad 6-9 quick answers).
    [_threadId, _text, _answers, _callsign, _flash] call FUNC(askObservers);
};

if (!_fresh) exitWith {};
private _seqs = localNamespace getVariable [QGVAR(promptSeqs), createHashMap];
private _seq = (_seqs getOrDefault [_threadId, 0]) + 1;
_seqs set [_threadId, _seq];
localNamespace setVariable [QGVAR(promptSeqs), _seqs];

// Still waiting: the same prompt, and the thread still the asset's.
private _fnc_waiting = {
    params ["_assetId", "_threadId", "_seq"];
    if (((localNamespace getVariable [QGVAR(threadAssets), createHashMap]) getOrDefault [_threadId, ""]) isNotEqualTo _assetId) exitWith {false};
    ((localNamespace getVariable [QGVAR(promptSeqs), createHashMap]) getOrDefault [_threadId, 0]) isEqualTo _seq
};

[{
    params ["_assetId", "_threadId", "_seq", "_answers", "_callsign", "_onEnd", "_fnc_waiting"];
    if !([_assetId, _threadId, _seq] call _fnc_waiting) exitWith {};
    [_assetId, _threadId, PROMPT_NO_RESPONSE, _answers, _callsign, _onEnd, false] call FUNC(prompt);
}, [_assetId, _threadId, _seq, _answers, _callsign, _onEnd, _fnc_waiting], PROMPT_HOLD] call CBA_fnc_waitAndExecute;

[{
    params ["_assetId", "_threadId", "_seq", "_onEnd", "_fnc_waiting"];
    if !([_assetId, _threadId, _seq] call _fnc_waiting) exitWith {};
    INFO_2("thread %1: %2 - no answer to its prompt, it ends it",_threadId,_assetId);
    [_assetId, _threadId] call _onEnd;
}, [_assetId, _threadId, _seq, _onEnd, _fnc_waiting], PROMPT_END] call CBA_fnc_waitAndExecute;
