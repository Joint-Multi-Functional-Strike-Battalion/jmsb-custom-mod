#include "script_component.hpp"
/*
 * Author: 3Mydlo3, JMSB
 * Server: activates addons on a curator module, by remoteExec from
 * FUNC(zeusAssigned). Only for the module the sender himself is assigned to
 * (review S7) - a client cannot change another curator's module.
 *
 * Arguments:
 * 0: The curator module <OBJECT>
 * 1: CfgPatches class names <ARRAY of STRINGs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_curatorModule, _addons] remoteExecCall ["jmfsb_curator_fnc_zeusActivateAddons", 2]
 *
 * Public: No
 */

params [["_curatorModule", objNull, [objNull]], ["_addons", [], [[]]]];

if (!isServer || {isNull _curatorModule}) exitWith {};

if !([] call EFUNC(common,fromServer)) then {
    ([] call EFUNC(common,sender)) params ["", "_sender"];
    if ((getAssignedCuratorLogic _sender) isNotEqualTo _curatorModule) then {_curatorModule = objNull};
};
if (isNull _curatorModule) exitWith {
    WARNING_1("zeusActivateAddons: refused a request from machine %1",remoteExecutedOwner);
};

INFO_1("Activating curator addons - '%1'",_curatorModule);

_curatorModule addCuratorAddons (_addons select {_x isEqualType ""});
