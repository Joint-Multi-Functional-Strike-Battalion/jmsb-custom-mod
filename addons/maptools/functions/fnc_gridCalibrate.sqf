#include "script_component.hpp"
/*
 * Author: JMSB
 * Works out, once per mission, where this terrain's grid squares fall - so a
 * ten-digit grid can be built on the engine's own coarse one.
 *
 * WHY NOT THE CONFIG. CfgWorlds' Grid class gives offsets and steps, and terrain
 * makers fill them in every way there is: origin top or bottom, northing up or
 * down, offsets that are not a whole number of squares. mapGridPosition is
 * what the map itself prints, so it is right by definition; this asks it.
 *
 * From the middle of the world: the square size from how many digits an axis
 * gets (three digits, 100 m squares), which way each axis counts from whether
 * one square further on reads higher or lower, and where the line between two
 * squares sits from a bisection to a fraction of a metre.
 *
 * A grid that is not all digits in two equal halves - a lettered one - gets a
 * zero square, and FUNC(gridText) falls back to the engine's string as is.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [square metres, x phase, y phase, x direction, y direction, digits an axis] <ARRAY>
 *
 * Example:
 * [] call jmfsb_maptools_fnc_gridCalibrate
 *
 * Public: No
 */

private _unusable = [0, 0, 0, 1, 1, 0];

private _mid = worldSize / 2;
private _probe = mapGridPosition [_mid, _mid];
private _len = count _probe;

if (_len == 0 || {_len mod 2 != 0} || {(_probe splitString "0123456789") isNotEqualTo []}) exitWith {_unusable};

private _half = _len / 2;
if (_half > GRID_DIGITS) exitWith {_unusable};

private _square = 10 ^ (GRID_DIGITS - _half);

private _fnc_index = {
    params ["_axis", "_value"];
    private _probeAt = [_mid, _mid];
    _probeAt set [_axis, _value];
    parseNumber ((mapGridPosition _probeAt) select [_axis * _half, _half])
};

private _phases = [];
private _dirs = [];
{
    private _axis = _x;
    private _lo = _mid;
    private _hi = _mid + _square;
    private _first = [_axis, _lo] call _fnc_index;

    _dirs pushBack ([1, -1] select (([_axis, _hi] call _fnc_index) < _first));

    for "_i" from 1 to GRID_BISECT do {
        private _split = (_lo + _hi) / 2;
        if (([_axis, _split] call _fnc_index) == _first) then {_lo = _split} else {_hi = _split};
    };
    _phases pushBack (_hi mod _square);
} forEach [0, 1];

[_square] + _phases + _dirs + [_half]
