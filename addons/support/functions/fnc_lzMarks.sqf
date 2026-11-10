#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the mark a circling aircraft sees round its landing point (user,
 * 2026-11-02: "caller pops smoke helo verifies color") - the nearest one of
 * the kinds asked for inside LZ_MARK_RADIUS m, not one the caller has called
 * WRONG. Each object is told apart in MARK_KINDS order (an IR strobe or a
 * chemlight may be a SmokeShell to the engine), so a chemlight is never read
 * as smoke. What it is called: "RED SMOKE", "WHITE SMOKE", "SMOKE" (a colour
 * its config does not give), "IR STROBE", "GREEN CHEMLIGHT", "FLARE"
 * (FUNC(markColour)).
 *
 * Arguments:
 * 0: The landing point <ARRAY>
 * 1: The kinds looked for, pop words (MARK_KINDS) <ARRAY>
 * 2: Marks called WRONG - not seen again <ARRAY>
 *
 * Return Value:
 * [mark, what it is called], [] for none <ARRAY>
 *
 * Example:
 * [_lz, ["SMOKE", "IR"], []] call jmfsb_support_fnc_lzMarks
 *
 * Public: No
 */

params [["_point", [], [[]]], ["_kinds", [], [[]]], ["_ignored", [], [[]]]];

if (count _point < 2 || _kinds isEqualTo []) exitWith {[]};

private _classes = [];
{
    _x params ["_kind", "_kindClasses"];
    if (_kind in _kinds) then {_classes append _kindClasses};
} forEach MARK_KINDS;

private _found = [];
{
    private _mark = _x;
    private _type = typeOf _mark;
    private _root = [configFile >> "CfgVehicles", configFile >> "CfgAmmo"] select (isClass (configFile >> "CfgAmmo" >> _type));
    private _at = MARK_KINDS findIf {((_x select 1) findIf {_type isKindOf [_x, _root]}) >= 0};
    if (_at >= 0 && !(_mark in _ignored)) then {
        (MARK_KINDS select _at) params ["_kind", "", "_name"];
        if (_kind in _kinds) then {
            private _colour = "";
            if (_kind isNotEqualTo MARK_IR) then {_colour = [_mark, _kind isEqualTo MARK_SMOKE] call FUNC(markColour)};
            _found = [_mark, trim format ["%1 %2", _colour, _name]];
        };
    };
    if (_found isNotEqualTo []) exitWith {};
} forEach (nearestObjects [_point, _classes, LZ_MARK_RADIUS]);

_found
