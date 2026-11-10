#include "script_component.hpp"
/*
 * Author: YonV
 * A drone's electronics are cooked (runs where the drone is local): engine
 * dead, fuel gone, its AI stopped so it cannot recover, and the airframe
 * falls. UNTESTED PER AIRFRAME (spec blocker B1): a quadcopter, a fixed
 * wing and a loitering munition each simulate differently and may glide,
 * autorotate or drop - the method is the spec's preferred one, kept in one
 * place so it can be changed once.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_d", objNull, [objNull]]];
if (isNull _d || {!local _d}) exitWith {};

_d setHitPointDamage ["HitEngine", 1];
_d setFuel 0;
_d engineOn false;
{ _x disableAI "ALL" } forEach crew _d;
// a flown drone keeps its pilot's link - forcing the disconnect is deferred (B3)
