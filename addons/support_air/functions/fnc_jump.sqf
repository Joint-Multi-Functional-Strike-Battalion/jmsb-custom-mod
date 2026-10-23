#include "script_component.hpp"
/*
 * Author: JMSB
 * One static-line jumper out of the door, and his descent handed to
 * FUNC(chuteTick).
 *
 * OUT BEHIND THE AIRCRAFT, NOT THROUGH IT. He is taken out of his seat and
 * put just behind and below the tail, a metre or two either side, with the
 * aircraft's own velocity - the way the drop crates leave - so he never meets
 * the airframe on the way down. The line pulls his round canopy
 * STATIC_OPEN_DELAY after exit.
 *
 * HE CANNOT BE HURT ON THE WAY DOWN. An AI in a chute cannot dodge anything
 * and a bad landing is a dead QRF; damage comes back on the ground.
 *
 * Arguments:
 * 0: The jumper <OBJECT>
 * 1: The aircraft <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, _veh] call jmfsb_support_air_fnc_jump
 *
 * Public: No
 */

// Clearance behind the tail and under the belly, m, and the spread either side.
#define EXIT_TAIL_GAP 3
#define EXIT_BELLY_GAP 3
#define EXIT_SIDE 2

params [
    ["_unit", objNull, [objNull]],
    ["_veh", objNull, [objNull]]
];

if (!alive _unit || {isNull _veh}) exitWith {};
// Asked twice, or already out: one jump only.
if (vehicle _unit isNotEqualTo _veh) exitWith {};

private _at = _veh modelToWorldWorld [random [-EXIT_SIDE, 0, EXIT_SIDE], -((sizeOf typeOf _veh) / 2 + EXIT_TAIL_GAP), -EXIT_BELLY_GAP];
private _vel = velocity _veh;

_unit allowDamage false;
unassignVehicle _unit;
moveOut _unit;
_unit setPosASL _at;
_unit setDir getDir _veh;
_unit setVelocity _vel;

[FUNC(chuteTick), CHUTE_TICK, [_unit, objNull, CBA_missionTime + STATIC_OPEN_DELAY]] call CBA_fnc_addPerFrameHandler;
