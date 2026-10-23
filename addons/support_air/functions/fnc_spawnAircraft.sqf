#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a module's aircraft class in the air over the module - the module is
 * the airbase - pointed at where it is going, crewed and ready.
 *
 * IN THE AIR, NOT ON A RUNWAY. A module dropped in a field has no runway, and
 * AI taxiing is the least reliable thing the engine does; the response delay
 * on the module is the time a real launch would have taken.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Where it is going (only the bearing is used) <ARRAY>
 * 2: Height above the terrain to appear at, m <NUMBER>
 *
 * Return Value:
 * The aircraft, objNull when it could not be made <OBJECT>
 *
 * Example:
 * [_logic, _pos, 600] call jmfsb_support_air_fnc_spawnAircraft
 *
 * Public: No
 */

// A fixed-wing aircraft created still is a stall; it starts at this share of
// its top speed.
#define PLANE_START_SPEED 0.6

params [["_logic", objNull, [objNull]], ["_to", [], [[]]], ["_height", 100, [0]], ["_from", [], [[]]]];

if (isNull _logic) exitWith {objNull};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _at = [_from, _home] select (_from isEqualTo []);
private _start = [_at select 0, _at select 1, _height];
private _dir = if (_to isEqualTo []) then {_logic getVariable [QGVAR(homeDir), 0]} else {_at getDir _to};

private _veh = createVehicle [_cls, _start, [], 0, "FLY"];
if (isNull _veh) exitWith {
    WARNING_2("%1 could not put '%2' in the air",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_cls);
    objNull
};

_veh setDir _dir;
_veh setPosATL _start;
_veh setVectorUp [0, 0, 1];
if (_veh isKindOf "Plane") then {
    _veh setVelocityModelSpace [0, PLANE_START_SPEED * getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") / 3.6, 0];
};
_veh flyInHeight _height;

if (isNull ([_logic, _veh] call FUNC(prepareAircraft))) exitWith {
    deleteVehicle _veh;
    objNull
};

_veh
