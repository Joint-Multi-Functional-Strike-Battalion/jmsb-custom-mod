#include "script_component.hpp"
/*
 * Author: YonV
 * The Zeus's building mark (user, 2026-11-06), a ZEN module: the building
 * clicked, else the nearest within MARK_MODULE_RADIUS of where he clicked;
 * then a dialog for its colour (CLEAR takes a mark off) and label, sent to
 * the server (FUNC(markSet)).
 *
 * Arguments:
 * 0: Position clicked, ASL <ARRAY>
 * 1: Object clicked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_pos, _object] call jmfsb_ecoti_fnc_zenMark
 *
 * Public: No
 */

params [["_pos", [0, 0, 0], [[]]], ["_object", objNull, [objNull]]];

if (!hasInterface) exitWith {};

private _building = [objNull, _object] select (!isNull _object && {_object isKindOf MARK_BUILDING_CLASS});
if (isNull _building) then {
    private _near = nearestObjects [ASLToAGL _pos, [MARK_BUILDING_CLASS], MARK_MODULE_RADIUS, true];
    if (_near isNotEqualTo []) then {_building = _near select 0};
};
if (isNull _building) exitWith {
    playSound "FD_Start_F";
    [objNull, format ["No building within %1 m.", MARK_MODULE_RADIUS]] call BIS_fnc_showCuratorFeedbackMessage;
};

private _names = (MARK_COLOURS apply {_x select 0}) + [MARK_CLEAR_WORD];
private _values = [];
for "_i" from 0 to (count MARK_COLOURS - 1) do {_values pushBack _i};
_values pushBack MARK_CLEAR;
[
    "AiTR building mark",
    [
        ["COMBO", ["Colour", "The box every AiTR draws round this building. CLEAR takes a mark off."], [_values, _names, 0]],
        ["EDIT", ["Label", "Under the box, with the range. Empty: MARK."], [""]]
    ],
    {
        params ["_results", "_args"];
        _results params ["_colour", "_label"];
        _args params ["_building"];
        [_building, _colour, _label] remoteExecCall [QFUNC(markSet), SERVER_OWNER];
        [objNull, "Building mark set."] call BIS_fnc_showCuratorFeedbackMessage;
    },
    {},
    [_building]
] call zen_dialog_fnc_create;
