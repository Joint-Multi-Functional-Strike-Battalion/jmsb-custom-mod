#include "script_component.hpp"
/*
 * Author: JMSB
 * Sets which edge of the screen a side device sits against and keeps it in
 * the player's profile, the way the shown / hidden state is kept
 * (FUNC(overlaySetShown)). Set from the tablet's SETTINGS > DEVICES and from a
 * walking-view button; it ticks at once, so a walking view that is up moves
 * on this frame rather than the next half second - the tick re-lays the layer
 * out because the edge is part of what it was placed for.
 *
 * Arguments:
 * 0: Edge - "left" or "right" <STRING>
 *
 * Return Value:
 * Set <BOOL>
 *
 * Example:
 * ["left"] call jmfsb_devices_fnc_overlaySetEdge
 *
 * Public: Yes
 */

params [["_edge", "", [""]]];

if !(_edge in EDGES) exitWith {false};

GVAR(overlayEdge) = _edge;
if ((profileNamespace getVariable [QGVAR(overlayEdge), ""]) isNotEqualTo _edge) then {
    profileNamespace setVariable [QGVAR(overlayEdge), _edge];
    saveProfileNamespace;
};

[] call FUNC(overlayTick);

true
