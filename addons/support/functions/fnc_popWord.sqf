#include "script_component.hpp"
/*
 * Author: YonV
 * What the issuer is asked to pop, from a card's marking words: IR, FLARE,
 * CHEMLIGHT or SMOKE (POP_WORDS) - SMOKE without one. One place for it, so
 * the 1 MIN OUT alert (FUNC(inbound)) and the mark a circling aircraft looks
 * for (FUNC(lzClear), user 2026-11-02) say the same.
 *
 * Arguments:
 * 0: The card's marking words, "" for none <STRING>
 *
 * Return Value:
 * The pop word <STRING>
 *
 * Example:
 * ["IR STROBE"] call jmfsb_support_fnc_popWord
 *
 * Public: Yes
 */

params [["_marking", "", [""]]];

private _words = (toUpper _marking) splitString POP_SEPARATORS;
private _pop = POP_DEFAULT;
{
    _x params ["_word", "_say"];
    if (_word in _words) exitWith {_pop = _say};
} forEach POP_WORDS;

_pop
