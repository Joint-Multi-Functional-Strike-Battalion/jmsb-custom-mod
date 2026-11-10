#include "script_component.hpp"
/*
 * Author: YonV
 * Sends a transport that is out home: writes the HOME leg as its current
 * order, which its watch re-plans on the next tick (FUNC(transportTick)),
 * and says why. Bingo fuel, a finished extraction, a paradrop that is out.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The watch's state <HASHMAP>
 * 2: What the side is told <STRING>
 * 3: Points flown first, in order - an extraction's EGRESS (user, 2026-11-02) <ARRAY> (optional, default [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _st, "bingo fuel, returning to base"] call jmfsb_support_air_fnc_transportHome
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_st", createHashMap, [createHashMap]], ["_why", "", [""]], ["_via", [], [[]]]];

if (isNull _logic) exitWith {};

private _requester = _st getOrDefault ["requester", objNull];
_logic setVariable [QGVAR(order), [TASK_HOME, _logic getVariable [QGVAR(home), getPosATL _logic], _requester, TASK_HEIGHT_NONE, 0, 0, 0, createHashMapFromArray [["via", +_via]]]];
_logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];
[_logic, _why, "normal", _requester] call FUNC(say);
