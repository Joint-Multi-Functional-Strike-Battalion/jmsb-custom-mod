#include "script_component.hpp"
/*
 * Author: JMSB
 * Every PM_TICK seconds (XEH_postInit): a tablet map that has opened gets the
 * route drawn on it, and a walked route moves on when the GPS says the next
 * waypoint is inside the arrival radius - or ends at the last. No fix, no
 * arrival: a jammed set does not walk the route by itself.
 *
 * Arguments:
 * None (a CBA per-frame handler)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_pointman_fnc_tick
 *
 * Public: No
 */

private _tablet = uiNamespace getVariable [QEGVAR(devices,display), displayNull];
if (!isNull _tablet) then {[_tablet displayCtrl IDC_HOST_MAP] call FUNC(attach)};

if (!GVAR(navigating)) exitWith {};
([] call FUNC(state)) params ["", "_i", "_n", "_label", "_dist"];
if (_dist < 0 || _dist > GVAR(arriveRadius)) exitWith {};

if (_i + 1 >= _n) exitWith {
    [false] call FUNC(use);
    [format ["WP %1 %2 reached. Route complete.", _i + 1, _label], "high"] call FUNC(say);
};
GVAR(next) = _i + 1;
(GVAR(waypoints) select GVAR(next)) params ["", "_nextLabel"];
[format ["WP %1 reached. Next: WP %2 %3.", _i + 1, _i + 2, _nextLabel]] call FUNC(say);
