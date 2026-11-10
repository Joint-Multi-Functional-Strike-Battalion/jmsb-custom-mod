#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a client arms a scanner alarm (FUNC(alarmArm), FUNC(scannerAlarm),
 * by remoteExec). The setter's name is the sender's own player, never one
 * from the request (review S7); a machine with no live player is refused.
 * The delay is clamped and the count capped in FUNC(alarmAdd).
 *
 * Arguments:
 * 0: Seconds from now <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [300] remoteExecCall ["jmfsb_hacking_fnc_srvAlarmAdd", 2]
 *
 * Public: No
 */

params [["_delay", 0, [0]]];

if (!isServer) exitWith {};

// The sender is known only here, before anything is delayed (review S7).
([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isRemoteExecuted && {isNull _unit || {!alive _unit}}) exitWith {
    WARNING_1("srvAlarmAdd: refused - machine %1 has no live player",_owner);
};

[_delay, [name _unit, "Command"] select (isNull _unit)] call FUNC(alarmAdd);
