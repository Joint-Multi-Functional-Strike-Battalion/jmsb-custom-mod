#include "script_component.hpp"
/*
 * Author: JMSB
 * A QRF module's order, on the server: books one squad and launches it after
 * the response delay (FUNC(qrfLaunch)), or recalls the aircraft.
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

private _left = _logic getVariable [QGVAR(left), -1];
if (_left > 0) then {_logic setVariable [QGVAR(left), _left - 1, true]};
_logic setVariable [QGVAR(status), STATUS_LAUNCHING, true];
_logic setVariable [QGVAR(plan), [[_pos, _task]], true];
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_START) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};

private _delay = _logic getVariable [QGVAR(spawnDelay), 90];
[_logic, format ["copy %1 on %2 - wheels up in %3 sec", _task, mapGridPosition _pos, round _delay], "high", _requester] call FUNC(say);

[FUNC(qrfLaunch), [_logic, _task, _pos, _requester], _delay] call CBA_fnc_waitAndExecute;
