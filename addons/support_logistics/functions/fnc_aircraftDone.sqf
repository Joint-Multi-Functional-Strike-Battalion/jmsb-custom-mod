#include "script_component.hpp"
/*
 * Author: YonV
 * One aircraft of a delivery is done - home over the module, or lost. The row's
 * vehicle moves to one still flying; the last one ends the delivery
 * (FUNC(finish)). Called by the watch before it removes the aircraft.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The sortie <HASHMAP>
 * 2: The aircraft <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _sortie, _veh] call jmfsb_support_logistics_fnc_aircraftDone
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_sortie", createHashMap, [createHashMap]], ["_veh", objNull, [objNull]]];

if (isNull _logic) exitWith {};

// THE DRONE ESCORTS (2026-11-01) go with an aircraft that made it home; the
// escorts of one that was lost fly home by themselves (the support core's
// escort watch).
if (alive _veh) then {[_veh] call EFUNC(support,escortEnd)};

private _aircraft = _sortie getOrDefault ["aircraft", []];
private _at = _aircraft find _veh;
if (_at > -1) then {_aircraft deleteAt _at};
private _flying = _aircraft select {alive _x};
_logic setVariable [QGVAR(vehicle), _flying param [0, objNull], true];

if (_aircraft isEqualTo []) then {[_logic] call FUNC(finish)};
