#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the local player on the Global channel, or takes him off it - the
 * leaders' GLOBAL button on the tablet (user, 2026-10-21). On: the adapter
 * opens Global to him and makes it his current channel, so push-to-talk
 * reaches everyone, no mesh, no range. Off: back to his active net. Refused
 * for a man FUNC(canGlobal) does not allow.
 *
 * Arguments:
 * 0: On <BOOL> (default: the opposite of now)
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * [true] call jmfsb_voice_fnc_global
 *
 * Public: Yes
 */

params [["_on", !GVAR(globalOn), [false]]];

if (!GVAR(active) || {!hasInterface}) exitWith {false};
if (_on && {!([player] call FUNC(canGlobal))}) exitWith {
    [QGVAR(note), [GLOBAL_TITLE, GLOBAL_REFUSED]] call CBA_fnc_localEvent;
    false
};
if !([_on, GVAR(activeNetId)] call HOOK("global")) exitWith {false};

GVAR(globalOn) = _on;
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
true
