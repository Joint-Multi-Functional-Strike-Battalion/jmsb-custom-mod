#include "script_component.hpp"
/*
 * Author: YonV
 * One module as one TAC//SUPPORT row, in the core's shape:
 *
 *   [id, type, callsign, platform, status, ordnance, guns, vehicle, plan]
 *
 * No ordnance list: what it brings is the catalog, which the ITEM stepper
 * walks (FUNC(tasks)). THE VEHICLE is the lead aircraft while one is out, so
 * the map marks it; THE PLAN is the delivery point and the way out, so the
 * board draws the task markers and the route.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The row, [] when the logic is gone <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_support_logistics_fnc_entityRow
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[]};

([_logic] call FUNC(available)) params ["", "_status"];
// NO AIRFRAME LEFT (user, 2026-11-02): off the SUPPORT list.
if (_status isEqualTo STATUS_GONE) exitWith {[]};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    TYPE_LOGISTICS,
    _logic getVariable [QGVAR(callsign), DEF_CALLSIGN],
    getText (configFile >> "CfgVehicles" >> (_logic getVariable [QGVAR(cls), ""]) >> "displayName"),
    _status,
    [],
    0,
    _logic getVariable [QGVAR(vehicle), objNull],
    _logic getVariable [QGVAR(plan), []]
]
