#include "script_component.hpp"
/*
 * Author: YonV
 * A guided munition loses its guidance (runs where the projectile is local):
 * the target is cleared, so it flies on ballistically past the hull, with a
 * small kick so the miss is visible.
 *
 * Arguments:
 * 0: Projectile <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_p", objNull, [objNull]]];
if (isNull _p || {!local _p}) exitWith {};

_p setMissileTarget objNull;
private _v = velocityModelSpace _p;
_p setVelocityModelSpace [(_v select 0) + (random 30) - 15, _v select 1, (_v select 2) + 10 + random 10];
