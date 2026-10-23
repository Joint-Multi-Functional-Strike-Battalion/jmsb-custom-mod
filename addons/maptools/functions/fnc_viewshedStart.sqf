#include "script_component.hpp"
/*
 * Author: JMSB
 * Starts working out line of sight from a point, out to the radius setting,
 * replacing any viewshed already on the map.
 *
 * A COARSE POLAR GRID. Rings a cell apart (QGVAR(viewshedCell)) out to the
 * radius (QGVAR(viewshedRadius)), each cut into sectors about a cell wide at
 * the outer ring, held between VS_SECTORS_MIN and VS_SECTORS_MAX. One ray per
 * cell, eye height at the point to target height at the cell's middle.
 *
 * IN SLICES. FUNC(viewshedStep) runs as a per-frame handler and traces
 * VS_RAYS_PER_FRAME rays a frame, nearest ring first, so the shading grows
 * out from the point and no frame ever stalls on it.
 *
 * Arguments:
 * 0: World position <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [getPosATL player] call jmfsb_maptools_fnc_viewshedStart
 *
 * Public: Yes
 */

params [["_pos", [], [[]]]];

if (count _pos < 2) exitWith {};

[] call FUNC(viewshedCancel);

private _cell = GVAR(viewshedCell) max VS_CELL_MIN;
private _rings = ceil ((GVAR(viewshedRadius) max _cell) / _cell);
private _radius = _rings * _cell;
private _sectors = (VS_SECTORS_MIN max (ceil (2 * pi * _radius / _cell))) min VS_SECTORS_MAX;

private _centre = [_pos # 0, _pos # 1, 0];
private _eye = AGLToASL [_pos # 0, _pos # 1, VS_EYE];

GVAR(viewshed) = [_centre, _radius, _rings, _sectors, _eye, 0];
GVAR(vsSeen) = [];
GVAR(vsHidden) = [];

GVAR(vsHandle) = [LINKFUNC(viewshedStep), 0, []] call CBA_fnc_addPerFrameHandler;
