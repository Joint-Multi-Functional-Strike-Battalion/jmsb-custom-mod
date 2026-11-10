#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a held or aborted transport carries on with the order it had
 * (2026-11-09) - EXECUTE answering HOLDING or STATE INTENTIONS
 * (FUNC(liftReply)). The order it was flying in the air is written again
 * (FUNC(liftHold) kept it), the step it was in put back and its question, if
 * it was waiting on one, asked again; on the way in the LZ STATUS is asked
 * again. Never launched (a hot LZ held before EXECUTE): launched now
 * (FUNC(liftGo)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * Carried on <BOOL>
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_liftResume
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {false};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if !((_job getOrDefault ["step", ""]) in [JOB_HELD, JOB_ABORTED]) exitWith {false};

private _threadId = _job get "thread";
private _order = _job getOrDefault ["heldOrder", []];
private _step = _job getOrDefault ["heldStep", JOB_FLYING];
_job deleteAt "heldOrder";
_job deleteAt "heldStep";

if !(_logic getVariable [QGVAR(ticking), false]) exitWith {
    [_logic, _threadId, format [SAID_WILCO, toUpper (_job getOrDefault ["kind", ""])]] call FUNC(liftSay);
    [_logic] call FUNC(liftGo)
};

if (_order isNotEqualTo []) then {
    _logic setVariable [QGVAR(order), _order];
    _logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];
};
if (_step in [JOB_LZ_STATUS, JOB_HOT, JOB_MOVE]) then {
    _step = JOB_FLYING;
    _job set ["asked", false];
};
// A paradrop held on its run-in: EXECUTE is the drop (2026-11-09).
if (_step isEqualTo JOB_STANDBY) then {
    _step = JOB_FLYING;
    {_job set _x} forEach [["dropCleared", true], ["closedTraffic", false]];
};
_job set ["step", _step];
[_logic, _threadId, format [SAID_WILCO, SAID_CARRY_ON]] call FUNC(liftSay);

// The question it was waiting on, again.
switch (_step) do {
    case JOB_ALL_IN: {[_logic] call FUNC(liftLoad)};
    case JOB_INSERT: {[_logic, _threadId, PROMPT_INSERT, ANSWERS_INSERT] call FUNC(threadPrompt)};
    case JOB_PAX: {[_logic, _threadId, PROMPT_PAX, ANSWERS_PAX] call FUNC(threadPrompt)};
    case JOB_DEST: {[_logic, _threadId, PROMPT_DEST, ANSWERS_DEST] call FUNC(threadPrompt)};
    case JOB_STATION: {_job set ["onStation", false]};
    default {};
};
true
