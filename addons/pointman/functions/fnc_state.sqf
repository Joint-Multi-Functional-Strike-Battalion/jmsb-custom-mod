#include "script_component.hpp"
/*
 * Author: JMSB
 * What Point Man is doing now: whether a route is being walked, which
 * waypoint is next, and how far and which way it is from where the GPS says
 * the player is (FUNC(gpsPos)). One answer for the page, the tile, the
 * phone's cell, the tablet bar and the map.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: Navigating <BOOL>
 * 1: The next waypoint's index, -1 for none <NUMBER>
 * 2: How many waypoints <NUMBER>
 * 3: The next waypoint's label <STRING>
 * 4: Distance to it in metres, -1 with no fix <NUMBER>
 * 5: Bearing to it in degrees, -1 with no fix <NUMBER>
 *
 * Example:
 * ([] call jmfsb_pointman_fnc_state) params ["_navigating", "_next", "_count", "_label", "_distance", "_bearing"]
 *
 * Public: Yes
 */

private _wps = GVAR(waypoints);
private _n = count _wps;
if (!GVAR(navigating) || GVAR(next) < 0 || GVAR(next) >= _n) exitWith {[false, -1, _n, "", -1, -1]};

private _wp = _wps select GVAR(next);
private _label = _wp select WP_LABEL;
// Where it is now: a FOLLOW waypoint moves with its man.
private _pos = [_wp] call FUNC(wpPos);
private _here = [] call FUNC(gpsPos);
if (_here isEqualTo []) exitWith {[true, GVAR(next), _n, _label, -1, -1]};

[true, GVAR(next), _n, _label, _here distance2D _pos, _here getDir _pos]
