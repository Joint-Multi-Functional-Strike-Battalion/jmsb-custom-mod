#include "script_component.hpp"
/*
 * Author: YonV
 * Somewhere a car can actually stand near a building - the kerb outside it,
 * not the middle of its floor.
 *
 * WHY THIS EXISTS: a house's position is the centre of the house, and both
 * the parking and the driving used it directly. Parking dropped cars on top
 * of buildings, and a MOVE waypoint on it ordered the driver to steer into
 * the wall and keep pushing, which is what "leaders drive into houses" was.
 *
 * The road wins when there is one - a civilian car stopping at the kerb is
 * exactly right, and it gives the driver a path that ends somewhere it can
 * legally be. Failing that, a point clear of the building's own bounding box
 * on open ground.
 *
 * Arguments:
 * 0: The building <OBJECT>
 *
 * Return Value:
 * Position <ARRAY>
 *
 * Example:
 * [_house] call jmfsb_leaders_fnc_parkSpot
 */

params [["_house", objNull, [objNull]]];

if (isNull _house) exitWith {[0, 0, 0]};

private _at = getPosATL _house;

// the kerb, if this house has one
private _roads = _at nearRoads LEADERS_PARK_ROAD;
if (_roads isNotEqualTo []) exitWith {
    private _best = _roads select 0;
    {
        if ((getPosATL _x) distance2D _at < (getPosATL _best) distance2D _at) then { _best = _x };
    } forEach _roads;
    getPosATL _best
};

// no road: outside the building's own footprint, on ground a car can sit on.
// The bounding box is the honest measure of "outside" - a fixed offset puts
// the car through the wall of anything bigger than a shed.
(boundingBoxReal _house) params ["_bbMin", "_bbMax"];
private _reach = 4 + (((_bbMax select 0) - (_bbMin select 0)) max ((_bbMax select 1) - (_bbMin select 1))) / 2;

private _spot = [[], 1, createHashMapFromArray [
    ["centre", _at],
    ["minRange", _reach],
    ["maxRange", _reach + 25],
    ["footprint", 3],
    ["clearRadius", 3]
]] call EFUNC(common,findSite);

_spot param [0, _at getPos [_reach + 5, random 360]]
