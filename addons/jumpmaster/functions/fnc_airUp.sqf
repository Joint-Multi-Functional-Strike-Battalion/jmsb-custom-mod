#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a JMSB - Jump Aircraft module is tasked - its JUMP REQUEST accepted
 * (FUNC(srvThread)) - and its aircraft is made (user, 2026-11-02: "all support
 * aircraft needs to be virtual till tasked, then they spawn in at alt over the
 * support module location"). Until now it was virtual: nothing in the mission.
 *
 * Made directly over the module, AIR_ALT m up, engines on and flying, clear of
 * any other aircraft (FUNC(spawnAircraft), EFUNC(support,spawnAirborne)),
 * crewed, profiled and dark like every jump aircraft (EFUNC(support,tactical)
 * with no airfield). It orbits the module - AIR_ORBIT_PLANE / AIR_ORBIT_HELI m
 * round - for the leader's BOARD. Its drone escorts go up with it
 * (EFUNC(support_air,escortLaunch): a plane always, a helicopter only for a
 * YELLOW or RED LZ - a jump card has none). Losing it is counted
 * (FUNC(airLost)); its watch is FUNC(airTick).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The aircraft, objNull when none was made <OBJECT>
 *
 * Example:
 * [_logic] call jmfsb_jumpmaster_fnc_airUp
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {objNull};
if (isRemoteExecuted) exitWith {
    WARNING_1("airUp: refused - remote call from machine %1",remoteExecutedOwner);
    objNull
};
private _have = _logic getVariable [QGVAR(veh), objNull];
if (alive _have) exitWith {_have};

private _callsign = _logic getVariable [QGVAR(callsign), JUMP_CALLSIGN];
private _side = _logic getVariable [QGVAR(side), west];
(getPosATL _logic) params ["_mx", "_my"];
private _station = [_mx, _my, 0];
private _veh = [_side, _logic getVariable [QGVAR(cls), ""], _station, getDir _logic, AIR_ALT] call FUNC(spawnAircraft);
if (isNull _veh) exitWith {
    WARNING_1("jump aircraft '%1' could not be put in the air",_callsign);
    objNull
};

[_veh, []] call EFUNC(support,tactical);
_veh setVariable [QGVAR(owner), _logic];
// MPKilled, counted on the server: Killed fires only where the aircraft is
// local, and a player at the controls moves it to his client.
_veh addMPEventHandler ["MPKilled", {
    params ["_veh"];
    if (!isServer) exitWith {};
    [_veh getVariable [QGVAR(owner), objNull], _veh, "shot down"] call FUNC(airLost);
}];

private _heli = _veh isKindOf "Helicopter";
// A plane orbits at NORMAL: slow and tight in a turn is a stall (support_air's
// FW_HOLD_ORBIT, RPT 2026-10-20).
[_veh, _station, ["NORMAL", "LIMITED"] select _heli, "LOITER", [AIR_ORBIT_PLANE, AIR_ORBIT_HELI] select _heli] call EFUNC(support_air,moveTo);

_logic setVariable [QGVAR(veh), _veh, true];
_logic setVariable [QGVAR(airPhase), AIR_STATION, true];

[_logic, _veh, _station, format ["%1%2%3", JUMP_KIND, ID_SEP, _logic getVariable [QGVAR(id), -1]], _side] call EFUNC(support_air,escortLaunch);
[FUNC(airTick), AIR_TICK, [_logic, _veh]] call CBA_fnc_addPerFrameHandler;

INFO_2("jump aircraft '%1' tasked - airborne over %2",_callsign,mapGridPosition _station);
_veh
