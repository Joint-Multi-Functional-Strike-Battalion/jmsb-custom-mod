#include "script_component.hpp"
/*
 * Author: JMSB
 * The protractor: a rose around its centre - a tick every ten degrees, a long
 * one every thirty, N E S W outside - and the arm. While the arm is free it
 * follows the cursor and reads bearing and distance to it; locked, it stands
 * at its bearing and reads that.
 *
 * THE ROSE IS A FIXED SIZE ON SCREEN, not in metres. A rose a kilometre wide is
 * a dot at one zoom and the whole screen at another; this one is measured off
 * the map's own scale every frame, so it is always a hand's width.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: Colour <ARRAY>
 * 2: Label size <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map, _accent, 0.045] call jmfsb_maptools_fnc_drawProtractor
 *
 * Public: No
 */

params ["_map", "_color", "_size"];

GVAR(protractor) params [["_at", []], ["_arm", -1]];
if (_at isEqualTo []) exitWith {};

private _centre = [_at # 0, _at # 1, 0];
private _onScreen = _map ctrlMapWorldToScreen _centre;
private _radius = _centre distance2D (_map ctrlMapScreenToWorld [(_onScreen # 0) + PROT_RADIUS * (_size / LABEL_SIZE), _onScreen # 1]);

_map drawEllipse [_centre, _radius, _radius, 0, _color, ""];

for "_deg" from 0 to (DEG_PER_TURN - PROT_TICK_MINOR) step PROT_TICK_MINOR do {
    private _len = [PROT_TICK_MINOR_K, PROT_TICK_MAJOR_K] select (_deg mod PROT_TICK_MAJOR == 0);
    _map drawLine [_centre getPos [_radius * (1 - _len), _deg], _centre getPos [_radius, _deg], _color];
};

{
    _x params ["_letter", "_deg"];
    [_map, _centre getPos [_radius * PROT_LABEL_K, _deg], _letter, _color, _size, "center"] call FUNC(label);
} forEach PROT_CARDINALS;

// The arm. Free, it is a measured leg to the cursor; locked, a line to the rim
// with its bearing past the end.
if (_arm < 0) exitWith {
    if (GVAR(cursor) isEqualTo []) exitWith {};
    [_map, _centre, GVAR(cursor), _color, _size] call FUNC(drawLeg);
};

private _rim = _centre getPos [_radius, _arm];
_map drawLine [_centre, _rim, _color];
[_map, _centre getPos [_radius * PROT_LABEL_K, _arm], [_arm] call FUNC(bearingText), _color, _size, "center"] call FUNC(label);
