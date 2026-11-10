#include "..\script_component.hpp"
/*
 * Author: YonV
 * The range menu on one controller: Start, Stop, and the mode and its
 * settings. Each setting lists the choices it is not already on; the menu
 * title shows what is set. Settings change only while the range is idle.
 * Nothing without ACE.
 *
 * Arguments:
 * 0: Controller <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_ctrl", objNull, [objNull]]];

if (!hasInterface || {isNull _ctrl}) exitWith {};
if (!isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};

private _range = _ctrl getVariable [QGVAR(range), objNull];
private _cfg = _range getVariable [QGVAR(cfg), createHashMap];

private _fnc_idle = {(((_target getVariable [QGVAR(range), objNull]) getVariable [QGVAR(run), []]) isEqualTo [])};

// The title: the range, what it is set to, and whether someone is on it.
private _root = [QGVAR(root), _cfg get "name", ACE_ICON, {}, {true}, {}, [], [0, 0, 0], 3, [false, false, false, false, false], {
    params ["_target", "", "", "_actionData"];
    private _range = _target getVariable [QGVAR(range), objNull];
    private _cfg = _range getVariable [QGVAR(cfg), createHashMap];
    private _run = _range getVariable [QGVAR(run), []];
    private _mode = [_range, "mode"] call FUNC(setting);
    private _detail = [_mode, [_range, "duration"] call FUNC(setting), [_range, "count"] call FUNC(setting),
        [_range, "exposure"] call FUNC(setting), count (_cfg get "targets")] call FUNC(detail);
    _actionData set [1, if (_run isEqualTo []) then {
        format ["%1 - %2, %3", _cfg get "name", MODE_NAMES select _mode, _detail]
    } else {
        format ["%1 - in use: %2", _cfg get "name", name (_run select 0)]
    }];
}] call ace_interact_menu_fnc_createAction;
[_ctrl, 0, [], _root] call ace_interact_menu_fnc_addActionToObject;
private _path = [QGVAR(root)];

private _start = [QGVAR(start), "Start", "", {
    params ["_target", "_player"];
    [_target getVariable [QGVAR(range), objNull], _player] call FUNC(start);
}, _fnc_idle] call ace_interact_menu_fnc_createAction;
[_ctrl, 0, _path, _start] call ace_interact_menu_fnc_addActionToObject;

// The shooter stops their own run; an admin, or anyone once the shooter is
// gone, stops anyone's.
private _stop = [QGVAR(stop), "Stop", "", {
    params ["_target"];
    [_target getVariable [QGVAR(range), objNull]] call FUNC(stop);
}, {
    params ["_target", "_player"];
    private _run = (_target getVariable [QGVAR(range), objNull]) getVariable [QGVAR(run), []];
    if (_run isEqualTo []) exitWith {false};
    private _shooter = _run select 0;
    _shooter isEqualTo _player || {!alive _shooter} || {_player getVariable [QEGVAR(common,isAdmin), false]}
}] call ace_interact_menu_fnc_createAction;
[_ctrl, 0, _path, _stop] call ace_interact_menu_fnc_addActionToObject;

// [setting, menu name, choices, which modes it applies to]
{
    _x params ["_key", "_label", "_choices", "_modes", "_fnc_name"];
    private _node = format ["%1_%2", QGVAR(set), _key];
    private _parent = [_node, _label, "", {}, {
        params ["_target", "", "_args"];
        _args params ["_modes"];
        private _range = _target getVariable [QGVAR(range), objNull];
        (_range getVariable [QGVAR(run), []]) isEqualTo [] && {([_range, "mode"] call FUNC(setting)) in _modes}
    }, {}, [_modes]] call ace_interact_menu_fnc_createAction;
    [_ctrl, 0, _path, _parent] call ace_interact_menu_fnc_addActionToObject;
    {
        private _act = [format ["%1_%2", _node, _x], [_x] call _fnc_name, "", {
            params ["_target", "", "_args"];
            _args params ["_key", "_value"];
            [_target getVariable [QGVAR(range), objNull], _key, _value] call FUNC(setting);
        }, {
            params ["_target", "", "_args"];
            _args params ["_key", "_value"];
            ([_target getVariable [QGVAR(range), objNull], _key] call FUNC(setting)) isNotEqualTo _value
        }, {}, [_key, _x]] call ace_interact_menu_fnc_createAction;
        [_ctrl, 0, _path + [_node], _act] call ace_interact_menu_fnc_addActionToObject;
    } forEach _choices;
} forEach [
    ["mode", "Mode", MODES, MODES, {MODE_NAMES select (_this select 0)}],
    ["duration", "Duration", _cfg get "durations", [MODE_TIMED, MODE_RAMPAGE], {format ["%1 s", _this select 0]}],
    ["count", "Targets", _cfg get "counts", [MODE_COUNT], {format ["%1 targets", _this select 0]}],
    ["exposure", "Exposure", _cfg get "exposures", [MODE_TIMED, MODE_COUNT], {format ["%1 s up", _this select 0]}]
];
