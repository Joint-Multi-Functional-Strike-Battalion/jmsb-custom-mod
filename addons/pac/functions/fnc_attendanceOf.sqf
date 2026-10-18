#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_attendanceOf

Description:
    One player's attendance, counted off the sessions and the op windows,
    the way a personnel file states it: how many operations were held
    since they enlisted, how many they were on for, how many absences an
    admin excused (the record's "excused" window ids), and what is left -
    unexcused. Server only. An operation is a closed op window
    (GVAR(windows) with an end) of kind "operation" that started on or after
    the enlistment date; "on for" is any session filed under that window.
    Pass another kind to count those instead - FUNC(promotionPoints) asks for
    "training". A window from before kinds counts as an operation.

Parameters:
    0: UID <STRING>
    1: Kind <STRING> - "operation" (default) | "training" | "special"

Returns:
    [scheduled, attended, excused, unexcused, percentage] <ARRAY>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_uid", "", [""]], ["_kind", "operation", [""]]];

if (!isServer || _uid isEqualTo "") exitWith {[0, 0, 0, 0, 0]};

private _rec = GVAR(players) getOrDefault [_uid, createHashMap];
private _since = _rec getOrDefault ["enlistedAt", ""];
private _sinceMin = if (_since isEqualTo "") then {0} else {([_since + " 00:00"] call FUNC(stampMinutes)) # 0};

private _ids = [];
{
    _x params ["_id", "", "_start", "_end"];
    if (_end isEqualTo "" || {(_x param [5, "operation"]) isNotEqualTo _kind}) then {continue};
    if ((([_start] call FUNC(stampMinutes)) # 0) >= _sinceMin) then {_ids pushBack _id};
} forEach GVAR(windows);

private _attended = [];
{
    if ((_x # 0) isEqualTo _uid && {(_x param [5, ""]) in _ids}) then {_attended pushBackUnique (_x # 5)};
} forEach GVAR(sessions);

private _excused = (_rec getOrDefault ["excused", []]) select {_x in _ids && {!(_x in _attended)}};

private _scheduled = count _ids;
private _on = count _attended;
private _loa = count _excused;
private _awol = (_scheduled - _on - _loa) max 0;
private _pct = if (_scheduled > 0) then {(round (_on / _scheduled * 1000)) / 10} else {0};

[_scheduled, _on, _loa, _awol, _pct]
