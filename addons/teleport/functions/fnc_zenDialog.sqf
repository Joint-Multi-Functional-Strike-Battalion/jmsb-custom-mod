#include "script_component.hpp"
/*
 * Author: Reeveli
 * The Zeus dialog for turning a selected object into a teleport point.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_object] call jmfsb_teleport_fnc_zenDialog
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

if (!hasInterface) exitWith {false};

if (isNull _object) exitWith {
    playSound "FD_Start_F";
    [objNull, "No object was selected."] call BIS_fnc_showCuratorFeedbackMessage;
};

if (([_object] call FUNC(listCheck)) > -1) exitWith {
    playSound "FD_Start_F";
    [objNull, "That object is already a teleport point."] call BIS_fnc_showCuratorFeedbackMessage;
};

[
    "Add teleportation point to object",
    [
        ["EDIT", ["Display name", "What this point is called in the teleport list."], ["Teleportation point"], true],
        ["SIDES", ["Side", "Which side may use this point."], [west], true]
    ],
    {
        params ["_results", "_args"];
        _results params ["_name", "_side"];
        _args params ["_object"];

        // The server checks this Zeus itself (review S7, FUNC(addPoint)).
        [_object, _name, _side # 0] remoteExecCall [QFUNC(addPoint), SERVER_OWNER];
        [objNull, "Teleport point created."] call BIS_fnc_showCuratorFeedbackMessage;
    },
    {
        playSound "FD_Start_F";
        [objNull, "Dialog closed."] call BIS_fnc_showCuratorFeedbackMessage;
    },
    [_object]
] call zen_dialog_fnc_create;
