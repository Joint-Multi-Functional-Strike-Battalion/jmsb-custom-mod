#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens a thread: fetches its messages from the server if they are not cached,
 * marks them read, and hands the rendered thread to the callback. With no UI
 * yet the default callback prints it, which is how a thread is read today.
 *
 * The bodies are fetched per thread rather than pushed with the index, because
 * an index is small and a mission's worth of report bodies is not.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: Called with [thread, messages] once they arrive <CODE> (optional, default prints)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["T0007"] call jmfsb_messaging_fnc_open
 *
 * Public: Yes
 */

params [["_threadId", "", [""]], ["_callback", {}, [{}]]];

if (_threadId == "" || {isNull player}) exitWith {};

if (_callback isEqualTo {}) then {
    _callback = {
        params ["_thread", "_messages"];

        private _out = [format ["%1  [%2]", _thread get "subject", _thread get "status"]];
        {
            _out pushBack format [
                "-- %1  %2",
                _x get "fromCallsign",
                [_x get "templateId", _x get "payload", false] call FUNC(render)
            ];
        } forEach _messages;

        [_thread get "subject", _out joinString endl] call FUNC(notify);
        diag_log text format ["[jmfsb_messaging] %1", _out joinString " | "];
    };
};

GVAR(openCallback) = _callback;

// Read through missionNamespace rather than off the variable: a nil cache is a
// thread that has not been fetched yet, not an error to throw at the player.
private _cached = (missionNamespace getVariable [QGVAR(cache), createHashMap]) getOrDefault [_threadId, []];
if (_cached isNotEqualTo []) exitWith {
    _cached call _callback;
    [player, _threadId] remoteExecCall [QFUNC(srvMarkRead), SERVER_OWNER];
};

// By remoteExecCall, so the server can check the player named is the sender's
// own (review S7).
[player, _threadId] remoteExecCall [QFUNC(srvRequestThread), SERVER_OWNER];
