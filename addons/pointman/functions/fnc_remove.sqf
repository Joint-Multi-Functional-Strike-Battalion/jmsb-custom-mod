#include "script_component.hpp"
/*
 * Author: YonV
 * Takes one waypoint out of the route. The one being walked to keeps its
 * place in the list; with the last one gone the route is over.
 *
 * Arguments:
 * 0: Index <NUMBER>
 *
 * Return Value:
 * Removed <BOOL>
 *
 * Example:
 * [0] call jmfsb_pointman_fnc_remove
 *
 * Public: Yes
 */

params [["_index", -1, [0]]];

if (_index < 0 || {_index >= count GVAR(waypoints)}) exitWith {false};

GVAR(waypoints) deleteAt _index;
if (GVAR(next) > _index) then {GVAR(next) = GVAR(next) - 1};
if (GVAR(next) >= count GVAR(waypoints)) then {GVAR(next) = (count GVAR(waypoints)) - 1};
if (GVAR(waypoints) isEqualTo []) then {[false] call FUNC(use)};

true
