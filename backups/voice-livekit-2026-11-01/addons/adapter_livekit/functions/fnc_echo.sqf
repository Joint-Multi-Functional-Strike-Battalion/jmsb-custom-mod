#include "script_component.hpp"
/*
 * Author: YonV
 * Starts or ends the player's echo test: a call to the voice server's echo
 * bot, which plays back what he says (docs/DESIGN_VOICE_LIVEKIT.md "Echo
 * test"). Starting asks the server for a token to his own room, echo-<UID>
 * (FUNC(srvEchoToken)); the extension joins with it, and the microphone opens
 * when the bot answers (FUNC(callback)). Talk, pause, hear it back. Ending
 * leaves the room and closes the microphone. Raises jmfsb_adapter_livekit_echo
 * [state] on every change, for the screens that show it.
 *
 * Arguments:
 * 0: On <BOOL> (default: true)
 * 1: Why it ended, shown to him <STRING> (default: "")
 *
 * Return Value:
 * Changed <BOOL>
 *
 * Example:
 * [true] call jmfsb_adapter_livekit_fnc_echo
 *
 * Public: Yes
 */

params [["_on", true, [true]], ["_why", "", [""]]];

if (!hasInterface || GVAR(echo) isEqualTo ECHO_NONE) exitWith {false};

if (!_on) exitWith {
    if (GVAR(echo) isEqualTo ECHO_IDLE) exitWith {false};
    ["disconnect"] call FUNC(ext);
    GVAR(echo) = ECHO_IDLE;
    [ECHO_TITLE, ["Ended.", _why] select (_why isNotEqualTo "")] call EFUNC(notify,notify);
    [QGVAR(echo), [GVAR(echo)]] call CBA_fnc_localEvent;
    // The mission's room has the session back (FUNC(roomJoin) refuses while
    // the test runs; a beat later it does not).
    [FUNC(roomJoin), [], ECHO_TICK_S] call CBA_fnc_waitAndExecute;
    true
};

if (GVAR(echo) isNotEqualTo ECHO_IDLE) exitWith {false};
// The extension has one session: the test takes it from the mission's room.
[] call FUNC(roomLeave);
GVAR(echo) = ECHO_JOINING;
GVAR(echoSince) = CBA_missionTime;
[player] remoteExecCall [QFUNC(srvEchoToken), 2];
if (GVAR(echoPfh) < 0) then {
    GVAR(echoPfh) = [FUNC(echoTick), ECHO_TICK_S] call CBA_fnc_addPerFrameHandler;
};
[ECHO_TITLE, "Calling the voice server..."] call EFUNC(notify,notify);
[QGVAR(echo), [GVAR(echo)]] call CBA_fnc_localEvent;
true
