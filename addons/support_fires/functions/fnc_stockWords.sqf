#include "script_component.hpp"
/*
 * Author: YonV
 * What a battery has left, in the words its end-of-mission prompts carry
 * (user, 2026-11-02: "ROUNDS COMPLETE - 12 HE, 6 SMOKE LEFT - REQUEST BDA"):
 * every round type it still holds, in the module's order, unlimited as UNL;
 * nothing left, NO ROUNDS LEFT.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * "12 HE, 6 SMOKE LEFT" <STRING>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_stockWords
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

private _left = [_logic] call FUNC(ordnance);
if (_left isEqualTo []) exitWith {STOCK_NONE};

format [STOCK_LEFT, (_left apply {
    _x params ["_name", "_rounds"];
    format [STOCK_ITEM, [str _rounds, REACH_UNLIMITED] select (_rounds < 0), _name]
}) joinString STOCK_SEP]
