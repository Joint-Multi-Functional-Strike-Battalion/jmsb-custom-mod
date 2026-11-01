#include "script_component.hpp"
/*
 * Author: JMSB
 * What the tablet bar says while a route is walked (jmfsb_devices'
 * deviceFacts): the next waypoint, its distance and bearing. "" otherwise.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The line, "" when not navigating <STRING>
 *
 * Example:
 * [] call jmfsb_pointman_fnc_navText
 *
 * Public: Yes
 */

([] call FUNC(state)) params ["_nav", "_i", "", "", "_dist", "_brg"];

if (!_nav) exitWith {""};
if (_dist < 0) exitWith {format [NAV_FORMAT, _i + 1, "NO FIX", ""]};

format [NAV_FORMAT, _i + 1, [_dist] call EFUNC(maptools,distanceText), [_brg] call EFUNC(maptools,bearingText)]
