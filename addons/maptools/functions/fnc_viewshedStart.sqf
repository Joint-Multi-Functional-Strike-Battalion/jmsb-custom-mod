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

// AT MOST VS_CELLS_MAX CELLS (review P7, 2026-10-31). Every cell is two
// triangles redrawn each frame the map is open; the finest cell at the widest
// radius made ~27,000 cells, ~160,000 vertices a frame. Past the cap the cell
// grows (fewer, wider rings) until the grid fits, and the radius stays what
// was asked.
if (_rings * _sectors > VS_CELLS_MAX) then {
    _rings = floor (VS_CELLS_MAX / _sectors) max 1;
    _cell = _radius / _rings;
    _sectors = (VS_SECTORS_MIN max (ceil (2 * pi * _radius / _cell))) min VS_SECTORS_MAX;
};

private _centre = [_pos # 0, _pos # 1, 0];
private _eye = AGLToASL [_pos # 0, _pos # 1, VS_EYE];

GVAR(viewshed) = [_centre, _radius, _rings, _sectors, _eye, 0];
GVAR(vsSeen) = [];
GVAR(vsHidden) = [];

GVAR(vsHandle) = [LINKFUNC(viewshedStep), 0, []] call CBA_fnc_addPerFrameHandler;
