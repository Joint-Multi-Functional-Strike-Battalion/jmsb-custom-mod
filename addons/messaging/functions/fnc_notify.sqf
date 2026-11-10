#include "script_component.hpp"
/*
 * Author: YonV
 * The one place this addon talks to the notification widget. Everything else
 * calls here, so when the widget is replaced there is a single line to change
 * and no chance of half the addon still calling the old one.
 *
 * Falls back to a plain hint when notify is absent, which is what makes this a
 * seam rather than a wrapper - the addon keeps working with the widget removed.
 *
 * Arguments:
 * 0: Title <STRING>
 * 1: Body <STRING> (optional, default "")
 * 2: Priority - "normal" or "high" <STRING> (optional, default "normal")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["CASEVAC", "Alpha 1-2 - grid 0345 0912", "high"] call jmfsb_messaging_fnc_notify
 *
 * Public: No
 */

params [["_title", "", [""]], ["_body", "", [""]], ["_priority", "normal", [""]]];

if (!hasInterface) exitWith {};
if (_title == "") exitWith {};

private _colour = [COLOUR_NORMAL, COLOUR_HIGH] select (_priority == "high");

if (isNil QEFUNC(notify,notify)) exitWith {
    hintSilent ([_title, _body] select {_x != ""} joinString endl);
};

[_title, _body, _colour] call EFUNC(notify,notify)
