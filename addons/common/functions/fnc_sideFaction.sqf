#include "script_component.hpp"
/*
 * Author: YonV
 * The faction a side fights with, read off the men the mission put on the map.
 *
 * WHO WITHOUT ALiVE (user, 2026-11-02: "works with or without"). With ALiVE a
 * commander names its faction; without one, the mission's own placement does:
 * the most common faction among that side's AI. Never a setting - a mission
 * maker who placed Iranian infantry gets Iranian reinforcements without typing
 * a class anywhere. A unit handed in (one synchronised to a module) wins
 * outright, which is how a mission says which faction it means.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: A unit naming the faction outright <OBJECT> (optional)
 *
 * Return Value:
 * Faction class, "" when the side has nobody on the map <STRING>
 *
 * Example:
 * private _faction = [east] call jmfsb_common_fnc_sideFaction;
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [sideUnknown]], ["_named", objNull, [objNull]]];

if (!isNull _named && {(faction _named) isNotEqualTo ""}) exitWith {faction _named};

private _counts = createHashMap;
{
    if (isPlayer _x || {(side group _x) isNotEqualTo _side}) then {continue};
    private _f = faction _x;
    _counts set [_f, (_counts getOrDefault [_f, 0]) + 1];
} forEach allUnits;

private _best = "";
private _most = 0;
{
    if (_y > _most) then {_best = _x; _most = _y};
} forEach _counts;

_best
