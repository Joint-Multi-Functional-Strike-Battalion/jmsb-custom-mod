#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the leader's BOARD in a run's thread (user, 2026-11-02: "have team
 * leader send a board message then move the team to cargo"), the answer to
 * ON STATION - SEND BOARD WHEN READY. Only a run waiting for it (PHASE_BOARD,
 * a module's aircraft made at the request and orbiting the module - virtual
 * until tasked, user 2026-11-02).
 *
 * The stick is counted again as the request counted it (FUNC(srvThread)): the
 * living men of the leader's group within JUMP_PICKUP_RADIUS of the pickup,
 * each with a parachute and, for HALO / HAHO, a mask (FUNC(ready)). Not
 * ready: it asks again with the reason (FUNC(srvAskBoard)) and waits for the
 * next BOARD. Ready: the run starts (FUNC(srvLaunch)) - every man moved
 * aboard where he is local, STICK ABOARD - n MEN - RED LIGHT IN m:ss, the
 * aircraft off its orbit to the run-in at the jump altitude. Its aircraft
 * gone meanwhile: CLOSED AIRCRAFT LOST.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: Who sent it <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st, _leader] call jmfsb_jumpmaster_fnc_srvBoard
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_who", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvBoard: refused - remote call from machine %1",remoteExecutedOwner);
};
if ((_st get "phase") isNotEqualTo PHASE_BOARD) exitWith {};

private _veh = (_st getOrDefault ["logic", objNull]) getVariable [QGVAR(veh), objNull];
if (!alive _veh) exitWith {
    [_st] call FUNC(srvRelease);
    [_st, "CLOSED", SAID_LOST] call FUNC(threadState);
};

// THE STICK, counted again: the leader's men at the pickup, ready.
private _pickup = _st getOrDefault ["pickup", []];
private _men = (units (_st get "group")) select {alive _x && {(_x distance2D _pickup) <= JUMP_PICKUP_RADIUS}};
if (_men isEqualTo []) exitWith {[_st, WHY_NOBODY] call FUNC(srvAskBoard)};
([_men, _st get "type"] call FUNC(ready)) params ["_noChute", "_noMask"];
private _whys = [];
if (_noChute > 0) then {_whys pushBack format [WHY_NO_CHUTE, _noChute, [WORD_MAN, WORD_MEN] select (_noChute > 1)]};
if (_noMask > 0) then {_whys pushBack format [WHY_NO_MASK, _noMask, [WORD_MAN, WORD_MEN] select (_noMask > 1)]};
if (_whys isNotEqualTo []) exitWith {[_st, _whys joinString WILCO_SEP] call FUNC(srvAskBoard)};

INFO_3("srvBoard: %1 boarding %2 men for %3",_st get "callsign",count _men,name _who);
_st set ["jumpers", _men];
_st set ["stick", [_men, _st get "passes"] call FUNC(stick)];
_st set ["veh", _veh];
[_st] call FUNC(srvLaunch);
