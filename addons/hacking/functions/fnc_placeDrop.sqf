#include "script_component.hpp"
/*
 * Author: YonV
 * Puts the drop case down in front of the player, standing on the ground it
 * is actually on rather than floating at map height.
 *
 * The item leaves the inventory first: if the placement somehow fails, having
 * neither the item nor the object would lose the drop entirely, so the object
 * is made before the item is taken.
 *
 * Arguments:
 * 0: The player <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {};
if !(QGVAR(dropItem) in (items _unit)) exitWith {};

private _dir = getDir _unit;
private _pos = _unit modelToWorldVisual [0, 1.5, 0];

// Sit it on whatever surface is really there - a slope, a floor, a ramp.
private _hits = lineIntersectsSurfaces [
    (AGLToASL _pos) vectorAdd [0, 0, 1.5],
    (AGLToASL _pos) vectorDiff [0, 0, 1.5],
    _unit, objNull, true, 1, "GEOM", "FIRE"
];

private _drop = createVehicle [QGVAR(drop), [0, 0, 0], [], 0, "CAN_COLLIDE"];
if (isNull _drop) exitWith {
    ["Intel Drop", "Could not place it here.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

_drop setDir _dir;
if (_hits isNotEqualTo []) then {
    (_hits select 0) params ["_touch", "_normal"];
    _drop setPosASL _touch;
    _drop setVectorUp _normal;
} else {
    _drop setPosATL _pos;
};

_unit removeItem QGVAR(dropItem);

["Intel Drop", "Collection point established."] call EFUNC(notify,notify);
