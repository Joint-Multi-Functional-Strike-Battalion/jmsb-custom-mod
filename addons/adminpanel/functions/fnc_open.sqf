#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens the console, or says why it will not.
 *
 * THE GATE IS SAID OUT LOUD. The panel used to open for anybody and then close
 * itself again from inside fn_displayOpened, which reads as the screen flashing
 * and breaking rather than as a refusal. A man who is not on the list is told he
 * is not on the list.
 *
 * The message box is not gated and never was: it is how a player reaches an
 * admin, so gating it would defeat its only purpose.
 *
 * Arguments:
 * 0: Open the message box instead of the console <BOOL> (optional, default false)
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_open
 *
 * Public: Yes
 */

params [["_message", false, [false]]];

if (!hasInterface) exitWith {false};

// Switched off is switched off for both screens. An addon that is disabled but
// still opens one of its two windows is worse than one that does neither.
if !(missionNamespace getVariable [QGVAR(enabled), true]) exitWith {false};

if (_message) exitWith {
    [QGVAR(message)] call FUNC(openDisplay)
};

if !([player] call FUNC(isAdmin)) exitWith {
    ["Admin Panel", "You are not on this mission's admin list.", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify);
    false
};

[QGVAR(console)] call FUNC(openDisplay)
