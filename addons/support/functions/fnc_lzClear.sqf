#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a support aircraft circling its landing point asks to land (user,
 * 2026-11-02: "support trans needs to circle till smoke is verified, caller
 * pops smoke helo verifies color, either way transport needs final permission
 * to land"). The provider flies the circle and calls this once; the core does
 * the rest in the thread, as the asset (FUNC(lzClearTick), FUNC(lzClearReply)):
 *
 *   looking        smoke within LZ_MARK_RADIUS m - and the card's IR strobe,
 *                  chemlight or flare when its marking asks for one
 *                  (FUNC(popWord), FUNC(lzMarks))
 *   one seen       I SEE RED SMOKE (FLASH; correct / wrong). CORRECT -
 *                  verified, the landing point is the mark; WRONG - that one
 *                  is ignored, it looks again
 *   none seen      after LZ_NAG_S s: CIRCLING - NO SMOKE SEEN - POP SMOKE
 *                  (routine; nosmoke). NO SMOKE skips the verification: it
 *                  lands on the grid
 *   either way     READY TO LAND - CLEARED? (FLASH; clearedland / hold /
 *                  abort). CLEARED TO LAND - `[assetId, threadId, point] call
 *                  onCleared`, the provider lands; HOLD - asked again
 *                  LZ_HOLD_S s later; ABORT is the provider's stop
 *
 * D9 runs on every prompt (FUNC(prompt)): silent 3 min NO RESPONSE - HOLDING,
 * 5 min the provider's own end. The wait ends with the thread (closed, no
 * longer the asset's) or the aircraft. A second call for the thread starts it
 * again.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: Call sign <STRING>
 * 3: The aircraft <OBJECT>
 * 4: The landing point <ARRAY>
 * 5: The card's marking words, "" for none - SMOKE <STRING>
 * 6: Cleared to land, [assetId, threadId, point] <CODE>
 * 7: No answer for PROMPT_END s, [assetId, threadId] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_assetId, _threadId, "RAVEN", _heli, _lz, "SMOKE", _onCleared, _onEnd] call jmfsb_support_fnc_lzClear
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_callsign", "", [""]],
    ["_vehicle", objNull, [objNull]],
    ["_point", [], [[]]],
    ["_marking", "", [""]],
    ["_onCleared", {}, [{}]],
    ["_onEnd", {}, [{}]]
];

if (!isServer || _assetId isEqualTo "" || _threadId isEqualTo "" || count _point < 2) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_2("lzClear: refused - remote call from machine %1 (%2)",remoteExecutedOwner,_assetId);
};

private _pop = [_marking] call FUNC(popWord);
private _kinds = [MARK_SMOKE];
if (_pop isNotEqualTo MARK_SMOKE) then {_kinds pushBack _pop};
_point params ["_px", "_py"];

private _clears = localNamespace getVariable [QGVAR(lzClears), createHashMap];
localNamespace setVariable [QGVAR(lzClears), _clears];
_clears set [_threadId, createHashMapFromArray [
    ["asset", _assetId],
    ["callsign", _callsign],
    ["vehicle", _vehicle],
    ["point", [_px, _py, 0]],
    ["pop", _pop],
    ["kinds", _kinds],
    ["onCleared", _onCleared],
    ["onEnd", _onEnd],
    ["step", LZ_LOOKING],
    ["since", CBA_missionTime],
    ["nagged", false],
    ["mark", objNull],
    ["at", [_px, _py, 0]],
    ["ignored", []],
    ["until", 0]
]];
INFO_4("thread %1: %2 circling %3 - looking for %4",_threadId,_assetId,mapGridPosition [ARR_2(_px,_py)],_kinds joinString "/");

if ((localNamespace getVariable [QGVAR(lzClearPfh), -1]) < 0) then {
    localNamespace setVariable [QGVAR(lzClearPfh), [FUNC(lzClearTick), LZ_CLEAR_TICK, []] call CBA_fnc_addPerFrameHandler];
};
