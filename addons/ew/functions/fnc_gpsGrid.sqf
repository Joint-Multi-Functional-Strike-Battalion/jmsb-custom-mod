#include "script_component.hpp"
/*
 * Author: JMSB
 * A man's GPS grid as a status line reads it - the getter for grid readouts
 * outside this addon (the devices' tablet bar "GRID ..."): the engine's grid
 * of his GPS position with its two halves apart ("041 116"), " SUSPECT"
 * after it when an anti-spoof set flags the fix, or "NO FIX" when the GPS is
 * denied. A spoofed set reads its false grid and says nothing.
 *
 * Arguments:
 * 0: Unit (optional, default the player) <OBJECT>
 *
 * Return Value:
 * "041 116", "041 116 SUSPECT" or "NO FIX" <STRING>
 *
 * Example:
 * format ["GRID %1", [call CBA_fnc_currentUnit] call jmfsb_ew_fnc_gpsGrid]
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

([_unit] call FUNC(gpsOf)) params ["_state", "", "_pos"];

if (_state isEqualTo GPS_NOFIX) exitWith {GPS_NOFIX};

private _grid = mapGridPosition _pos;
private _half = floor (count _grid / 2);
private _text = format ["%1 %2", _grid select [0, _half], _grid select [_half]];
if (_state isEqualTo GPS_SUSPECT) then {_text = _text + " " + GPS_SUSPECT};
_text
