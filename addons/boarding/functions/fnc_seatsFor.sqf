#include "script_component.hpp"
/*
 * Author: YonV
 * The transport a boarding point may use, nearest first.
 *
 * Synchronised vehicles are the mission's answer and are used as given.
 * With none, anything with free cargo near the module is taken instead - a
 * module dropped beside the trucks that are already parked there should just
 * work.
 *
 * Nearest first so a section fills the vehicle it is standing at before the
 * one across the compound.
 *
 * Arguments:
 * 0: The module <OBJECT>
 * 1: Synchronised vehicles (optional, default the logic's public copy; the
 *    server passes its own - review R1) <ARRAY>
 *
 * Return Value:
 * Vehicles with at least one free cargo seat <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_boarding_fnc_seatsFor
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_vehicles", nil, [[]]]];

if (isNull _logic) exitWith {[]};

private _at = getPosATL _logic;
if (isNil "_vehicles") then {_vehicles = _logic getVariable [QGVAR(vehicles), []]};

if (_vehicles isEqualTo []) then {
    _vehicles = (_at nearEntities [["Car", "Truck", "Tank", "Air", "Ship"], BOARD_VEH_SEARCH]);
};

_vehicles = _vehicles select {
    !isNull _x && {alive _x} && {(_x emptyPositions "cargo") > 0}
};

// nearest to the muster point first
private _ranked = _vehicles apply { [_at distance2D _x, _x] };
_ranked sort true;
_ranked apply { _x select 1 }
