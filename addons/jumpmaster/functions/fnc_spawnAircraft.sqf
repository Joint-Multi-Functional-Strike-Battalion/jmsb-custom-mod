#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the jump aircraft in the air at the start of the run - the setting's
 * class, or the side's own - pointed down the path at altitude and at speed,
 * crewed by the squad's side, careless and locked, left alone by LAMBS and
 * ALiVE. Everything about where it goes is FUNC(srvTick)'s.
 *
 * Arguments:
 * 0: The leader <OBJECT>
 * 1: Where it appears, [x, y] <ARRAY>
 * 2: Heading <NUMBER>
 * 3: Altitude over the ground, m <NUMBER>
 *
 * Return Value:
 * The aircraft, objNull when it could not be made <OBJECT>
 *
 * Example:
 * [player, [1000, 2000], 90, 6000] call jmfsb_jumpmaster_fnc_spawnAircraft
 *
 * Public: No
 */

params [["_leader", objNull, [objNull]], ["_start", [], [[]]], ["_dir", 0, [0]], ["_alt", 150, [0]]];

if (isNull _leader || {count _start < 2}) exitWith {objNull};

private _side = side group _leader;
private _cls = trim GVAR(aircraft);
if (_cls isEqualTo "") then {
    _cls = DEFAULT_AIRCRAFT select (([west, east, independent] find _side) max 0);
};
if (!isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_1("jump aircraft '%1' is not a class on this server",_cls);
    objNull
};

private _at = [_start select 0, _start select 1, _alt];
private _veh = createVehicle [_cls, _at, [], 0, "FLY"];
if (isNull _veh) exitWith {objNull};

_veh setDir _dir;
_veh setPosATL _at;
_veh setVectorUp [0, 0, 1];
if (_veh isKindOf "Plane") then {
    _veh setVelocityModelSpace [0, PLANE_START_SPEED * getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") / 3.6, 0];
};
_veh flyInHeight _alt;

private _grp = createGroup [_side, true];
_grp createVehicleCrew _veh;
if (isNull driver _veh) then {createVehicleCrew _veh};
_grp = group driver _veh;
if (isNull _grp) exitWith {
    WARNING_1("jump aircraft '%1' could not be crewed",_cls);
    deleteVehicle _veh;
    objNull
};

_grp allowFleeing 0;
_grp setBehaviour "CARELESS";
_grp setCombatMode "BLUE";
_veh lockDriver true;
_veh setVariable [QGVAR(jumpAircraft), true, true];
[_veh] call EFUNC(common,lambsOff);
if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
    [_veh] call EFUNC(adapter_alive,profileIgnore);
};

_veh
