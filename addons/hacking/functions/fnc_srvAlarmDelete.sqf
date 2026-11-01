#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: one alarm off the roster, by id (review S7). Reached by remoteExec
 * from a client with a live player, or called on the server. The roster is
 * the section's, so anyone on it may delete; the waiter finds its id gone
 * and stands down.
 *
 * Arguments:
 * 0: Alarm id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [3] remoteExecCall ["jmfsb_hacking_fnc_srvAlarmDelete", 2]
 *
 * Public: No
 */

params [["_id", -1, [0]]];

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isRemoteExecuted && {isNull _unit || {!alive _unit}}) exitWith {
    WARNING_1("srvAlarmDelete: refused - machine %1 has no live player",_owner);
};

private _list = localNamespace getVariable [QGVAR(alarms), []];
private _i = _list findIf {(_x select 0) == _id};
if (_i == -1) exitWith {};
_list deleteAt _i;
[] call FUNC(alarmPublish);
