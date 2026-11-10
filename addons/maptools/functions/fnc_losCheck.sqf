#include "script_component.hpp"
/*
 * Author: YonV
 * LINE OF SIGHT between two points on the map: from a man's eyes at the
 * first (VS_EYE over the ground) to a man's chest at the second (VS_TARGET),
 * the viewshed's own heights. The ground is asked first
 * (terrainIntersectASL); only a line the ground lets through is asked of
 * the view geometry (lineIntersectsSurfaces). Blocked, the answer names
 * where: the first sample along the line that is under the terrain, or the
 * surface hit.
 *
 * Arguments:
 * 0: From, world position <ARRAY>
 * 1: To, world position <ARRAY>
 *
 * Return Value:
 * 0: Clear <BOOL>
 * 1: Where the line is blocked, ASL; [] when clear <ARRAY>
 *
 * Example:
 * ([_from, _to] call jmfsb_maptools_fnc_losCheck) params ["_clear", "_blockedAt"]
 *
 * Public: Yes
 */

params [["_from", [], [[]]], ["_to", [], [[]]]];

if (count _from < 2 || {count _to < 2}) exitWith {[false, []]};

private _a = [_from select 0, _from select 1, (getTerrainHeightASL _from) + VS_EYE];
private _b = [_to select 0, _to select 1, (getTerrainHeightASL _to) + VS_TARGET];
private _len = _a vectorDistance _b;
if (_len <= 0) exitWith {[true, []]};

if (terrainIntersectASL [_a, _b]) exitWith {
    private _dir = vectorNormalized (_b vectorDiff _a);
    private _at = [];
    for "_d" from LOS_STEP to _len step LOS_STEP do {
        private _p = _a vectorAdd (_dir vectorMultiply _d);
        if ((_p select 2) <= getTerrainHeightASL _p) exitWith {_at = _p};
    };
    if (_at isEqualTo []) then {_at = _b};
    [false, _at]
};

private _hits = lineIntersectsSurfaces [_a, _b, objNull, objNull, true, 1, "GEOM", "NONE"];
if (_hits isEqualTo []) exitWith {[true, []]};

[false, (_hits select 0) select 0]
