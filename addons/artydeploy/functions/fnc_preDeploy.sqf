#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: PRE-DEPLOY - marks the gun's spot behind the carrier with an ACE
 * mortar baseplate, right away (user, 2026-10-25: "a predeploy step that
 * places an ace_csw_mortarBaseplate in the spawn spot, right away, then the
 * driver can hit deploy"). Without ACE's crew-served weapons there is no
 * baseplate class, so a small sign stands in.
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 * 1: The driver <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, player] remoteExecCall ["jmfsb_artydeploy_fnc_preDeploy", 2]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (!isServer) exitWith {};
// Sent by remoteExec: the driver named must be the sender himself (review S6).
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("preDeploy: refused - machine %1 named %2",remoteExecutedOwner,_unit);
};
if !([_veh, _unit, ACT_PRE] call FUNC(canAct)) exitWith {};

([_veh] call FUNC(spot)) params ["_pos", "_dir"];
private _cls = [SPOT_MARKER_FALLBACK, SPOT_MARKER_CLASS] select (isClass (configFile >> "CfgVehicles" >> SPOT_MARKER_CLASS));
private _plate = createVehicle [_cls, _pos, [], 0, "CAN_COLLIDE"];
_plate setDir _dir;
_plate setPosATL _pos;
_plate setVectorUp surfaceNormal _pos;

_veh setVariable [QGVAR(plate), _plate, true];
_veh setVariable [QGVAR(spotAt), [_pos, _dir], true];
["ARTILLERY", "Spot marked behind the vehicle. Deploy when ready.", NOTE_OK, _unit] call EFUNC(notify,broadcast);
