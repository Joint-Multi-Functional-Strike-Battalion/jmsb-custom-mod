#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a projectile has something the RF burst can disrupt, and what
 * kind: "ir" for an IR or laser seeker (the dazzler's old customers),
 * "atgm" for any other guidance - radar, wire, datalink, an engine-guided
 * missile with manoeuvring - and "" for a dumb round, which is immune by
 * omission. Read from CfgAmmo, cached per class.
 *
 * Arguments:
 * 0: Projectile <OBJECT>
 *
 * Return Value:
 * "ir" | "atgm" | "" <STRING>
 *
 * Example:
 * [_missile] call jmfsb_aps_fnc_isGuided
 *
 * Public: Yes
 */

params [["_p", objNull, [objNull]]];
if (isNull _p) exitWith { "" };

private _type = typeOf _p;
if (isNil QGVAR(guidedCache)) then { GVAR(guidedCache) = createHashMap };
private _known = GVAR(guidedCache) get _type;
if (!isNil "_known") exitWith { _known };

private _cfg = configFile >> "CfgAmmo" >> _type;
private _sensors = _cfg >> "Components" >> "SensorsManagerComponent" >> "Components";
private _sensor = {
    params ["_name"];
    getNumber (_sensors >> _name >> "AirTarget" >> "maxRange") > 0
    || {getNumber (_sensors >> _name >> "GroundTarget" >> "maxRange") > 0}
};

private _kind = "";
if (getNumber (_cfg >> "irLock") > 0 || {getNumber (_cfg >> "laserLock") > 0}
        || {["IRSensorComponent"] call _sensor} || {["NVSensorComponent"] call _sensor}
        || {["LaserSensorComponent"] call _sensor}) then {
    _kind = "ir";
} else {
    if (getNumber (_cfg >> "airLock") > 0 || {getNumber (_cfg >> "manualControl") > 0}
            || {getNumber (_cfg >> "weaponLockSystem") > 0}
            || {["ActiveRadarSensorComponent"] call _sensor} || {["VisualSensorComponent"] call _sensor}
            || {["DataLinkSensorComponent"] call _sensor}
            || {_p isKindOf "MissileBase" && {getNumber (_cfg >> "maneuvrability") > 0}}) then {
        _kind = "atgm";
    };
};
GVAR(guidedCache) set [_type, _kind];
_kind
