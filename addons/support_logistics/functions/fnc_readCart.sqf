#include "script_component.hpp"
/*
 * Author: YonV
 * The order out of TAC//SUPPORT's parameter array, as a cart:
 * [[catalog index, count], ...], one pair per item, in catalog order.
 *
 * THE CART IS THE REAL SHAPE (slot 49, written by the v2 board's cart of
 * items). Without one - the v1 screen never writes it - the ITEM and COUNT
 * steppers (slots 50, 51) are a cart of one, read the way the steppers draw
 * them: an unset ITEM is the first item, an unset COUNT one, and a COUNT
 * left high by another task is clamped to this task's maximum (the slot is
 * shared - an AIRDROP of 3 then a one-helicopter SLING shows, and sends, 1).
 *
 * Anything that is not a pair of numbers, an index outside this catalog or a
 * count under one is dropped; the same item twice is one pair, counted
 * together. The array is shared by every asset on the board, so a slot can
 * hold whatever another screen left in it.
 *
 * Arguments:
 * 0: The parameter array <ARRAY>
 * 1: The asset's catalog <ARRAY>
 * 2: The COUNT stepper's maximum for this task <NUMBER> (optional, default COUNT_MAX)
 *
 * Return Value:
 * The cart, [] when nothing valid is ordered <ARRAY>
 *
 * Example:
 * [_prm, _catalog, 4] call jmfsb_support_logistics_fnc_readCart
 *
 * Public: No
 */

params [["_prm", [], [[]]], ["_catalog", [], [[]]], ["_countMax", COUNT_MAX, [0]]];

private _n = count _catalog;
if (_n isEqualTo 0) exitWith {[]};

private _cart = [];
private _raw = _prm param [SLOT_CART, []];
if (_raw isEqualType []) then {
    {
        if (_x isEqualType []) then {
            private _i = _x param [0, -1];
            private _c = _x param [1, 0];
            if (_i isEqualType 0 && _c isEqualType 0) then {_cart pushBack [round _i, (round _c) min COUNT_MAX]};
        };
    } forEach _raw;
};

if (_cart isEqualTo []) then {
    _cart = [[
        [_prm, SLOT_ITEM, 0, _n - 1] call EFUNC(support_air,readParam),
        [_prm, SLOT_COUNT, COUNT_MIN, _countMax max COUNT_MIN] call EFUNC(support_air,readParam)
    ]];
};

private _merged = createHashMap;
{
    _x params ["_i", "_c"];
    if (_i >= 0 && _i < _n && _c >= COUNT_MIN) then {_merged set [_i, (_merged getOrDefault [_i, 0]) + _c]};
} forEach _cart;

private _order = keys _merged;
_order sort true;
_order apply {[_x, _merged get _x]}
