#include "script_component.hpp"
/*
 * Author: YonV
 * Registers cards the mod carries, on this machine, each with the option
 * ["builtin", true]. THE MOD'S OWN CARD ALWAYS WINS (user, 2026-11-02: card
 * changes reach the game with the mod - nobody runs a script against the
 * database): a mission's own deck (JMFSBFR_Templates, FUNC(loadTemplates))
 * registered first is replaced where it stands (FUNC(registerTemplate)), and
 * the TAC//PAC deck, which arrives later, adds only the ids the mod does not
 * have (pac templatesApply).
 *
 * WHEN: messaging's preInit for its own cards (FUNC(builtinCards)), the
 * support core's preInit for its (jmfsb_support_fnc_builtinCards), PAC's
 * postInit for the OPORD and METT-TC - every machine, the same cards in the
 * same place in the registry.
 *
 * One RPT line per call names the cards registered.
 *
 * Arguments:
 * 0: Cards, each [id, title, short, lines, options] <ARRAY>
 * 1: Who carries them, for the RPT line <STRING> (default: "")
 *
 * Return Value:
 * How many were registered <NUMBER>
 *
 * Example:
 * [[] call jmfsb_messaging_fnc_builtinCards, "messaging"] call jmfsb_messaging_fnc_registerBuiltins
 *
 * Public: No
 */

params [["_cards", [], [[]]], ["_source", "", [""]]];

private _used = [];
{
    _x params [["_id", "", [""]], ["_title", "", [""]], ["_short", "", [""]], ["_lines", [], [[]]], ["_options", [], [[]]]];
    if (([_id, _title, _short, _lines, _options + [["builtin", true]]] call FUNC(registerTemplate)) isNotEqualTo "") then {
        _used pushBack _id;
    };
} forEach _cards;

// Hoisted: a comma inside a macro argument reads as an argument separator.
private _usedText = _used joinString ", ";
if (_used isNotEqualTo []) then {
    INFO_3("built-in cards (%1): %2 - %3",_source,count _used,_usedText);
};

count _used
