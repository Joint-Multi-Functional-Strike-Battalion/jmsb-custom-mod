#include "script_component.hpp"
/*
 * Author: JMSB
 * Runs on a timer. Closes threads nobody has touched, drops the bodies of
 * ephemeral threads that have fallen out of every mailbox, and forgets old
 * draft nonces.
 *
 * A store that only ever grows is the failure mode of every mission-long
 * message system, and it does not show up until hour four.
 *
 * Arguments (CBA per-frame handler):
 * 0: Arguments <ARRAY> - unused
 * 1: Handle <NUMBER> - unused
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["", ""];

if (!isServer) exitWith {};

private _now = CBA_missionTime;
private _idle = GVAR(idleClose) * 60;

if (_idle > 0) then {
    {
        if (!(_y get "closed") && {_now - (_y get "lastActivity") > _idle}) then {
            _y set ["closed", true];
            _y set ["status", "CLOSED"];
        };
    } forEach GVAR(threads);
};

// A thread that no mailbox still lists is unreachable: nothing can index it and
// nobody can open it. Its bodies are the largest thing in the store, so they go
// first and the thread record follows.
private _live = [];
{
    {
        _live pushBackUnique _x;
    } forEach (_y getOrDefault ["threads", []]);
} forEach GVAR(boxes);

// Keys are collected before anything is deleted - removing entries from a
// HashMap while iterating it is not safe.
private _dead = (keys GVAR(threads)) select {!(_x in _live)};
{
    private _thread = GVAR(threads) get _x;
    {
        GVAR(messages) deleteAt _x;
    } forEach (_thread get "messages");

    private _marker = _thread getOrDefault ["marker", ""];
    if (_marker != "") then {
        [_marker, []] remoteExecCall [QFUNC(cltMarker), TARGET_ALL];
    };

    GVAR(threads) deleteAt _x;
} forEach _dead;

// Nonces only have to outlive the round trip that could double-submit them.
private _stale = (keys GVAR(nonces)) select {_now - (GVAR(nonces) get _x) > SWEEP_INTERVAL};
{
    GVAR(nonces) deleteAt _x;
} forEach _stale;
