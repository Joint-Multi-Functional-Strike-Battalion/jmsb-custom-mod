#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the pack finished - AI still on the gun is put off it and the gun
 * goes. A player still on it stops the pack. A gun that was destroyed, or left more than PACK_RANGE metres
 * away, is simply forgotten so the carrier can deploy again.
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 * 1: The driver <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, player] remoteExecCall ["jmfsb_artydeploy_fnc_undeploy", 2]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (!isServer) exitWith {};
// Sent by remoteExec: the driver named must be the sender himself (review S6).
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("undeploy: refused - machine %1 named %2",remoteExecutedOwner,_unit);
};
if !([_veh, _unit, ACT_PACK] call FUNC(canAct)) exitWith {};

private _gun = _veh getVariable [QGVAR(gun), objNull];
private _inRange = !isNull _gun && {alive _gun} && {(_gun distance _veh) <= PACK_RANGE};

// moveOut only works where the unit is local, so a player on the gun would
// still be in it when it is deleted. He gets off himself first.
if (_inRange && {((crew _gun) findIf {isPlayer _x}) > -1}) exitWith {
    ["ARTILLERY", "Pack refused - a player is still on the gun.", NOTE_WARN, _unit] call EFUNC(notify,broadcast);
};

if (_inRange) then {
    {
        if (local _x) then {
            moveOut _x;
        } else {
            [_x] remoteExecCall ["moveOut", _x];
        };
    } forEach (crew _gun);
    deleteVehicle _gun;
};
_veh setVariable [QGVAR(gun), objNull, true];
_veh setVariable [QGVAR(spotAt), nil, true];
["ARTILLERY", "Gun packed - ready to move.", NOTE_OK, _unit] call EFUNC(notify,broadcast);
