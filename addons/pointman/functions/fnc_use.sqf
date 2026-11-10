#include "script_component.hpp"
/*
 * Author: YonV
 * Starts or stops walking the route: USE and STOP on the page. Walking starts
 * at the waypoint the page has as next (the first, unless one was pressed),
 * moves on at the arrival radius (FUNC(tick)) and ends at the last. While a
 * route is walked PM is the first cell of the phone's status row.
 *
 * Arguments:
 * 0: Navigate <BOOL> (optional, default true)
 *
 * Return Value:
 * Navigating now <BOOL>
 *
 * Example:
 * [true] call jmfsb_pointman_fnc_use
 *
 * Public: Yes
 */

params [["_on", true, [true]]];

if (_on && {GVAR(waypoints) isEqualTo []}) exitWith {
    ["No waypoints yet: type a grid and ADD, or PICK ON MAP.", "high"] call FUNC(say);
    false
};
if (_on && {GVAR(next) < 0 || {GVAR(next) >= count GVAR(waypoints)}}) then {GVAR(next) = 0};
GVAR(navigating) = _on;

// jmfsb_devices shows the first OVERLAY_STATUS_CELLS (seven) of its order on
// the phone and the side devices: PM goes in front while a route is walked,
// out when not.
private _order = (missionNamespace getVariable [QEGVAR(devices,overlayOrder), []]) - [STATUS_ICON];
if (_on) then {_order = [STATUS_ICON] + _order};
missionNamespace setVariable [QEGVAR(devices,overlayOrder), _order];

if (_on) then {
    (GVAR(waypoints) select GVAR(next)) params ["", "_label"];
    [format ["Navigating. WP %1 of %2: %3.", GVAR(next) + 1, count GVAR(waypoints), _label]] call FUNC(say);
};

_on
