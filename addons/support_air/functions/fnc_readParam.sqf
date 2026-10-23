#include "script_component.hpp"
/*
 * Author: JMSB
 * One value out of TAC//SUPPORT's parameter array, read the way the stepper
 * that wrote it drew it.
 *
 * AN UNSET SLOT IS THE STEPPER'S MINIMUM - that is what the screen shows for
 * it - and anything that is not a number (the confirm pads the array with
 * empty arrays) reads the same. A slot backed by a value table is an index:
 * entry 0 of every table here is 0, which means "the module's own value".
 *
 * Arguments:
 * 0: The parameter array <ARRAY>
 * 1: Slot <NUMBER>
 * 2: Minimum <NUMBER>
 * 3: Maximum <NUMBER>
 * 4: Value table, [] when the slot holds the value itself <ARRAY> (optional, default [])
 * 5: The module's value, used for table entry 0 <NUMBER> (optional, default 0)
 *
 * Return Value:
 * The value <NUMBER>
 *
 * Example:
 * [_prm, 23, 0, 5, [0, 300, 500], 600] call jmfsb_support_air_fnc_readParam
 *
 * Public: No
 */

params [
    ["_prm", [], [[]]],
    ["_slot", 0, [0]],
    ["_min", 0, [0]],
    ["_max", 0, [0]],
    ["_table", [], [[]]],
    ["_default", 0, [0]]
];

private _v = _prm param [_slot, _min];
if !(_v isEqualType 0) then {_v = _min};
_v = (round _v) max _min min _max;

if (_table isEqualTo []) exitWith {_v};

private _picked = _table param [_v, 0];
[_picked, _default] select (_picked <= 0)
