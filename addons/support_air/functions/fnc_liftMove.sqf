#include "script_component.hpp"
/*
 * Author: YonV
 * Server: MOVE in a transport's thread (docs/DESIGN_MESSAGE_TEMPLATES.md,
 * 2026-11-09: "go to a point, then LOITER / LAND / HOVER / HOLD"). The job
 * becomes the move (step JOB_MOVE, its "move" record): flown to the POINT by
 * its ROUTE (FUNC(liftOrder)), at its ALTITUDE when it gave one
 * (FUNC(liftTick) keeps it there), and there:
 *
 *   LOITER, HOLD   it orbits the point (TASK_ORBIT)
 *   HOVER          it holds a hover over it (TASK_MOVE)
 *   LAND           it circles for the mark and the clearance, as every
 *                  landing (user, 2026-11-02), then lands and shuts down
 *                  (TASK_LAND_OFF)
 *
 * With a TIME it asks STATE INTENTIONS that many minutes after it gets there;
 * without one it stays until told. Whatever the lift was doing is over - its
 * landing wait, its question; the passengers aboard stay aboard.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The MOVE (EFUNC(support,readOrder), kind "move") <HASHMAP>
 * 2: What it says instead of its WILCO, "" for the WILCO <STRING> (optional, default "")
 *
 * Return Value:
 * Flown <BOOL>
 *
 * Example:
 * [_logic, _move] call jmfsb_support_air_fnc_liftMove
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_move", createHashMap, [createHashMap]], ["_said", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {false};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0) exitWith {false};
private _threadId = _job get "thread";
private _point = _move getOrDefault ["point", []];
if (_point isEqualTo []) exitWith {
    [_logic, _threadId, WHY_NO_TARGET] call FUNC(liftSay);
    false
};

private _arrival = _move getOrDefault ["arrival", ""];
if (_arrival isEqualTo "") then {_arrival = MOVE_DEFAULT};
private _task = switch (_arrival) do {
    case MOVE_HOVER: {TASK_MOVE};
    case MOVE_LAND: {TASK_LAND_OFF};
    default {TASK_ORBIT};
};

[_threadId, WORD_ABORT] call EFUNC(support,lzClearReply);
{_job set _x} forEach [
    ["step", JOB_MOVE],
    ["landing", ""],
    ["landAt", []],
    ["holding", false],
    ["asked", false],
    ["inboundTo", []],
    ["askAt", ""],
    ["move", createHashMapFromArray [
        ["arrival", _arrival],
        ["point", _point],
        ["altitude", _move getOrDefault ["altitude", -1]],
        ["minutes", _move getOrDefault ["minutes", -1]],
        ["arrived", -1],
        ["said", false]
    ]]
];
_job deleteAt "heldOrder";
_job deleteAt "heldStep";
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
if (!isNull _veh) then {
    _veh setVariable [QGVAR(allIn), nil, true];
    _veh setVariable [QGVAR(waveOff), nil, true];
};

private _flown = [_logic, _task, _point, _move getOrDefault ["route", []]] call FUNC(liftOrder);
if (!_flown) exitWith {
    ([_logic] call FUNC(available)) params ["", "_status"];
    [_logic, _threadId, format ["UNABLE - %1", toUpper _status]] call FUNC(liftSay);
    false
};
INFO_3("liftMove: %1 to %2 - %3",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],mapGridPosition _point,_arrival);
if (_said isEqualTo "") then {_said = format [SAID_WILCO, format [SAID_MOVE_WILCO, mapGridPosition _point, _arrival]]};
[_logic, _threadId, _said] call FUNC(liftSay);
true
