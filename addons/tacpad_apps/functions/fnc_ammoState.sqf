#include "script_component.hpp"
/*
 * Author: YonV
 * How much ammunition a man has left for his primary weapon, as a percentage.
 *
 * MEASURED AGAINST WHAT HE IS CARRYING, not against what he started with. There
 * is no record of a starting loadout to compare to - a man who has picked up two
 * magazines is not at 140% - so the denominator is the magazines in his hands
 * and his kit, full. It answers "how full is what you have", which is the
 * question that goes in a report, and it falls as he fires.
 *
 * The loaded magazine counts. Reading only the pouches says RED to a man with a
 * full magazine on the weapon.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * 0: Percentage, -1 when he has no primary weapon or no magazines for it <NUMBER>
 * 1: Rounds remaining <NUMBER>
 *
 * Example:
 * ([player] call jmfsb_tacpad_apps_fnc_ammoState) params ["_pct", "_rounds"]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit}) exitWith {[-1, 0]};

private _primary = primaryWeapon _unit;
if (_primary == "") exitWith {[-1, 0]};

private _compatible = [_primary] call BIS_fnc_compatibleMagazines;
if (_compatible isEqualTo []) exitWith {[-1, 0]};

// magazinesAmmoFull covers the pouches, the vest, the backpack AND what is in
// the weapon, which magazinesAmmo on its own does not.
private _rounds = 0;
private _capacity = 0;

{
    _x params ["_class", "_ammo"];
    if !(_class in _compatible) then {continue};

    _rounds = _rounds + _ammo;
    _capacity = _capacity + getNumber (configFile >> "CfgMagazines" >> _class >> "count");
} forEach (magazinesAmmoFull _unit);

if (_capacity <= 0) exitWith {[-1, 0]};

[round (100 * _rounds / _capacity), _rounds]
