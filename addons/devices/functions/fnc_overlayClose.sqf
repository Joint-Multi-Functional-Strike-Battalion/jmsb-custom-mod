#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes the walking-view layer down, if it is up.
 *
 * DOWN, NOT HIDDEN. A named title layer is not cleared by leaving a mission -
 * jmfsb_hud learned that over eight builds with its readouts sitting on the
 * main menu - so whenever the view is not wanted the layer is cut away
 * entirely, and the mission's Ended event cuts it too. Raising it again is
 * one cutRsc; there is nothing to save by keeping an empty layer around.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Was up <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_overlayClose
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(overlayDisplay), displayNull];
if (isNull _display) exitWith {false};

QGVAR(overlay) cutText ["", "PLAIN", 0, false];
uiNamespace setVariable [QGVAR(overlayDisplay), displayNull];
GVAR(overlayKey) = "";

true
