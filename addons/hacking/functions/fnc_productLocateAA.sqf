#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE AA: every hostile air-defence piece, plotted exactly.
 *
 * Exact on purpose. Air defence is hunted to be UN-INTEGRATED (new.md
 * section 1) - a fuzzy SAM ring is a navigation hazard rather than a target,
 * and the work of finding it was already paid for by getting into the tower.
 *
 * The plot is a SNAPSHOT at hack time: the profile may move afterwards and
 * the map does not follow it. Same grammar as every other product.
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

if (isNil QEFUNC(adapter_alive,aaTargets)) exitWith {false};

private _pool = (call EFUNC(adapter_alive,aaTargets)) select {
    (_x select 2) getFriend _side < 0.6
};

// The air-defence stopgap that used to join the pool here had no producer
// in the repo, and the adapter now reads every anti-air-capable profile
// ALiVE runs, placement-registered or not - the pool above is the lot.

// EXACT ICONS FOR THE WHOLE POOL was what this did, which handed over every
// air-defence system on the map for one hack and left nothing to work for.
// Same ladder as artillery now - see FUNC(ladderCircle) for the rules.
if (isNil QGVAR(aaLock)) then { GVAR(aaLock) = createHashMap };

[_pool, _pos, _side, GVAR(aaLock), "aa", "AIR DEFENCE"] call FUNC(ladderCircle)
