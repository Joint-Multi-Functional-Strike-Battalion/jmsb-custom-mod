#include "script_component.hpp"
/*
 * Author: YonV
 * JMSB - AiTR Building Mark, placed in Eden or by a Zeus (user, 2026-11-06:
 * "a way in 3den, zeus and by players to make a building that this is
 * highligheted in ecoti"). Server: marks the buildings synced to the module,
 * else the nearest building within MARK_MODULE_RADIUS of it, in the module's
 * Colour with its Label (FUNC(markSet)). Placed by a Zeus, the module has its
 * defaults; the Zeus dialog (FUNC(zenMark)) asks colour and label.
 *
 * Arguments:
 * 0: Logic <OBJECT>
 * 1: Synced units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [], true] call jmfsb_ecoti_fnc_moduleMark
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], "", ["_activated", true, [true]]];

if (!isServer || {isNull _logic} || {!_activated}) exitWith {};

private _colour = _logic getVariable ["colour", 0];
private _label = _logic getVariable ["label", ""];

private _buildings = (synchronizedObjects _logic) select {_x isKindOf MARK_BUILDING_CLASS};
if (_buildings isEqualTo []) then {
    private _near = nearestObjects [_logic, [MARK_BUILDING_CLASS], MARK_MODULE_RADIUS, true];
    if (_near isNotEqualTo []) then {_buildings = [_near select 0]};
};
if (_buildings isEqualTo []) exitWith {
    WARNING_2("moduleMark: no building within %1 m of %2",MARK_MODULE_RADIUS,mapGridPosition _logic);
};

{
    [_x, _colour, _label] call FUNC(markSet);
} forEach _buildings;
INFO_3("moduleMark: %1 building(s) at %2 marked '%3'",count _buildings,mapGridPosition _logic,_label);
