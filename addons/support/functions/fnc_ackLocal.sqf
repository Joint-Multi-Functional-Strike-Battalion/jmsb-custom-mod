#include "script_component.hpp"
/*
 * Author: JMSB
 * A delivery receipt arriving on this machine (FUNC(ack)): runs the hooks
 * registered with FUNC(onAck). Called on this machine, or sent by the server
 * by remoteExec - a remote call from anyone else is dropped (review R1).
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Acknowledged <BOOL>
 * 2: What to tell the requester <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["cas:0", true, "REAPER 1 acknowledged - wilco"] remoteExecCall ["jmfsb_support_fnc_ackLocal", _requester]
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_ok", true, [true]], ["_said", "", [""]]];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("ackLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};

{
    [_assetId, _ok, _said] call _x;
} forEach (localNamespace getVariable [QGVAR(ackHooks), []]);
