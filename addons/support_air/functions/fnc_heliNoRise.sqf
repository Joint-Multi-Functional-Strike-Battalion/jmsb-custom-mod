#include "script_component.hpp"
/*
 * Author: YonV
 * NO RISE TO SLOW DOWN (user, 2026-11-08: "make sure helos and vtol do not do
 * a large rise to slow down or gain alt to slow down"): every frame while the
 * AI flies a helicopter or VTOL on an order (FUNC(heliOrder)), a climb more
 * than HELI_RISE_MARGIN m over the height it was told (jmfsb_support_fnc_flyAt),
 * both over the terrain under it, is stopped - the AI's braking flare bleeds speed without gaining height; a
 * climb it was told to make is not touched. Lets go when the order is over;
 * stands aside while the flight control holds the airframe, which brakes level
 * itself (FUNC(heliFrame)).
 *
 * Arguments:
 * 0: [the aircraft] <ARRAY>
 * 1: The handler's id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(heliNoRise), 0, [_veh]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params ["_args", "_handle"];
_args params ["_veh"];

if (!alive _veh || {!local _veh} || {count (_veh getVariable [QGVAR(order), createHashMap]) isEqualTo 0}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    _veh setVariable [QGVAR(noRisePfh), -1];
};
if (count (_veh getVariable [QGVAR(flight), createHashMap]) > 0 || {isTouchingGround _veh}) exitWith {};

// ONLY THE BRAKING AT THE END: inside HELI_NO_RISE_RING m of the point.
// THE LIMIT IS OVER THE TERRAIN (user, 2026-11-09: "the flight limit should
// be above terrain"): measured from the terrain - or the sea - under the
// airframe, so following the ground up a hill is never a climb past it.
private _told = _veh getVariable [QEGVAR(support,flyHeight), -1];
if (_told < 0) exitWith {};
private _at = (_veh getVariable [QGVAR(order), createHashMap]) getOrDefault ["at", []];
if (_at isEqualTo [] || {_veh distance2D _at > HELI_NO_RISE_RING}) exitWith {};
private _vel = velocity _veh;
// A take-off or a hover climbs slow; a braking flare climbs fast (the
// Chinook held at 60 m on take-off and never left, 2026-11-08).
if ((_vel select 2) <= 0 || {(vectorMagnitude [_vel select 0, _vel select 1, 0]) < HELI_NO_RISE_SPEED}) exitWith {};
private _pos = getPosASL _veh;
private _ground = (getTerrainHeightASL _pos) max HELI_SEA_Z;
if ((_pos select 2) > _ground + _told + HELI_RISE_MARGIN) then {
    _veh setVelocity [_vel select 0, _vel select 1, 0];
};
