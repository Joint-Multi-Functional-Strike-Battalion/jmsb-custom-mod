#include "script_component.hpp"
/*
 * Author: 3Mydlo3, JMSB
 * Server: gives a player a curator module, by remoteExec from
 * FUNC(assignZeus). A client may ask only for himself, and only gets Zeus
 * when the server agrees (review S7): he is an admin by the server's records,
 * or the server has him on its own Zeus list (GVAR(zeusAllowed), kept in
 * localNamespace so no client can write it). The server's own calls - the
 * Eden "Zeus" attribute running on the server - are trusted and put the unit
 * on that list.
 *
 * Arguments:
 * 0: Unit to assign as Zeus <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] remoteExecCall ["jmfsb_curator_fnc_zeusAssign", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {isNull _unit}) exitWith {};

private _allowed = localNamespace getVariable [QGVAR(zeusAllowed), []];
if ([] call EFUNC(common,fromServer)) then {
    _allowed pushBackUnique _unit;
    localNamespace setVariable [QGVAR(zeusAllowed), _allowed];
} else {
    if !([_unit] call EFUNC(common,senderIs)) exitWith {_unit = objNull};
    if (!(_unit in _allowed) && {!([] call EFUNC(common,senderIsAdmin))}) exitWith {_unit = objNull};
};
if (isNull _unit) exitWith {
    WARNING_1("zeusAssign: refused a request from machine %1",remoteExecutedOwner);
};
if !(isPlayer _unit) exitWith {};

INFO_1("Assigning Zeus to '%1'",_unit);

private _curatorModule = [_unit] call FUNC(getFreeCuratorModule);
unassignCurator getAssignedCuratorLogic _unit;

// Curator unassign can take a moment, add delay. A plain delayed call - the
// old waitUntilAndExecute form used {} as the condition, which returns Nothing
// and threw a type error every frame for the whole five seconds; the
// assignment only ever happened because the timeout branch fired.
[{
    params ["_unit", "_curatorModule"];

    _unit assignCurator _curatorModule;

    [_curatorModule] remoteExecCall [QFUNC(zeusAssigned), _unit];
}, [_unit, _curatorModule], ASSIGN_DELAY] call CBA_fnc_waitAndExecute;
