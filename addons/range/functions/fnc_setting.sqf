#include "..\script_component.hpp"
/*
 * Author: YonV
 * A range's current choice for one setting - what the menu last set, public
 * on the range so every controller agrees, else the module's default.
 *
 * Arguments:
 * 0: Range (the module logic) <OBJECT>
 * 1: Setting: "mode", "duration", "count" or "exposure" <STRING>
 * 2: New value, to set it <NUMBER> (optional)
 *
 * Return Value:
 * The value <NUMBER>
 *
 * Example:
 * [_range, "duration"] call jmfsb_range_fnc_setting
 *
 * Public: No
 */

params [["_range", objNull, [objNull]], ["_key", "", [""]], ["_value", -1, [0]]];

private _var = format ["%1_%2", QGVAR(sel), _key];
if (_value >= 0) then {_range setVariable [_var, _value, true]};

_range getVariable [_var, (_range getVariable [QGVAR(cfg), createHashMap]) getOrDefault [_key, 0]]
