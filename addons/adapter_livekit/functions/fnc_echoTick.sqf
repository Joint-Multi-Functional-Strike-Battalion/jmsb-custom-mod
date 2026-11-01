#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every ECHO_TICK_S while an echo test runs: ends it when the bot has
 * not answered in ECHO_ANSWER_S (the voice server is down, or its echo test is
 * off), or after ECHO_MAX_S, so a forgotten test does not keep the microphone
 * open. Removes itself when the test ends.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(echoTick), ECHO_TICK_S] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

private _for = CBA_missionTime - GVAR(echoSince);
switch (GVAR(echo)) do {
    case ECHO_JOINING: {
        if (_for > ECHO_ANSWER_S) then {
            [false, "No answer: the voice server, or its echo test, is off."] call FUNC(echo);
        };
    };
    case ECHO_LIVE: {
        if (_for > ECHO_MAX_S) then {
            [false, format ["Ended after %1 s.", ECHO_MAX_S]] call FUNC(echo);
        };
    };
};

if (GVAR(echo) in [ECHO_IDLE, ECHO_NONE]) then {
    [_handle] call CBA_fnc_removePerFrameHandler;
    GVAR(echoPfh) = -1;
};
