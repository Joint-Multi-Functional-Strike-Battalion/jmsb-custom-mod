#include "script_component.hpp"
/*
 * Author: YonV
 * The vehicle pops smoke as the launchers engage - on the machine that owns
 * it (BIS_fnc_fire needs locality), once every ten seconds at most, from
 * whatever smoke launcher its turrets carry.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];
if (isNull _veh || {!local _veh}) exitWith {};
if !(_veh getVariable [QGVAR(canSmoke), true]) exitWith {};

private _weapons = [];
{ _weapons append (_veh weaponsTurret _x) } forEach allTurrets _veh;
private _launcher = _weapons select {
    _x == "SmokeLauncher" || {"SmokeLauncher" in ([configFile >> "CfgWeapons" >> _x, true] call BIS_fnc_returnParents)}
};
if (_launcher isEqualTo []) exitWith {};

_veh setVariable [QGVAR(canSmoke), false];
[_veh, _launcher select 0] call BIS_fnc_fire;
[{ (_this select 0) setVariable [QGVAR(canSmoke), true] }, [_veh], 10] call CBA_fnc_waitAndExecute;
