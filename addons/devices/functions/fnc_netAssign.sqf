#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a net on one of the twelve net buttons, or sets the button back to
 * AUTO (the tablet's RADIO app, NETS > BUTTONS). A net may sit on more than
 * one button - on several pages at once (user, 2026-11-08). Kept in the
 * player's profile, so it holds from mission to mission; FUNC(netButtons)
 * reads it.
 *
 * Arguments:
 * 0: Button, 0-based: 0-3 QUICK 1-4, 4-7 page 2, 8-11 page 3 <NUMBER>
 * 1: Net id, NET_BUTTON_AUTO ("") for AUTO <STRING>
 *
 * Return Value:
 * Set <BOOL>
 *
 * Example:
 * [0, "c2"] call jmfsb_devices_fnc_netAssign
 *
 * Public: Yes
 */

params [["_button", -1, [0]], ["_netId", NET_BUTTON_AUTO, [""]]];

if (_button < 0 || {_button >= NET_BUTTONS}) exitWith {false};

private _buttons = +GVAR(netButtons);
_buttons set [_button, _netId];
GVAR(netButtons) = _buttons;
profileNamespace setVariable [QGVAR(netButtons), _buttons];
saveProfileNamespace;
[] call FUNC(overlayTick);
true
