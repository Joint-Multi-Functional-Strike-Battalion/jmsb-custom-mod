#include "script_component.hpp"
/*
 * Author: YonV
 * What the enemy commanders currently know about a side's forces.
 *
 * Every OPCOM keeps "knownentities" - the spot reports its troops file -
 * and the COP broadcasts them as ALiVE_COP_IntelData_<SIDE> (mil_c2istar
 * cop fnc_COPServer.sqf:346): [pos, sideKey, type, factionCode, count,
 * sizeInd, activity, heading, speed, age, isMixed, trail]. Read for every
 * side hostile to the asking one, filtered to entries ABOUT the asking one,
 * this is "the enemy has your position" - the one thing a patrol most
 * wants to know before it is too late.
 *
 * Public variables, so this answers on any machine.
 *
 * Arguments:
 * 0: Side <SIDE> - whose forces are being asked about
 *
 * Return Value:
 * [[pos <ARRAY>, type <STRING>, count <NUMBER>, age <NUMBER>, bySide <STRING>], ...]
 *
 * Example:
 * [west] call jmfsb_adapter_alive_fnc_enemyKnowledge
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [sideUnknown]]];
if (_side isEqualTo sideUnknown) exitWith {[]};

private _me = toUpper str _side;
private _out = [];
{
    _x params ["_enemy", "_key"];
    if (_enemy getFriend _side >= 0.6) then {continue};
    private _rows = missionNamespace getVariable [format ["ALiVE_COP_IntelData_%1", _key], []];
    if !(_rows isEqualType []) then {continue};
    {
        if !(_x isEqualType [] && {count _x >= 10}) then {continue};
        _x params ["_pos", "_sideKey", "_type", "", "_count", "", "", "", "", "_age"];
        if (toUpper str _sideKey isNotEqualTo _me) then {continue};
        if !(_pos isEqualType [] && {count _pos >= 2}) then {continue};
        _out pushBack [_pos, toLower str _type, _count, _age, _key];
    } forEach _rows;
} forEach [[west, "WEST"], [east, "EAST"], [independent, "GUER"]];
_out
