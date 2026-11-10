#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the deploy finished - the baseplate goes and the carrier's gun (the
 * launcher or the mortar, FUNC(weaponClass)) stands where it was, facing the
 * way the vehicle faced when the spot was marked. The gun is remembered on the
 * vehicle so the driver can pack it.
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 * 1: The driver <OBJECT>
 *
 * Return Value:
 * The gun, objNull if it could not be set up <OBJECT>
 *
 * Example:
 * [_veh, player] remoteExecCall ["jmfsb_artydeploy_fnc_deploy", 2]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (!isServer) exitWith {objNull};
// Sent by remoteExec: the driver named must be the sender himself (review S6).
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("deploy: refused - machine %1 named %2",remoteExecutedOwner,_unit);
    objNull
};
if !([_veh, _unit, ACT_DEPLOY] call FUNC(canAct)) exitWith {objNull};

private _cls = [_veh] call FUNC(weaponClass);
if (_cls isEqualTo "") exitWith {
    WARNING_1("carrier %1 names no gun this mod set has",typeOf _veh);
    objNull
};

private _plate = _veh getVariable [QGVAR(plate), objNull];
(_veh getVariable [QGVAR(spotAt), [_veh] call FUNC(spot)]) params ["_pos", "_dir"];
if (!isNull _plate) then {deleteVehicle _plate};
_veh setVariable [QGVAR(plate), objNull, true];

private _gun = createVehicle [_cls, _pos, [], 0, "CAN_COLLIDE"];
_gun setDir _dir;
_gun setPosATL _pos;
_gun setVectorUp surfaceNormal _pos;
_gun setVariable [QGVAR(carrier), _veh, true];

_veh setVariable [QGVAR(gun), _gun, true];
INFO_3("%1 deployed %2 at %3",typeOf _veh,_cls,mapGridPosition _pos);
["ARTILLERY", "Gun up behind the vehicle.", NOTE_OK, _unit] call EFUNC(notify,broadcast);
_gun
