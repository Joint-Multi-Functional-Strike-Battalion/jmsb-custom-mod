#include "script_component.hpp"
/*
 * Author: YonV
 * A target another player shared (FUNC(slotShare)), on this machine: onto
 * the profile's slots unless it is there already or they are full (FUNC(toggle)
 * says so), and a line saying who sent it.
 *
 * Arguments:
 * 0: Profile id <STRING>
 * 1: Target <OBJECT>
 * 2: Who shared it <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["medical", _patient, "Doe"] call jmfsb_watch_fnc_slotShared
 *
 * Public: No
 */

params [["_id", "", [""]], ["_target", objNull, [objNull]], ["_from", "", [""]]];

if (isNull _target || {!(_id in GVAR(profiles))}) exitWith {};
if (((GVAR(slots) getOrDefault [_id, []]) findIf {(_x # 0) isEqualTo _target}) >= 0) exitWith {};
if !([_id, _target] call FUNC(toggle)) exitWith {};

private _what = [[_target] call FUNC(contactName), name _target] select (_target isKindOf "CAManBase");
[NOTE_TITLE, format ["%1: %2 shared %3.", toUpper ((GVAR(profiles) get _id) getOrDefault ["name", _id]), _from, _what], NOTE_COLOUR] call EFUNC(notify,notify);
