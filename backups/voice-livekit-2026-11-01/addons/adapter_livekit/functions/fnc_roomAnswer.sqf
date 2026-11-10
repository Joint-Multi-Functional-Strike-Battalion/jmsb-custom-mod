#include "script_component.hpp"
/*
 * Author: YonV
 * The server's answer to FUNC(roomJoin): the voice server's address and a
 * token, or why not. The extension connects with them; the room is live on
 * its "connected" callback. A refusal (settings not set, no extension on the
 * server) is said once and asked again after ROOM_RETRY_SLOW_S - an admin may
 * set the server's settings mid-mission; a connect the extension refuses is
 * asked again after ROOM_RETRY_S. ONE ANSWER, ONE CONNECT: an answer to an
 * ask that is not the last (it came after the ask timed out and was made
 * again), or a second answer to the same ask, is dropped.
 *
 * Arguments:
 * 0: Signed in <BOOL>
 * 1: The voice server's address, or why not <STRING>
 * 2: Token <STRING>
 * 3: The ask it answers (GVAR(ask) when asked) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [true, "ws://voice:7880", "eyJ...", 1] call jmfsb_adapter_livekit_fnc_roomAnswer
 *
 * Public: No
 */

params [["_ok", false, [false]], ["_url", "", [""]], ["_token", "", [""]], ["_ask", -1, [0]]];

if (isMultiplayer && {isRemoteExecuted} && {remoteExecutedOwner isNotEqualTo 2}) exitWith {};
if (GVAR(state) isNotEqualTo ROOM_JOINING || _ask isNotEqualTo GVAR(ask)) exitWith {
    TRACE_2("room answer dropped",_ask,GVAR(ask));
};
// answered: a repeat of this answer finds no ask to match
GVAR(ask) = GVAR(ask) + 1;

if (!_ok) exitWith {
    GVAR(state) = ROOM_IDLE;
    WARNING_1("voice server: the server cannot sign us in: %1",_url);
    if (!GVAR(toldNoServer)) then {
        GVAR(toldNoServer) = true;
        [VOICE_TITLE, format ["No voice: %1.", _url]] call EFUNC(notify,notify);
    };
    [FUNC(roomJoin), [], ROOM_RETRY_SLOW_S] call CBA_fnc_waitAndExecute;
};

(["connect", [_url, _token]] call FUNC(ext)) params ["_result", "_ran"];
if (!_ran) exitWith {
    GVAR(state) = ROOM_IDLE;
    WARNING_1("voice server: the extension cannot connect: %1",_result);
    [VOICE_TITLE, format ["The voice extension cannot connect: %1.", _result]] call EFUNC(notify,notify);
    [FUNC(roomJoin), [], ROOM_RETRY_S] call CBA_fnc_waitAndExecute;
};
GVAR(since) = CBA_missionTime;
TRACE_1("connecting",_url);
