#include "script_component.hpp"
/*
 * Author: JMSB
 * One line on the notify rail, titled POINT MAN. Nothing is said with no
 * text, and nothing without messaging.
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: Priority - "normal" or "high" <STRING> (optional, default "normal")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["WP 2 reached."] call jmfsb_pointman_fnc_say
 *
 * Public: No
 */

params [["_text", "", [""]], ["_level", "normal", [""]]];

if (_text isEqualTo "" || {isNil QEFUNC(messaging,notify)}) exitWith {};

[NOTIFY_TITLE, _text, _level] call EFUNC(messaging,notify);
