#include "script_component.hpp"
/*
 * Author: YonV
 * Server: every armed alarm off the roster (the Clear Scanner Alarms key, the
 * hack.alarm clear command). Reached by remoteExec from a client with a live
 * player, or called on the server (review S7). Each waiter finds its id gone
 * and stands down.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] remoteExecCall ["jmfsb_hacking_fnc_srvAlarmsClear", 2]
 *
 * Public: No
 */

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isRemoteExecuted && {isNull _unit || {!alive _unit}}) exitWith {
    WARNING_1("srvAlarmsClear: refused - machine %1 has no live player",_owner);
};

if ((localNamespace getVariable [QGVAR(alarms), []]) isEqualTo []) exitWith {};
localNamespace setVariable [QGVAR(alarms), []];
[] call FUNC(alarmPublish);
private _by = [name _unit, "the server"] select (isNull _unit);
INFO_1("scanner alarms cleared by %1",_by);
