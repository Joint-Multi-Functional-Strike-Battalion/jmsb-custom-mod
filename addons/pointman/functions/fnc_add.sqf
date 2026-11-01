#include "script_component.hpp"
/*
 * Author: JMSB
 * Adds a waypoint at the end of the route. Its label is the grid it was
 * typed as; a point picked on the map gets its ten-figure grid. With a
 * target it FOLLOWS him (FUNC(follow)): its position is wherever he is.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Label <STRING> (optional, default "": the position's grid)
 * 2: Target to follow <OBJECT> (optional, default objNull: a fixed point)
 *
 * Return Value:
 * Its index, -1 when it was not added <NUMBER>
 *
 * Example:
 * [[1200, 3400, 0]] call jmfsb_pointman_fnc_add
 *
 * Public: Yes
 */

params [["_pos", [], [[]]], ["_label", "", [""]], ["_target", objNull, [objNull]]];

if (count _pos < 2) exitWith {-1};
if (count GVAR(waypoints) >= MAX_WAYPOINTS) exitWith {
    [format ["Point Man holds %1 waypoints. Delete one first.", MAX_WAYPOINTS], "high"] call FUNC(say);
    -1
};

_pos = [_pos select 0, _pos select 1, 0];
if (_label isEqualTo "") then {_label = [_pos] call EFUNC(maptools,gridText)};
if (_label isEqualTo "") then {_label = WP_UNNAMED};
GVAR(waypoints) pushBack [_pos, _label, _target];
if (GVAR(next) < 0) then {GVAR(next) = 0};

count GVAR(waypoints) - 1
