#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the two letters a battery's recorded targets are named with
 * (RECORD AS TARGET, user 2026-11-02) - TARGET_FORMAT, "AB1001": the letters,
 * then a running number (FUNC(record)).
 *
 * THE SCHEME. The module's Target Prefix when it gives two letters, kept as
 * given even when another battery has them (the mission maker's call).
 * Otherwise the callsign's first two letters (THUNDER: TH), stepped on - TI,
 * TJ ... - past any a battery registered before has, so no two batteries'
 * targets share a name. A callsign short of two letters is made up with A
 * (none at all: AA).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * Two capital letters <STRING>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_targetPrefix
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

private _fnc_letters = {
    params ["_text"];
    (toArray toUpper _text) select {_x >= LETTER_A && _x <= LETTER_Z}
};

private _codes = [_logic getVariable ["targetPrefix", ""]] call _fnc_letters;
private _given = count _codes >= TARGET_LETTERS;
if (!_given) then {
    _codes = ([_logic getVariable ["callsign", ""]] call _fnc_letters) + [LETTER_A, LETTER_A];
};
_codes params ["_first", "_second"];
private _prefix = toString [_first, _second];
if (_given) exitWith {_prefix};

private _taken = (GVAR(entities) select {_x isNotEqualTo _logic}) apply {_x getVariable [QGVAR(targetPrefix), ""]};
for "_i" from 1 to (ALPHABET * ALPHABET) do {
    if !(_prefix in _taken) exitWith {};
    _second = _second + 1;
    if (_second > LETTER_Z) then {
        _second = LETTER_A;
        _first = [_first + 1, LETTER_A] select (_first >= LETTER_Z);
    };
    _prefix = toString [_first, _second];
};

_prefix
