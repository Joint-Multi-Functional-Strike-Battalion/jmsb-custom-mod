#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a new mission for the battery in its own thread - a second CALL FOR
 * FIRE filed in it ("task"), or a FRAGO of the mission ("frago": the order
 * with its changes laid over it, EFUNC(support,srvFollowUp)) - from
 * FUNC(threadReply), once the rounds in the air are down
 * (docs/DESIGN_MESSAGE_TEMPLATES.md tree 4, 2026-11-09: "a second call for
 * fire in it is a new mission on the same guns"; FRAGO "shell, fuze, rounds,
 * sheaf").
 *
 * The guns are laid again through the call for fire's own path
 * (FUNC(srvThread)) - range, stock, danger close, shape, method, TOT - as if
 * the card had opened the thread: the battery between missions (laid,
 * adjusting or holding for the BDA) counts as free for it. Refused, the last
 * mission stands - its state put back - and the battery says why
 * (PROMPT_RETASK). A FRAGO laid says WILCO FRAGO, since the mission's WILCO
 * was said already.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread <HASHMAP>
 * 2: The order - the new card, or the order the FRAGO changed <HASHMAP>
 * 3: Who sent it <OBJECT>
 * 4: "task" or "frago" <STRING>
 *
 * Return Value:
 * Laid <BOOL>
 *
 * Example:
 * ["fires:0", _thread, _message, _observer, "frago"] call jmfsb_support_fires_fnc_threadRetask
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_who", objNull, [objNull]],
    ["_word", "", [""]]
];

if (!isServer) exitWith {false};
if (isRemoteExecuted) exitWith {
    WARNING_1("threadRetask: refused - remote call from machine %1",remoteExecutedOwner);
    false
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {false};
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _threadId = _thread getOrDefault ["id", ""];

// Between missions it is free for this thread's next one.
private _was = _logic getVariable [QGVAR(status), STATUS_IDLE];
if (_was in [STATUS_LAID, STATUS_ADJUST, STATUS_HOLDING]) then {
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
};

private _answer = [_assetId, _thread, _message, _who] call FUNC(srvThread);
if (isNil "_answer" || {!(_answer isEqualType [])}) then {_answer = []};
_answer params [["_ok", false, [false]], ["_why", "", [""]]];

if (!_ok) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) then {
        _logic setVariable [QGVAR(status), _was, true];
    };
    if (_why isEqualTo "") then {_why = SAID_CANNOT_FIRE};
    INFO_3("%1: %2 not laid - %3",_callsign,_word,_why);
    // srvThread may have named no thread; the prompt asks in the mission's.
    if ((_logic getVariable [QGVAR(thread), ""]) isEqualTo "") then {_logic setVariable [QGVAR(thread), _threadId]};
    [_logic, format [PROMPT_RETASK, _why], ANSWERS_RETASK] call FUNC(threadPrompt);
    false
};

if (_word isEqualTo WORD_FRAGO) then {
    [_assetId, _threadId, format [SAID_FRAGO, SAID_FRAGO_LAID], false, _callsign] call EFUNC(support,threadEvent);
};
INFO_2("%1: %2 laid",_callsign,_word);
true
