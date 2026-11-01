#include "script_component.hpp"
/*
 * Author: JMSB
 * The call's window over the tablet (FUNC(callWindow)), in the corner the
 * player stepped it to with the device arrows (FUNC(callCorner); bottom left
 * until he does). Drawn on the row tick and after every app draw
 * (jmfsb_tacpad_appOpened), so an app or panel built since never covers it.
 *
 * Arguments:
 * 0: The tablet dialog <DISPLAY>
 *
 * Return Value:
 * Drawn <BOOL>
 *
 * Example:
 * [_display] call jmfsb_devices_fnc_tabletCall
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {false};

private _map = (_display getVariable [QGVAR(rows), createHashMap]) getOrDefault ["map", [0, 0, 0, 0]];
private _hint = format ["%1 / %2 MOVE", [QGVAR(button_left)] call FUNC(keyLabel), [QGVAR(button_right)] call FUNC(keyLabel)];
[
    _display, _map,
    profileNamespace getVariable [QGVAR(callCorner), CALL_CORNER_DEFAULT],
    CALL_WINDOW_SHARE, _hint, 0,
    {!isNull (uiNamespace getVariable [QGVAR(display), displayNull])}
] call FUNC(callWindow)
