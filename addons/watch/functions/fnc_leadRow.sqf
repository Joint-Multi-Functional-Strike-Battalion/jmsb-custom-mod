#include "script_component.hpp"
/*
 * Author: YonV
 * The team lead profile's readout for one man of his squad (design
 * team_lead.hud.fields): name, role, health, rifle magazines, AT, distance
 * and bearing, and whether his device is in reach (a man's voice net is
 * his own machine's and is not shown). Health is FUNC(health).
 *
 * Arguments:
 * 0: The man <OBJECT>
 *
 * Return Value:
 * [name, state word, colour, [line 2, line 3], live] <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_watch_fnc_leadRow
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

([_unit] call FUNC(health)) params ["_word", "_colour"];
private _mags = {_x in compatibleMagazines primaryWeapon _unit} count magazines _unit;
private _launcher = secondaryWeapon _unit;
private _at = if (_launcher isEqualTo "") then {"-"} else {
    format ["%1 +%2", getText (configFile >> "CfgWeapons" >> _launcher >> "displayName"), {_x in compatibleMagazines _launcher} count magazines _unit]
};
private _role = if (isNil QEFUNC(tacpad,roleShort)) then {""} else {[_unit] call EFUNC(tacpad,roleShort)};
[
    toUpper name _unit,
    _word,
    _colour,
    [
        format ["%1   MAGS %2   AT %3", _role, _mags, _at],
        format ["DIST %1 M   BRG %2   %3", round (player distance _unit), [round (player getDir _unit), 3] call CBA_fnc_formatNumber,
            ["NO SIGNAL", "SIGNAL"] select ([_unit] call FUNC(hasSignal))]
    ],
    alive _unit
]
