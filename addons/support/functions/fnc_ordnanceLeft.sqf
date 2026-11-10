#include "script_component.hpp"
/*
 * Author: YonV
 * The AIRFRAME CHECK-IN's ORDNANCE line (user, 2026-11-02, FUNC(checkIn)):
 * what an aircraft still has to strike the ground with, off the live
 * airframe - "GBU-12 x2, 20mm x450". The core knows no provider's store list,
 * so it reads the engine's: every magazine aboard, pylons included, with
 * rounds left, of ammunition that can hit the ground (ORDNANCE_RANK),
 * heaviest first; air-to-air only (airLock 2) left out. The same store on
 * two pylons is one entry. Names are the short ones, cut to ORDNANCE_NAME_MAX.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * The line, ORDNANCE_NONE when nothing is left <STRING>
 *
 * Example:
 * [_veh] call jmfsb_support_fnc_ordnanceLeft
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (isNull _veh) exitWith {ORDNANCE_NONE};

// magazinesAllTurrets is [magazine, turret, rounds, id, creator].
private _left = createHashMap;
{
    _x params ["_mag", "", ["_rounds", 0]];
    if (_rounds > 0) then {_left set [_mag, (_left getOrDefault [_mag, 0]) + _rounds]};
} forEach (magazinesAllTurrets _veh);

private _rows = [];
// Over a hashmap _x is the KEY (the magazine) and _y the value (its rounds).
{
    private _cfgMag = configFile >> "CfgMagazines" >> _x;
    private _cfgAmmo = configFile >> "CfgAmmo" >> getText (_cfgMag >> "ammo");
    private _rank = ORDNANCE_RANK find (toLower getText (_cfgAmmo >> "simulation"));
    if (_rank < 0) then {continue};
    if (getNumber (_cfgAmmo >> "airLock") isEqualTo ORDNANCE_AIR_ONLY) then {continue};
    private _name = getText (_cfgMag >> "displayNameShort");
    if (_name isEqualTo "") then {_name = getText (_cfgMag >> "displayName")};
    if (_name isEqualTo "") then {_name = _x};
    _rows pushBack [_rank, _name select [0, ORDNANCE_NAME_MAX], _y];
} forEach _left;

if (_rows isEqualTo []) exitWith {ORDNANCE_NONE};
_rows sort true;
(_rows apply {format [ORDNANCE_ITEM, _x select 1, _x select 2]}) joinString ORDNANCE_SEP
