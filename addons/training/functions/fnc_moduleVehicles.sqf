#include "script_component.hpp"
/*
 * Author: YonV
 * JMSB - Vehicle Range's module function. The module is read by the
 * TAC//TRAINING app (FUNC(vehRanges)), not run: this only says once in the
 * RPT, on the server, which range it is and what it holds.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [], true] call jmfsb_training_fnc_moduleVehicles
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
private _name = _logic getVariable ["name", ""];
private _classes = _logic getVariable ["vehicles", ""];
private _grid = mapGridPosition _logic;
INFO_3("vehicle range '%1' at %2: %3",_name,_grid,_classes);
