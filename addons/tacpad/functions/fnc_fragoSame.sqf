#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a field of a FRAGO's order still says what the order said
 * (2026-11-09, FUNC(composeFragoPayload), FUNC(composeCard)'s CHANGED mark).
 * Read as the card means it, not as it is held: a number typed as "3" is the
 * 3 the order carried; an unticked box and an empty one are both no answer;
 * a position is its grid, so the same marker picked again is no change.
 *
 * Arguments:
 * 0: The field <HASHMAP>
 * 1: The composer's value <ANY>
 * 2: The order's value <ANY>
 *
 * Return Value:
 * The same <BOOL>
 *
 * Example:
 * [_field, "3", 3] call jmfsb_tacpad_fnc_fragoSame
 *
 * Public: No
 */

params [["_field", createHashMap, [createHashMap]], ["_now", ""], ["_was", ""]];

private _type = _field getOrDefault ["type", "text"];
private _fnc_norm = {
    params ["_v"];
    if (isNil "_v") exitWith {""};
    if (_type isEqualTo "bool") exitWith {_v isEqualTo true || {_v isEqualType "" && {(toLower _v) in ["true", "yes", "x", "1"]}}};
    if (_v isEqualTo false || _v isEqualTo []) exitWith {""};
    if (_v isEqualType [] && {count _v >= 2}) exitWith {mapGridPosition _v};
    if (_v isEqualType 0) exitWith {str _v};
    if (_v isEqualType "") exitWith {
        private _t = trim _v;
        if (_type isEqualTo "number" && {_t regexMatch "^-?\d+(\.\d+)?$"}) exitWith {str parseNumber _t};
        _t
    };
    str _v
};

([_now] call _fnc_norm) isEqualTo ([_was] call _fnc_norm)
