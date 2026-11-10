#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an RTO (or admin) sets who is on one of the RTO nets (by remoteExec
 * from FUNC(netMembers); the caller must be the sender,
 * jmfsb_common_fnc_senderIs) - both lists are replaced. The right is FUNC(canFlash)'s, checked here; a net nobody knows
 * is refused back to the caller. The publication carries the change; the
 * roster joins and leaves people on its next tick.
 *
 * Arguments:
 * 0: Caller <OBJECT>
 * 1: Net id <STRING>
 * 2: Squads on it - callsigns <ARRAY of STRINGs>
 * 3: Players on it - UIDs <ARRAY of STRINGs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "RECON 2", ["GHOST 1"], []] remoteExecCall ["jmfsb_voice_fnc_srvNetMembers", 2]
 *
 * Public: No
 */

params [["_caller", objNull, [objNull]], ["_id", "", [""]], ["_squads", [], [[]]], ["_uids", [], [[]]]];

if (!isServer || {!([_caller] call EFUNC(common,senderIs))}) exitWith {};
if (isNull _caller) exitWith {};

if !([_caller] call FUNC(canFlash)) exitWith {
    [REASON_NOT_RTO, _id] remoteExecCall [QFUNC(netFailed), _caller];
};
if !(_id in GVAR(customNets)) exitWith {
    [REASON_UNKNOWN, _id] remoteExecCall [QFUNC(netFailed), _caller];
};

private _net = GVAR(customNets) get _id;
_squads = (_squads select {_x isEqualType ""}) apply {toUpper trim _x};
_uids = _uids select {_x isEqualType "" && _x isNotEqualTo ""};
_net set [CUSTOM_COL_SQUADS - 1, _squads arrayIntersect _squads];
_net set [CUSTOM_COL_UIDS - 1, _uids arrayIntersect _uids];
[] call FUNC(srvNetPublish);
