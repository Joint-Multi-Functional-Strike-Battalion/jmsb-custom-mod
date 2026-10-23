#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: an RTO (or admin) removes one of the RTO nets (the
 * jmfsb_voice_srvNetRemove event from FUNC(netRemove)). Any RTO may remove
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
 * [player, "RECON 2"] call jmfsb_voice_fnc_srvNetRemove
 *
 * Public: No
 */

params [["_caller", objNull, [objNull]], ["_id", "", [""]]];

if (!isServer || isNull _caller) exitWith {};

if !([_caller] call FUNC(canFlash)) exitWith {
    [QGVAR(netFailed), [REASON_NOT_RTO, _id], _caller] call CBA_fnc_targetEvent;
};
if !(_id in GVAR(customNets)) exitWith {
    [QGVAR(netFailed), [REASON_UNKNOWN, _id], _caller] call CBA_fnc_targetEvent;
};

GVAR(customNets) deleteAt _id;
[] call FUNC(srvNetPublish);
INFO_2("RTO net %1 removed by %2",_id,name _caller);
