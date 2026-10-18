#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Is this vehicle air defence, and with what - read once per class from its
 * own loadout and cached, so every later vehicle of the class is one lookup.
 *
 *   GUN      a gun round of ADS_GUN_HIT or more that can lock air, and either a
 *            CIWS rate of fire (ADS_CIWS_RELOAD) or an air search radar on the
 *            vehicle. Every rifle and MG bullet has airLock 1, so airLock
 *            alone would make every armed car air defence.
 *   MISSILE  a missile with the dedicated AA lock (airLock ADS_AA_LOCK) - an
 *            anti-tank missile that may take a helicopter is airLock 1.
 *
 * The longest-reaching of each is kept. Entry:
 *   [turret path, weapon, fire mode, magazine, speed m/s, max range m, is missile]
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * [gun entry or [], missile entry or []] <ARRAY>
 *
 * Example:
 * [_vehicle] call jmfsb_adsite_fnc_profile
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

private _cls = typeOf _veh;
private _cached = GVAR(classes) get _cls;
if (!isNil "_cached") exitWith {_cached};

// an air search radar on the vehicle
private _radar = ("true" configClasses (configOf _veh >> "Components" >> "SensorsManagerComponent" >> "Components"))
    findIf {getText (_x >> "componentType") isEqualTo "ActiveRadarSensorComponent"} > -1;

private _gun = [];
private _missile = [];
private _base = configFile >> "CfgAmmo";
{
    private _path = _x;
    private _mags = _veh magazinesTurret _path;
    {
        private _weapon = _x;
        private _wcfg = configFile >> "CfgWeapons" >> _weapon;
        private _compatible = (compatibleMagazines _weapon) apply {toLower _x};
        private _mag = _mags param [_mags findIf {(toLower _x) in _compatible}, ""];
        if (_mag isEqualTo "") then { continue };

        private _ammo = getText (configFile >> "CfgMagazines" >> _mag >> "ammo");
        private _acfg = _base >> _ammo;

        // the weapon's reach and fastest rate, over its fire modes
        private _range = 0;
        private _reload = 1e9;
        private _modes = getArray (_wcfg >> "modes");
        {
            private _m = [_wcfg >> _x, _wcfg] select (_x isEqualTo "this");
            _range = _range max getNumber (_m >> "maxRange");
            private _r = getNumber (_m >> "reloadTime");
            if (_r > 0) then { _reload = _reload min _r };
        } forEach _modes;
        private _mode = _modes param [0, "this"];
        if (_mode isEqualTo "this") then { _mode = _weapon };

        if (_ammo isKindOf ["MissileCore", _base]) then {
            if (getNumber (_acfg >> "airLock") < ADS_AA_LOCK) then { continue };
            _range = _range max getNumber (_acfg >> "missileLockMaxDistance");
            private _speed = (getNumber (_acfg >> "maxSpeed") max ADS_DEFAULT_SPEED) * ADS_MISSILE_AVG;
            if (_range > (_missile param [5, -1])) then {
                _missile = [_path, _weapon, _mode, _mag, _speed, _range, true];
            };
        } else {
            if (getNumber (_acfg >> "airLock") < 1 || {getNumber (_acfg >> "hit") < ADS_GUN_HIT}) then { continue };
            if (_reload > ADS_CIWS_RELOAD && {!_radar}) then { continue };
            private _speed = getNumber (configFile >> "CfgMagazines" >> _mag >> "initSpeed");
            if (_speed <= 0) then { _speed = ADS_DEFAULT_SPEED };
            if (_range > (_gun param [5, -1])) then {
                _gun = [_path, _weapon, _mode, _mag, _speed, _range, false];
            };
        };
    } forEach (_veh weaponsTurret _path);
} forEach ((allTurrets [_veh, false]) + [[-1]]);

private _profile = [_gun, _missile];
GVAR(classes) set [_cls, _profile];
_profile
