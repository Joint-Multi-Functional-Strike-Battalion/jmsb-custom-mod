#include "script_component.hpp"
/*
 * Author: YonV
 * A transport module's order, on the server.
 *
 * THE HELICOPTER STAYS OUT BETWEEN ORDERS. The first order launches it at
 * once (user, 2026-11-02: virtual until tasked - made over the module when
 * tasked; the Response Delay is retired); every later one is
 * written onto the module as the CURRENT order and the helicopter's watch
 * (FUNC(transportTick)) re-plans on the next tick - so a PICKUP followed by a
 * HOVER is one helicopter flying two legs, and a man can redirect it in the
 * air. RTB is an order like the others: fly home.
 *
 * WHAT THE REQUESTER SET is read here, once: the jump height on a PARADROP,
 * speed, door guns, final approach, landing signal, wait, orbit radius, and
 * the points - VIA legs flown first, and the LZ a PICKUP > LZ goes on to or a
 * SLINGLOAD sets its load down at. It rides on the order as its options
 * (element 7), so a re-plan flies exactly what was asked. Not the height it
 * flies at nor its lights (user, 2026-11-01: HEIGHT and LIGHTS retired): it
 * flies nap of the earth and dark away from its airfield (the support core's
 * tactical flight); element 3 is only the task's own height, a jump height or
 * TASK_HEIGHT_NONE.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token, or "rtb" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "PICKUP", _pos, [], player] call jmfsb_support_air_fnc_transportOrder
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_requester", objNull, [objNull]]];

private _out = _logic getVariable [QGVAR(ticking), false];

if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_LAUNCHING) exitWith {
        _logic setVariable [QGVAR(abort), true, true];
    };
    if (!_out) exitWith {};
    private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
    _logic setVariable [QGVAR(order), [TASK_HOME, _home, _requester, TASK_HEIGHT_NONE, 0, 0, 0, createHashMap]];
    _logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];
    [_logic, "returning to base", "normal", _requester] call FUNC(say);
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[_logic, "cannot take it - " + _why, "normal", _requester, false] call FUNC(say)};

private _height = if (_task isEqualTo TASK_PARADROP) then {
    [_prm, SLOT_JUMP_ALT, 0, count JUMP_ALT_TABLE - 1, JUMP_ALT_TABLE, _logic getVariable [QGVAR(jumpHeight), 250]] call FUNC(readParam)
} else {TASK_HEIGHT_NONE};
private _speed = [_prm, SLOT_SPEED, 0, count SPEED_WORDS - 1] call FUNC(readParam);
private _roe = [_prm, SLOT_ROE, 0, count ROE_WORDS - 1] call FUNC(readParam);
private _wait = [_prm, SLOT_WAIT, 0, count WAIT_TABLE - 1, WAIT_TABLE, _logic getVariable [QGVAR(waitTime), 300]] call FUNC(readParam);

// The options each task declared. A slot a task does not declare is read as
// its default, never as whatever another screen left in it.
private _decl = ((([format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], [_logic] call FUNC(entityRow)] call FUNC(tasks)) select {(_x select 0) isEqualTo _task}) param [0, []]);
private _declares = {
    params ["_slot"];
    ((_decl param [4, []]) findIf {(_x param [1, -1]) isEqualTo _slot}) > -1
        || {((_decl param [7, []]) findIf {(_x param [1, -1]) isEqualTo _slot}) > -1}
};
private _approach = if ([SLOT_APPROACH] call _declares) then {[_prm, SLOT_APPROACH, 0, count APPROACH_WORDS - 1] call FUNC(readParam)} else {0};
private _opts = createHashMapFromArray [
    ["via", [_prm, SLOT_VIA, true] call FUNC(readPoint)],
    ["lz", [[], [_prm, SLOT_LZ] call FUNC(readPoint)] select ([SLOT_LZ] call _declares)],
    ["approach", [-1, (_approach - 1) * APPROACH_STEP] select (_approach > 0)],
    ["signal", [SIGNAL_NONE, [_prm, SLOT_SIGNAL, 0, count SIGNAL_WORDS - 1] call FUNC(readParam)] select ([SLOT_SIGNAL] call _declares)],
    ["radius", [_prm, SLOT_RADIUS, RADIUS_MIN, RADIUS_MAX] call FUNC(readParam)]
];

_logic setVariable [QGVAR(order), [_task, _pos, _requester, _height, _speed, _roe, _wait, _opts]];
_logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];

if (_out) exitWith {
    [_logic, format ["copy %1, %2", _task, mapGridPosition _pos], "normal", _requester] call FUNC(say);
};

if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_START) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};

// VIRTUAL UNTIL TASKED (user, 2026-11-02): made now, over the module - on the
// next frame, so the WILCO is in the thread before WHEELS UP. A synced
// helicopter starts now too: it has to take off.
_logic setVariable [QGVAR(status), STATUS_LAUNCHING, true];
_logic setVariable [QGVAR(plan), [[_pos, _task]], true];
[_logic, format ["copy %1, %2 - wheels up", _task, mapGridPosition _pos], "high", _requester] call FUNC(say);

[FUNC(transportLaunch), [_logic, _requester]] call CBA_fnc_execNextFrame;
