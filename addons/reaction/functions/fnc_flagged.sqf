#include "script_component.hpp"
/*
 * Author: YonV
 * Is this player carrying a silent flag, and what does it cost them?
 *
 * Read by the hacking console so a flagged player's FAIL chance is trebled
 * too, not only their detect chance - pushing your luck should be worse in
 * both directions.
 *
 * Arguments:
 * 0: The player <OBJECT>
 *
 * Return Value:
 * [flagged <BOOL>, multiplier <NUMBER>]
 *
 * Example:
 * ([_player] call jmfsb_reaction_fnc_flagged) params ["_flagged", "_mult"];
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[false, 1]};

// The server's hashmap is canonical; a CLIENT has no hashmap - the hacking
// console asks from the hacker's machine - so the flag is mirrored onto
// the unit itself when it is set (FUNC(roll)) and read back here. Expired
// mirrors answer false through the same time check, so only the set needs
// broadcasting.
private _until = if (!isNil QGVAR(flags)) then {
    GVAR(flags) getOrDefault [netId _unit, -1]
} else {
    _unit getVariable [QGVAR(flaggedUntil), -1]
};

private _f = CBA_missionTime < _until;
[_f, [1, REACT_FLAG_MULT] select _f]
