#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the battery asks the observer for what it needs next (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 5.4 and step 6) - a `prompt` card in its thread:
 * what it asks, and the reply ids offered as answers. A prompt never moves the
 * thread; the observer's answer does (FUNC(threadReply)).
 *
 * D9 FOR ARTILLERY (user, 2026-11-01): no answer for PROMPT_HOLD s - it asks
 * again, NO RESPONSE - HOLDING, with the same answers; none for PROMPT_END s -
 * it stands down itself (FUNC(threadEnd)), the thread CLOSED. Any call of the
 * observer's, or a newer prompt, ends the wait (QGVAR(promptSeq)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: What it asks <STRING>
 * 2: The answers, reply ids comma-separated <STRING>
 * 3: Start the D9 waits - false for the NO RESPONSE repeat <BOOL> (optional, default true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "ADJUST?", "adjust,ffe,close"] call jmfsb_support_fires_fnc_threadPrompt
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_text", "", [""]], ["_answers", "", [""]], ["_fresh", true, [true]]];

if (!isServer || {isNull _logic}) exitWith {};
private _threadId = _logic getVariable [QGVAR(thread), ""];
if (_threadId isEqualTo "") exitWith {};

[_logic, CARD_PROMPT, [[CARD_TEXT_KEY, _text], [CARD_ANSWERS_KEY, _answers]]] call FUNC(threadCard);
// On the observer's phone too (2026-11-06, numpad 6-9 quick answers); the
// issuer's reads it off the thread.
[_threadId, _text, _answers, _logic getVariable [QGVAR(callsign), "FIRES"]] call EFUNC(support,askObservers);

if (!_fresh) exitWith {};
// The question kept (2026-11-02): RECORDED AS TARGET asks it again, its
// answers less RECORD (FUNC(threadReply)).
_logic setVariable [QGVAR(promptAsked), [_text, _answers]];
private _seq = (_logic getVariable [QGVAR(promptSeq), 0]) + 1;
_logic setVariable [QGVAR(promptSeq), _seq];

[{
    params ["_logic", "_threadId", "_seq", "_answers"];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
    if ((_logic getVariable [QGVAR(promptSeq), 0]) isNotEqualTo _seq) exitWith {};
    [_logic, PROMPT_NO_RESPONSE, _answers, false] call FUNC(threadPrompt);
}, [_logic, _threadId, _seq, _answers], PROMPT_HOLD] call CBA_fnc_waitAndExecute;

[{
    params ["_logic", "_threadId", "_seq"];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(thread), ""]) isNotEqualTo _threadId) exitWith {};
    if ((_logic getVariable [QGVAR(promptSeq), 0]) isNotEqualTo _seq) exitWith {};
    [_logic, SAID_NO_RESPONSE] call FUNC(threadEnd);
}, [_logic, _threadId, _seq], PROMPT_END] call CBA_fnc_waitAndExecute;
