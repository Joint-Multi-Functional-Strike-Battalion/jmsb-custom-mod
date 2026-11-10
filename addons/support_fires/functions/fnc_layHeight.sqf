#include "script_component.hpp"
/*
 * Author: YonV
 * Where a CFF SHIFT's rounds come down. The fire direction centre lays the
 * guns for the known point's height plus the card's UP / DOWN, as a real one
 * does for a shift. A target at that height is hit; one lower or higher is
 * missed along the line of fire, by the height difference over the tangent of
 * the descent: laid too high, the rounds fly on and land long; too low, they
 * hit the ground short. An observer who gives the right UP / DOWN (doctrine:
 * whenever the target is 35 m or more above or below the known point) puts
 * them on. Any other order, or one without a known point, is aimed at the
 * ground at its target as before.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The order <HASHMAP>
 * 2: The point the mission is aimed at <ARRAY>
 *
 * Return Value:
 * [where the rounds land [x, y, 0], the miss (m) - long positive] <ARRAY>
 *
 * Example:
 * [_logic, _order, _aim] call jmfsb_support_fires_fnc_layHeight
 *
 * Public: No
 */

params ["_logic", "_order", "_aim"];

private _known = _order getOrDefault ["known", []];
if ((_order getOrDefault ["method", ""]) isNotEqualTo FIRE_BY_SHIFT || _known isEqualTo [] || _aim isEqualTo []) exitWith {[_aim, 0]};

private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _ball = [_origin distance2D _aim, _logic getVariable [QGVAR(muzzleVelocity), VA_DEF_MV], _logic getVariable [QGVAR(highAngle), true], RISE(_origin,_aim)] call FUNC(ballistics);
if (_ball isEqualTo []) exitWith {[_aim, 0]};

private _laid = (getTerrainHeightASL _known) + (_order getOrDefault ["vertical", 0]);
private _miss = (_laid - getTerrainHeightASL _aim) / tan ((_ball select 0) max LAY_MIN_DESCENT);
if (abs _miss < 1) exitWith {[_aim, 0]};

(_aim getPos [_miss, _origin getDir _aim]) params ["_landX", "_landY"];
[[_landX, _landY, 0], _miss]
