#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function assigns (or unassigns) given unit as Zeus. The request goes to the
 * server by remoteExec, never a CBA event, so the server knows who sent it and
 * decides itself whether he may have Zeus (review S7, FUNC(zeusAssign)).
 *
 * Arguments:
 * 0: Unit to assign as Zeus <OBJECT>
 * 1: Assign as Zeus <BOOL> (optional, default true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_curator_fnc_assignZeus
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_isZeus", true, [true]]];

if (isNull _unit) exitWith {};
// A client may only ask for himself (the Eden attribute runs on every machine
// for every unit); the server refuses anything else.
if (!isServer && {!local _unit}) exitWith {};

if (_isZeus) then {
    [_unit] remoteExecCall [QFUNC(zeusAssign), SERVER_OWNER];
} else {
    [_unit] remoteExecCall [QFUNC(zeusUnassign), SERVER_OWNER];
};
