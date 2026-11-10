#include "script_component.hpp"
/*
 * Author: Reeveli
 * Makes an object a teleport point. Server side: run it from an Eden init
 * field (which runs everywhere, and the server check below picks the one that
 * counts) or remoteExec it to the server.
 *
 * A REQUEST FROM A CLIENT (the Zeus module, FUNC(zenDialog)) is taken only
 * from an admin by the server's records or a player who holds a curator
 * module (review S7) - checked here, at the top, from the real sender.
 *
 * Arguments:
 * 0: Object <OBJECT>
 * 1: Display name <STRING>
 * 2: Side that may use it <SIDE>
 *
 * Return Value: None
 *
 * Example:
 * [this, "Staging area", west] call jmfsb_teleport_fnc_addPoint
 *
 * Public: Yes
 */

params [
    ["_object", objNull, [objNull]],
    ["_name", "", [""]],
    ["_side", west, [civilian]]
];

if (!isServer) exitWith {false};
if (!([] call EFUNC(common,senderIsAdmin)) && {isNull getAssignedCuratorLogic (([] call EFUNC(common,sender)) select 1)}) exitWith {
    WARNING_1("addPoint: refused - machine %1 is no admin and no Zeus",remoteExecutedOwner);
    false
};
if (isNull _object) exitWith {false};

if (([_object] call FUNC(listCheck)) > -1) exitWith {
    WARNING_1("'%1' is already a teleport point",_object);
    false
};

// The server's own list, then a copy for the menus (review S7).
private _list = localNamespace getVariable [QTP_LIST, []];
_list pushBack [_object, _name, _side];
localNamespace setVariable [QTP_LIST, _list];
[] call FUNC(listPublish);

// The point goes when the object does, so a destroyed shed does not stay on
// the list as somewhere you can still be sent.
_object addEventHandler ["Killed", {
    params ["_unit"];
    [_unit] call FUNC(deletePoint);
}];

_object addEventHandler ["Deleted", {
    params ["_entity"];
    [_entity] call FUNC(deletePoint);
}];

[_object, _side] remoteExecCall [QFUNC(addAction), 0, true];
