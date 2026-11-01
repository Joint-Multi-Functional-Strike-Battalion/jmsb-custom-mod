#include "script_component.hpp"
/*
 * Author: JMSB
 * A thread's bodies arrived. Caches them and hands them to whatever asked.
 *
 * An empty payload means the server refused - the player is not a participant
 * and is not in any mailbox the thread is filed under. That is answered with
 * silence rather than an error, because "that thread exists but is not yours"
 * is itself information.
 *
 * Sent by remoteExecCall from the server (FUNC(srvRequestThread)), and taken
 * only from the server (review S7).
 *
 * Arguments:
 * 0: Thread <ARRAY> - array form of a thread HashMap, [] when refused
 * 1: Messages <ARRAY> - array forms of message HashMaps, in seq order
 *
 * Return Value:
 * None
 *
 * Example:
 * [_threadArray, _messageArrays] remoteExecCall ["jmfsb_messaging_fnc_cltThread", _unit]
 *
 * Public: No
 */

params [["_threadArray", [], [[]]], ["_messageArrays", [], [[]]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};
if (_threadArray isEqualTo []) exitWith {};

private _thread = createHashMapFromArray _threadArray;
private _messages = _messageArrays apply {createHashMapFromArray _x};

// The id is the cache KEY, and a nil key throws - the same fault
// FUNC(cltReceive) carried. A thread that arrives without one is not cacheable
// and saying so beats an error per fetch.
private _threadId = _thread getOrDefault ["id", ""];
if (!(_threadId isEqualType "") || _threadId isEqualTo "") exitWith {
    diag_log text format ["[jmfsb_messaging] malformed thread, no id: %1", _threadArray];
};

private _cache = missionNamespace getVariable [QGVAR(cache), createHashMap];
_cache set [_threadId, [_thread, _messages]];
missionNamespace setVariable [QGVAR(cache), _cache];

[QGVAR(threadOpened), [_thread, _messages]] call CBA_fnc_localEvent;

private _callback = missionNamespace getVariable [QGVAR(openCallback), {}];
if (_callback isNotEqualTo {}) then {
    [_thread, _messages] call _callback;
};

[player, _threadId] remoteExecCall [QFUNC(srvMarkRead), SERVER_OWNER];
