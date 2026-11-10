#include "script_component.hpp"
/*
 * Author: YonV
 * Server: GO over the drop zone (2026-11-02) - the leader's answer to MEN
 * STILL ABOARD - HOLDING OVER THE DZ or to ABORTED (FUNC(srvReply)), or no
 * answer to the first for 5 min (D9, FUNC(srvTimeout)). Holding only: every
 * man still aboard goes out, one every JUMP_INTERVAL (FUNC(srvTick)), and the
 * thread hears GREEN LIGHT - GO "2 OUT OVER THE DZ" (FLASH); the aircraft
 * leaves once the cabin is empty. At the red light (2026-11-09): the green
 * light is given now (FUNC(srvTick)) rather than at the green-light point.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: What goes in front of the detail, "" none ("NO RESPONSE") <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st, "NO RESPONSE"] call jmfsb_jumpmaster_fnc_srvGo
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_why", "", [""]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvGo: refused - remote call from machine %1",remoteExecutedOwner);
};
// GO AT THE RED LIGHT (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09: "Jump.
// Given at the red light to release the stick"): the green light now, not at
// the green-light point (FUNC(srvTick)).
if ((_st get "phase") isEqualTo PHASE_RED) exitWith {_st set ["goNow", true]};
if ((_st get "phase") isNotEqualTo PHASE_HOLD) exitWith {};

private _aboard = [_st] call FUNC(aboard);
if (_aboard isEqualTo []) exitWith {};

_st set ["go", true];
_st set ["lastOut", 0];
[_st, "GREEN LIGHT. GO.", true] call FUNC(srvLight);
[_st, CARD_GREEN_LIGHT, ([_why, format [SAID_GO, count _aboard]] select {_x isNotEqualTo ""}) joinString WILCO_SEP, true] call FUNC(threadCard);
