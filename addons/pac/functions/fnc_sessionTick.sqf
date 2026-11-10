#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_sessionTick

Description:
    The heartbeat. Every PAC_HEARTBEAT seconds the server moves lastSeenAt
    forward on every open session whose player is still here. Its whole
    purpose is the server that dies without a disconnect: those rows keep an
    empty leftAt, and lastSeenAt is then within a minute of when the player
    was actually last on.

    A player found on the server with no open session - the connect event was
    missed somehow - gets one now, so attendance is never silently short.

    IT WRITES NOTHING (user, 2026-09-05: "write only on edit"). The rows are
    kept in memory and go out with the next save something else asks for -
    a connect, a disconnect, an admin's edit, a window stopped, the mission
    ending. A server that dies between two of those loses the minutes since
    the last one on its open sessions, and that is the trade. (The same
    loop in XEH_postInit then writes a save the debounce held back - an
    edit, not the tick.)

    Runs from a plain spawn loop in XEH_postInit; vanilla plumbing. Does
    nothing until the boot has loaded the store (GVAR(storeReady)).

Parameters:
    None

Returns:
    How many sessions were touched <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {0};
// Before the store is loaded the sessions are preInit's empty list; the boot
// replays who connected meanwhile.
if !(GVAR(storeReady)) exitWith {0};

private _now = [] call FUNC(stamp);
private _touched = 0;
// open rows by uid, one pass - not a walk of every session per player
// (this server's rows only - another server's are ticked by that server)
private _open = createHashMap;
private _server = GVAR(settings) getOrDefault ["serverId", PAC_SERVER_DEV];
{
    if ((_x # 4) isEqualTo "" && {(_x param [PAC_ROW_SERVER, _server]) isEqualTo _server}) then {
        private _rows = _open getOrDefault [_x # 0, []];
        _rows pushBack _x;
        _open set [_x # 0, _rows];
    };
} forEach GVAR(sessions);

// The store's one id function, FUNC(uid), as every other caller (review L1);
// headless clients are in allPlayers and are not players.
{
    private _uid = [_x] call FUNC(uid);

    if (_uid in _open) then {
        {_x set [3, _now]} forEach (_open get _uid);
    } else {
        [_uid, name _x] call FUNC(sessionStart);
    };
    _touched = _touched + 1;
} forEach ((allPlayers - entities "HeadlessClient_F") select {isPlayer _x});

_touched
