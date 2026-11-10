#include "script_component.hpp"
/*
 * Author: YonV
 * A man's buddy: the man he paired with by ACE interaction (FUNC(buddySet)).
 * A pair counts only while it holds both ways, both are alive and both are
 * still in one group - a man who changed group or died leaves no buddy behind.
 *
 * Arguments:
 * 0: The man <OBJECT>
 *
 * Return Value:
 * His buddy, objNull none <OBJECT>
 *
 * Example:
 * [ACE_player] call jmfsb_bft_fnc_buddyOf
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

private _buddy = _unit getVariable [QGVAR(buddy), objNull];
if (isNull _buddy || {!alive _buddy} || {!alive _unit}) exitWith {objNull};
if (group _buddy isNotEqualTo group _unit) exitWith {objNull};
if ((_buddy getVariable [QGVAR(buddy), objNull]) isNotEqualTo _unit) exitWith {objNull};

_buddy
