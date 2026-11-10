#include "script_component.hpp"
/*
 * Author: YonV
 * The stick split across the passes, evenly and in squad order (user,
 * 2026-10-30: "if the window is small drop 1/2 team first pass then the plane
 * circles around for second pass").
 *
 * Arguments:
 * 0: The jumpers, in order <ARRAY>
 * 1: Passes <NUMBER>
 *
 * Return Value:
 * One array of jumpers per pass <ARRAY>
 *
 * Example:
 * [units group player, 2] call jmfsb_jumpmaster_fnc_stick
 *
 * Public: No
 */

params [["_jumpers", [], [[]]], ["_passes", 1, [0]]];

_passes = (round _passes) max PASSES_MIN min PASSES_MAX;
private _per = ceil ((count _jumpers) / _passes) max 1;
private _out = [];
for "_i" from 0 to (_passes - 1) do {
    _out pushBack (_jumpers select [_i * _per, _per]);
};
_out
