#include "script_component.hpp"
/*
 * Author: YonV
 * The colour of a mark on the ground, from its config (user, 2026-11-02:
 * "caller pops smoke helo verifies color"): the first colour word in its class
 * name or a parent's (SmokeShellRed - RED, G_40mm_SmokeGreen - GREEN,
 * ACE_G_Chemlight_HiRed - RED). A smoke whose names give none is WHITE when
 * its smokeColor is white or it has none (the plain SmokeShell, G_40mm_Smoke);
 * otherwise no colour is said rather than a wrong one.
 *
 * Arguments:
 * 0: The mark - the thrown object <OBJECT>
 * 1: Smoke - the smokeColor rule applies <BOOL> (optional, default false)
 *
 * Return Value:
 * The colour word, "" for none <STRING>
 *
 * Example:
 * [_grenade, true] call jmfsb_support_fnc_markColour
 *
 * Public: No
 */

params [["_mark", objNull, [objNull]], ["_smoke", false, [false]]];

if (isNull _mark) exitWith {""};

// A thrown grenade is CfgAmmo; an attached strobe CfgVehicles.
private _type = typeOf _mark;
private _cfg = configFile >> "CfgAmmo" >> _type;
if (!isClass _cfg) then {_cfg = configFile >> "CfgVehicles" >> _type};
if (!isClass _cfg) exitWith {""};

private _colour = "";
private _at = _cfg;
while {_colour isEqualTo "" && isClass _at} do {
    private _name = toUpper configName _at;
    private _found = MARK_COLOURS findIf {_x in _name};
    if (_found >= 0) then {_colour = MARK_COLOURS select _found};
    _at = inheritsFrom _at;
};
if (_colour isNotEqualTo "" || !_smoke) exitWith {_colour};

private _rgb = getArray (_cfg >> "smokeColor");
if (count _rgb < RGB_CHANNELS) exitWith {MARK_WHITE};
if (selectMin (_rgb select [0, RGB_CHANNELS]) >= SMOKE_WHITE_MIN) exitWith {MARK_WHITE};
""
