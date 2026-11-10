#include "script_component.hpp"
/*
 * Author: YonV
 * Records that this operator has just broken into a net, so the next one costs
 * more - see FUNC(netFailChance).
 *
 * Written whether the break SUCCEEDED or not. Being caught is not what raises
 * the temperature; getting into the net at all is, and a player who could reset
 * the ramp by failing on purpose would have found the cheapest exploit on the
 * screen.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_hacking_fnc_netBroken
 *
 * Public: No
 */

private _hist = missionNamespace getVariable [QGVAR(netHistory), []];
_hist pushBack CBA_missionTime;

// Bounded: the window throws away anything old on every read, and a list that
// only ever grows is a leak on a four-hour operation.
if (count _hist > 64) then { _hist deleteAt 0 };

GVAR(netHistory) = _hist;
