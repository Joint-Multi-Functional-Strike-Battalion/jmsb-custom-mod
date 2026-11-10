#include "script_component.hpp"
/*
 * Author: YonV
 * Charges left on a vehicle's launchers, both sides together.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * Charges <NUMBER>
 *
 * Example:
 * [_tank] call jmfsb_aps_fnc_charges
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]]];
if (isNull _veh) exitWith { 0 };
(_veh getVariable [QGVAR(ammoL), 0]) + (_veh getVariable [QGVAR(ammoR), 0])
