#include "script_component.hpp"
/*
 * Author: JMSB
 * Sets whether the walking view is shown and keeps that in the player's
 * profile, so a man who hid his device finds it hidden in the next mission
 * too (docs/DESIGN_PHONE_WALKING.md, "State saved per profile").
 *
 * Arguments:
 * 0: Shown <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [false] call jmfsb_devices_fnc_overlaySetShown
 *
 * Public: No
 */

params [["_shown", true, [true]]];

GVAR(overlayShown) = _shown;
if ((profileNamespace getVariable [QGVAR(overlayShown), true]) isNotEqualTo _shown) then {
    profileNamespace setVariable [QGVAR(overlayShown), _shown];
    saveProfileNamespace;
};
