#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminLog

Description:
    Sends the action log to the admin who asked for it, newest first,
    through FUNC(logRecv). The log is server-only like the notes: it names
    who did what to whom, and the roster does not carry it. Admin-checked
    the way every other door is.

Parameters:
    0: Caller <OBJECT>
    1: Filter <STRING> - a substring, case-insensitive, over the whole row;
       "" for everything
    2: At most this many rows <NUMBER> (optional, default 400)

Returns:
    How many rows were sent <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_filter", "", [""]], ["_limit", 400, [0]]];

if (!isServer) exitWith {0};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {0};

_filter = toLower trim _filter;
private _rows = [];
private _n = count GVAR(log);
for "_i" from (_n - 1) to 0 step -1 do {
    if (count _rows >= _limit) exitWith {};
    private _row = GVAR(log) # _i;
    if (_filter isNotEqualTo "" && {!(_filter in toLower (_row joinString " "))}) then {continue};
    _rows pushBack _row;
};

[_rows, _n] remoteExec [QFUNC(logRecv), owner _caller];

count _rows
