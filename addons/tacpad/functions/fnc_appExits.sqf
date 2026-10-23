#include "script_component.hpp"
/*
 * Author: JMSB
 * Hangs the two ways out of an open app on the host display: ESC and a press on
 * the map. Lifted out of FUNC(openApp) so a screen that draws itself and is
 * adopted with FUNC(appHost) - the TAC//MSG reader and TAC//PAC inside the
 * tablet - closes the same way as one opened through a handler.
 *
 *   ESC          closes the app and NOT the host. Without the consume, one
 *                press would shut both: the map, or on a tablet the whole
 *                device dialog, with the reader still half-typed in it.
 *   map click    a press that reaches the map control is by definition
 *                outside the app - the app's own ground eats everything
 *                inside it - so it means "I am done with this".
 *
 * Once per display, not once per open: a handler added on every open is a
 * handler that fires as many times as the app has been opened.
 *
 * Arguments:
 * 0: Host display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_tacpad_fnc_appExits
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};
if (_display getVariable [QGVAR(exitWired), false]) exitWith {};
_display setVariable [QGVAR(exitWired), true];

_display displayAddEventHandler ["KeyDown", {
    params ["", "_key"];
    if (_key isNotEqualTo KEY_ESCAPE) exitWith {false};
    [] call FUNC(appClose)
}];

// The host's map - the same idc on the vanilla map and the device dialog.
private _map = _display displayCtrl IDC_HOST_MAP;
if (!isNull _map) then {
    _map ctrlAddEventHandler ["MouseButtonDown", {
        params ["", "_button"];
        if (_button isNotEqualTo 0) exitWith {false};
        // AN APP THAT HOLDS THE MAP keeps it: a press there is the app's input
        // (a support target, a grid), not a way out. FUNC(appClose) releases it.
        if ((uiNamespace getVariable [QGVAR(appMapClaim), ""]) isNotEqualTo "") exitWith {false};
        [] call FUNC(appClose)
    }];
};
