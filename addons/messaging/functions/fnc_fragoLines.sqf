#include "script_component.hpp"
/*
 * Author: YonV
 * A FRAGO's changed lines (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09: "the
 * card it makes shows only the changed lines, old value and new"), in the
 * order card's own line order: one row per line with a changed field, its
 * fields' old values, an arrow, the new. The readers draw these (FUNC(render),
 * tacpad's thread view); nothing reads them back as an order - the merged
 * order is FUNC(currentOrder)'s.
 *
 * Arguments:
 * 0: The FRAGO's payload, [key, value] pairs <ARRAY>
 *
 * Return Value:
 * [[line title, line label, "old -> new"], ...] <ARRAY>
 *
 * Example:
 * private _rows = [_payload] call jmfsb_messaging_fnc_fragoLines
 *
 * Public: Yes
 */

params [["_payload", [], [[]]]];

private _values = createHashMapFromArray _payload;
private _card = [_values getOrDefault [FRAGO_CARD_KEY, ""]] call FUNC(template);
if (_card isEqualTo createHashMap) exitWith {[]};

private _rows = [];
{
    _x params ["", "_lineTitle", "_lineLabel", "_lineFields"];
    private _changed = _lineFields select {(_x get "key") in _values};
    if (_changed isEqualTo []) then {continue};
    private _olds = [];
    private _news = [];
    {
        private _key = _x get "key";
        private _prefix = [_x get "prefix", ""] select ((_x get "type") isEqualTo "bool");
        private _old = [_x, _values getOrDefault [_key + FRAGO_WAS, ""], _values] call FUNC(fieldText);
        private _new = [_x, _values get _key, _values] call FUNC(fieldText);
        if (_old isNotEqualTo "") then {_olds pushBack (_prefix + _old)};
        if (_new isNotEqualTo "") then {_news pushBack (_prefix + _new)};
    } forEach _changed;
    private _oldText = [_olds joinString ", ", "-"] select (_olds isEqualTo []);
    private _newText = [_news joinString ", ", "-"] select (_news isEqualTo []);
    _rows pushBack [_lineTitle, _lineLabel, _oldText + FRAGO_ARROW + _newText];
} forEach (_card get "lines");

_rows
