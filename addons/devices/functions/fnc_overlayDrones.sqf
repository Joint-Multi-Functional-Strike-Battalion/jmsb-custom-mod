#include "script_component.hpp"
/*
 * Author: YonV
 * The drones the walking view's map marks (docs/DESIGN_PHONE_WALKING.md,
 * "Map": "drones (circle + callsign)"), and the colour they are drawn in.
 *
 * THE DRONES BOARD'S FLEET, NOT A NEW LIST: every live UAV of the players'
 * side, derived the way the DRONES app derives it (D59), straight from
 * jmfsb_tacpad_apps_fnc_appDronesData - so the phone marks exactly what the
 * tablet's FLEET lists.
 *
 * THE NAME is the FLEET row's own (appDronesData), so the map and the board
 * agree.
 *
 * Called by FUNC(overlayTick) every DRONE_MARK_PERIOD seconds while the
 * walking view is up, never per frame; FUNC(overlayDrawDrones) draws what it
 * answers on every frame.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [accent RGBA, [[drone, callsign], ...]] <ARRAY>
 *
 * Example:
 * GVAR(overlayDrones) = [] call jmfsb_devices_fnc_overlayDrones
 *
 * Public: No
 */

private _accent = ["accent"] call EFUNC(tacpad,theme);
if (isNil QEFUNC(tacpad_apps,appDronesData)) exitWith {[_accent, []]};

private _drones = [];
{
    // The FLEET row's own name, so the map and the board agree.
    _x params [["_uav", objNull, [objNull]], ["_name", "", [""]]];
    if (!isNull _uav) then {
        _drones pushBack [_uav, _name];
    };
} forEach ([] call EFUNC(tacpad_apps,appDronesData));

[_accent, _drones]
