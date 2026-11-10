#include "script_component.hpp"
/*
 * Author: YonV
 * A side as ALiVE spells it: "WEST", "EAST", "GUER", "CIV".
 *
 * This conversion was written nine times across the mod, and the copies had
 * already drifted - four different defaults for the same unknown side. It is
 * ALiVE's vocabulary rather than Arma's (`str west` gives "WEST" but `str
 * independent` gives "GUER" only by luck of the engine's naming), so it is
 * worth stating once and deliberately.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: What an unrecognised side returns <STRING> (optional, default "")
 *
 * Return Value:
 * ALiVE's side text <STRING>
 *
 * Example:
 * [east] call jmfsb_common_fnc_sideToText
 */

params [["_side", sideUnknown, [sideUnknown]], ["_default", "", [""]]];

switch (_side) do {
    case west: {"WEST"};
    case east: {"EAST"};
    case independent: {"GUER"};
    case civilian: {"CIV"};
    default {_default};
};
