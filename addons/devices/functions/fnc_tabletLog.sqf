#include "script_component.hpp"
/*
 * Author: JMSB
 * The notification line was clicked: everything in the history so far is now
 * seen, any open app closes, and the docked reader turns to its LOG view - the
 * page back through every notification that scrolled past
 * (jmfsb_tacpad_apps_fnc_panelReader).
 *
 * The reader is rebuilt on the next frame, as its own LOG button does it: a
 * rebuild deletes controls, and the press that called this is still on one.
 *
 * THE CLICK OPENS THE LOG (DESIGN_TABLET, "Layout") even when the player has
 * switched the reader off: it is built on the tablet first, at its fixed
 * place, the same way the shell's open builds it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Reader shown <BOOL> - false when the suite has no reader panel at all
 *
 * Example:
 * [] call jmfsb_devices_fnc_tabletLog
 *
 * Public: No
 */

private _history = missionNamespace getVariable [QEGVAR(notify,history), []];
if !(_history isEqualType []) then {_history = []};
{
    GVAR(notifySeen) = GVAR(notifySeen) max (_x param [3, 0]);
} forEach _history;

[] call EFUNC(tacpad,appClose);

private _panel = EGVAR(tacpad,panels) getOrDefault ["reader", createHashMap];
if (count _panel == 0) exitWith {false};

EGVAR(tacpad_apps,readerLog) = true;
uiNamespace setVariable [QEGVAR(tacpad_apps,readerNetOpen), false];
[{
    params ["_panel"];
    private _display = HOST_DISPLAY;
    if (isNull _display) exitWith {};
    if ("reader" in EGVAR(tacpad,open)) then {
        ["reader"] call EFUNC(tacpad,rebuild);
    } else {
        [_display, _panel] call EFUNC(tacpad,build);
    };
}, [_panel]] call CBA_fnc_execNextFrame;

true
