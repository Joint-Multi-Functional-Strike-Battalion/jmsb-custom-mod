#include "script_component.hpp"
/*
 * Author: JMSB
 * KeyDown on the mission display: swallows the VON toggle (Voice Over Net)
 * so the mic is never left open - the mesh volume, the sounds and the
 * cut-offs all follow the push-to-talk - and tells the player once to bind
 * Push To Talk instead.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: DIK key code <NUMBER>
 *
 * Return Value:
 * true when the key was swallowed <BOOL>
 *
 * Example:
 * [findDisplay 46, 47] call jmfsb_adapter_von_fnc_keyDown
 *
 * Public: No
 */

params ["", ["_key", -1, [0]]];

if !(_key in (actionKeys ACTION_TOGGLE)) exitWith {false};
if (!GVAR(toldToggle)) then {
    GVAR(toldToggle) = true;
    [QEGVAR(voice,note), [NOTE_TITLE, NOTE_TOGGLE]] call CBA_fnc_localEvent;
};
true
