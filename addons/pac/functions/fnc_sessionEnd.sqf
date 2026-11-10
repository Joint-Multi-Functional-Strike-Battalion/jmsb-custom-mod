#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_sessionEnd

Description:
    Closes a player's open attendance session - writes leftAt and a last
    lastSeenAt - on disconnect. See FUNC(sessionStart) for the row.

Parameters:
    0: UID <STRING>

Returns:
    Whether an open session was found <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_uid", "", [""]]];

if (!isServer || _uid isEqualTo "") exitWith {false};

private _now = [] call FUNC(stamp);
private _found = false;
private _server = GVAR(settings) getOrDefault ["serverId", PAC_SERVER_DEV];

// Only this server's open row: the same man on another server is still on there.
{
    if ((_x # 0) isEqualTo _uid && {(_x # 4) isEqualTo ""} && {(_x param [PAC_ROW_SERVER, _server]) isEqualTo _server}) then {
        _x set [3, _now];
        _x set [4, _now];
        _found = true;
    };
} forEach GVAR(sessions);

// LOGOFF IS A PLAY-TIME COMMIT: the whole session is now known, so it is
// forced past the debounce and sent to the database at once - a server that
// dies a minute later has already put this player's time down (user,
// 2026-09-05: "save to db on player logon and logoff").
if (_found) then {[true, true] call FUNC(storeSave)};

_found
