#include "script_component.hpp"
/*
 * Author: YonV
 * Whether the flight control holds a helicopter now, and where it is in its
 * work (FUNC(heliTake): approach, hover, land, down). For the watches of the
 * other providers - logistics' sling set-down waits for the hover to be
 * reached - so none has to read the control's own state or guess from the
 * airframe's position.
 *
 * Arguments:
 * 0: The helicopter <OBJECT>
 *
 * Return Value:
 * [held <BOOL>, phase <STRING> - "" when not held, how long held (s) <NUMBER>] <ARRAY>
 *
 * Example:
 * ([_veh] call jmfsb_support_air_fnc_heliHeld) params ["_held", "_phase"]
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]]];

private _st = _veh getVariable [QGVAR(flight), createHashMap];
if (isNull _veh || count _st isEqualTo 0) exitWith {[false, "", 0]};

[true, _st getOrDefault ["phase", ""], CBA_missionTime - (_st getOrDefault ["took", CBA_missionTime])]
