#include "script_component.hpp"
/*
 * Author: YonV
 * Takes the layer down.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

// THE SLOTS ARE CONTROLS ON THE MISSION DISPLAY NOW, so taking the HUD down
// is deleting them - there is no title layer left to blank. The display
// itself is the game's and is never touched.
private _display = uiNamespace getVariable [QGVAR(display), displayNull];
uiNamespace setVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {};

{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {ctrlDelete _ctrl};
} forEach [IDC_HUD_LEFT, IDC_HUD_RIGHT];
