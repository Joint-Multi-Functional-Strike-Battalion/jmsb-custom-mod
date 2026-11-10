#include "script_component.hpp"
/*
 * Author: YonV
 * One field's value as the card prints it - a tick as its prefix, a grid as
 * the grid with the marker's name beside it, anything else as it was typed.
 * FUNC(render)'s own reading, split out (2026-11-09) so a FRAGO's changed
 * lines read the same way (FUNC(fragoLines)). "" when there is nothing to say.
 *
 * Arguments:
 * 0: The field <HASHMAP>
 * 1: Its value <ANY>
 * 2: The payload it came from, for a grid's marker name <HASHMAP> (optional, default empty)
 *
 * Return Value:
 * Text, the prefix not yet joined (a tick's is) <STRING>
 *
 * Example:
 * [_field, _value, _values] call jmfsb_messaging_fnc_fieldText
 *
 * Public: No
 */

params [["_field", createHashMap, [createHashMap]], "_value", ["_values", createHashMap, [createHashMap]]];

if (isNil "_value") exitWith {""};
private _key = _field getOrDefault ["key", ""];
private _prefix = _field getOrDefault ["prefix", ""];

switch (_field getOrDefault ["type", "text"]) do {
    case "bool": {
        // A bool slot is not always a BOOL: reply prefills and edit harvests
        // leave STRINGS here (274 errors in one RPT once, when the eager &&
        // was handed one). Truthy strings count as ticked.
        private _on = if (_value isEqualType false) then {_value} else {
            _value isEqualType "" && {(toLower _value) in ["true", "yes", "x", "1"]}
        };
        if (_on) then {[_prefix, "yes"] select (_prefix == "")} else {""};
    };
    case "grid": {
        // A position, or the grid a player typed.
        private _grid = if (_value isEqualType [] && {count _value >= 2}) then {
            mapGridPosition _value
        } else {
            if (_value isEqualType "") then {trim _value} else {""};
        };
        // Picked from a map marker: the marker's name beside the grid
        // (user, 2026-11-05), from the sibling key.
        private _marker = _values getOrDefault [_key + MARKER_NAME_SUFFIX, ""];
        if (_grid != "" && _marker isEqualType "" && _marker != "") then {
            _grid = format ["%1 (%2)", _grid, _marker];
        };
        _grid
    };
    default {
        if (_value isEqualType "") then {trim _value} else {str _value};
    };
}
