#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a lift job's own order on its transport (2026-11-09) - a HOLD's
 * orbit, a MOVE's point - written so the watch flies it as the job's
 * (options "job" the thread: FUNC(liftTick) keeps the job) with its own legs
 * and orbit radius. Out: the module's current order, re-planned on the next
 * tick (FUNC(transportPlan)), the speed and door guns of the order it had.
 * Not out: the board's own path (FUNC(transportOrder)) launches it.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The transport task <STRING>
 * 2: Where <ARRAY>
 * 3: Legs flown first <ARRAY> (optional, default [])
 * 4: Orbit radius, m <NUMBER> (optional, default LZ_HOLD_ORBIT)
 * 5: Final approach bearing - where it comes in from, -1 none <NUMBER> (optional, default -1)
 *
 * Return Value:
 * Written <BOOL>
 *
 * Example:
 * [_logic, "ORBIT", getPosATL _veh] call jmfsb_support_air_fnc_liftOrder
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_task", "", [""]],
    ["_pos", [], [[]]],
    ["_via", [], [[]]],
    ["_radius", LZ_HOLD_ORBIT, [0]],
    ["_approach", -1, [0]]
];

if (!isServer || {isNull _logic} || {_pos isEqualTo []}) exitWith {false};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
private _issuer = _job getOrDefault ["issuer", objNull];
private _was = _logic getVariable [QGVAR(order), []];

// Not out: launched by the board's path; its options are the job's before the
// launch plans them on the next frame. Refused (busy, spent): not written.
if !(_logic getVariable [QGVAR(ticking), false]) exitWith {
    [_logic, _task, _pos, [], _issuer] call FUNC(transportOrder);
    if ((_logic getVariable [QGVAR(status), ""]) isNotEqualTo STATUS_LAUNCHING) exitWith {false};
    private _launchOpts = (_logic getVariable [QGVAR(order), []]) param [7, createHashMap];
    {_launchOpts set _x} forEach [["job", _job getOrDefault ["thread", ""]], ["via", +_via], ["radius", _radius], ["approach", _approach]];
    _logic setVariable [QGVAR(sortieThread), _job getOrDefault ["thread", ""]];
    true
};

private _opts = createHashMapFromArray [
    ["job", _job getOrDefault ["thread", ""]],
    ["via", +_via],
    ["lz", []],
    ["approach", _approach],
    ["signal", SIGNAL_NONE],
    ["radius", _radius],
    ["lzVia", []]
];
_logic setVariable [QGVAR(order), [_task, _pos, _issuer, TASK_HEIGHT_NONE, _was param [4, 0], _was param [5, 0], _was param [6, 0], _opts]];
_logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];
true
