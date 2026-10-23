#include "script_component.hpp"
/*
 * Author: JMSB
 * A ten-digit grid - five an axis, one metre - for a world position.
 *
 * The engine's own square (mapGridPosition) gives the leading digits, so the
 * grid agrees with what is printed on the map; the metres inside the square
 * come from where its lines were found to fall (FUNC(gridCalibrate), worked
 * out on first use and kept). An axis that counts the other way - northing
 * running down the sheet on some terrains - measures from the other edge.
 *
 * Arguments:
 * 0: World position <ARRAY>
 *
 * Return Value:
 * "EEEEE NNNNN", or the engine's grid where it cannot be refined <STRING>
 *
 * Example:
 * [getPosATL player] call jmfsb_maptools_fnc_gridText
 *
 * Public: Yes
 */

params [["_pos", [], [[]]]];

if (count _pos < 2) exitWith {""};

if (GVAR(gridCal) isEqualTo []) then {
    GVAR(gridCal) = [] call FUNC(gridCalibrate);
};
GVAR(gridCal) params ["_square", "_phaseX", "_phaseY", "_dirX", "_dirY", "_half"];

private _cell = mapGridPosition _pos;
if (_square <= 0 || {count _cell != 2 * _half}) exitWith {_cell};

private _digits = [];
{
    _x params ["_index", "_value", "_phase", "_dir"];
    private _in = (_value - _phase) mod _square;
    if (_in < 0) then {_in = _in + _square};
    if (_dir < 0) then {_in = _square - _in};
    private _metres = (_index * _square + ((floor _in) min (_square - 1))) mod GRID_SPAN;
    _digits pushBack ([_metres, GRID_DIGITS] call CBA_fnc_formatNumber);
} forEach [
    [parseNumber (_cell select [0, _half]), _pos # 0, _phaseX, _dirX],
    [parseNumber (_cell select [_half, _half]), _pos # 1, _phaseY, _dirY]
];

_digits joinString " "
