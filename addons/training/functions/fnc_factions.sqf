#include "script_component.hpp"
/*
 * Author: YonV
 * The factions a trainer can spawn as the enemy: every faction with riflemen
 * that is not on the trainer's own side, by name.
 *
 * Arguments:
 * 0: The trainer's side <SIDE>
 *
 * Return Value:
 * [[faction class, display name, side], ...] <ARRAY>
 *
 * Example:
 * [side group player] call jmfsb_training_fnc_factions
 *
 * Public: No
 */

params [["_mine", sideUnknown, [sideUnknown]]];

private _out = [];
{
    _y params ["_side", "_men"];
    if (_men isEqualTo [] || _side isEqualTo _mine || !(_side in [east, west, independent])) then {continue};
    private _name = getText (configFile >> "CfgFactionClasses" >> _x >> "displayName");
    if (_name isEqualTo "") then {_name = _x};
    _out pushBack [_name, _x, _side];
} forEach ([] call FUNC(factionClasses));

_out sort true;
_out apply {[_x # 1, _x # 0, _x # 2]}
