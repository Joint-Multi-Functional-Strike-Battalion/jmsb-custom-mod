#include "script_component.hpp"
/*
 * Author: YonV
 * The side behind a side name, however the caller spells it.
 *
 * Accepts ALiVE's vocabulary ("GUER"), Arma's ("RESISTANCE"), the mod's own
 * module attributes ("INDEPENDENT") and the friendly forms a mission maker
 * types into a module field ("independent", "blufor", "opfor"), because all of
 * those already appear in this codebase's module controllers and each one used
 * to be handled by its own switch with its own default.
 *
 * The default is an ARGUMENT, not a constant. The five call sites this
 * replaces disagreed about whether an unknown string meant east, independent
 * or sideUnknown, and each of them was right for its own context - a module's
 * force picker should fall back to a real side, a lookup should not invent one.
 *
 * Arguments:
 * 0: Side name <STRING>
 * 1: What an unrecognised name returns <SIDE> (optional, default sideUnknown)
 *
 * Return Value:
 * The side <SIDE>
 *
 * Example:
 * ["GUER", east] call jmfsb_common_fnc_sideFromText
 */

params [["_text", "", [""]], ["_default", sideUnknown, [sideUnknown]]];

switch (toUpper _text) do {
    case "WEST";
    case "BLUFOR": {west};
    case "EAST";
    case "OPFOR": {east};
    case "GUER";
    case "GUERRILA";
    case "RESISTANCE";
    case "INDEPENDENT": {independent};
    case "CIV";
    case "CIVILIAN": {civilian};
    default {_default};
};
