#include "script_component.hpp"
/*
 * Author: JMSB
 * The voice API's "global" hook (jmfsb_voice_fnc_global): on, Global is
 * opened to him (FUNC(channels) keeps it open while GVAR(globalOn) holds) and
 * made his current channel; off, it is closed again unless he is an admin, and
 * his current channel goes back to his active net.
 *
 * Arguments:
 * 0: On <BOOL>
 * 1: His active net, to go back to <STRING>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * [true, "GHOST 1"] call jmfsb_adapter_von_fnc_global
 *
 * Public: No
 */

params [["_on", false, [false]], ["_back", "", [""]]];

GVAR(globalOn) = _on;
[] call FUNC(channels);
if (_on) exitWith {
    setCurrentChannel CH_GLOBAL;
    currentChannel isEqualTo CH_GLOBAL
};
[_back] call FUNC(setActive);
true
