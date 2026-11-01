#include "script_component.hpp"
/*
 * Author: JMSB
 * One line on the notify rail, titled JUMPMASTER. Nothing is said with no
 * text, without a screen, or without messaging.
 *
 * Called on this machine, or sent by the server (FUNC(srvLaunch),
 * FUNC(srvEnd)) by remoteExec and then taken only from the server (review
 * S7: it was the `tell` CBA event, which any client could raise).
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: Priority - "normal" or "high" <STRING> (optional, default "normal")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["GREEN LIGHT. GO.", "high"] call jmfsb_jumpmaster_fnc_say
 *
 * Public: No
 */

params [["_text", "", [""]], ["_level", "normal", [""]]];

if (!hasInterface || _text isEqualTo "" || {isNil QEFUNC(messaging,notify)}) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

[NOTIFY_TITLE, _text, _level] call EFUNC(messaging,notify);
