#include "script_component.hpp"
/*
 * Author: YonV
 * Server: RTB with a LAND AT point while players are aboard (user,
 * 2026-11-09: "we need a way to set an rtb landing location if an aircraft
 * has players on board"), from FUNC(srvReply) when EFUNC(support,rtbLanding)
 * gives one. Until now an RTB with men aboard ended the run by putting them
 * out (FUNC(srvEnd)); now the aircraft flies to the point and lands there -
 * a helicopter on it, a plane at the nearest airfield
 * (EFUNC(support_air,landAt)) - and FUNC(srvTick)'s PHASE_LAND puts everyone
 * aboard out once it is down, closes the thread and sends it home.
 *
 * A plane with no airfield on the map cannot land: said in the thread, and
 * false - the caller flies the RTB as before (FUNC(srvAbort)).
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: The landing point <ARRAY>
 *
 * Return Value:
 * Landing <BOOL>
 *
 * Example:
 * [_st, _land] call jmfsb_jumpmaster_fnc_srvRtbLand
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_land", [], [[]]]];

if (!isServer) exitWith {false};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvRtbLand: refused - remote call from machine %1",remoteExecutedOwner);
    false
};

private _veh = _st get "veh";
private _fnc_say = {
    params ["_line"];
    [_st get "assetId", _st get "thread", _line, false, _st get "callsign"] call EFUNC(support,threadEvent);
};

if (!alive _veh || {_land isEqualTo []} || {(_st get "phase") isEqualTo PHASE_LEAVE}) exitWith {false};

if !([_veh, _land, RTB_LAND_MODE] call EFUNC(support_air,landAt)) exitWith {
    [SAID_RTB_NO_FIELD] call _fnc_say;
    false
};

_st set ["go", false];
_st set ["goNow", false];
_st set ["phase", PHASE_LAND];
_st set ["landAt", _land];
// A fresh RUN_MAX_S for the flight in: past it FUNC(srvEnd) would put the men
// out wherever the aircraft is.
_st set ["started", CBA_missionTime];
[_st, "RTB. We are landing - stay seated until we are down.", false] call FUNC(srvLight);
[format [SAID_RTB_LANDING, mapGridPosition _land, count ([_st] call FUNC(aboard))]] call _fnc_say;
INFO_2("srvRtbLand: %1 landing at %2 to let its players off",_st get "callsign",mapGridPosition _land);
true
