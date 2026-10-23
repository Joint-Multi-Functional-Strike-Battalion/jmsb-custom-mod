#include "script_component.hpp"
/*
 * Author: JMSB
 * What the world takes out of a link between two points: log-distance path
 * loss, terrain and clutter. Symmetric, so the mesh casts it once per pair
 * and band and uses it in both directions.
 *
 * THIS IS THE COST. Three terrainIntersectASL and one or two
 * lineIntersectsSurfaces per pair; everything else in the budget is
 * arithmetic. jmfsb_rf_fnc_edge caches the result and reuses it until an end
 * moves, and the mesh prefilters pairs beyond the band's range, so with 60
 * players the casts are paid for moving pairs in range only.
 *
 * Terrain: the line is cut into three samples (segments); each the ground
 * blocks costs the terrain setting. Clutter: one hit per object, walls and
 * trees priced apart (tree and bush models start t_ / b_); men and vehicles
 * are not clutter. Past CLUTTER_FULL_M only the stretch at each end is cast.
 *
 * Arguments:
 * 0: End A ASL <ARRAY>
 * 1: End B ASL <ARRAY>
 * 2: Band <STRING>
 * 3: Object at A, ignored by the clutter cast <OBJECT>
 * 4: Object at B, ignored by the clutter cast <OBJECT>
 *
 * Return Value:
 * [path loss dB, terrain dB, clutter dB] <ARRAY>
 *
 * Example:
 * [eyePos player, getPosASL _relay, "UHF", player, _relay] call jmfsb_rf_fnc_pathLoss
 *
 * Public: No
 */

params [
    ["_a", [0, 0, 0], [[]], 3],
    ["_b", [0, 0, 0], [[]], 3],
    ["_band", "VHF", [""]],
    ["_objA", objNull, [objNull]],
    ["_objB", objNull, [objNull]]
];

private _dist = _a vectorDistance _b;
private _path = [_dist, _band] call FUNC(pathLossFree);

// TERRAIN - three samples
private _blocked = 0;
private _step = (_b vectorDiff _a) vectorMultiply (1 / TERRAIN_SAMPLES);
for "_i" from 0 to (TERRAIN_SAMPLES - 1) do {
    private _p0 = _a vectorAdd (_step vectorMultiply _i);
    private _p1 = _a vectorAdd (_step vectorMultiply (_i + 1));
    if (terrainIntersectASL [_p0, _p1]) then {_blocked = _blocked + 1};
};
private _terrain = _blocked * GVAR(terrainDb);

// CLUTTER - counted per object
private _segments = if (_dist <= CLUTTER_FULL_M) then {
    [[_a, _b]]
} else {
    private _dir = vectorNormalized (_b vectorDiff _a);
    [
        [_a, _a vectorAdd (_dir vectorMultiply CLUTTER_END_M)],
        [_b vectorAdd (_dir vectorMultiply -CLUTTER_END_M), _b]
    ]
};
private _clutter = 0;
{
    _x params ["_p0", "_p1"];
    {
        private _obj = _x select 2;
        if (isNull _obj || {_obj isKindOf "AllVehicles"}) then {continue};
        private _model = toLower ((getModelInfo _obj) select 0);
        private _isTree = (TREE_MODEL_PREFIXES findIf {(_model find _x) == 0}) >= 0;
        _clutter = _clutter + ([GVAR(wallDb), GVAR(treeDb)] select _isTree);
    } forEach (lineIntersectsSurfaces [_p0, _p1, _objA, _objB, true, CLUTTER_MAX_HITS, "GEOM", "NONE", true]);
} forEach _segments;

[_path, _terrain, _clutter]
