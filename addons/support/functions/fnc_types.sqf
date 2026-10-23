#include "script_component.hpp"
/*
 * Author: JMSB
 * The asset types TAC//SUPPORT lists in its ASSET group, merged from every
 * provider's "types" declaration:
 *
 *   [type, label, one, many, order, tasks]
 *
 * Merged by type. The first declaration (lowest order, then kind order) gives
 * the label, the counted nouns and the order; the task lists are united by
 * token in the same order, so the list shown before a unit is picked holds
 * every task some provider of that type answers. Once a unit is picked,
 * FUNC(tasks) narrows it to that unit's provider.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Type declarations, sorted by order <ARRAY>
 *
 * Example:
 * call jmfsb_support_fnc_types
 *
 * Public: Yes
 */

private _kinds = keys GVAR(providers);
_kinds sort true;

// Sorted by [order, sequence] - the sequence is kind order, then position in
// the provider's own list, so equal orders keep a stable, documented winner.
// The declarations themselves stay out of the sort keys.
private _all = [];
private _keys = [];
{
    {
        if (_x isEqualType [] && {(_x param [0, ""]) isEqualType ""} && {(_x param [0, ""]) isNotEqualTo ""}) then {
            private _order = _x param [4, TYPE_ORDER_LAST];
            if !(_order isEqualType 0) then {_order = TYPE_ORDER_LAST};
            _keys pushBack [_order, count _all];
            _all pushBack _x;
        };
    } forEach ((GVAR(providers) get _x) getOrDefault ["types", []]);
} forEach _kinds;
_keys sort true;

private _byType = createHashMap;
private _out = [];
{
    _x params ["_order", "_seq"];
    (_all select _seq) params ["_type", ["_label", ""], ["_one", ""], ["_many", ""], "", ["_tasks", []]];
    if !(_tasks isEqualType []) then {_tasks = []};

    private _have = _byType getOrDefault [_type, []];
    if (_have isEqualTo []) then {
        _have = [_type, [_label, toUpper _type] select (_label isEqualTo ""), _one, _many, _order, +_tasks];
        _byType set [_type, _have];
        _out pushBack _have;
    } else {
        private _known = (_have select 5) apply {_x param [0, ""]};
        {
            if !((_x param [0, ""]) in _known) then {
                (_have select 5) pushBack _x;
                _known pushBack (_x param [0, ""]);
            };
        } forEach _tasks;
    };
} forEach _keys;

_out
