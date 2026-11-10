#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE ARTILLERY: the nearest hostile battery, on the shrinking ladder.
 *
 * Fuzzed rather than exact, and shrinking per hack against the SAME battery -
 * the guns are a bigger prize than a radar, so finding them is work rather
 * than a single button.
 *
 * THE THROW IS CACHED PER BATTERY PER TIER. Re-hacking for the same tier
 * re-draws the identical circle instead of rolling a luckier centre, which is
 * the rule the target circles already follow. Profiles are not objects and
 * cannot carry an object variable, so the cache is a hashmap keyed by
 * profileID, here on the server.
 *
 * Arguments:
 * 0: Where the hack happened <ARRAY>
 * 1: Asking side <SIDE>
 *
 * Return Value:
 * Anything drawn <BOOL>
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]]];

if (isNil QEFUNC(adapter_alive,artyTargets)) exitWith {false};

private _pool = ([sideUnknown] call EFUNC(adapter_alive,artyTargets)) select {
    (_x select 2) getFriend _side < 0.6
};

// The nearest battery used to be re-picked on EVERY hack, so walking a few
// hundred metres started the ladder again somewhere else and the circle never
// closed. The lock now holds until the battery is destroyed.
if (isNil QGVAR(artyLock)) then { GVAR(artyLock) = createHashMap };

[_pool, _pos, _side, GVAR(artyLock), "arty", "ARTILLERY"] call FUNC(ladderCircle)
