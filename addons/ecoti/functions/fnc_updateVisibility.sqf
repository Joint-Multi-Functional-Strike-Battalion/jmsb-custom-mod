#include "script_component.hpp"
/*
 * Author: JMSB
 * Re-checks line of sight for one slice of the candidates. Called every
 * VIS_TICK; the slices rotate, so each target is refreshed every
 * VIS_TICK * VIS_SLICES seconds and no single frame checks them all.
 *
 * Line of sight only: a target is SEEN from the check that shows VIS_SHOW of
 * him until the one that shows less than VIS_MIN - never held past it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_updateVisibility
 *
 * Public: No
 */

private _all = GVAR(men) + GVAR(vehicles);
private _count = count _all;
if (_count == 0) exitWith {};

private _slice = ceil (_count / VIS_SLICES);
private _start = GVAR(visCursor) % _count;

for "_i" from 0 to (_slice - 1) do {
    private _target = _all select ((_start + _i) % _count);
    if (!isNull _target) then {
        private _vis = [_target] call FUNC(targetVisibility);
        private _seen = [_vis >= VIS_SHOW, _vis >= VIS_MIN] select (_target getVariable [QGVAR(seen), false]);
        _target setVariable [QGVAR(seen), _seen];
    };
};

GVAR(visCursor) = (_start + _slice) % _count;
