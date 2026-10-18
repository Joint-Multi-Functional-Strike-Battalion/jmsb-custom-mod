#include "..\script_component.hpp"
/*
 * Author: JMSB
 * The JMSB - Air Defence Site module: its synced air defence vehicles share one
 * alarm area and take the module's Protected Radius and Intercept Chance
 * (either left at its "own" value falls back to the vehicle's reach and the
 * setting). Synced vehicles that are not air defence are skipped and named in
 * the RPT.
 *
 * WHERE is the module's position and WHAT is its sync - nothing on it says a
 * side.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, [], true] call jmfsb_adsite_fnc_moduleSite
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic} || {!isServer}) exitWith {};

// a synced crewman means his vehicle
private _members = [];
{
    private _v = vehicle _x;
    if (_v isKindOf "AllVehicles" && {!(_v isKindOf "CAManBase")}) then { _members pushBackUnique _v };
} forEach ((synchronizedObjects _logic) + _units);

private _radius = _logic getVariable ["radius", 0];
// blank in Eden = the Intercept chance setting, carried on as -1 (FUNC(register)'s "use the setting")
private _chanceText = trim (_logic getVariable ["interceptChance", ""]);
private _chance = if (_chanceText isEqualTo "") then {-1} else {(parseNumber _chanceText) max 0 min 1};
private _key = format ["site_%1", mapGridPosition _logic];

private _n = 0;
{
    if ([_x, _key, _radius, _chance, true] call FUNC(register)) then {
        _n = _n + 1;
    } else {
        WARNING_2("Air Defence Site at %1: %2 is not air defence - skipped",mapGridPosition _logic,typeOf _x);
    };
} forEach _members;

INFO_2("Air Defence Site at %1: %2 unit(s)",mapGridPosition _logic,_n);
