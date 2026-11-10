#include "..\script_component.hpp"
/*
 * Author: YonV
 * Server: removes a MOUT course's men (FUNC(moutCreate)), dead or alive.
 *
 * Arguments:
 * 0: Controller <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_ctrl", objNull, [objNull]]];

if (!isServer || {isNull _ctrl}) exitWith {};

{deleteVehicle _x} forEach (_ctrl getVariable [QGVAR(moutUnits), []]);
_ctrl setVariable [QGVAR(moutUnits), [], true];
