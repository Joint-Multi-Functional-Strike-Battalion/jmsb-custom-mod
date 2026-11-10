#include "script_component.hpp"
/*
 * Author: YonV
 * The building under the player's crosshair, for his mark key (user,
 * 2026-11-06). The view line from the camera, out to MARK_LOOK_RANGE: the
 * first surface that belongs to a building (or a building's part) - a fence or
 * a tree in front is looked past, the player and his vehicle are skipped.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The building, objNull for none <OBJECT>
 *
 * Example:
 * private _house = [] call jmfsb_ecoti_fnc_markTarget
 *
 * Public: No
 */

private _from = AGLToASL positionCameraToWorld ORIGIN;
private _to = AGLToASL positionCameraToWorld [0, 0, MARK_LOOK_RANGE];
private _hits = lineIntersectsSurfaces [_from, _to, player, vehicle player, true, MARK_LOOK_HITS, "GEOM", "FIRE"];

private _found = objNull;
{
    _x params ["", "", "_object", "_parent"];
    private _candidate = [_object, _parent] select (!isNull _parent);
    if (!isNull _candidate && {_candidate isKindOf MARK_BUILDING_CLASS}) exitWith {_found = _candidate};
} forEach _hits;

_found
