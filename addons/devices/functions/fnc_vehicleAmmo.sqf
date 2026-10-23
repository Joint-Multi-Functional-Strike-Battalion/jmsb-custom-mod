#include "script_component.hpp"
/*
 * Author: JMSB
 * A vehicle's ammunition, turret by turret and weapon by weapon, and its
 * countermeasures - smoke and flares - counted apart.
 *
 * READ OFF magazinesAllTurrets: every magazine on the vehicle, with the turret
 * it is loaded in and the rounds in it, and filed under the first of that
 * turret's weapons that takes it (compatibleMagazines), or OTHER when none does.
 * Magazines of the same kind are counted together: "APFSDS-T  4 MAGS  20 RDS".
 *
 * A magazine's ammunition says whether it is a countermeasure: shotCM, or
 * shotSmoke for any smoke a turret carries. SMOKE OR FLARE IS THE LAUNCHER'S
 * CALL, not the simulation's: a vehicle smoke launcher's ammunition
 * (SmokeLauncherAmmo) is shotCM exactly like a flare, so a shotCM magazine is
 * smoke when the weapon that takes it is a SmokeLauncher, or its ammunition's
 * muzzle effect is the smoke launcher's, and a flare otherwise.
 *
 * A turret is named the way its config names its seat (gunnerName); [-1] is
 * the DRIVER, or the PILOT on an aircraft, whose guns, pylons and flares sit
 * on that seat.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * 0: Turrets: [label, [[weapon name, [[magazine name, magazines, rounds], ...]], ...]] <ARRAY>
 * 1: Countermeasures: [smoke rounds, smoke magazines, flare rounds, flare magazines] <ARRAY of NUMBERs>
 *
 * Example:
 * ([vehicle player] call jmfsb_devices_fnc_vehicleAmmo) params ["_turrets", "_countermeasures"]
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle) exitWith {[[], [0, 0, 0, 0]]};

private _countermeasures = [0, 0, 0, 0];
private _simFlare = SIM_FLARE;
private _simSmoke = SIM_SMOKE;

// path (as a string) -> [path, weapon class -> magazine name -> [mags, rounds]]
private _turrets = createHashMap;
private _takes = createHashMap;

{
    _x params ["_magazine", "_path", ["_rounds", 0, [0]]];

    // Which of this turret's weapons takes the magazine. Each weapon's list
    // is asked once per read, lower case, because config spellings differ.
    private _magLower = toLower _magazine;
    private _weapon = ((_vehicle weaponsTurret _path) select {
        private _weaponClass = _x;
        if !(_weaponClass in _takes) then {
            _takes set [_weaponClass, (compatibleMagazines _weaponClass) apply {toLower _x}];
        };
        _magLower in (_takes get _weaponClass)
    }) param [0, ""];

    private _ammo = getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
    private _sim = toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation");
    if (_sim in _simFlare || {_sim in _simSmoke}) then {
        private _smoke = _sim in _simSmoke
            || {_weapon isNotEqualTo "" && {_weapon isKindOf [SMOKE_LAUNCHER_WEAPON, configFile >> "CfgWeapons"]}}
            || {((toLower getText (configFile >> "CfgAmmo" >> _ammo >> "muzzleEffect")) find SMOKE_LAUNCHER_EFFECT) >= 0};
        private _slot = [2, 0] select _smoke;
        _countermeasures set [_slot, (_countermeasures select _slot) + _rounds];
        _countermeasures set [_slot + 1, (_countermeasures select (_slot + 1)) + 1];
        continue;
    };

    private _key = str _path;
    (_turrets getOrDefault [_key, [_path, createHashMap]]) params ["", "_weapons"];
    private _mags = _weapons getOrDefault [_weapon, createHashMap];

    private _cfg = configFile >> "CfgMagazines" >> _magazine;
    private _magName = getText (_cfg >> "displayNameShort");
    if (_magName isEqualTo "") then {_magName = getText (_cfg >> "displayName")};
    if (_magName isEqualTo "") then {_magName = _magazine};
    _magName = toUpper _magName;

    (_mags getOrDefault [_magName, [0, 0]]) params ["_count", "_total"];
    _mags set [_magName, [_count + 1, _total + _rounds]];
    _weapons set [_weapon, _mags];
    _turrets set [_key, [_path, _weapons]];
} forEach (magazinesAllTurrets _vehicle);

// Into the page's order: driver first, then the turrets by path.
private _ordered = (values _turrets) apply {[str (_x select 0), _x]};
_ordered sort true;

private _out = _ordered apply {
    (_x select 1) params ["_path", "_weapons"];

    private _label = if (_path isEqualTo TURRET_DRIVER) then {
        [TURRET_LABEL_DRIVER, TURRET_LABEL_PILOT] select (_vehicle isKindOf VEHICLE_KIND_AIR)
    } else {
        private _seat = getText (([_vehicle, _path] call BIS_fnc_turretConfig) >> "gunnerName");
        [toUpper _seat, format ["TURRET %1", _path]] select (_seat isEqualTo "")
    };

    private _rows = [];
    {
        private _weaponClass = _x;
        private _mags = _y;
        private _weaponName = if (_weaponClass isEqualTo "") then {"OTHER"} else {
            private _shown = getText (configFile >> "CfgWeapons" >> _weaponClass >> "displayName");
            toUpper ([_shown, _weaponClass] select (_shown isEqualTo ""))
        };
        private _magRows = [];
        {
            _magRows pushBack [_x, _y select 0, _y select 1];
        } forEach _mags;
        _magRows sort true;
        _rows pushBack [_weaponName, _magRows];
    } forEach _weapons;
    _rows sort true;

    [_label, _rows]
};

[_out, _countermeasures]
