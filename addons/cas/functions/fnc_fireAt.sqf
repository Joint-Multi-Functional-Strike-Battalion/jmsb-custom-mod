#include "script_component.hpp"
/*
 * Author: YonV
 * One pull of the trigger on a CAS aircraft's store - the only thing in the
 * mod that fires a support aircraft's weapon (2026-11-05: the pull of the
 * pass, FUNC(passFrame); it picked the store, made the dummy and fired once
 * before - FUNC(pickStore) and FUNC(passBegin) do that now).
 *
 * THE AI PILOT IS NOT ASKED, AND THAT IS THE DESIGN. Arma's air AI decides for
 * itself whether it likes a target, and a CAS run that depends on it is a CAS
 * run that sometimes orbits the objective without firing. The crewman on the
 * store's turret - the pilot for his own weapons - is made to fire it, the
 * way Simplex Support Services pulls a trigger (its method, no code of it):
 * the weapon selected on its turret, its reload cleared so the pulls come at
 * the pass's interval, forceWeaponFire. Where the round goes is the pass's
 * doing: the nose on the solution, a seeker on the dummy laser target, a bomb
 * flown to the aim (FUNC(bombDrop)).
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: The weapon <STRING>
 * 2: Its turret path <ARRAY>
 *
 * Return Value:
 * The trigger was pulled on a loaded weapon <BOOL>
 *
 * Example:
 * [_veh, "Gatling_30mm_Plane_CAS_01_F", [-1]] call jmfsb_cas_fnc_fireAt
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_weapon", "", [""]], ["_turret", TURRET_PILOT, [[]]]];

if (!alive _veh || _weapon isEqualTo "") exitWith {false};

private _unit = [_veh turretUnit _turret, driver _veh] select (_turret isEqualTo TURRET_PILOT);
if (!alive _unit) exitWith {
    WARNING_2("'%1' could not fire %2 - no crewman on that store",typeOf _veh,_weapon);
    false
};

if ((_veh currentWeaponTurret _turret) isNotEqualTo _weapon) then {
    _veh selectWeaponTurret [_weapon, _turret];
};
(weaponState [_veh, _turret, _weapon]) params ["", ["_muzzle", "", [""]], ["_mode", "", [""]], "", ["_rounds", 0, [0]]];
if (_muzzle isEqualTo "" || _rounds <= 0) exitWith {false};

_veh setWeaponReloadingTime [_unit, _muzzle, 0];
_unit forceWeaponFire [_muzzle, _mode];
true
