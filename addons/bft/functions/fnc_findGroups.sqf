#include "script_component.hpp"
/*
 * Author: YonV
 * Resolves the group token an admin typed into actual groups. One token, never
 * quoted: chat arguments are split on spaces and a call sign like "B Alpha 1-1"
 * would not survive being one, so the token is matched as a case-insensitive
 * SUBSTRING of the group id - "alpha" finds "B Alpha 1-1".
 *
 * "all" is every group with anyone left in it; a side name is every group on
 * that side.
 *
 * Arguments:
 * 0: Token - group id fragment, "all", or west/east/guer/civ <STRING>
 *
 * Return Value:
 * Matching groups <ARRAY>
 *
 * Example:
 * ["alpha"] call jmfsb_bft_fnc_findGroups
 *
 * Public: No
 */

params [["_token", "", [""]]];

private _needle = toLower trim _token;
if (_needle isEqualTo "") exitWith {[]};

private _manned = allGroups select {units _x isNotEqualTo []};

if (_needle isEqualTo "all") exitWith {_manned};

private _side = switch (_needle) do {
    case "west";
    case "blufor": {west};
    case "east";
    case "opfor": {east};
    case "guer";
    case "indep";
    case "independent": {independent};
    case "civ";
    case "civilian": {civilian};
    default {sideUnknown};
};

if (_side isNotEqualTo sideUnknown) exitWith {
    _manned select {side _x isEqualTo _side}
};

_manned select {(toLower groupId _x) find _needle > -1}
