#include "script_component.hpp"
/*
 * Author: YonV
 * Drops every waypoint and stops navigating.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_pointman_fnc_clear
 *
 * Public: Yes
 */

[false] call FUNC(use);
GVAR(waypoints) = [];
GVAR(next) = -1;
