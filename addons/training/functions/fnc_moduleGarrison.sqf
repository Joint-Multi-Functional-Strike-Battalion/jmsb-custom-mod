#include "script_component.hpp"
/*
 * Author: YonV
 * JMSB - Garrison Area module. Runs FUNC(garrison) with the module's
 * attributes each time its synced trigger fires, or once at mission start
 * with no trigger. The area is the marker attribute when set, else the
 * module's own area.
 *
 * Arguments:
 * 0: Module logic <OBJECT>
 * 1: Synced units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!isServer || {!_activated} || {isNull _logic}) exitWith {};

private _marker = _logic getVariable ["marker", ""];
private _area = [_marker, _logic] select (_marker isEqualTo "");
private _groups = (_logic getVariable ["groups", ""]) splitString ", ";

[
    _area,
    _groups,
    _logic getVariable ["count", 1],
    _logic getVariable ["patrol", DEFAULT_PATROL],
    _logic getVariable ["hold", DEFAULT_HOLD]
] call FUNC(garrison);
