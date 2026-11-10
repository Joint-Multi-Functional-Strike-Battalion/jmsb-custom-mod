#include "script_component.hpp"
/*
 * Author: YonV
 * A cart as the names of what it holds, one name per item in the order it
 * is flown - [[2, 2], [0, 1]] is ["HUNTER", "HUNTER", "CRATE - MAGAZINES"].
 * Indices are the catalog's; the cart has been through FUNC(readCart).
 *
 * Arguments:
 * 0: The asset's catalog <ARRAY>
 * 1: The cart <ARRAY>
 *
 * Return Value:
 * Names <ARRAY of STRINGs>
 *
 * Example:
 * [_catalog, [[0, 2]]] call jmfsb_support_logistics_fnc_cartNames
 *
 * Public: No
 */

params [["_catalog", [], [[]]], ["_cart", [], [[]]]];

private _names = [];
{
    _x params ["_i", "_c"];
    private _name = (_catalog param [_i, []]) param [ITEM_NAME, "?"];
    for "_k" from 1 to _c do {_names pushBack _name};
} forEach _cart;

_names
