#include "script_component.hpp"
/*
 * Author: 3Mydlo3, JMSB
 * Server: takes a player's curator module away, by remoteExec from
 * FUNC(assignZeus). A client may unassign only himself; an admin by the
 * server's records may unassign anyone (review S7).
 *
 * Arguments:
 * 0: Unit to unassign <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] remoteExecCall ["jmfsb_curator_fnc_zeusUnassign", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {isNull _unit}) exitWith {};
if (!([_unit] call EFUNC(common,senderIs)) && {!([] call EFUNC(common,senderIsAdmin))}) exitWith {
    WARNING_1("zeusUnassign: refused a request from machine %1",remoteExecutedOwner);
};
if !(isPlayer _unit) exitWith {};

INFO_1("Unassigning Zeus from '%1'",_unit);

private _curatorModule = getAssignedCuratorLogic _unit;
if (isNull _curatorModule) exitWith {};
unassignCurator _curatorModule;
