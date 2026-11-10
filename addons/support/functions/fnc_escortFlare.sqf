#include "script_component.hpp"
/*
 * Author: YonV
 * Puts out one aircraft's own countermeasures: ESCORT_FLARE_BURSTS bursts,
 * ESCORT_FLARE_GAP seconds apart, from the first countermeasure launcher it
 * carries (a CfgWeapons class of simulation "cmlauncher", on any turret, the
 * pilot's first). The AI's own countermeasures still fire as well; this makes
 * sure an escort flares for the lead, which the AI does only for itself.
 *
 * The launcher is looked up once per airframe and kept. No launcher, no
 * flares. One alarm per aircraft inside ESCORT_FLARE_REST seconds - the
 * handler and the watch's scan may both raise the same missile.
 *
 * Fired by the unit on that turret, where the aircraft is local (the server
 * for every escort and every AI-crewed lead).
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * Flares put out <BOOL>
 *
 * Example:
 * [_veh] call jmfsb_support_fnc_escortFlare
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (!alive _veh || {!local _veh}) exitWith {false};
if (CBA_missionTime < (_veh getVariable [QGVAR(flaredAt), -ESCORT_FLARE_REST]) + ESCORT_FLARE_REST) exitWith {false};

// false: not looked up yet; [] none aboard; else [turret path, weapon].
private _cm = _veh getVariable [QGVAR(cm), false];
if (_cm isEqualTo false) then {
    _cm = [];
    {
        private _path = _x;
        private _weapons = _veh weaponsTurret _path;
        private _at = _weapons findIf {(toLower getText (configFile >> "CfgWeapons" >> _x >> "simulation")) isEqualTo ESCORT_CM_SIMULATION};
        if (_at > -1) exitWith {_cm = [_path, _weapons select _at]};
    } forEach ([[-1]] + allTurrets [_veh, false]);
    _veh setVariable [QGVAR(cm), _cm];
};
if (_cm isEqualTo []) exitWith {false};

_cm params ["_path", "_weapon"];
private _unit = if (_path isEqualTo [-1]) then {driver _veh} else {_veh turretUnit _path};
if (!alive _unit) exitWith {false};

private _modes = getArray (configFile >> "CfgWeapons" >> _weapon >> "modes");
private _mode = _modes param [0, _weapon];
if (ESCORT_CM_MODE in _modes) then {_mode = ESCORT_CM_MODE};
if (_mode isEqualTo "this") then {_mode = _weapon};

_veh setVariable [QGVAR(flaredAt), CBA_missionTime];
for "_k" from 0 to (ESCORT_FLARE_BURSTS - 1) do {
    [{
        params ["_veh", "_unit", "_weapon", "_mode"];
        if (!alive _veh || {!alive _unit}) exitWith {};
        _unit forceWeaponFire [_weapon, _mode];
    }, [_veh, _unit, _weapon, _mode], _k * ESCORT_FLARE_GAP] call CBA_fnc_waitAndExecute;
};

true
