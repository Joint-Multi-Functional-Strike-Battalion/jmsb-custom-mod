#include "script_component.hpp"
/*
 * Author: YonV
 * The side's friendlies as ALiVE's COP knows them - profiled groups that are
 * not spawned right now and so are no group the tracker could draw.
 *
 * ALiVE broadcasts ALiVE_COP_BftData_<SIDE> to everyone (mil_c2istar cop
 * fnc_COPServer.sqf:458): [center, sideKey, dominantType, totalCount,
 * sizeInd, factionCode] per cluster of profiles. It is a public variable, so
 * this answers on any machine. Positions are the side's own, so nothing
 * here is a secret the tracker should not have.
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Return Value:
 * [[pos <ARRAY>, type <STRING>, count <NUMBER>], ...] <ARRAY>
 * type is ALiVE's: air, armor, mech, art, aa, at, motor, infantry, unknown
 *
 * Example:
 * [west] call jmfsb_adapter_alive_fnc_virtualFriendlies
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [sideUnknown]]];
if (_side isEqualTo sideUnknown) exitWith {[]};

private _key = switch (_side) do {
    case west: {"WEST"};
    case east: {"EAST"};
    case independent: {"GUER"};
    default {""};
};
if (_key isEqualTo "") exitWith {[]};

private _rows = missionNamespace getVariable [format ["ALiVE_COP_BftData_%1", _key], []];
if !(_rows isEqualType []) exitWith {[]};

private _out = [];
{
    if !(_x isEqualType [] && {count _x >= 4}) then {continue};
    _x params ["_pos", "_sideKey", "_type", "_count"];
    if (toUpper str _sideKey isNotEqualTo _key) then {continue};
    if !(_pos isEqualType [] && {count _pos >= 2}) then {continue};
    _out pushBack [_pos, toLower str _type, _count];
} forEach _rows;
_out
