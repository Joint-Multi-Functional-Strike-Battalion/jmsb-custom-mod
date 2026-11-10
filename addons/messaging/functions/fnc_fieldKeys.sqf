#include "script_component.hpp"
/*
 * Author: YonV
 * Field keys of a template, in the order they appear on the form. A UI walks
 * this to build a compose screen; the ALiVE forwarder walks it to find the one
 * field it wants without knowing how many lines came before it.
 *
 * Arguments:
 * 0: Template id, or the template itself <STRING|HASHMAP>
 * 1: Line key to restrict to, "" for all <STRING> (optional, default "")
 *
 * Return Value:
 * Field keys <ARRAY>
 *
 * Example:
 * private _keys = ["contactrep", "L"] call jmfsb_messaging_fnc_fieldKeys
 *
 * Public: Yes
 */

params [["_template", "", ["", createHashMap]], ["_line", "", [""]]];

if (_template isEqualType "") then {
    _template = [_template] call FUNC(template);
};

private _order = _template getOrDefault ["order", []];
if (_line == "") exitWith {+_order};

private _fields = _template getOrDefault ["fields", createHashMap];
_order select {(_fields get _x) get "line" == _line}
