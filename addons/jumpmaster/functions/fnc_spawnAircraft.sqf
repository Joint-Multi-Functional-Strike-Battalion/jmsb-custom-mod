#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a jump aircraft in the air - a side's own at the start of the run,
 * a module's over the module when it is tasked (FUNC(airUp)) - pointed on its
 * heading at altitude and at speed, crewed by the squad's side, careless and
 * locked, left alone by LAMBS and ALiVE. Everything about where it goes is
 * FUNC(srvTick)'s and FUNC(airTick)'s.
 *
 * Arguments:
 * 0: The squad's side <SIDE>
 * 1: Aircraft class <STRING>
 * 2: Where it appears, [x, y] <ARRAY>
 * 3: Heading <NUMBER>
 * 4: Altitude over the ground, m <NUMBER>
 *
 * Return Value:
 * The aircraft, objNull when it could not be made <OBJECT>
 *
 * Example:
 * [west, "B_T_VTOL_01_infantry_F", [1000, 2000], 90, 6000] call jmfsb_jumpmaster_fnc_spawnAircraft
 *
 * Public: No
 */

params [["_side", west, [west]], ["_cls", "", [""]], ["_start", [], [[]]], ["_dir", 0, [0]], ["_alt", 150, [0]]];

if (count _start < 2) exitWith {objNull};
if (!isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_1("jump aircraft '%1' is not a class on this server",_cls);
    objNull
};

private _at = [_start select 0, _start select 1, _alt];
private _veh = createVehicle [_cls, _at, [], 0, "FLY"];
if (isNull _veh) exitWith {objNull};

// Engines on and flying, clear of any other aircraft (user, 2026-11-02:
// the support core's spawnAirborne).
[_veh, _at, _alt, _dir] call EFUNC(support,spawnAirborne);

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
