#include "script_component.hpp"
/*
 * Author: YonV
 * JMSB - Medical Training's module function. The module is read by the
 * TAC//TRAINING app (FUNC(stretchers)), not run: this only says once in the
 * RPT, on the server, which station it is and how many points it names.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [], true] call jmfsb_training_fnc_moduleMedical
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
private _name = _logic getVariable ["name", ""];
private _named = count (((_logic getVariable ["points", ""]) splitString ", ") select {_x isNotEqualTo ""});
private _synced = {!(_x isKindOf "Logic")} count (synchronizedObjects _logic);
INFO_3("medical training '%1': %2 named point(s), %3 synced",_name,_named,_synced);
