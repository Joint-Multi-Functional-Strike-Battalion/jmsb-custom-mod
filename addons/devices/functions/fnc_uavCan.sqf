#include "script_component.hpp"
/*
 * Author: JMSB
 * May this unit link to and fly this drone? The test the vanilla terminal's
 * isUAVConnectable used to be, now that there is no terminal (user,
 * 2026-10-20: the vanilla UAV terminal is out of the arsenal). FUNC(uavControl)
 * asks it before it links or hands a seat over, and again every tick while it
 * holds one (FUNC(uavTick)); the DRONES board asks it for its buttons.
 *
 *   WHO     the UAV operator - the engine trait the UAV tablet is given for
 *           (UAV_TRAIT, the same test as FUNC(open))
 *   WHOSE   the players' side only, derived the way the DRONES board derives
 *           it (D59): the unit's own side when players hold it, else the first
 *           side they do
 *   FREE    nobody else links it (FUNC(uavOperator)) - a link is one man's
 *   LINK    the DATA net (DESIGN_TABLET_APPS.md, DRONES): RF's quality for the
 *           local player's sets; an unknown link (no RF) does not block, a
 *           lost one does. Skipped when the caller asks only about the rest.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Unit <OBJECT> (optional, default the local player)
 * 2: Test the DATA link too <BOOL> (optional, default true)
 *
 * Return Value:
 * [may <BOOL>, why not - "" when he may <STRING>, DATA quality 0..1 or -1 unknown <NUMBER>] <ARRAY>
 *
 * Example:
 * ([_uav] call jmfsb_devices_fnc_uavCan) params ["_ok", "_why", "_quality"]
 *
 * Public: Yes
 */

params [["_uav", objNull, [objNull]], ["_unit", objNull, [objNull]], ["_needLink", true, [true]]];

if (isNull _unit) then {_unit = player};

private _quality = if (isNil QEFUNC(tacpad_apps,radioRfQuality)) then {UAV_QUALITY_UNKNOWN} else {
    [UAV_LINK_NET] call EFUNC(tacpad_apps,radioRfQuality)
};

if (!alive _uav) exitWith {[false, "That drone is gone.", _quality]};
if !(unitIsUAV _uav) exitWith {[false, "That is not a drone.", _quality]};
if !(_unit getUnitTrait UAV_TRAIT) exitWith {[false, "Only the UAV operator flies drones.", _quality]};

private _sides = call EFUNC(common,playerSides);
private _side = side group _unit;
if (_sides isNotEqualTo [] && !(_side in _sides)) then {_side = _sides select 0};
if ((side group _uav) isNotEqualTo _side) exitWith {[false, "That drone is not on your side.", _quality]};

private _operator = [_uav] call FUNC(uavOperator);
if (!isNull _operator && _operator isNotEqualTo _unit) exitWith {
    [false, format ["%1 has that drone.", name _operator], _quality]
};

if (_needLink && _quality > UAV_QUALITY_UNKNOWN && _quality < UAV_LINK_LOST) exitWith {
    [false, "No DATA link.", _quality]
};

[true, "", _quality]
