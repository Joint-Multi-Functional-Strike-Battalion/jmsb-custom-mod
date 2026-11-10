#include "script_component.hpp"
/*
 * Author: YonV
 * The car a leader moves town in. One per leader, parked at whichever safe
 * house he is currently in and travelling with him.
 *
 * A civilian vehicle by preference. The man is hiding among the population, so
 * he moves the way the population moves - an armed technical parked outside the
 * house he is hiding in tells players exactly which house to search.
 *
 * Arguments:
 * 0: Where to park it <ARRAY>
 *
 * Return Value:
 * The car, objNull if none could be placed <OBJECT>
 *
 * Example:
 * [getPosATL _house] call jmfsb_leaders_fnc_leaderCar
 */

params [["_at", [], [[]]], ["_house", objNull, [objNull]]];

if (_at isEqualTo []) exitWith {objNull};

// Off the road edge rather than in the middle of it, and never inside the
// house's own footprint.
private _spot = [[], 1, createHashMapFromArray [
    ["centre", _at],
    ["minRange", 15],
    ["maxRange", LEADERS_CAR_RANGE],
    ["footprint", 3],
    ["clearRadius", 3],
    ["nearRoad", 40]
]] call EFUNC(common,findSite);

// The fallback used to be a bare random offset, which is how a car ended up
// standing in a living room: twenty metres from a big house's centre is
// still inside the big house. FUNC(parkSpot) knows where the walls are.
private _pos = _spot param [0, []];
if (_pos isEqualTo []) then {
    _pos = if (isNull _house) then {_at getPos [25, random 360]} else {
        [_house] call FUNC(parkSpot)
    };
};

private _cls = "";
{
    if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _cls = _x };
} forEach LEADERS_CAR_CLASSES;

if (_cls isEqualTo "") exitWith {
    WARNING("no civilian car class available - leaders will move on foot");
    objNull
};

private _car = createVehicle [_cls, _pos, [], 0, "NONE"];
if (isNull _car) exitWith {objNull};

_car setDir random 360;
_car setVectorUp surfaceNormal (getPosATL _car);

// Not a prize. A player who finds the car has found a parked civilian car;
// what it is worth is that it tells them somebody is here.
_car setVariable [QGVAR(leaderCar), true, true];
_car lock 2;

_car
