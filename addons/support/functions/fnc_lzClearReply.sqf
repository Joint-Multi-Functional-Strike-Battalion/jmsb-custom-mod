#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an answer in a thread whose asset is waiting to land (user,
 * 2026-11-02, FUNC(lzClear)) - from FUNC(srvFollowUp), before the provider
 * hears it, already gated (D6):
 *
 *   "correct"      to I SEE <it>: verified - READY TO LAND - CLEARED? (FLASH)
 *   "wrong"        to I SEE <it>: that mark is ignored, it looks again (the
 *                  nag LZ_NAG_S s on)
 *   "nosmoke"      looking or a mark seen: no verification, the grid -
 *                  READY TO LAND - CLEARED?
 *   "clearedland"  asked or held: the wait ends, the provider lands
 *                  (`[assetId, threadId, point] call onCleared`)
 *   "hold"         asked or held: asked again LZ_HOLD_S s later
 *   "continueapproach"  CONTINUE APPROACH (2026-11-09, FM 3-21.38 Table
 *                  3-2): asked or held - keep coming, not cleared yet; asked
 *                  again LZ_HOLD_S s later, as HOLD
 *   "goaround"     GO AROUND (2026-11-09, Table 3-3): asked or held - do not
 *                  land; it circles, looks for the mark again and asks again
 *   "stop"/"abort" the wait ends; the provider hears it (ABORT, RTB, CLOSE)
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: What it is - the follow-up's word <STRING>
 *
 * Return Value:
 * Taken here - the provider is not told <BOOL>
 *
 * Example:
 * ["T0042", "correct"] call jmfsb_support_fnc_lzClearReply
 *
 * Public: No
 */

params [["_threadId", "", [""]], ["_word", "", [""]]];

if (!isServer) exitWith {false};
if (isRemoteExecuted) exitWith {
    WARNING_1("lzClearReply: refused - remote call from machine %1",remoteExecutedOwner);
    false
};

private _clears = localNamespace getVariable [QGVAR(lzClears), createHashMap];
private _clear = _clears getOrDefault [_threadId, createHashMap];
if (count _clear isEqualTo 0) exitWith {false};
private _step = _clear get "step";
private _asked = _step in [LZ_ASKED, LZ_HELD];

private _fnc_ask = {
    _clear set ["step", LZ_ASKED];
    [_threadId, LZ_CLEAR_TEXT, LZ_CLEAR_ANSWERS, true] call FUNC(lzClearAsk);
};

private _taken = true;
switch (_word) do {
    case WORD_STOP;
    case WORD_ABORT: {
        _clears deleteAt _threadId;
        _taken = false;
    };
    case WORD_GO_AROUND: {
        _taken = _asked;
        if (_asked) then {
            _clear set ["mark", objNull];
            _clear set ["at", +(_clear get "point")];
            _clear set ["step", LZ_LOOKING];
            _clear set ["since", CBA_missionTime];
            _clear set ["nagged", false];
            INFO_2("thread %1: %2 going around",_threadId,_clear get "asset");
        };
    };
    case WORD_CORRECT: {
        if (_step isEqualTo LZ_SEEN) then {call _fnc_ask};
    };
    case WORD_WRONG: {
        if (_step isEqualTo LZ_SEEN) then {
            (_clear get "ignored") pushBack (_clear get "mark");
            _clear set ["mark", objNull];
            _clear set ["at", +(_clear get "point")];
            _clear set ["step", LZ_LOOKING];
            _clear set ["since", CBA_missionTime];
            _clear set ["nagged", false];
        };
    };
    case WORD_NOSMOKE: {
        if (_step in [LZ_LOOKING, LZ_SEEN]) then {
            _clear set ["at", +(_clear get "point")];
            call _fnc_ask;
        };
    };
    case WORD_CLEARED_LAND: {
        if (_asked) then {
            _clears deleteAt _threadId;
            INFO_3("thread %1: %2 cleared to land at %3",_threadId,_clear get "asset",mapGridPosition (_clear get "at"));
            [_clear get "asset", _threadId, _clear get "at"] call (_clear get "onCleared");
        };
    };
    case WORD_CONTINUE_APP;
    case WORD_HOLD: {
        _taken = _asked;
        if (_asked) then {
            _clear set ["step", LZ_HELD];
            _clear set ["until", CBA_missionTime + LZ_HOLD_S];
        };
    };
    default {_taken = false};
};

_taken
