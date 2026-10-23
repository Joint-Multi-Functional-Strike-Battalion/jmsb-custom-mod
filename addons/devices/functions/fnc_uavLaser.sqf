#include "script_component.hpp"
/*
 * Author: JMSB
 * The laser designator a drone carries, if any: the first turret weapon (the
 * driver's counted as turret UAV_DRIVER_TURRET) whose magazine's ammo
 * simulates UAV_LASER_SIM, or that is one of the engine's designator families
 * (UAV_LASER_BASES). Read off the config, so it answers on any machine, and
 * cached per class (GVAR(uavLaserCache)) - the DRONES board asks on every draw.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 *
 * Return Value:
 * [weapon, turret path], [] when the airframe has no laser <ARRAY>
 *
 * Example:
 * ([_uav] call jmfsb_devices_fnc_uavLaser) params ["_weapon", "_turret"]
 *
 * Public: Yes
 */

params [["_uav", objNull, [objNull]]];

if (isNull _uav) exitWith {[]};

private _class = typeOf _uav;
private _cached = GVAR(uavLaserCache) get _class;
if (!isNil "_cached") exitWith {+_cached};

private _cfgWeapons = configFile >> "CfgWeapons";
private _fnc_isLaser = {
    params ["_weapon"];
    if ((UAV_LASER_BASES findIf {_weapon isKindOf [_x, _cfgWeapons]}) >= 0) exitWith {true};
    (getArray (_cfgWeapons >> _weapon >> "magazines")) findIf {
        private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") == UAV_LASER_SIM
    } >= 0
};

private _found = [];
{
    private _turret = _x;
    private _i = (_uav weaponsTurret _turret) findIf {[_x] call _fnc_isLaser};
    if (_i >= 0) exitWith {
        _found = [(_uav weaponsTurret _turret) select _i, _turret];
    };
} forEach ((allTurrets [_uav, false]) + [UAV_DRIVER_TURRET]);

GVAR(uavLaserCache) set [_class, _found];
+_found
