#include "script_component.hpp"
/*
 * Author: YonV
 * A unit's blood type - "O+", "AB-" and the six between - as a string.
 *
 * Nothing in ACE medical knows a blood type, so the unit's is DEALT once and
 * then remembered: a mission (or an admin) that sets the variable
 * QGVAR(bloodType) on the unit wins outright; otherwise the type is drawn from
 * a hash of the player's UID (a name-hash for AI), so the same player draws
 * the same type every session, on every client, without any sync. The draw
 * follows the population frequencies (O+ 37 %, A+ 36 %, B+ 8 %, AB+ 3 %,
 * O- 7 %, A- 6 %, B- 2 %, AB- 1 %) so a squad reads like one.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Blood type <STRING> - "" for a null unit
 *
 * Example:
 * [player] call jmfsb_common_fnc_bloodType
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith { "" };

private _set = _unit getVariable [QGVAR(bloodType), ""];
if (_set isNotEqualTo "") exitWith { _set };

// the population, in cumulative percent
private _table = [["O+", 37], ["A+", 73], ["B+", 81], ["AB+", 84], ["O-", 91], ["A-", 97], ["B-", 99], ["AB-", 100]];

private _key = getPlayerUID _unit;
if (_key isEqualTo "") then { _key = format ["%1|%2", name _unit, typeOf _unit] };
// a small stable hash of the key - the engine's hashValue is 128-bit hex
private _hex = hashValue _key;
private _n = 0;
{
    private _d = "0123456789abcdef" find (toLower _x);
    if (_d < 0) then { _d = 0 };
    _n = (_n * 16 + _d) mod 1000;
} forEach (toArray (_hex select [0, 12]) apply { toString [_x] });
private _roll = _n mod 100;

private _type = "O+";
{
    _x params ["_t", "_upTo"];
    if (_roll < _upTo) exitWith { _type = _t };
} forEach _table;

_unit setVariable [QGVAR(bloodType), _type];
_type
