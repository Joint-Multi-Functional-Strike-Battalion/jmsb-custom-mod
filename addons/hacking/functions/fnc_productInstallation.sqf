#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE INSTALLATION: the asymmetric commander's physical network - the
 * factory, the HQ, the depot, the roadblocks (new.md section 5).
 *
 * THE OTHER HALF OF THE ASYMMETRIC HUNT. TRACE NETWORK points at the men and
 * the houses they sleep in; this points at the things they need to keep
 * working. Both run the same ladder, so a section that keeps hacking closes on
 * one installation rather than being handed the set.
 *
 * The pool is ALiVE's own objective list, read through the adapter - jmfsb
 * places none of it and invents none of it, so a map whose asymmetric commander
 * has no installations returns empty and the product is never offered.
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

if (isNil QEFUNC(adapter_alive,installations)) exitWith {false};

// The adapter answers [id, pos, size, type]; the ladder wants [id, pos, side].
// An installation belongs to whichever asymmetric commander owns the ground,
// and the asking side is by definition not that one - a player only reaches
// this product by hacking inside asymmetric ground.
private _pool = ([] call EFUNC(adapter_alive,installations)) apply {
    _x params ["_id", "_at", "", "_type"];
    [format ["%1_%2", _type, _id], _at, sideUnknown]
};

if (isNil QGVAR(installLock)) then { GVAR(installLock) = createHashMap };

[_pool, _pos, _side, GVAR(installLock), "installation", "INSTALLATION"] call FUNC(ladderCircle)
