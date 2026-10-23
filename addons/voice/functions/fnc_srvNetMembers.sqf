#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: an RTO (or admin) sets who is on one of the RTO nets (the
 * jmfsb_voice_srvNetMembers event from FUNC(netMembers)) - both lists are
 * replaced. The right is FUNC(canFlash)'s, checked here; a net nobody knows
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
 * [player, "RECON 2", ["GHOST 1"], []] call jmfsb_voice_fnc_srvNetMembers
 *
 * Public: No
 */

params [["_caller", objNull, [objNull]], ["_id", "", [""]], ["_squads", [], [[]]], ["_uids", [], [[]]]];

if (!isServer || isNull _caller) exitWith {};

if !([_caller] call FUNC(canFlash)) exitWith {
    [QGVAR(netFailed), [REASON_NOT_RTO, _id], _caller] call CBA_fnc_targetEvent;
};
if !(_id in GVAR(customNets)) exitWith {
    [QGVAR(netFailed), [REASON_UNKNOWN, _id], _caller] call CBA_fnc_targetEvent;
};

private _net = GVAR(customNets) get _id;
_squads = (_squads select {_x isEqualType ""}) apply {toUpper trim _x};
_uids = _uids select {_x isEqualType "" && _x isNotEqualTo ""};
_net set [CUSTOM_COL_SQUADS - 1, _squads arrayIntersect _squads];
_net set [CUSTOM_COL_UIDS - 1, _uids arrayIntersect _uids];
[] call FUNC(srvNetPublish);
