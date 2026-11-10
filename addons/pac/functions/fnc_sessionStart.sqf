#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_sessionStart

Description:
    Opens an attendance session for a player who has just connected.

    A SESSION IS ONE ROW, APPEND-ONLY:

        [uid, name, joinedAt, lastSeenAt, leftAt, windowId, serverId]

    serverId is the server's: "ops", "training" or "dev" (PAC_SERVERS). Only
    ops time counts toward a player's time; the others are tracked apart.

    joinedAt and lastSeenAt start equal; FUNC(sessionTick) moves lastSeenAt
    forward every PAC_HEARTBEAT seconds while the player is on, and
    FUNC(sessionEnd) writes leftAt when they go. A server that dies mid-op
    leaves leftAt empty and lastSeenAt within a minute of the truth, which is
    what the heartbeat is for; the next mission start closes such rows at
    lastSeenAt (FUNC(boot), once the store is loaded).

    windowId is the op window open when they joined, or "" - attendance is
    answered per window, and a join is stamped with the one it fell in so the
    report does not have to work it out from timestamps later.

    A SECOND CONNECT CLOSES THE FIRST. A player who dropped without the server
    seeing a disconnect and came straight back would otherwise hold two open
    rows; the older is closed at its lastSeenAt.

Parameters:
    0: UID <STRING>
    1: Name <STRING>

Returns:
    Nothing

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_uid", "", [""]], ["_name", "", [""]]];

if (!isServer || _uid isEqualTo "") exitWith {};

private _now = [] call FUNC(stamp);
private _server = GVAR(settings) getOrDefault ["serverId", PAC_SERVER_DEV];

// Only this server's open row: the same man on another server is its own.
{
    if ((_x # 0) isEqualTo _uid && {(_x # 4) isEqualTo ""} && {(_x param [PAC_ROW_SERVER, _server]) isEqualTo _server}) then {
        _x set [4, _x # 3];
    };
} forEach GVAR(sessions);

GVAR(sessions) pushBack [_uid, _name, _now, _now, "", [] call FUNC(windowCurrent), _server];

// LOGON IS A PLAY-TIME COMMIT: forced past the debounce and sent to the
// database, so the row is down the moment they are on (user, 2026-09-05:
// "time tracking - save to db on player logon and logoff"). The database
// write itself still waits for READY - see FUNC(storeSave) - so the host's
// own logon during the boot cannot push the profile copy over the store.
[true, true] call FUNC(storeSave);
