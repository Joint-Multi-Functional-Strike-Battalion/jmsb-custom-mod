#include "script_component.hpp"
/*
 * Author: YonV
 * What a man is for, in the three or four letters a roster uses.
 *
 * A QUALIFICATION WINS FIRST (2026-10-07): the PAC skill tags on the unit
 * (jmfsb_pac_skillTags, most telling first), so a medic in a recon slot reads
 * MED. CLS alone does not: a squad leader is still SL.
 *
 * Then the mission's own answer: `roleDescription` is what a mission maker or a
 * slotting script sets, and if somebody has said what this slot is then no
 * amount of inspecting the loadout should argue with them. Only when it is empty
 * does this read the unit - traits first, because they are declared, then the
 * weapon, because it is at least evidence.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Role <STRING>
 *
 * Example:
 * private _role = [player] call jmfsb_tacpad_fnc_roleShort
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {""};

private _tags = (_unit getVariable ["jmfsb_pac_skillTags", []]) select {_x isNotEqualTo "CLS"};
if (_tags isNotEqualTo []) exitWith {_tags # 0};

// roleDescription is often "Rifleman@Alpha 1-1" - only the part before the @ is
// the role, the rest is the group it was slotted into.
private _described = roleDescription _unit;
if (_described != "") exitWith {
    toUpper ((_described splitString "@") param [0, _described])
};

if (_unit isEqualTo (leader group _unit)) exitWith {"SL"};
if (_unit getUnitTrait "medic") exitWith {"MED"};
if (_unit getUnitTrait "engineer") exitWith {"ENG"};
if (_unit getUnitTrait "UAVHacker") exitWith {"UAV"};

private _primary = primaryWeapon _unit;
if (_primary != "") then {
    private _cursor = getText (configFile >> "CfgWeapons" >> _primary >> "cursor");
    if (_cursor in ["srifle", "sniper"]) exitWith {"DM"};
    if (_cursor in ["mg", "machinegun"]) exitWith {"AR"};
};

if (secondaryWeapon _unit != "") exitWith {"AT"};

"RFL"
