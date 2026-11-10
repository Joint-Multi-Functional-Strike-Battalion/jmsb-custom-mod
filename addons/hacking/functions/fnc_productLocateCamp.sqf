#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE CAMP: the enemy's camps and outposts, on the shrinking circle ladder.
 *
 * A camp is where the men who are not on the objective are. ALiVE's placement
 * stands them up on strategic clusters and the adapter reads them back, side
 * derived from who garrisons them now - so a camp you cleared and they
 * re-took is hostile again, and one they abandoned drops out (its side is
 * unknown, and the unknown are not hunted).
 *
 * Same ladder as everything else - see FUNC(ladderCircle) for the rules.
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

if (isNil QEFUNC(adapter_alive,camps)) exitWith {false};

private _pool = [];
{
    _x params ["_id", "_at", "", "_cside"];
    if (_cside isEqualTo sideUnknown || {_cside getFriend _side >= 0.6}) then {continue};
    _pool pushBack [_id, _at, _cside];
} forEach (call EFUNC(adapter_alive,camps));

if (isNil QGVAR(campLock)) then { GVAR(campLock) = createHashMap };
[_pool, _pos, _side, GVAR(campLock), "camp", "CAMP"] call FUNC(ladderCircle)
