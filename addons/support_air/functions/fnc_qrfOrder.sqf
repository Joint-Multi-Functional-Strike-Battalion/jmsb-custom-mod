#include "script_component.hpp"
/*
 * Author: YonV
 * A QRF module's order, on the server: launches the squad (FUNC(qrfLaunch))
 * at once - its airframe made over the module with the squad aboard (user,
 * 2026-11-02: virtual until tasked; the Response Delay is retired) - or
 * recalls the aircraft. Squads are retired: one airframe, one squad a
 * tasking; the respawn count says how many more after a loss.
 *
 * The QRF tasks declare no steppers: the static-line height is the module's.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: "STATIC", "ASSAULT" or "rtb" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: TAC//SUPPORT's parameter array (unused) <ARRAY>
 * 4: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "STATIC", _pos, [], player] call jmfsb_support_air_fnc_qrfOrder
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], "", ["_requester", objNull, [objNull]]];

if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isNotEqualTo STATUS_IDLE) then {
        _logic setVariable [QGVAR(abort), true, true];
    };
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[_logic, "cannot take it - " + _why, "normal", _requester, false] call FUNC(say)};
if !(_task in (_logic getVariable [QGVAR(allowed), []])) exitWith {
    [_logic, format ["does not fly %1", _task], "normal", _requester, false] call FUNC(say);
};

_logic setVariable [QGVAR(status), STATUS_LAUNCHING, true];
_logic setVariable [QGVAR(plan), [[_pos, _task]], true];
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_START) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};

// VIRTUAL UNTIL TASKED (user, 2026-11-02): made now, on the next frame so the
// WILCO is in the thread before WHEELS UP.
[_logic, format ["copy %1 on %2 - wheels up", _task, mapGridPosition _pos], "high", _requester] call FUNC(say);

[FUNC(qrfLaunch), [_logic, _task, _pos, _requester]] call CBA_fnc_execNextFrame;
