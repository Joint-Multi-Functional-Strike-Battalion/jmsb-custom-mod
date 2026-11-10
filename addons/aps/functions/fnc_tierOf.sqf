#include "script_component.hpp"
/*
 * Author: YonV
 * The tier a vehicle is fitted to: its faction's, from the tier table, with
 * the module's and the setting's overrides on top, and the default tier
 * for a faction nobody has placed.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * Tier 0-4 <NUMBER>
 *
 * Example:
 * [_tank] call jmfsb_aps_fnc_tierOf
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]]];
if (isNull _veh) exitWith { 0 };

private _fac = toLower (_veh getVariable [QGVAR(faction), getText (configOf _veh >> "faction")]);
if (_fac isEqualTo "") exitWith { GVAR(defaultTier) };

private _t = GVAR(tierOverride) get _fac;
if (isNil "_t") then { _t = GVAR(tierTable) get _fac };
if (isNil "_t") then { _t = GVAR(defaultTier) };
_t
