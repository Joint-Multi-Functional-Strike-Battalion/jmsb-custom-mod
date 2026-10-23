#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes an asset's target marker off every map and out of the JIP queue
 * (FUNC(mark)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_unmark
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};

private _id = _logic getVariable [QGVAR(id), -1];
[format ["%1_mark_%2", QUOTE(ADDON), _id]] call CBA_fnc_removeGlobalEventJIP;
[QGVAR(unmark), [_id]] call CBA_fnc_globalEvent;
