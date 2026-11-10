#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE JAMMER: the emitters holding the quiet up, plotted exactly.
 *
 * Exact rather than fuzzed, and for the same reason LOCATE AA is: a jammer is
 * a thing you go and switch off, and the work of finding it was paid for by
 * getting into the tower. What it buys is a choice - hack it and the zone
 * dies quietly, or blow it and everyone knows you were there.
 *
 * Arguments:
 * 0: Where the hack happened <ARRAY>
 * 1: Asking side <SIDE>
 *
 * Return Value:
 * Anything plotted <BOOL>
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]]];

if (isNil QEFUNC(hacking,ladderCircle)) exitWith {false};

// THE SAME LADDER ARTILLERY AND AIR DEFENCE RUN (user, 2026-08-31: "add these
// sites to the intel like the arty and aa sites"). This used to plot every
// emitter as an icon in one go, which is a different product from the other
// two: no narrowing, no lock, and - the part that mattered - no spotrep, so a
// located jammer never reached the COP and nobody who was not standing at the
// terminal ever heard about it.
//
// ladderCircle draws a circle that tightens with each hack, holds its lock on
// one site until that site is dead, and files the intel through
// its own registry off the label below.
private _pool = [];
{
    private _obj = _x param [ZONE_OBJ, objNull];
    if (isNull _obj || {!alive _obj}) then { continue };

    private _model = _x param [ZONE_MODEL, createHashMap];
    private _zside = _model getOrDefault ["side", sideUnknown];

    // Only somebody else's. A commander's own masts are not intel.
    if (_zside isNotEqualTo sideUnknown && {_zside getFriend _side >= 0.6}) then { continue };

    _pool pushBack [_x param [ZONE_ID, ""], getPosATL _obj, _zside];
} forEach (missionNamespace getVariable [QGVAR(jammers), []]);

if (_pool isEqualTo []) exitWith {false};

if (isNil QGVAR(jamLock)) then { GVAR(jamLock) = createHashMap };

[_pool, _pos, _side, GVAR(jamLock), "jam", "JAMMING"] call EFUNC(hacking,ladderCircle)
