#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: asks the server to remove one of the RTO nets
 * (FUNC(srvNetRemove)). Refused here only for what a client can tell.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * ["RECON 2"] call jmfsb_voice_fnc_netRemove
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

if (!GVAR(active) || !hasInterface || _id isEqualTo "") exitWith {false};
if !([player] call FUNC(canManageNets)) exitWith {
    [REASON_NOT_RTO, _id] call FUNC(netFailed);
    false
};

[player, _id] remoteExecCall [QFUNC(srvNetRemove), SERVER_OWNER];
true
