#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a transport stops where it is (docs/DESIGN_MESSAGE_TEMPLATES.md,
 * 2026-11-09) - HOLD ("stop where you are and wait for the next order") and
 * ABORT ("on a landing or lift-off: do not complete it ... then asks for
 * intentions", FM 3-21.38 Table 3-3), in any step of its lift job:
 *
 *   in the air        the core's landing wait is ended, ropes in, and it
 *                     orbits where it is (FUNC(liftOrder), TASK_ORBIT) - the
 *                     order it was flying kept ("heldOrder") for EXECUTE to
 *                     carry on with (FUNC(liftResume))
 *   on the ground     it stays there; nothing it was waiting for there lifts
 *                     it until it is told
 *   not out yet       (a hot LZ waiting for EXECUTE) it stays on its pad;
 *                     EXECUTE launches the job; made this very frame, it
 *                     stops once it is up
 *
 * HOLD says HOLDING AT <grid>; ABORT asks STATE INTENTIONS (FUNC(liftIntentions)).
 * A MOVE, a FRAGO, a starter in the thread or RTB is the next order.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The step it is put in - JOB_HELD or JOB_ABORTED <STRING>
 * 2: What an ABORTED says before STATE INTENTIONS <STRING> (optional, default SAID_ABORTED)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "held"] call jmfsb_support_air_fnc_liftHold
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_step", JOB_HELD, [""]], ["_said", SAID_ABORTED, [""]]];

if (!isServer || {isNull _logic}) exitWith {};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0) exitWith {};

private _threadId = _job get "thread";
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _out = _logic getVariable [QGVAR(ticking), false];

// Made this frame (the launch is the next frame's, FUNC(transportLaunch)): it
// stops once it is up - the board's stand-down would close the thread.
if (!_out && {(_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_LAUNCHING}) exitWith {
    [
        {(_this select 0) getVariable [QGVAR(ticking), false]},
        {_this call FUNC(liftHold)},
        [_logic, _step, _said],
        LIFT_HOLD_LAUNCH_WAIT
    ] call CBA_fnc_waitUntilAndExecute;
};

// The core's landing wait: over (asked again when it carries on).
[_threadId, WORD_ABORT] call EFUNC(support,lzClearReply);
{_job set _x} forEach [["landing", ""], ["landAt", []], ["holding", false]];

// The order to carry on with - the first stop's, never a hold's own orbit.
if !((_job get "step") in [JOB_HELD, JOB_ABORTED]) then {
    _job set ["heldStep", _job get "step"];
    // In the air only: on the ground it never left the order it was on.
    _job set ["heldOrder", [[], +(_logic getVariable [QGVAR(order), []])] select (_out && {alive _veh} && {!isTouchingGround _veh})];
};

private _where = [mapGridPosition _logic, mapGridPosition _veh] select (alive _veh);
if (_out && {alive _veh} && {!isTouchingGround _veh}) then {
    // ropes in, the flight control let go
    if (!isNil "ace_fastroping_fnc_cutRopes" && {(_veh getVariable ["ace_fastroping_deployedRopes", []]) isNotEqualTo []}) then {
        [_veh] call ace_fastroping_fnc_cutRopes;
    };
    [_veh, false] call FUNC(rappelRopes);
    [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
    [_logic, TASK_ORBIT, getPosATL _veh] call FUNC(liftOrder);
};
if (!isNull _veh) then {
    _veh setVariable [QGVAR(allIn), nil, true];
    _veh setVariable [QGVAR(waveOff), nil, true];
};

_job set ["step", _step];
INFO_3("liftHold: %1 %2 at %3",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_step,_where);
if (_step isEqualTo JOB_ABORTED) exitWith {
    [_logic, _threadId, _said] call FUNC(liftIntentions);
};
[_logic, _threadId, format [SAID_HELD, _where]] call FUNC(liftSay);
