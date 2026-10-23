#include "script_component.hpp"
/*
 * Author: JMSB
 * A logistics module's order, on the server: books one drop and launches it
 * after the response delay (FUNC(dropLaunch)), or recalls the aircraft.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: "DROP" or "rtb" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "DROP", _pos, [], player] call jmfsb_support_air_fnc_dropOrder
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_requester", objNull, [objNull]]];

if (_task isEqualTo TASK_RTB) exitWith {
    if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isNotEqualTo STATUS_IDLE) then {
        _logic setVariable [QGVAR(abort), true, true];
    };
};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[_logic, "cannot take it - " + _why, "normal", _requester, false] call FUNC(say)};

private _height = [_prm, SLOT_DROP_ALT, 0, count DROP_ALT_TABLE - 1, DROP_ALT_TABLE, _logic getVariable [QGVAR(dropHeight), 250]] call FUNC(readParam);

// CONTENTS and CRATE SIGNAL, as declared for this module (FUNC(tasks)). An
// index past this module's loads - the slot is shared - is its first load.
private _loads = _logic getVariable [QGVAR(loads), [""]];
private _load = _loads param [[_prm, SLOT_CONTENTS, 0, count _loads - 1] call FUNC(readParam), ""];
private _sigIdx = [_prm, SLOT_CRATE_SIGNAL, 0, count CRATE_SIGNAL_CLASSES - 1] call FUNC(readParam);
private _signal = if (_sigIdx isEqualTo 0) then {_logic getVariable [QGVAR(signalClass), ""]} else {CRATE_SIGNAL_CLASSES select _sigIdx};

private _left = _logic getVariable [QGVAR(left), -1];
if (_left > 0) then {_logic setVariable [QGVAR(left), _left - 1, true]};
_logic setVariable [QGVAR(status), STATUS_LAUNCHING, true];
_logic setVariable [QGVAR(plan), [[_pos, "DROP"]], true];
if ((_logic getVariable [QGVAR(cooldownTrigger), COOLDOWN_AT_END]) isEqualTo COOLDOWN_AT_START) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};

private _delay = _logic getVariable [QGVAR(spawnDelay), 60];
[_logic, format ["copy supply drop on %1 - airborne in %2 sec", mapGridPosition _pos, round _delay], "high", _requester] call FUNC(say);

[FUNC(dropLaunch), [_logic, _pos, _height, _requester, _load, _signal], _delay] call CBA_fnc_waitAndExecute;
