#include "script_component.hpp"
/*
 * Author: YonV
 * Pairs two men as buddies, or ends a man's pair. A pair is both ways: each
 * holds the other. Whoever either of them was paired with before is let go,
 * so a man is never in two pairs. Stored on the units, public, so every
 * machine's squad list and map read the same pairs (FUNC(buddyOf)).
 *
 * Arguments:
 * 0: The man <OBJECT>
 * 1: His new buddy, objNull to end his pair <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ACE_player, _target] call jmfsb_bft_fnc_buddySet
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_buddy", objNull, [objNull]]];

if (isNull _unit) exitWith {};

// Let go of whoever either man held, when that man still held him back.
{
    private _old = _x getVariable [QGVAR(buddy), objNull];
    if (!isNull _old && {(_old getVariable [QGVAR(buddy), objNull]) isEqualTo _x}) then {
        _old setVariable [QGVAR(buddy), objNull, true];
    };
    _x setVariable [QGVAR(buddy), objNull, true];
} forEach ([[_unit], [_unit, _buddy]] select !isNull _buddy);

if (isNull _buddy) exitWith {};

_unit setVariable [QGVAR(buddy), _buddy, true];
_buddy setVariable [QGVAR(buddy), _unit, true];
