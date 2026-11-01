#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_rosterTotals

Description:
    Works out the numbers FUNC(publish) sends that need the whole session
    list: each player's attendance [minutes, joins] (GVAR(rosterTotals)) and
    who is due a promotion (GVAR(promotable)). Server only.

    ON THE HEARTBEAT, NOT ON EVERY PUBLISH. The sessions are never trimmed and
    FUNC(promotionPoints) walks them once per player, so doing this per
    publish - every join, edit, seed and ticket - grew with the unit's whole
    history. The boot runs it once before the first publish; the heartbeat
    (XEH_postInit, scheduled) after that. Totals reach clients with the next
    publish; the heartbeat publishes by itself only when the due list changed.

    Open sessions count to lastSeenAt, the way FUNC(attendanceReport) counts.

Parameters:
    None

Returns:
    Whether the promotion-due list changed (who, and to what rank) <BOOL>

Example:
    [] call jmfsb_pac_fnc_rosterTotals

Public: No

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {false};

private _totals = createHashMap;
{
    _x params ["_uid", "", "_joined", "_seen", "_left"];
    private _end = [_left, _seen] select (_left isEqualTo "");
    private _mins = (([_end] call FUNC(stampMinutes)) # 0) - (([_joined] call FUNC(stampMinutes)) # 0);
    private _t = _totals getOrDefault [_uid, [0, 0]];
    _t set [0, (_t # 0) + (_mins max 0)];
    _t set [1, (_t # 1) + 1];
    _totals set [_uid, _t];
} forEach GVAR(sessions);
GVAR(rosterTotals) = _totals;

// One row per man due: [name, rankId, nextRankId, points, needed, uid].
private _due = [];
{
    ([_x] call FUNC(promotionPoints)) params ["_pts", "", "_next", "_need"];
    if (_next isNotEqualTo "" && _need <= 0) then {
        _due pushBack [_y getOrDefault ["name", ""], _y getOrDefault ["rankId", ""], _next, _pts, _need, _x];
    };
} forEach GVAR(players);

// Points move every minute a man is on; only who is due, and for what, is news.
private _fnc_key = {
    params ["_rows"];
    private _k = _rows apply {[_x # 5, _x # 2]};
    _k sort true;
    _k
};
private _changed = ([_due] call _fnc_key) isNotEqualTo ([GVAR(promotable)] call _fnc_key);
GVAR(promotable) = _due;

_changed
