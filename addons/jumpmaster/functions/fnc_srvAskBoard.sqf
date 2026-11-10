#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a module's jump aircraft, up on station, asks for the stick (user,
 * 2026-11-02: "have team leader send a board message then move the team to
 * cargo"): ON STATION - SEND BOARD WHEN READY, BOARD and ABORT offered (the
 * support core's prompt; no D9 waits - the run's own BOARD_WAIT_MAX stands it
 * down). After the WILCO (FUNC(srvThread), BOARD_PROMPT_DELAY s on, so the
 * WILCO is filed first), and again with the reason when a BOARD found the
 * stick not ready (FUNC(srvBoard)): "2 MEN WITHOUT A PARACHUTE - SEND BOARD
 * WHEN READY". Only while the run still waits for BOARD.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: Why it asks again, "" the first time <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st, ""] call jmfsb_jumpmaster_fnc_srvAskBoard
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_why", "", [""]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvAskBoard: refused - remote call from machine %1",remoteExecutedOwner);
};
if ((GVAR(runs) findIf {(_x get "thread") isEqualTo (_st getOrDefault ["thread", ""])}) < 0) exitWith {};
if ((_st get "phase") isNotEqualTo PHASE_BOARD) exitWith {};

private _text = [format [PROMPT_BOARD_AGAIN, _why], PROMPT_BOARD_TEXT] select (_why isEqualTo "");
[_st get "assetId", _st get "thread", _text, PROMPT_BOARD_ANSWERS, _st get "callsign", {}, false] call EFUNC(support,prompt);
