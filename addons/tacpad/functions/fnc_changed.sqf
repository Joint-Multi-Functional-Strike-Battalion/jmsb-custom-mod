#include "script_component.hpp"
/*
 * Author: YonV
 * The change key a live screen skips work with (code review R8). The screen
 * says what it would draw as a value; this keeps that value's text on the
 * holder under the name given, and answers whether the new one differs - and
 * when it does, remembers it. The tablet's rows are the pattern
 * (jmfsb_devices_fnc_tabletTick): redraw on a new key, never on the tick.
 *
 * KEPT ON THE HOLDER, so a holder that is rebuilt - a new display, a new
 * group - starts with no keys and draws once. A HASHMAP holder is the key
 * store itself, for a screen that keeps its keys where it can forget them.
 *
 * Arguments:
 * 0: Holder <DISPLAY, CONTROL, NAMESPACE, OBJECT or HASHMAP>
 * 1: Name of the key <STRING>
 * 2: What would be drawn <ANY>
 *
 * Return Value:
 * Changed - draw it <BOOL>
 *
 * Example:
 * if !([_display, "nets", [_nets, _app]] call jmfsb_tacpad_fnc_changed) exitWith {}
 *
 * Public: Yes
 */

params [["_holder", controlNull], ["_name", "", [""]], ["_value", []]];

private _keys = _holder;
if !(_holder isEqualType createHashMap) then {
    _keys = _holder getVariable [QGVAR(changeKeys), createHashMap];
    _holder setVariable [QGVAR(changeKeys), _keys];
};

private _key = str _value;
if (_key isEqualTo (_keys getOrDefault [_name, ""])) exitWith {false};
_keys set [_name, _key];
true
