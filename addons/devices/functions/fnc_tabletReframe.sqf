#include "script_component.hpp"
/*
 * Author: JMSB
 * The Tablet frame setting changed (initSettings.inc.sqf): an open large or
 * UAV tablet is closed and opened again, so it wears the new frame at once -
 * flip the setting on SETTINGS > DEVICES and the frame swaps under the same
 * screen (user, 2026-10-21: "a way to toggle between the large and uav
 * tablet"). The vehicle tablet is left alone; nothing open, nothing done.
 *
 * Both steps wait a frame: the change usually comes from a button on the
 * tablet itself, which is not closed from inside its own click.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Reopening <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_tabletReframe
 *
 * Public: No
 */

if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {false};
if !(GVAR(device) in [LARGE_DEVICE, UAV_DEVICE]) exitWith {false};

[{
    [] call FUNC(close);
    [{[LARGE_DEVICE] call FUNC(open)}] call CBA_fnc_execNextFrame;
}] call CBA_fnc_execNextFrame;

true
