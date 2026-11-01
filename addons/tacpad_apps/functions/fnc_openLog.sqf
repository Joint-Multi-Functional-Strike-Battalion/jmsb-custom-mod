#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens the notices log - the docked reader's LOG view, the page back through
 * every notification that scrolled past (FUNC(panelReader)) - from anywhere:
 * SETTINGS > NETS & ALERTS, the MSG tile's long press and the full reader's
 * rail (user, 2026-10-24: "need to readd the notices log"). The full reader
 * and any open app close first; the docked reader is rebuilt a frame later,
 * because the press that called this is still on a control the rebuild
 * deletes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The log will show - false when the suite has no reader panel <BOOL>
 *
 * Example:
 * [] call jmfsb_tacpad_apps_fnc_openLog
 *
 * Public: Yes
 */

if (!hasInterface) exitWith {false};

private _panel = EGVAR(tacpad,panels) getOrDefault ["reader", createHashMap];
if (count _panel == 0) exitWith {false};

GVAR(readerLog) = true;
uiNamespace setVariable [QGVAR(readerNetOpen), false];

if (!isNil QEFUNC(tacpad,readerClose)) then {[] call EFUNC(tacpad,readerClose)};
[] call EFUNC(tacpad,appClose);
{["reader"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
true
