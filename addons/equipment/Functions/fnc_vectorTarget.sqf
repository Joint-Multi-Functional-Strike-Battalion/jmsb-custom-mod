#include "script_component.hpp"
/*
 * Author: YonV
 * Where the player is looking through a [JMSB] Vector, as an ASL position.
 *
 * ONE RAYCAST, TWO CONSUMERS. The shared target marker and the personal waypoint
 * both need the same answer, and two copies of a line-of-sight test are two
 * copies that can disagree about what "the target" is - one taking a building
 * face and the other the ground behind it.
 *
 * IT TAKES THE NEARER OF TWO HITS. lineIntersectsSurfaces finds objects and
 * building faces; terrainIntersectAtASL finds the ground, which the first does
 * not. Whichever is closer to the eye is what the player is actually looking at,
 * and taking the object hit unconditionally is how a Vector aimed over a wall
 * lands its marker on the wall.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: Target position ASL, [] for nothing in range <ARRAY>
 * 1: Range in metres <NUMBER>
 *
 * Example:
 * ([] call jmfsb_equipment_fnc_vectorTarget) params ["_posASL", "_range"]
 *
 * Public: No
 */

if (isNull ACE_player || {!alive ACE_player}) exitWith {[[], 0]};
if !(currentWeapon ACE_player in [QGVAR(Vector_Designator), QGVAR(Vector_Designator_NVG)]) exitWith {[[], 0]};

private _begin = AGLToASL positionCameraToWorld [0, 0, 0];
private _end = AGLToASL positionCameraToWorld [0, 0, 5000]; // matches maxRange of the Vector

private _posASL = [];
private _intersections = lineIntersectsSurfaces [_begin, _end, ACE_player, objNull, true, 1, "VIEW", "GEOM"];
if (_intersections isNotEqualTo []) then {
    _posASL = (_intersections select 0) select 0;
};

private _terrain = terrainIntersectAtASL [_begin, _end];
if (count _terrain == 3) then {
    if (_posASL isEqualTo [] || {_begin vectorDistance _terrain < _begin vectorDistance _posASL}) then {
        _posASL = _terrain;
    };
};

if (_posASL isEqualTo []) exitWith {[[], 0]};

[_posASL, round (_begin vectorDistance _posASL)]
