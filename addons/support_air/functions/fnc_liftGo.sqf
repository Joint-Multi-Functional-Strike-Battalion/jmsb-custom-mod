#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a transport's lift job is flown (2026-11-01, DESIGN_SUPPORT_MESSAGING
 * step 7) - its task and point written as the module's order through the
 * board's own path (FUNC(transportOrder)): the first order launches it, a later
 * one (a NEXT LIFT, a casevac's destination) re-plans it in the air. The order
 * carries the job (options "job" - the thread; "lzVia" - the card's flight path
 * after the pickup: the LIFT REQUEST's ROUTE, flown before the LZ of a PICKUP >
 * LZ, the EXTRACTION's EGRESS, 2026-11-02; "paxNear" - the passengers are the men
 * at the pickup, a PICKUP > LZ's and an EXTRACT's), so the watch knows it
 * (FUNC(liftTick)) and a board order,
 * which carries none, ends the job.
 *
 * Launched: WHEELS UP and ON TASK come at the launch (FUNC(transportLaunch));
 * already out: ON TASK now. Refused (busy, spent): CANTCO with the reason.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * Flown <BOOL>
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_liftGo
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {false};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0) exitWith {false};

private _threadId = _job get "thread";
private _task = _job get "task";
private _out = _logic getVariable [QGVAR(ticking), false];
private _serial = _logic getVariable [QGVAR(serial), 0];

[_logic, _task, _job get "first", _job get "prm", _job get "issuer"] call FUNC(transportOrder);

if ((_logic getVariable [QGVAR(serial), 0]) isEqualTo _serial) exitWith {
    ([_logic] call FUNC(available)) params ["", "_status"];
    [_logic, "DECLINED", [WHY_TASKED, toUpper _status] select (_status isEqualTo STATUS_EXPENDED), _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(liftJob), nil];
    false
};

private _opts = (_logic getVariable [QGVAR(order), []]) param [7, createHashMap];
_opts set ["job", _threadId];
// The card's flight path after the pickup (user, 2026-11-02): the LIFT
// REQUEST's ROUTE to the LZ, the EXTRACTION's EGRESS to the destination or
// home (FUNC(liftJob), FUNC(transportStep)).
_opts set ["lzVia", _job getOrDefault ["lzVia", []]];
_opts set ["paxNear", _task in [TASK_LIFT, TASK_EXTRACT]];
// A PICKUP's LAND HEADING is its pickup leg's approach (2026-11-09).
if ((_job get "kind") isEqualTo ORDER_PICKUP) then {_opts set ["approach", _job getOrDefault ["approach", -1]]};

_logic setVariable [QGVAR(sortieThread), _threadId];
// An extraction goes on station first (FUNC(liftTick)).
private _step = [JOB_FLYING, JOB_STATION] select ((_job getOrDefault ["station", []]) isNotEqualTo []);
{_job set _x} forEach [["step", _step], ["leg", ""], ["asked", false], ["down", false], ["holding", false]];

if (_out) then {[_logic, "IN_PROGRESS", "", _threadId] call FUNC(threadState)};
true
