#include "..\script_component.hpp"
/*
 * Author: YonV
 * A MOUT / CQB course: the controller gets Create and Clear entries. Create
 * puts a man on a random share of the course's spawn points; Clear removes
 * them. One course per controller.
 *
 * Spawn points are objects named <base>_0 .. <base>_<count - 1> (the VR
 * selectors are usual); they are hidden in game. A point of a listed
 * special class can get a special man instead. Side comes from the man's
 * own config.
 *
 * Call from the controller's init field.
 *
 * Arguments:
 * 0: Controller <OBJECT>
 * 1: Course name <STRING>
 * 2: Spawn point base name <STRING>
 * 3: Spawn point count <NUMBER>
 * 4: Unit classes <ARRAY>
 * 5: Chance a point is manned, 0-100 <NUMBER> (optional, default 30)
 * 6: Specials - [point class, [unit classes], chance 0-100] each <ARRAY> (optional, default [])
 *
 * Return Value: None
 *
 * Example:
 * [this, "CQB 1", "cqb1", 75, ["O_G_Soldier_F"], 45, [["VR_3DSelector_01_exit_F", ["O_G_Soldier_AR_F"], 60]]] call jmfsb_training_fnc_mout
 *
 * Public: Yes
 */

params [
    ["_ctrl", objNull, [objNull]],
    ["_name", "", [""]],
    ["_base", "", [""]],
    ["_count", 0, [0]],
    ["_classes", [], [[]]],
    ["_chance", MOUT_CHANCE, [0]],
    ["_specials", [], [[]]]
];

if (isNull _ctrl || {_classes isEqualTo []}) exitWith {
    WARNING_1("mout: nothing to do on %1",_ctrl);
};

private _points = [];
for "_i" from 0 to (_count - 1) do {
    private _point = missionNamespace getVariable [format ["%1_%2", _base, _i], objNull];
    if (_point isEqualType objNull && {!isNull _point}) then {
        _point hideObject true;
        _points pushBack _point;
    };
};

_ctrl setVariable [QGVAR(mout), [_name, _points, _classes, _chance, _specials]];

if (!hasInterface) exitWith {};
if (!isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};

private _create = [QGVAR(moutCreate), format ["Create %1", _name], MOUT_ICON_CREATE, {
    params ["_target"];
    [QGVAR(moutCreate), [_target]] call CBA_fnc_serverEvent;
    [NOTE_TITLE, format ["%1 is being manned.", (_target getVariable [QGVAR(mout), [""]]) select 0], NOTE_INFO] call EFUNC(notify,notify);
}, {(_target getVariable [QGVAR(moutUnits), []]) isEqualTo []}] call ace_interact_menu_fnc_createAction;
[_ctrl, 0, ["ACE_MainActions"], _create] call ace_interact_menu_fnc_addActionToObject;

private _clear = [QGVAR(moutClear), format ["Clear %1", _name], MOUT_ICON_CLEAR, {
    params ["_target"];
    [QGVAR(moutClear), [_target]] call CBA_fnc_serverEvent;
    [NOTE_TITLE, format ["%1 cleared.", (_target getVariable [QGVAR(mout), [""]]) select 0], NOTE_INFO] call EFUNC(notify,notify);
}, {(_target getVariable [QGVAR(moutUnits), []]) isNotEqualTo []}] call ace_interact_menu_fnc_createAction;
[_ctrl, 0, ["ACE_MainActions"], _clear] call ace_interact_menu_fnc_addActionToObject;
