#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Fires one engagement, on the machine where the gunner is local - the firing
 * commands take a local unit. Called directly by the server for its own AI,
 * or by the server's targeted event for a headless client's crew.
 *
 * The gunner watches the aim point; after ADS_SLEW the weapon is fired with
 * forceWeaponFire - once for a missile, a burst of ADS_BURST_ROUNDS for a gun
 * (FUNC(burst), CBA timers, no PFH). A missile is steered at the aim point as
 * it leaves (setMissileTargetPos, from a one-shot Fired handler). The rounds
 * are for the eye: whether the threat dies is FUNC(resolve)'s roll.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Gunner <OBJECT>
 * 2: Weapon <STRING>
 * 3: Fire mode <STRING>
 * 4: Aim point ASL <ARRAY>
 * 5: Is a missile <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_veh, gunner _veh, "weapon_Cannon_Phalanx", "manual", _aim, false] call jmfsb_adsite_fnc_fire
 *
 * Public: No
 */

params ["_veh", "_gunner", "_weapon", "_fireMode", "_aim", "_isMissile"];

if (!alive _veh || {!alive _gunner} || {!local _gunner}) exitWith {};

_gunner doWatch ASLToAGL _aim;

if (_isMissile) then {
    private _old = _veh getVariable [QGVAR(steerEh), -1];
    if (_old >= 0) then { _veh removeEventHandler ["Fired", _old] };
    _veh setVariable [QGVAR(steerAt), _aim];
    private _eh = _veh addEventHandler ["Fired", {
        params ["_veh", "", "", "", "", "", "_proj"];
        _veh removeEventHandler [_thisEvent, _thisEventHandler];
        _veh setVariable [QGVAR(steerEh), -1];
        if (local _proj) then {
            _proj setMissileTargetPos ASLToAGL (_veh getVariable [QGVAR(steerAt), getPosASL _proj]);
        };
    }];
    _veh setVariable [QGVAR(steerEh), _eh];
};

[LINKFUNC(burst), [_veh, _gunner, _weapon, _fireMode, [ADS_BURST_ROUNDS, 1] select _isMissile], ADS_SLEW] call CBA_fnc_waitAndExecute;
