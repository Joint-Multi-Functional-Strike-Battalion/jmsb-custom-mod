#include "script_component.hpp"
/*
 * Author: YonV
 * A rank as the three letters it is written as on a roster.
 *
 * The engine spells them out - SERGEANT, LIEUTENANT - and a rail 0.15 of the
 * screen wide has no room to spell a rank and then a name after it. Three
 * letters is what a roster uses and what everyone reads anyway.
 *
 * Arguments:
 * 0: Rank, as `rank _unit` gives it <STRING>
 *
 * Return Value:
 * Three-letter abbreviation, or the input if it is not a rank <STRING>
 *
 * Example:
 * private _short = [rank player] call jmfsb_tacpad_fnc_rankShort
 *
 * Public: No
 */

params [["_rank", "", [""]]];

switch (toUpper _rank) do {
    case "PRIVATE": {"PVT"};
    case "CORPORAL": {"CPL"};
    case "SERGEANT": {"SGT"};
    case "LIEUTENANT": {"LT"};
    case "CAPTAIN": {"CPT"};
    case "MAJOR": {"MAJ"};
    case "COLONEL": {"COL"};
    default {toUpper _rank};
};
