#include "script_component.hpp"
/*
 * Author: YonV
 * Server: every LZ_CLEAR_TICK s, each landing's wait (user, 2026-11-02,
 * FUNC(lzClear)):
 *
 *   looking    a mark seen (FUNC(lzMarks)) - I SEE <it> (FLASH; correct /
 *              wrong); none LZ_NAG_S s after the circle began (or the last
 *              WRONG) - CIRCLING - NO SMOKE SEEN - POP SMOKE (nosmoke), once
 *   held       LZ_HOLD_S s after a HOLD - READY TO LAND - CLEARED? again
 *
 * A wait whose thread is over, no longer the asset's, or whose aircraft is
 * gone is dropped; the handler goes with the last one.
 *
 * Arguments:
 * 0: Arguments, unused <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(lzClearTick), 2, []] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params ["", ["_handle", -1, [0]]];

private _clears = localNamespace getVariable [QGVAR(lzClears), createHashMap];
private _assets = localNamespace getVariable [QGVAR(threadAssets), createHashMap];
private _threads = missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap];
private _gone = [];

{
    private _threadId = _x;
    private _clear = _y;
    private _assetId = _clear get "asset";
    private _thread = _threads getOrDefault [_threadId, createHashMap];
    private _ours = (_assets getOrDefault [_threadId, ""]) isEqualTo _assetId;
    private _open = count _thread > 0 && !(_thread getOrDefault ["closed", false]) && !((_thread getOrDefault ["status", ""]) in STATES_OVER);
    if (!alive (_clear get "vehicle") || !_ours || !_open) then {
        _gone pushBack _threadId;
    } else {
        switch (_clear get "step") do {
            case LZ_LOOKING: {
                private _seen = [_clear get "point", _clear get "kinds", _clear get "ignored"] call FUNC(lzMarks);
                if (_seen isNotEqualTo []) exitWith {
                    _seen params ["_mark", "_words"];
                    (getPosATL _mark) params ["_mx", "_my"];
                    _clear set ["step", LZ_SEEN];
                    _clear set ["mark", _mark];
                    _clear set ["at", [_mx, _my, 0]];
                    [_threadId, format [LZ_SEEN_TEXT, _words], LZ_SEEN_ANSWERS, true] call FUNC(lzClearAsk);
                };
                if (_clear get "nagged") exitWith {};
                if (CBA_missionTime - (_clear get "since") < LZ_NAG_S) exitWith {};
                _clear set ["nagged", true];
                [_threadId, format [LZ_NAG_TEXT, _clear get "pop"], LZ_NAG_ANSWERS, false] call FUNC(lzClearAsk);
            };
            case LZ_HELD: {
                if (CBA_missionTime < (_clear get "until")) exitWith {};
                _clear set ["step", LZ_ASKED];
                [_threadId, LZ_CLEAR_TEXT, LZ_CLEAR_ANSWERS, true] call FUNC(lzClearAsk);
            };
            default {};
        };
    };
} forEach _clears;

{
    _clears deleteAt _x;
    INFO_1("thread %1: the landing's wait is over",_x);
} forEach _gone;

if (count _clears isEqualTo 0) then {
    [_handle] call CBA_fnc_removePerFrameHandler;
    localNamespace setVariable [QGVAR(lzClearPfh), -1];
};
