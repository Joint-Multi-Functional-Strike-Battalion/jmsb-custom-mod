#include "script_component.hpp"
/*
 * Author: YonV
 * The nearest of a list to a position.
 *
 * WRITTEN OUT RATHER THAN SORTED, because BIS_fnc_sortBy runs its comparison
 * block inside its OWN scope - the private the caller wanted to measure
 * against is not visible in there, and the block silently compares against nil.
 * nearObjects returns its own results in distance order and would not have
 * needed this at all; the two designator classes have to be searched
 * separately for an independent side, and concatenating two sorted lists gives
 * one unsorted one.
 *
 * Arguments:
 * 0: Candidates <ARRAY>
 * 1: Position <ARRAY>
 *
 * Return Value:
 * The nearest, objNull for an empty list <OBJECT>
 *
 * Public: No
 */

params [["_list", [], [[]]], ["_pos", [], [[]]]];

if (_list isEqualTo [] || {_pos isEqualTo []}) exitWith {objNull};

private _best = objNull;
private _bestD = 1e9;

{
    private _d = _x distance2D _pos;
    if (_d < _bestD) then {
        _bestD = _d;
        _best = _x;
    };
} forEach _list;

_best
