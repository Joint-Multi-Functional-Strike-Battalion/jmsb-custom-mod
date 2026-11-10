#include "script_component.hpp"
/*
 * Author: YonV
 * One delivery aircraft in the air over the module (user, 2026-11-02: "all
 * support aircraft needs to be virtual till tasked, then they spawn in at alt
 * over the support module location"), at its flight height, engines on and
 * flying (EFUNC(support,spawnAirborne) - clear of any other aircraft there),
 * pointed at where it is going, crewed by the players' side and ready.
 *
 * IN THE AIR, NOT ON A RUNWAY - support_air's rule: AI taxiing is the least
 * reliable thing the engine does.
 *
 * THE AI DOES NOT DECIDE WHERE IT GOES: CARELESS, weapons held, no fleeing,
 * the driver locked - a cargo aircraft that breaks off to dodge small arms
 * never makes the delivery. ALiVE is told to leave it alone, through the
 * adapter, as support_air does for every aircraft it creates; its loss is
 * counted on the server (FUNC(lost)).
 *
 * TACTICAL (user, 2026-11-01): lit only over its airfield - the module - and
 * dark everywhere else, its crew kept from switching lights on
 * (EFUNC(support,tactical)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Where it appears, [x, y] or [x, y, z] - over the module, offset for a
 *    sling helicopter beside another <ARRAY>
 * 2: Where it is going (the heading) <ARRAY>
 * 3: Height above the terrain to appear and fly at, m <NUMBER>
 *
 * Return Value:
 * The aircraft, objNull when it could not be made <OBJECT>
 *
 * Example:
 * [_logic, getPosATL _logic, _pos, 250] call jmfsb_support_logistics_fnc_spawnAircraft
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_from", [], [[]]], ["_to", [], [[]]], ["_height", DEF_DROP_HEIGHT, [0]]];

if (isNull _logic || {count _from < 2}) exitWith {objNull};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _callsign = _logic getVariable [QGVAR(callsign), DEF_CALLSIGN];
private _start = [_from select 0, _from select 1, _height];

private _veh = createVehicle [_cls, _start, [], 0, "FLY"];
if (isNull _veh) exitWith {
    WARNING_2("%1 could not put '%2' in the air",_callsign,_cls);
    objNull
};

[_veh, _start, _height, _from getDir _to] call EFUNC(support,spawnAirborne);

private _grp = createGroup [_logic getVariable [QGVAR(side), west], true];
_grp createVehicleCrew _veh;
if (isNull driver _veh) exitWith {
    WARNING_2("%1: '%2' could not be crewed",_callsign,_cls);
    deleteVehicle _veh;
    deleteGroup _grp;
    objNull
};

_grp = group driver _veh;
_grp allowFleeing 0;
_grp setBehaviour "CARELESS";
_grp setCombatMode "BLUE";
// THE PILOT LEADS (2026-11-05, as support_air's aircraft): createVehicleCrew
// makes a gunner the leader as often as not, and a group's orders are its
// leader's. The crew never goes looking for a fight or drops into combat
// under fire - Simplex flies its delivery aircraft the same way.
_grp selectLeader (driver _veh);
{
    _x disableAI "TARGET";
    _x disableAI "AUTOTARGET";
    _x disableAI "AUTOCOMBAT";
} forEach (units _grp);
_veh lockDriver true;
_veh setVariable [QGVAR(owner), _logic, true];
[_veh] call EFUNC(common,lambsOff);
[_veh, _logic getVariable [QGVAR(home), getPosATL _logic]] call EFUNC(support,tactical);

if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
    [_veh] call EFUNC(adapter_alive,profileIgnore);
};

// MPKilled, counted on the server: Killed fires only where the aircraft is
// local, and a player taking the controls moves it to his client.
_veh addMPEventHandler ["MPKilled", {
    params ["_veh", "_killer"];
    if (!isServer) exitWith {};
    [_veh getVariable [QGVAR(owner), objNull], _veh, _killer] call FUNC(lost);
}];
// TAKING FIRE, said in its thread once per HIT_SAID_S (user, 2026-11-05).
// Hit fires where the aircraft is local - the server, it is made here.
_veh addEventHandler ["Hit", {
    params ["_veh"];
    if (isServer && {CBA_missionTime - (_veh getVariable [QGVAR(hitSaidAt), -HIT_SAID_S]) >= HIT_SAID_S}) then {
        _veh setVariable [QGVAR(hitSaidAt), CBA_missionTime];
        [QEGVAR(support,aircraftEvent), [_veh, format [EVENT_TAKING_FIRE, mapGridPosition _veh], true]] call CBA_fnc_localEvent;
    };
}];

_veh
