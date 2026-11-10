#include "script_component.hpp"
/*
 * Author: YonV
 * A list of item names as one line, counted, in the order first seen:
 * ["HUNTER", "HUNTER", "CRATE"] is "2 x HUNTER, 1 x CRATE". "" for none.
 *
 * Arguments:
 * 0: Names <ARRAY of STRINGs>
 *
 * Return Value:
 * The line <STRING>
 *
 * Example:
 * [["HUNTER", "HUNTER"]] call jmfsb_support_logistics_fnc_countLine
 *
 * Public: No
 */

params [["_names", [], [[]]]];

private _order = [];
private _count = createHashMap;
{
    _order pushBackUnique _x;
    _count set [_x, (_count getOrDefault [_x, 0]) + 1];
} forEach _names;

(_order apply {format ["%1 x %2", _count get _x, _x]}) joinString ", "
