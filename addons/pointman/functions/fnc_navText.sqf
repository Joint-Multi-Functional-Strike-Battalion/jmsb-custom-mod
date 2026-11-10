#include "script_component.hpp"
/*
 * Author: YonV
 * What the tablet bar says while a route is walked (jmfsb_devices'
 * deviceFacts): the next waypoint, its distance and bearing - the short leg
 * (FUNC(legText)), since the bar's right block lost room to the PAC button
 * (2026-11-01) and the full readout ran past it. "" otherwise.
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

format [NAV_FORMAT, _i + 1, [_dist, _brg] call FUNC(legText)]
