#include "..\script_component.hpp"
/*
 * Author: YonV
 * JMSB - Shooting Range module, on every machine (JIP too): reads the
 * module, ties its targets to it and gives its controllers the range menu.
 * The module logic is the range - the run in progress is a public variable
 * on it, so every controller of one range shows the same state.
 *
 * Targets and controllers are the named ones plus whatever is synced:
 * synced pop-up targets are targets, any other synced object a controller.
 *
 * Arguments:
 * 0: Module logic <OBJECT>
 * 1: Synced units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};

private _fnc_objects = {
    params ["_names"];
    ((_names splitString ", ") apply {missionNamespace getVariable [_x, objNull]}) select {!isNull _x}
};
private _fnc_numbers = {
    params ["_list", "_default"];
    private _out = ((_list splitString ", ") apply {parseNumber _x}) select {_x > 0};
    _out pushBackUnique _default;
    _out sort true;
    _out
};

private _synced = synchronizedObjects _logic;
private _targets = ([_logic getVariable ["targets", ""]] call _fnc_objects)
    + (_synced select {_x isKindOf "TargetP_Inf_F"});
_targets = _targets arrayIntersect _targets;
private _controllers = ([_logic getVariable ["controllers", ""]] call _fnc_objects)
    + (_synced select {!(_x isKindOf "TargetP_Inf_F") && {!(_x isKindOf "Logic")}});
_controllers = _controllers arrayIntersect _controllers;

private _name = _logic getVariable ["name", ""];
if (_name isEqualTo "") then {_name = format ["Range %1", mapGridPosition _logic]};

if (_targets isEqualTo [] || {_controllers isEqualTo []}) exitWith {
    WARNING_3("range '%1' not set up - %2 target(s), %3 controller(s)",_name,count _targets,count _controllers);
};

// A BOOL attribute can come through as a bool, a number or a string.
private _save = _logic getVariable ["savePac", true];
if (_save isEqualType 0) then {_save = _save > 0};
if (_save isEqualType "") then {_save = (toLower _save) in ["true", "1"]};

private _duration = _logic getVariable ["duration", 60];
private _count = _logic getVariable ["count", 20];
private _exposure = _logic getVariable ["exposure", 3];

private _cfg = createHashMapFromArray [
    ["name", _name],
    ["targets", _targets],
    ["controllers", _controllers],
    ["mode", _logic getVariable ["mode", MODE_TIMED]],
    ["durations", [_logic getVariable ["durations", ""], _duration] call _fnc_numbers],
    ["duration", _duration],
    ["counts", [_logic getVariable ["counts", ""], _count] call _fnc_numbers],
    ["count", _count],
    ["exposures", [_logic getVariable ["exposures", ""], _exposure] call _fnc_numbers],
    ["exposure", _exposure],
    ["countdown", _logic getVariable ["countdown", 5]],
    ["savePac", _save]
];
_logic setVariable [QGVAR(cfg), _cfg];

{_x setVariable [QGVAR(range), _logic]} forEach _targets;
{
    _x setVariable [QGVAR(range), _logic];
    [_x] call FUNC(aceActions);
} forEach _controllers;

TRACE_3("range up",_name,count _targets,count _controllers);
