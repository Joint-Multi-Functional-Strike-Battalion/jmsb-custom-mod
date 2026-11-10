#include "script_component.hpp"
/*
 * Author: Reeveli
 * Takes an object off the point list. Server only: the server's list lives in
 * localNamespace and the public copy is republished from it (review S7) - a
 * client's call does nothing.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_object] call jmfsb_teleport_fnc_deletePoint
 *
 * Public: Yes
 */

params [["_object", objNull, [objNull]]];

if (!isServer || {isNull _object}) exitWith {false};

private _index = [_object] call FUNC(listCheck);

// NOT FOUND IS NOT AN INDEX. deleteAt -1 takes the LAST entry off the list,
// so an object that was never a point - or one whose Killed and Deleted
// handlers both fire - used to remove somebody else's.
if (_index < 0) exitWith {false};

private _list = localNamespace getVariable [QTP_LIST, []];
_list deleteAt _index;
localNamespace setVariable [QTP_LIST, _list];
[] call FUNC(listPublish);
