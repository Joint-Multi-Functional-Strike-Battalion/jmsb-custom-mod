#include "script_component.hpp"
/*
 * Author: YonV
 * What a CAS aircraft still has to strike with, off the live airframe
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4 and step 5: "RE-ATTACK? <n>
 * <munition> LEFT"). FUNC(stores) names the stores the airframe is hung with;
 * this counts the rounds still in them, so a pylon shot off reads empty.
 *
 * The store asked for when it still has rounds, else the heaviest one that
 * does - the one FUNC(fireAt) would pick next. The drones and support_air's
 * aircraft read it alike.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: The store wanted, "" for the heaviest left <STRING> (optional, default "")
 *
 * Return Value:
 * 0: Rounds left in it, 0 when nothing is left <NUMBER>
 * 1: Its name <STRING>
 * 2: Its magazine class <STRING>
 *
 * Example:
 * ([_veh, _mag] call jmfsb_cas_fnc_storesLeft) params ["_rounds", "_name"]
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_want", "", [""]]];

if (!alive _veh) exitWith {[0, "", ""]};

// magazinesAllTurrets is [magazine, turret, rounds, id, creator], pylons
// included; the same store on two pylons is summed.
private _left = createHashMap;
{
    _x params ["_mag", "", ["_rounds", 0]];
    if (_rounds > 0) then {_left set [_mag, (_left getOrDefault [_mag, 0]) + _rounds]};
} forEach (magazinesAllTurrets _veh);

private _stores = ([_veh] call FUNC(stores)) select {(_left getOrDefault [_x select 0, 0]) > 0};
if (_stores isEqualTo []) exitWith {[0, "", ""]};

private _at = _stores findIf {(_x select 0) isEqualTo _want};
private _mag = (_stores select (_at max 0)) select 0;
private _cfg = configFile >> "CfgMagazines" >> _mag;
private _name = getText (_cfg >> "displayNameShort");
if (_name isEqualTo "") then {_name = getText (_cfg >> "displayName")};
if (_name isEqualTo "") then {_name = _mag};

[_left get _mag, _name, _mag]
