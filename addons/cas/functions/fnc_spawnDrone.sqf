#include "script_component.hpp"
/*
 * Author: YonV
 * Makes one drone of a module in the air, crewed and the server's to fly -
 * the one place a drone is made (user, 2026-11-02: "spawn in at flight level
 * with engines on"; factored out of FUNC(request), which made it at the
 * ingress point). Made when it is tasked, over the module (user, 2026-11-02:
 * "all support aircraft needs to be virtual till tasked, then they spawn in at
 * alt over the support module location"; FUNC(launch)).
 *
 * In the air at its height, engines on, on its heading, clear of any other
 * aircraft (EFUNC(support,spawnAirborne)), at the module's run speed capped at
 * the airframe's own. Nothing about it is the AI's to decide: driver locked,
 * CARELESS, BLUE, targeting off. It has no airfield: dark from the start,
 * its crew kept from lighting up (EFUNC(support,tactical)). ALiVE is told to
 * leave it alone through the adapter, when that is loaded. MPKilled, not
 * Killed: a loiter drone in a controller's hands is local to HIS machine - a
 * loss there would never reach the server (FUNC(killed)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Where, [x, y] or [x, y, z] <ARRAY>
 * 2: Height above the terrain, m <NUMBER>
 * 3: Heading <NUMBER>
 *
 * Return Value:
 * The drone, objNull when it could not be made <OBJECT>
 *
 * Example:
 * [_logic, _from, 4000, 90] call jmfsb_cas_fnc_spawnDrone
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_at", [], [[]]], ["_alt", 0, [0]], ["_dir", 0, [0]]];

if (!isServer || {isNull _logic} || {count _at < 2}) exitWith {objNull};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _side = _logic getVariable [QGVAR(side), west];
private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];
// Capped at what the airframe can actually do, so a module asking 900 km/h of
// a loitering UCAV gets the UCAV's best rather than a velocity write the
// flight model spends the whole run fighting.
private _speed = ((_logic getVariable [QGVAR(speed), REACH_DEF_SPEED]) / KMH_PER_MS)
    min (getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") / KMH_PER_MS);

private _grp = createGroup [_side, true];
private _veh = createVehicle [_cls, [_at select 0, _at select 1, _alt], [], 0, "FLY"];
if (isNull _veh) exitWith {
    WARNING_2("%1 could not put '%2' in the air",_callsign,_cls);
    if (!isNull _grp) then {deleteGroup _grp};
    objNull
};

// ATL: flyInHeight, not flyInHeightASL - over rising ground the ASL form is an
// aircraft that flies into the hill it was sent to bomb the far side of.
[_veh, _at, _alt, _dir] call EFUNC(support,spawnAirborne);
_veh setVelocityModelSpace [0, _speed, 0];
_veh lockDriver true;
_grp createVehicleCrew _veh;

// A UAV that comes out crewless flies nowhere. The unary form makes its own
// group, so the orders follow the crew there and the empty one is dropped.
if ((crew _veh) isEqualTo []) then {
    createVehicleCrew _veh;
    private _crewGrp = group ((crew _veh) param [0, objNull]);
    if (!isNull _crewGrp && _crewGrp isNotEqualTo _grp) then {
        deleteGroup _grp;
        _grp = _crewGrp;
    };
};

_veh setVariable [QGVAR(owner), _logic, true];
_grp allowFleeing 0;
_grp setBehaviour "CARELESS";
_grp setCombatMode "BLUE";
{
    _x disableAI "TARGET";
    _x disableAI "AUTOTARGET";
    _x disableAI "AUTOCOMBAT";
} forEach units _grp;
[_veh] call EFUNC(common,lambsOff);
[_veh, []] call EFUNC(support,tactical);

// Guarded: without ALiVE there is nobody to tell (user, 2026-11-02).
if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
    [_veh] call EFUNC(adapter_alive,profileIgnore);
};

_veh addMPEventHandler ["MPKilled", {
    params ["_u", "_k", "_i"];
    if (!isServer) exitWith {};
    [_u getVariable [QGVAR(owner), objNull], [_k, _i] select (!isNull _i), _u] call FUNC(killed);
}];
// TAKING FIRE, said in its thread once per HIT_SAID_S (user, 2026-11-05).
// Hit fires where the drone is local - the server, it is made here.
_veh addEventHandler ["Hit", {
    params ["_u"];
    if (isServer && {CBA_missionTime - (_u getVariable [QGVAR(hitSaidAt), -HIT_SAID_S]) >= HIT_SAID_S}) then {
        _u setVariable [QGVAR(hitSaidAt), CBA_missionTime];
        [QEGVAR(support,aircraftEvent), [_u, format [EVENT_TAKING_FIRE, mapGridPosition _u], true]] call CBA_fnc_localEvent;
    };
}];

_veh
