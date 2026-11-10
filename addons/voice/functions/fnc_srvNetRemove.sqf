#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an RTO (or admin) removes one of the RTO nets (by remoteExec from
 * FUNC(netRemove); the caller must be the sender,
 * jmfsb_common_fnc_senderIs). Any RTO may remove
 * any RTO net - it is the unit's comm plan, not one man's. The publication
 * drops it from every plan, the fills let it go and the roster leaves
 * everyone on its next tick. The VON channel stays made (VON cannot delete
 * one); the adapter keeps it by name and hands it back if the same name is
 * made again.
 *
 * Arguments:
 * 0: Caller <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "RECON 2"] remoteExecCall ["jmfsb_voice_fnc_srvNetRemove", 2]
 *
 * Public: No
 */

params [["_caller", objNull, [objNull]], ["_id", "", [""]]];

if (!isServer || {!([_caller] call EFUNC(common,senderIs))}) exitWith {};
if (isNull _caller) exitWith {};

if !([_caller] call FUNC(canFlash)) exitWith {
    [REASON_NOT_RTO, _id] remoteExecCall [QFUNC(netFailed), _caller];
};
if !(_id in GVAR(customNets)) exitWith {
    [REASON_UNKNOWN, _id] remoteExecCall [QFUNC(netFailed), _caller];
};

GVAR(customNets) deleteAt _id;
[] call FUNC(srvNetPublish);
INFO_2("RTO net %1 removed by %2",_id,name _caller);
