#include "script_component.hpp"
/*
 * Author: YonV
 * A catalog item by the name a card gives it (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 7: "map card lines to the catalog by name").
 * The name as the catalog says it, any case; else the one item whose name holds
 * it, or that it holds - two or more such: none, the card must say which.
 *
 * Arguments:
 * 0: The catalog <ARRAY>
 * 1: The name <STRING>
 *
 * Return Value:
 * Catalog index, -1 for none <NUMBER>
 *
 * Example:
 * [_catalog, "hunter"] call jmfsb_support_logistics_fnc_catalogFind
 *
 * Public: No
 */

params [["_catalog", [], [[]]], ["_name", "", [""]]];

private _wanted = toUpper trim _name;
if (_wanted isEqualTo "") exitWith {-1};

private _names = _catalog apply {toUpper (_x param [ITEM_NAME, ""])};
private _exact = _names find _wanted;
if (_exact >= 0) exitWith {_exact};

private _hits = [];
{
    if (_x isNotEqualTo "" && (_wanted in _x || _x in _wanted)) then {_hits pushBack _forEachIndex};
} forEach _names;

[-1, _hits param [0, -1]] select (count _hits isEqualTo 1)
