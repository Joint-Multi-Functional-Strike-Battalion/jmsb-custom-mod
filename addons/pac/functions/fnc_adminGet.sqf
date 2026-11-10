#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminGet

Description:
    Sends one player's full record to the admin who asked for it.

    THE ROSTER IS PUBLIC; THE RECORD IS NOT. Everybody holds the flat roster
    row - name, rank, role, skills - because the tacpad shows it. Notes and
    loadouts stay on the server, and the admin page is the only thing that
    needs them, for one player at a time. So it asks for that one, and the
    answer goes to that one machine, after the same admin check adminSet makes.

Parameters:
    0: Caller <OBJECT>
    1: Target UID <STRING>

Returns:
    Whether a record was sent <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_uid", "", [""]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {false};

private _rec = GVAR(players) getOrDefault [_uid, createHashMap];
if (count _rec isEqualTo 0) exitWith {false};

// The copy carries the attendance count and the promotion points - both are
// counted off the sessions, which stay here; neither is stored on the record.
private _copy = +_rec;
_copy set ["attendanceSummary", [_uid] call FUNC(attendanceOf)];
_copy set ["_promotion", [_uid] call FUNC(promotionPoints)];
[_uid, _copy] remoteExec [QFUNC(adminRecv), owner _caller];

true
