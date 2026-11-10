#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_attendanceReport

Description:
    One op window's attendance as plain text: who was on, for how long, how
    many times they joined. Server only - the sessions live here.

    WHICH SESSIONS COUNT. A session is stamped at join with the window it fell
    in (FUNC(sessionStart)), so a window's sessions are the rows that carry its
    id - no interval arithmetic against the window's start and end, which
    would go wrong the moment a window was started late or a player joined
    before it. An empty id means all sessions there are.

    TIME IS COUNTED TO THE LAST SIGHTING. A session still open (leftAt "")
    ends at lastSeenAt, which the heartbeat keeps within a minute of the
    truth. Stamps are the UTC strings FUNC(stamp) writes, turned into minutes
    by FUNC(stampMinutes).

Parameters:
    0: Window id <STRING> ("" for all time)

Returns:
    The report <STRING>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_windowId", "", [""]]];

if (!isServer) exitWith {""};

private _title = ["all time", [_windowId] call FUNC(windowName)] select (_windowId isNotEqualTo "");

// "uid|server" -> [name, minutes, joins, uid, server]: one line per server a
// man was on, so ops time (the time that counts) never mixes with training or
// dev. A row from before server ids is ops.
private _tally = createHashMap;
{
    _x params ["_uid", "_name", "_joined", "_seen", "_left", "_win"];
    if (_windowId isNotEqualTo "" && _win isNotEqualTo _windowId) then {continue};

    private _server = _x param [PAC_ROW_SERVER, PAC_SERVER_OPS];
    private _end = [_left, _seen] select (_left isEqualTo "");
    private _mins = ((([_end] call FUNC(stampMinutes)) # 0) - (([_joined] call FUNC(stampMinutes)) # 0)) max 0;

    private _key = _uid + "|" + _server;
    private _row = _tally getOrDefault [_key, [_name, 0, 0, _uid, _server]];
    _row set [0, _name];
    _row set [1, (_row # 1) + _mins];
    _row set [2, (_row # 2) + 1];
    _tally set [_key, _row];
} forEach GVAR(sessions);

private _lines = [format ["TAC//PAC attendance - %1", _title], format ["unit %1   server %2   generated %3", GVAR(settings) getOrDefault ["unitId", ""], GVAR(settings) getOrDefault ["serverId", ""], [] call FUNC(stamp)], ""];

private _rows = [];
{
    _y params ["_name", "_mins", "_joins", "_uid", "_server"];
    _rows pushBack [toLower _name + "|" + str (PAC_SERVERS find _server), format ["%1  %2  %3  %4h %5m  %6 join%7", _name, _uid, _server, floor (_mins / 60), _mins mod 60, _joins, ["s", ""] select (_joins isEqualTo 1)]];
} forEach _tally;
_rows sort true;
_lines append (_rows apply {_x # 1});

_lines pushBack "";
_lines pushBack format ["%1 player%2", count _tally, ["s", ""] select (count _tally isEqualTo 1)];

_lines joinString endl
