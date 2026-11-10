#include "script_component.hpp"
/*
 * Author: YonV
 * The gun a carrier sets up: the first class in its GVAR(weapons)[] that this
 * mod set has - the Western Sahara Hunter-SP launcher on the M-ATVs, falling
 * back to the Mk6 mortar without the CDLC.
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 *
 * Return Value:
 * Vehicle class, "" for none <STRING>
 *
 * Example:
 * [_veh] call jmfsb_artydeploy_fnc_weaponClass
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

private _list = getArray (configOf _veh >> QGVAR(weapons));
private _i = _list findIf {isClass (configFile >> "CfgVehicles" >> _x)};
_list param [_i, ""]
