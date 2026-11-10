#include "script_component.hpp"
/*
 * Author: YonV
 * One line on the notify rail, titled JUMPMASTER. Nothing is said with no
 * text, without a screen, or without messaging.
 *
 * Called on this machine - by FUNC(light), which the server sends, and by a
 * man's own FUNC(jump) - and taken only from the server's call or this
 * machine's own (review S7: it was the `tell` CBA event, which any client
 * could raise). What the leader is told goes in the run's thread since
 * 2026-11-02 (FUNC(threadCard)).
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
