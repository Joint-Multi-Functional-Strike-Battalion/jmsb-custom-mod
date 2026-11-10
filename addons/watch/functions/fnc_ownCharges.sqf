#include "script_component.hpp"
/*
 * Author: YonV
 * The engineer panel's line about his own charges (design
 * engineer.own_charges): how many mines and explosives he has laid that are
 * still there, how many are armed, and the nearest one's trigger and
 * distance. Empty when he has none.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The line, "" for none <STRING>
 *
 * Example:
 * [] call jmfsb_watch_fnc_ownCharges
 *
 * Public: No
 */

private _own = (getAllOwnedMines player) select {!isNull _x};
if (_own isEqualTo []) exitWith {""};
private _armed = {mineActive _x} count _own;
private _near = _own # 0;
{
    if ((player distance _x) < (player distance _near)) then {_near = _x};
} forEach _own;
private _nearRow = [_near] call FUNC(engineerRow);
format ["OWN CHARGES %1 - %2 ARMED - NEAREST %3, %4", count _own, _armed,
    (_nearRow # 3) param [0, ""], (_nearRow # 3) param [1, ""]]
