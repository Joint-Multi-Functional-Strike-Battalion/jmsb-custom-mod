#include "script_component.hpp"
/*
 * Author: YonV
 * Where a support aircraft holds while it is on station for a task point
 * (user, 2026-11-01: "loiter or on station needs to be 8k meters off map").
 * A fixed-wing holds OFF_MAP_HOLD m outside the map edge nearest the point,
 * level with it, and comes in from there to attack; a helicopter holds over
 * the point itself.
 *
 * Arguments:
 * 0: The aircraft, or its class <OBJECT or STRING>
 * 1: The task point [x, y] or [x, y, z] <ARRAY>
 *
 * Return Value:
 * The hold point [x, y, 0], [] when no point was given <ARRAY>
 *
 * Example:
 * [_veh, _pos] call jmfsb_support_fnc_holdPoint
 *
 * Public: Yes
 */

params [["_what", objNull, [objNull, ""]], ["_pos", [], [[]]]];

if (count _pos < 2) exitWith {[]};
_pos params ["_px", "_py"];
if (_what isKindOf "Helicopter") exitWith {[_px, _py, 0]};

private _size = worldSize;
// West, east, south, north - the gap to each edge, and the point past it.
private _gaps = [_px, _size - _px, _py, _size - _py];
private _past = [
    [-OFF_MAP_HOLD, _py, 0],
    [_size + OFF_MAP_HOLD, _py, 0],
    [_px, -OFF_MAP_HOLD, 0],
    [_px, _size + OFF_MAP_HOLD, 0]
];

_past select (_gaps find (selectMin _gaps))
