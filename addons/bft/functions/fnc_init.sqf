#include "script_component.hpp"
/*
 * Author: Jacco Douma, JMSB
 * Starts the tracker on this machine: sets the player group's default tracker
 * state, starts the redraw loop and hangs the map settings menu off ACE self
 * interaction. Safe to call again - the loop and the menu are both guarded, so
 * toggling the setting back on does not stack a second loop.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_bft_fnc_init
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

[] call FUNC(autoEnable);

// AND AGAIN EVERY TIME THE PLAYER CHANGES GROUP. The tracker switch lives on the
// GROUP, not on the man - so a player moved into another group, given his own
// team, or slotted somewhere else lands in a group nobody has switched on, and
// his own marker silently stops. It looked like the tracker breaking; it was the
// tracker correctly drawing a group that had never been turned on.
//
// Registered once. FUNC(init) is called again whenever the enabled setting is
// toggled, and a second handler would set the same variable twice.
if (!GVAR(groupWatch)) then {
    GVAR(groupWatch) = true;
    ["group", {[] call FUNC(autoEnable)}] call CBA_fnc_addPlayerEventHandler;
    ["unit", {[] call FUNC(autoEnable)}] call CBA_fnc_addPlayerEventHandler;
};

if (!GVAR(loopRunning)) then {
    GVAR(loopRunning) = true;
    [] call FUNC(loop);
};

[] call FUNC(settingsAdd);
[] call FUNC(buddyAdd);
