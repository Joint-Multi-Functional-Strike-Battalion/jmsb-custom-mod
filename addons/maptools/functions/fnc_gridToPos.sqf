#include "script_component.hpp"
/*
 * Author: YonV
 * A typed grid reference - 6, 8 or 10 digits, spaces allowed - to a position
 * on this terrain, the centre of the square it names. The inverse of
 * FUNC(gridText), on the same calibration (FUNC(gridCalibrate)), so it is
 * right whichever way the terrain's grid counts. For the ARTY calculator
 * (user, 2026-10-25: "a good arty calculator").
 *
 * Arguments:
 * 0: Grid reference <STRING>
 *
 * Return Value:
 * Position [x, y, 0], [] when it is not a grid on this map <ARRAY>
 *
 * Example:
 * ["034 127"] call jmfsb_maptools_fnc_gridToPos
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

private _digits = (toArray _text select {_x >= 48 && _x <= 57}) apply {toString [_x]};
private _n = count _digits;
if (_n < 2 || {_n mod 2 != 0} || {_n / 2 > GRID_DIGITS}) exitWith {[]};
private _half = _n / 2;
private _unit = 10 ^ (GRID_DIGITS - _half);

if (GVAR(gridCal) isEqualTo []) then {
    GVAR(gridCal) = [] call FUNC(gridCalibrate);
};
GVAR(gridCal) params ["_square", "_phaseX", "_phaseY", "_dirX", "_dirY", "_cellHalf"];

private _mid = worldSize / 2;
private _out = [0, 0, 0];
private _ok = true;
{
    _x params ["_axis", "_typed", "_phase", "_dir"];
    // The metres the grid gives at the middle of the map, as FUNC(gridText)
    // works them out - then the typed metres are that far away along the axis.
    private _probeAt = [_mid, _mid];
    private _cell = mapGridPosition _probeAt;
    private _ref = _mid;
    private _refMetres = _mid;
    if (_square > 0 && {count _cell == 2 * _cellHalf}) then {
        private _index = parseNumber (_cell select [_axis * _cellHalf, _cellHalf]);
        private _in = (_ref - _phase) mod _square;
        if (_in < 0) then {_in = _in + _square};
        if (_dir < 0) then {_in = _square - _in};
        _refMetres = (_index * _square + _in) mod GRID_SPAN;
    };
    private _want = parseNumber (_typed joinString "") * _unit + _unit / 2;
    private _delta = (_want - _refMetres) mod GRID_SPAN;
    if (_delta > GRID_SPAN / 2) then {_delta = _delta - GRID_SPAN};
    if (_delta < -GRID_SPAN / 2) then {_delta = _delta + GRID_SPAN};
    private _v = _ref + _dir * _delta;
    if (_v < 0 || {_v > worldSize}) then {_ok = false};
    _out set [_axis, _v];
} forEach [
    [0, _digits select [0, _half], _phaseX, _dirX],
    [1, _digits select [_half, _half], _phaseY, _dirY]
];

[[], _out] select _ok
