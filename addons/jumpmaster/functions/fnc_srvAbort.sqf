#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the leader stood the run down - ABORT, RTB or CLOSE in its thread
 * (FUNC(srvReply), 2026-11-02; the app's ABORT before). No more passes: the
 * aircraft holds over the drop zone while anyone is aboard, with JUMP open to
 * every man, and leaves once the cabin is empty (FUNC(srvTick)). With men
 * aboard it says so - ABORTED - HOLDING OVER THE DZ - n ABOARD - JUMP WHEN
 * READY, GO offered - and waits for no answer: an abort is never answered by
 * putting men out. Holding already (the hold's own ask answered ABORT): GO is
 * off, the same words. Leaving: nothing to stand down. Before WHEELS UP (a
 * side's own aircraft) or before BOARD (a module's, orbiting the module -
 * 2026-11-02; also its BOARD_WAIT_MAX run out): the run is dropped, the
 * aircraft given back (FUNC(srvRelease)) and the thread CLOSED - STOOD DOWN
 * BEFORE WHEELS UP / NOT BOARDED - STOOD DOWN; a module's aircraft flies home
 * and is removed (FUNC(airHome)).
 *
 * Arguments:
 * 0: The run <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st] call jmfsb_jumpmaster_fnc_srvAbort
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvAbort: refused - remote call from machine %1",remoteExecutedOwner);
};
// Before WHEELS UP, or - a module's aircraft orbiting the module (2026-11-02)
// - before BOARD: stood down, nothing flown; a module's aircraft goes home and
// is removed (FUNC(srvRelease), FUNC(airHome)).
if (isNull (_st get "veh")) exitWith {
    [_st] call FUNC(srvRelease);
    [_st, "CLOSED", [SAID_STOOD_DOWN, SAID_NOT_BOARDED] select (_st getOrDefault ["module", false])] call FUNC(threadState);
};

private _phase = _st get "phase";
if (_phase isEqualTo PHASE_LEAVE) exitWith {};

_st set ["go", false];
if (_phase isNotEqualTo PHASE_HOLD) then {
    _st set ["passes", (_st get "pass") + 1];
    _st set ["phase", PHASE_HOLD];
    [_st get "veh", _st get "green", "NORMAL", "LOITER", HOLD_RADIUS] call EFUNC(support_air,moveTo);
    [_st, "Jump aborted by the jumpmaster. Holding over the drop zone: JUMP when ready, or stay aboard.", true] call FUNC(srvLight);
};

private _aboard = [_st] call FUNC(aboard);
if (_aboard isEqualTo []) exitWith {};
[_st get "assetId", _st get "thread", format [PROMPT_ABORTED_TEXT, count _aboard], PROMPT_ABORTED_ANSWERS, _st get "callsign", {}, false] call EFUNC(support,prompt);
