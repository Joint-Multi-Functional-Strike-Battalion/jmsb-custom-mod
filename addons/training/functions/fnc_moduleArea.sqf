#include "script_component.hpp"
/*
 * Author: YonV
 * JMSB - Training Area's module function. The module is read by the
 * TAC//TRAINING app (FUNC(areas)), not run: this only says once in the RPT,
 * on the server, which area it is and what it offers.
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
 * [_logic, [], true] call jmfsb_training_fnc_moduleArea
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
private _name = _logic getVariable ["name", ""];
private _type = (TA_TYPES param [_logic getVariable ["type", 0], ["", "?"]]) # 1;
private _grid = mapGridPosition _logic;
INFO_3("training area '%1' (%2) at %3",_name,_type,_grid);
