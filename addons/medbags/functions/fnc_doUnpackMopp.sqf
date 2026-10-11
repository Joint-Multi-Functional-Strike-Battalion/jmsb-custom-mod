#include "..\script_component.hpp"
/*
 * Author: YonV
 * Unpacks the first MOPP bag a unit carries: that bag's CBRN suit (its
 * GVAR(suit) config value) and then the shared GVAR(contentsMopp) list -
 * respirator and the ACM CBRN self-aid autoinjectors.
 * (user, 2026-10-10: "3 mopp bags based on camo and acm cbrn self drugs")
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_medbags_fnc_doUnpackMopp
 *
 * Public: No
 */

#define UNPACK_TIME 3

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {};

private _items = items _unit;
private _bag = [QGVAR(Mopp_MTP), QGVAR(Mopp_Tropic), QGVAR(Mopp_Wdl)] select {_x in _items};
if (_bag isEqualTo []) exitWith {};
_bag = _bag select 0;

_unit playAction "Gear";

[
    UNPACK_TIME,
    [_unit, _bag],
    {
        (_this select 0) params ["_unit", "_bag"];
        if !(_bag in items _unit) exitWith {};
        _unit removeItem _bag;
        private _suit = getText (configFile >> "CfgWeapons" >> _bag >> QGVAR(suit));
        [_unit, ([format ["%1:1", _suit], GVAR(contentsMopp)] select {_x isNotEqualTo ""}) joinString ", "] spawn FUNC(issueContents);
    },
    {},
    "Unpacking MOPP Bag....",
    {true},
    ["isNotInside", "isNotSitting", "isNotSwimming"]
] call ACE_common_fnc_progressBar;
