#include "script_component.hpp"
/*
 * Author: JMSB
 * The sets a unit carries, as RF nodes to be: what RF recognises on him
 * (jmfsb_rf_fnc_carriedSets: the radio-slot set and a radio bag, profiles
 * from the items' own config), plus the vehicle set of his crew seat.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [[kind "sr" | "lr" | "veh", object, profile], ...] <ARRAY>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_radios
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};

private _out = ([_unit] call EFUNC(rf,carriedSets)) apply {[_x select 0, _unit, _x select 2]};

private _vehicle = [_unit] call FUNC(crewOf);
if (!isNull _vehicle) then {_out pushBack [NODE_VEH, _vehicle, VEHICLE_PROFILE]};

_out
