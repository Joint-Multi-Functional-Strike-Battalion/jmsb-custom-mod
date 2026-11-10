#include "script_component.hpp"
/*
 * Author: YonV
 * Server: one prompt of a landing's wait (user, 2026-11-02, FUNC(lzClear)) -
 * the core's prompt (FUNC(prompt)) in the thread, under the asset's call sign,
 * with the provider's D9 end.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: What it asks <STRING>
 * 2: The answers, reply ids comma-separated <STRING>
 * 3: FLASH <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_threadId, "READY TO LAND - CLEARED?", "clearedland,hold,abort", true] call jmfsb_support_fnc_lzClearAsk
 *
 * Public: No
 */

params [["_threadId", "", [""]], ["_text", "", [""]], ["_answers", "", [""]], ["_flash", false, [false]]];

private _clear = (localNamespace getVariable [QGVAR(lzClears), createHashMap]) getOrDefault [_threadId, createHashMap];
if (count _clear isEqualTo 0) exitWith {};

INFO_3("thread %1: %2 - %3",_threadId,_clear get "asset",_text);
[_clear get "asset", _threadId, _text, _answers, _clear get "callsign", _clear get "onEnd", true, _flash] call FUNC(prompt);
