#include "script_component.hpp"
/*
 * Author: JMSB
 * Stands in for ALiVE's own ALIVE_fnc_sendHint (CfgFunctions.hpp points ALiVE's
 * class at this file), so every message an ALiVE module shows a player - C2ISTAR's
 * AIR PICTURE, logistics, support - comes up in jmfsb_notify like everything
 * else, rather than as a hint box with the ALiVE logo (user, 2026-10-15).
 *
 * ALiVE writes the message as structured text: <br/> and \n break lines, and a
 * few tags colour words. The notification body is one plain line - notify
 * escapes markup - so the lines are joined with a dash and the tags dropped.
 *
 * Arguments:
 * 0: Module sending it, shown as the title <STRING>
 * 1: Message <STRING>
 * 2: Silent - ALiVE's no-sound flag; a notification makes no sound anyway <BOOL> (optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Player Command/Control (C2ISTAR)", "AIR PICTURE\nAir situation: contested"] call ALIVE_fnc_sendHint
 *
 * Public: No
 */

params [["_module", "", [""]], ["_message", "", [""]]];

if (!hasInterface) exitWith {};

private _text = _message regexReplace ["\\n", HINT_LINE_JOIN];
_text = _text regexReplace [toString [10], HINT_LINE_JOIN];
_text = _text regexReplace ["<[bB][rR]\s*/?>", HINT_LINE_JOIN];
_text = _text regexReplace ["<[^>]*>", ""];
_text = ((_text regexReplace ["&lt;", "<"]) regexReplace ["&gt;", ">"]) regexReplace ["&amp;", "&"];

// A message that opens, closes or doubles a break leaves dashes with nothing
// between them.
_text = _text regexReplace ["(\s*-\s*){2,}", HINT_LINE_JOIN];
_text = trim (_text regexReplace ["^\s*-\s*|\s*-\s*$", ""]);

[_module, _text, HINT_NOTIFY_COLOUR] call EFUNC(notify,notify);
