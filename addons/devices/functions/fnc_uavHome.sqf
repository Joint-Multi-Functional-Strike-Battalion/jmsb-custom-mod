#include "script_component.hpp"
/*
 * Author: JMSB
 * Where RTB flies a drone, and what to call it:
 *
 *   LAUNCH POINT  what the drone records, its public jmfsb_devices_uavHome -
 *                 set by whatever launched it (jmfsb_drone40 records the
 *                 launcher's position) or by FUNC(uavControl) when the drone
 *                 was linked sitting on the ground
 *   STAGING / a patrol base's name
 *                 else the nearest to the drone of the mission's staging zones
 *                 (jmfsb_mission, built on this machine) and the patrol bases
 *                 of the players' side (jmfsb_patrol_base, public) - the side
 *                 derived as FUNC(uavCan) derives it (D59)
 *   OPERATOR      else the unit asking
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Unit asking (optional, default the local player) <OBJECT>
 *
 * Return Value:
 * [position ATL, label] <ARRAY>
 *
 * Example:
 * ([_uav] call jmfsb_devices_fnc_uavHome) params ["_pos", "_label"]
 *
 * Public: Yes
 */

params [["_uav", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _unit) then {_unit = player};

private _home = _uav getVariable [QGVAR(uavHome), []];
if (_home isNotEqualTo []) exitWith {[+_home, UAV_HOME_LAUNCH]};

private _sides = call EFUNC(common,playerSides);
private _side = side group _unit;
if (_sides isNotEqualTo [] && !(_side in _sides)) then {_side = _sides select 0};

private _places = [];
{
    _x params [["_zone", objNull, [objNull, ""]]];
    if (_zone isEqualType objNull) then {
        if (!isNull _zone) then {_places pushBack [getPosATL _zone, UAV_HOME_STAGING]};
    } else {
        if (markerShape _zone isNotEqualTo "") then {_places pushBack [markerPos [_zone, true], UAV_HOME_STAGING]};
    };
} forEach (missionNamespace getVariable [QEGVAR(Staging,Zones), []]);

{
    _x params [["_beacon", objNull, [objNull]], ["_name", "", [""]], ["_baseSide", sideUnknown, [west]]];
    if (!isNull _beacon && _baseSide isEqualTo _side) then {
        _places pushBack [getPosATL _beacon, toUpper _name];
    };
} forEach (missionNamespace getVariable [QEGVAR(patrol_base,bases), []]);

if (_places isEqualTo []) exitWith {[getPosATL _unit, UAV_HOME_OPERATOR]};

private _from = getPosATL _uav;
private _best = _places select 0;
{
    if ((_from distance2D (_x select 0)) < (_from distance2D (_best select 0))) then {_best = _x};
} forEach _places;
_best
