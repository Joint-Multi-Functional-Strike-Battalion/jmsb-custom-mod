#include "script_component.hpp"
/*
 * Author: YonV
 * Has an asset say something on its side's notify rail after a delay - SHOT,
 * SPLASH, the next volley, ready for tasking - unless the mission it belongs
 * to has moved on by then (its token no longer the logic's).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The token the words belong to <NUMBER>
 * 2: The words <STRING>
 * 3: Priority, "normal" or "high" <STRING>
 * 4: Delay (s) <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, 3, "splash, over", "high", 40] call jmfsb_support_fires_fnc_sayLater
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_token", -1, [0]], ["_text", "", [""]], ["_priority", "normal", [""]], ["_delay", 0, [0]]];

if (isNull _logic || _text isEqualTo "") exitWith {};

[{
    params ["_logic", "_token", "_text", "_priority"];
    if (isNull _logic || {(_logic getVariable [QGVAR(token), -1]) isNotEqualTo _token}) exitWith {};
    [_logic, _text, _priority] call FUNC(say);
}, [_logic, _token, _text, _priority], 0 max _delay] call CBA_fnc_waitAndExecute;
