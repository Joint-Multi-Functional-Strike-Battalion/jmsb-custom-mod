#include "script_component.hpp"
/*
 * Author: JMSB
 * One slice of a viewshed: the next VS_RAYS_PER_FRAME cells, each traced and
 * sorted into the seen or the hidden triangle list. Removes itself when the
 * last cell is done.
 *
 * TERRAIN FIRST, THEN THINGS. terrainIntersectASL is cheap and settles most of
 * the dead ground; only a ray the ground lets through is asked of
 * lineIntersectsSurfaces against the view geometry - buildings, walls, trees.
 *
 * A cell is a ring segment drawn as two triangles off its four corners. The
 * innermost ring's inner corners are all the centre, which is a fan, which is
 * what it should be.
 *
 * Arguments:
 * 0: Per-frame handler arguments (unused) <ARRAY>
 * 1: Per-frame handler id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], _handle] call jmfsb_maptools_fnc_viewshedStep
 *
 * Public: No
 */

params ["", ["_handle", -1, [0]]];

if (GVAR(viewshed) isEqualTo []) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    GVAR(vsHandle) = -1;
};

GVAR(viewshed) params ["_centre", "_radius", "_rings", "_sectors", "_eye", "_next"];

private _cell = _radius / _rings;
private _arc = DEG_PER_TURN / _sectors;
private _total = _rings * _sectors;
private _last = (_next + VS_RAYS_PER_FRAME) min _total;

for "_i" from _next to (_last - 1) do {
    private _inner = (floor (_i / _sectors)) * _cell;
    private _outer = _inner + _cell;
    private _from = (_i mod _sectors) * _arc;
    private _to = _from + _arc;

    private _target = _centre getPos [_inner + _cell / 2, _from + _arc / 2];
    private _aim = AGLToASL [_target # 0, _target # 1, VS_TARGET];

    private _seen = !(terrainIntersectASL [_eye, _aim])
        && {(lineIntersectsSurfaces [_eye, _aim, objNull, objNull, true, 1, "VIEW", "NONE"]) isEqualTo []};

    private _a = _centre getPos [_inner, _from];
    private _b = _centre getPos [_outer, _from];
    private _c = _centre getPos [_outer, _to];
    private _d = _centre getPos [_inner, _to];

    ([GVAR(vsHidden), GVAR(vsSeen)] select _seen) append [_a, _b, _c, _a, _c, _d];
};

GVAR(viewshed) set [5, _last];

if (_last >= _total) then {
    [_handle] call CBA_fnc_removePerFrameHandler;
    GVAR(vsHandle) = -1;
};
