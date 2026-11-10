#include "script_component.hpp"
/*
 * Author: 3Mydlo3, JMSB
 * Client: the server has assigned this player a curator module
 * (FUNC(zeusAssign)). Taken only from the server (review S7). Asks the server
 * to activate every addon this machine has on the module, and draws the
 * curator locations once.
 *
 * Arguments:
 * 0: The curator module <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_curatorModule] remoteExecCall ["jmfsb_curator_fnc_zeusAssigned", _unit]
 *
 * Public: No
 */

params [["_curatorModule", objNull, [objNull]]];

if (!hasInterface || {isNull _curatorModule}) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

INFO_1("Assigned Curator '%1'",_curatorModule);

private _allAddons = ("true" configClasses (configFile >> "CfgPatches")) apply {configName _x};
[_curatorModule, _allAddons] remoteExecCall [QFUNC(zeusActivateAddons), SERVER_OWNER];

if !(_curatorModule getVariable [QGVAR(drawCuratorLocations), false]) then {
    _curatorModule setVariable [QGVAR(drawCuratorLocations), true];
    [_curatorModule] call BIS_fnc_drawCuratorLocations;
};
