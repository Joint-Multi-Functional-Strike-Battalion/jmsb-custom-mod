#include "script_component.hpp"
/*
 * Author: YonV
 * The drone marks on the walking view's map: a circle and the callsign for
 * each drone of the players' side (docs/DESIGN_PHONE_WALKING.md, "Map":
 * "drones (circle + callsign)"), in the scheme's accent.
 *
 * Drawn every frame on the map's Draw event from the list FUNC(overlayTick)
 * keeps (FUNC(overlayDrones), re-read every DRONE_MARK_PERIOD seconds) - only
 * the positions are read here, so a mark moves with its drone. Hung under the
 * BFT members (FUNC(overlayOpen)), so a man is never hidden by a drone over
 * him.
 *
 * Arguments (map Draw event):
 * 0: The map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _map ctrlAddEventHandler ["Draw", {_this call jmfsb_devices_fnc_overlayDrawDrones}]
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]]];

GVAR(overlayDrones) params ["_colour", "_drones"];
{
    _x params ["_uav", "_callsign"];
    if (!alive _uav) then {continue};
    _map drawIcon [
        GVAR(droneIcon),
        _colour,
        getPosVisual _uav,
        DRONE_MARK_PX, DRONE_MARK_PX, 0,
        _callsign,
        0, DRONE_MARK_TEXT_SIZE, "RobotoCondensed", "right"
    ];
} forEach _drones;
