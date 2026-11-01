#include "script_component.hpp"
/*
 * Author: JMSB
 * The device arrows while the call's window is over the tablet (user,
 * 2026-10-28: "tablet moved with arrows"): step it to the next corner of the
 * map area, clockwise on RIGHT, back on LEFT. The corner is kept in the
 * player's profile, so the next call opens where he left it. With no window up
 * the arrows are left to scroll and the active net (FUNC(softKey)).
 *
 * Arguments:
 * 0: Step, +1 or -1 <NUMBER>
 *
 * Return Value:
 * Handled - the window was up <BOOL>
 *
 * Example:
 * [1] call jmfsb_devices_fnc_callCorner
 *
 * Public: No
 */

params [["_step", 1, [0]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
if (isNull _display || {(_display getVariable [QGVAR(callCtrls), []]) isEqualTo []}) exitWith {false};

private _corner = ((profileNamespace getVariable [QGVAR(callCorner), CALL_CORNER_DEFAULT]) + _step + CALL_CORNERS) mod CALL_CORNERS;
profileNamespace setVariable [QGVAR(callCorner), _corner];
[_display] call FUNC(tabletCall);
true
