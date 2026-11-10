#include "script_component.hpp"
/*
 * Author: YonV
 * Packs a deployed drop back into a carried case, so a section can move its
 * collection point when the base moves.
 *
 * Arguments:
 * 0: The drop <OBJECT>
 * 1: The player <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_drop", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _drop || {isNull _unit}) exitWith {};

if !(_unit canAdd QGVAR(dropItem)) exitWith {
    ["Intel Drop", "No room for it.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
};

deleteVehicle _drop;
_unit addItem QGVAR(dropItem);

["Intel Drop", "Packed up."] call EFUNC(notify,notify);
