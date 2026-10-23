#include "script_component.hpp"
/*
 * Author: JMSB
 * The "tasks" code of provider "fires": the picked asset's own task, with its
 * steppers sized for it - its ordnance by name and rounds left, its gun count,
 * the missiles or munitions it can still send.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: The asset's row <ARRAY>
 *
 * Return Value:
 * Task declarations <ARRAY>
 *
 * Example:
 * ["fires:0", _row] call jmfsb_support_fires_fnc_tasks
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_row", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[]};

[_logic getVariable [QGVAR(type), _row param [1, ""]], _logic] call FUNC(taskDecls)
