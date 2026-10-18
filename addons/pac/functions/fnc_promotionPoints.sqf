#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_promotionPoints

Description:
    One player's promotion points, from the formula the unit keeps as an
    EDITABLE STRUCTURE SECTION - "promotion" (user, 2026-09-05: "a promotion
    point system based on attendance, time in service, time in grade,
    training, awards - make the formula an editable doc"). Server only: it
    counts off the sessions, which clients never hold.

    THE FORMULA IS DATA, NOT CODE. Every item in the promotion section is
    {name, value}; the id says what the value means:

        hour          points per hour on an operation (sessions filed under
                      an "operation" window - nothing else counts; user,
                      2026-10-11: "only operation missions count toward
                      promotion")
        op            points per op attended (closed operation windows, see
                      FUNC(attendanceOf))
        trainingSession  points per training window attended
        trainingHour     points per hour in a training window
                      (the user's "option for training time"; 0 or absent
                      = off)
        serviceMonth  points per 30 days since enlistedAt
        gradeMonth    points per 30 days since promotedAt (enlistedAt when
                      never promoted)
        training      points per training entry on the record
        award         points per award on the record
        rank_<id>     points required to hold rank <id> - the ladder

    Change a weight in EDIT STRUCTURE > PROMOTION (or on the database site,
    document <unitId>.promotion) and every player's points change with it.
    A weight or a rank that is not listed counts as 0.

    points = round(hours*hour + ops*op + serviceMonths*serviceMonth
                   + gradeMonths*gradeMonth + training*training
                   + awards*award + trainingSessions*trainingSession
                   + trainingHours*trainingHour)

    A "special" window counts for nothing, and neither does time on the
    server with no window open.

    The NEXT rank is the lowest rank_<id> threshold strictly above the
    player's current rank's threshold (0 when the current rank has none);
    "needed" is how far to it.

Parameters:
    0: UID <STRING>

Returns:
    [points, breakdown, nextRankId, needed, currentThreshold] <ARRAY>
      breakdown: [[what, quantity, weight, points], ...] in the order above

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_uid", "", [""]]];

private _none = [0, [], "", 0, 0];
if (!isServer || _uid isEqualTo "") exitWith {_none};
private _rec = GVAR(players) getOrDefault [_uid, createHashMap];
if !(_rec isEqualType createHashMap && {count _rec > 0}) exitWith {_none};

private _formula = GVAR(structure) getOrDefault ["promotion", createHashMap];
if !(_formula isEqualType createHashMap) then {_formula = createHashMap};

// a weight: the item's value, whatever type the config, the editor or the
// database handed it in as
private _fnc_weight = {
    params ["_key"];
    private _item = _formula getOrDefault [_key, createHashMap];
    if !(_item isEqualType createHashMap) exitWith {0};
    private _v = _item getOrDefault ["value", 0];
    if (_v isEqualType "") then {_v = parseNumber _v};
    if !(_v isEqualType 0) then {_v = 0};
    _v
};

private _today = [] call FUNC(stamp);
private _todayMin = ([_today] call FUNC(stampMinutes)) # 0;
private _fnc_days = {
    params ["_from"];
    if !(_from isEqualType "") exitWith {0};
    if (count _from < 10) exitWith {0};
    private _a = ([(_from select [0, 10]) + " 00:00"] call FUNC(stampMinutes)) # 0;
    (floor ((_todayMin - _a) / 1440)) max 0
};

// ---- the quantities ----------------------------------------------------------
// hours: sessions filed under a window, split by the window's kind, open rows
// to lastSeenAt - the way FUNC(publish) totals. Time under no window, or under
// a special one, is not counted.
private _kindOf = createHashMap;
{_kindOf set [_x # 0, _x param [5, "operation"]]} forEach GVAR(windows);
private _minutes = 0;
private _trainingMinutes = 0;
{
    _x params ["_sUid", "", "_joined", "_seen", "_left"];
    if (_sUid isNotEqualTo _uid) then {continue};
    private _kind = _kindOf getOrDefault [_x param [5, ""], ""];
    if !(_kind in ["operation", "training"]) then {continue};
    private _end = [_left, _seen] select (_left isEqualTo "");
    private _m = ((([_end] call FUNC(stampMinutes)) # 0) - (([_joined] call FUNC(stampMinutes)) # 0)) max 0;
    if (_kind isEqualTo "operation") then {_minutes = _minutes + _m} else {_trainingMinutes = _trainingMinutes + _m};
} forEach GVAR(sessions);
private _hours = _minutes / 60;
private _trainingHours = _trainingMinutes / 60;

private _ops = ([_uid] call FUNC(attendanceOf)) # 1;
private _trainingSessions = ([_uid, "training"] call FUNC(attendanceOf)) # 1;

private _enlisted = _rec getOrDefault ["enlistedAt", ""];
private _promoted = _rec getOrDefault ["promotedAt", ""];
if !(_promoted isEqualType "" && {count _promoted >= 10}) then {_promoted = _enlisted};
private _serviceMonths = ([_enlisted] call _fnc_days) / 30;
private _gradeMonths = ([_promoted] call _fnc_days) / 30;

private _training = count (_rec getOrDefault ["training", []]);
private _awards = count (_rec getOrDefault ["awards", []]);

// ---- the sum, itemised -------------------------------------------------------
private _breakdown = [];
private _points = 0;
{
    _x params ["_what", "_qty", "_key"];
    private _w = [_key] call _fnc_weight;
    private _p = _qty * _w;
    _breakdown pushBack [_what, _qty, _w, _p];
    _points = _points + _p;
} forEach [
    ["hours", _hours, "hour"],
    ["ops", _ops, "op"],
    ["service months", _serviceMonths, "serviceMonth"],
    ["grade months", _gradeMonths, "gradeMonth"],
    ["training", _training, "training"],
    ["awards", _awards, "award"],
    ["training sessions", _trainingSessions, "trainingSession"],
    ["training hours", _trainingHours, "trainingHour"]
];
_points = round _points;

// ---- the ladder: where they stand, what is next ------------------------------
private _current = ["rank_" + (_rec getOrDefault ["rankId", ""])] call _fnc_weight;
private _next = "";
private _nextAt = -1;
{
    if ((_x select [0, 5]) isNotEqualTo "rank_") then {continue};
    private _t = [_x] call _fnc_weight;
    if (_t > _current && {_nextAt < 0 || _t < _nextAt}) then {_nextAt = _t; _next = _x select [5]};
} forEach (keys _formula);
private _needed = if (_nextAt < 0) then {0} else {(_nextAt - _points) max 0};

[_points, _breakdown, _next, _needed, _current]
