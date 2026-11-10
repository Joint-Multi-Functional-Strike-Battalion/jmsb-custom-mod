#include "script_component.hpp"
/*
 * Author: YonV
 * A support question now waits for this player (user, 2026-11-06: "the
 * choice should be displayed on the phone till answered"): the walking view
 * puts it on the device keys, numpad 6-9 (FUNC(askView), FUNC(askKey)). Text
 * "" takes the thread's question down.
 *
 * Two callers. FUNC(askTraffic), here, when an asset's `prompt` arrives in a
 * thread this player was sent; and the server (jmfsb_support_fnc_askObservers)
 * for a call for fire's observer, who reads the thread's box but is not sent
 * its messages. Taken only from the server when remote-executed (review S7) -
 * any other machine could put a question on another man's phone.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: What is asked, "" to take it down <STRING>
 * 2: The answers, reply card ids comma-separated <STRING>
 * 3: Who asks - the call sign <STRING>
 * 4: FLASH <BOOL>
 * 5: The thread's root card <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["T0007", "READY TO LAND - CLEARED?", "clearedland,hold,abort", "RAVEN", true, "hlz"] call jmfsb_tacpad_fnc_askLocal
 *
 * Public: No
 */

params [
    ["_threadId", "", [""]],
    ["_text", "", [""]],
    ["_answers", "", [""]],
    ["_who", "", [""]],
    ["_flash", false, [false]],
    ["_rootId", "", [""]]
];

if (!hasInterface || _threadId isEqualTo "") exitWith {};
if (isRemoteExecuted && {!([] call EFUNC(common,fromServer))}) exitWith {};

if (_text isEqualTo "") exitWith {
    if (_threadId in GVAR(asks)) then {
        GVAR(asks) deleteAt _threadId;
        [] call FUNC(askChanged);
    };
};

private _ids = ((_answers splitString QUICK_ANSWER_SEP) apply {toLower (trim _x)}) select {_x isNotEqualTo ""};
if (_ids isEqualTo []) exitWith {};

GVAR(asks) set [_threadId, createHashMapFromArray [
    ["kind", ASK_MODE_ANSWER],
    ["text", _text],
    ["who", _who],
    ["flash", _flash],
    ["at", CBA_missionTime],
    ["rootId", _rootId],
    ["answers", _ids arrayIntersect _ids]
]];
[] call FUNC(askChanged);
