#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: makes objects and groups editable for every curator. Reached by
 * remoteExec from a curator's machine when he places something, and from
 * each client for its own player at start; the server's own calls go
 * straight through.
 *
 * Checked at the top (review S7 - these were CBA events any client could
 * raise to hand any object to every Zeus): a man assigned a curator module
 * may add anything; anyone else only what his own machine owns.
 *
 * Arguments:
 * 0: Objects and groups <ARRAY of OBJECTs and GROUPs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[player]] remoteExecCall ["jmfsb_curator_fnc_editableAdd", 2]
 *
 * Public: No
 */

params [["_things", [], [[]]]];

if (!isServer) exitWith {};

private _objects = [];
{
    if (_x isEqualType grpNull) then {_objects append (units _x)};
    if (_x isEqualType objNull) then {_objects pushBack _x};
} forEach _things;
_objects = _objects select {!isNull _x};

if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo SERVER_OWNER}) then {
    ([] call EFUNC(common,sender)) params ["_owner", "_unit"];
    if (isNull (getAssignedCuratorLogic _unit)) then {
        _objects = _objects select {(owner _x) isEqualTo _owner};
    };
};
if (_objects isEqualTo []) exitWith {};

{
    _x addCuratorEditableObjects [_objects, true];
} forEach allCurators;
