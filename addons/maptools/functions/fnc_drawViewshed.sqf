#include "script_component.hpp"
/*
 * Author: JMSB
 * The viewshed's cells, as two filled triangle lists - what the point sees in
 * the accent, what it does not in the ink - plus its outer edge and, while it
 * is still filling, how far through it is.
 *
 * TWO CALLS A FRAME, NOT ONE A CELL. FUNC(viewshedStep) sorts each finished
 * cell's two triangles into one list or the other as it goes, so a viewshed of
 * thousands of cells costs the draw the same as one of ten.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: Ink <ARRAY>
 * 2: Accent <ARRAY>
 * 3: Label size <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map, _ink, _accent, 0.045] call jmfsb_maptools_fnc_drawViewshed
 *
 * Public: No
 */

params ["_map", "_ink", "_accent", "_size"];

if (GVAR(viewshed) isEqualTo []) exitWith {};
GVAR(viewshed) params ["_centre", "_radius", "_rings", "_sectors", "", "_next"];

if (GVAR(vsHidden) isNotEqualTo []) then {
    _map drawTriangle [GVAR(vsHidden), [_ink # 0, _ink # 1, _ink # 2, VS_ALPHA_HIDDEN], FILL_SOLID];
};
if (GVAR(vsSeen) isNotEqualTo []) then {
    _map drawTriangle [GVAR(vsSeen), [_accent # 0, _accent # 1, _accent # 2, VS_ALPHA_SEEN], FILL_SOLID];
};

_map drawEllipse [_centre, _radius, _radius, 0, _accent, ""];
_map drawIcon [GVAR(dotIcon), _accent, _centre, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];

private _total = _rings * _sectors;
if (_next < _total) then {
    [_map, _centre, format ["  VIEWSHED %1%2", floor (PERCENT * _next / _total), "%"], _accent, _size] call FUNC(label);
};
