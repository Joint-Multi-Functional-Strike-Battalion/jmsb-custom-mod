#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a module's aircraft class in the air over the module - the module is
 * the airbase - pointed at where it is going, crewed and ready.
 *
 * VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked, then they spawn in at alt over the support module
 * location"). Made when it is tasked, never before: at its flight level over
 * the module, engines on and flying (EFUNC(support,spawnAirborne) - a plane
 * fast enough not to stall), clear of any other aircraft there. Full of fuel
 * and stores: every tasking is a fresh airframe.
 *
 * IN THE AIR, NOT ON A RUNWAY. A module dropped in a field has no runway, and
 * AI taxiing is the least reliable thing the engine does.
 *
 * ITS AIRFIELD (2026-11-01) is the module it was made over: the support
 * core's tactical lights let it show lights there and nowhere else
 * (FUNC(prepareAircraft)).
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

params [["_logic", objNull, [objNull]], ["_to", [], [[]]], ["_height", 0, [0]]];

if (isNull _logic) exitWith {objNull};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _start = [_home select 0, _home select 1, _height];
private _dir = if (count _to < 2) then {_logic getVariable [QGVAR(homeDir), 0]} else {_home getDir _to};

private _veh = createVehicle [_cls, _start, [], 0, "FLY"];
if (isNull _veh) exitWith {
    WARNING_2("%1 could not put '%2' in the air",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_cls);
    objNull
};

// A CLEAR START FOR THE ROTOR (2026-11-02, the user's RPT 07:37:53: RAVEN's
// main rotor wrecked before it had flown anywhere, nothing hit it): a
// helicopter is not started with anything standing into its rotor disc - the
// nearest clear spot instead, said in the RPT (FUNC(clearSpot)).
if ([_veh] call EFUNC(support,isRotary)) then {
    ([_veh, _start, _height, CLEAR_SPAWN_SEARCH] call FUNC(clearSpot)) params ["_spot", "_blockers"];
    if (_blockers isEqualTo []) exitWith {};
    private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
    if (_spot isEqualTo []) exitWith {
        WARNING_4("%1: '%2' starts at %3 with %4 in its rotor's way - no clear spot near",_callsign,_cls,mapGridPosition _start,_blockers joinString ", ");
    };
    WARNING_5("%1: '%2' start at %3 blocked for the rotor by %4 - moved %5 m",_callsign,_cls,mapGridPosition _start,_blockers joinString ", ",round (_start distance2D _spot));
    _start = [_spot select 0, _spot select 1, _height];
};
[_veh, _start, _height, _dir] call EFUNC(support,spawnAirborne);
_veh setVariable [QGVAR(airfield), _home];

if (isNull ([_logic, _veh] call FUNC(prepareAircraft))) exitWith {
    deleteVehicle _veh;
    objNull
};

_veh
