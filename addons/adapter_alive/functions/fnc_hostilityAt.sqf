#include "script_component.hpp"
/*
 * Author: YonV
 * How hostile the nearest settlement's civilians are to a side, 0 to 100.
 *
 * ALiVE's civilian model keeps a "hostility" hash on every settlement cluster
 * (amb_civ_population fnc_clusterHandler.sqf:160), keyed EAST / WEST / GUER,
 * moved by what each side does in the town - and by jmfsb's own
 * FUNC(bumpHostility). This is the read-side of that: a number a system can
 * scale by, so that how the players behave in a town changes what the town
 * does about them.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Side <SIDE>
 * 2: Search radius <NUMBER> (optional, default HOSTILITY_RADIUS)
 *
 * Return Value:
 * Hostility 0-100 <NUMBER>; 0 when there is no settlement in range
 *
 * Example:
 * [getPosATL player, west] call jmfsb_adapter_alive_fnc_hostilityAt
 *
 * Public: Yes
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]], ["_radius", HOSTILITY_RADIUS, [0]]];
if (!GVAR(ready) || {_pos isEqualTo []} || {_side isEqualTo sideUnknown}) exitWith {0};

private _hash = missionNamespace getVariable "ALIVE_clustersCivSettlement";
if (isNil "_hash" || {!(_hash isEqualType [])} || {count _hash <= HASH_VALUES}) exitWith {0};

private _key = toUpper str _side;
private _best = []; private _bestD = _radius;
{
    if !(_x isEqualType []) then {continue};
    private _c = [_x, "center", []] call ALiVE_fnc_hashGet;
    if (_c isEqualTo []) then {continue};
    private _d = _c distance2D _pos;
    if (_d < _bestD) then { _bestD = _d; _best = _x };
} forEach (_hash select HASH_VALUES);
if (_best isEqualTo []) exitWith {0};

private _hh = [_best, "hostility", []] call ALiVE_fnc_hashGet;
if (!(_hh isEqualType []) || {count _hh <= HASH_VALUES}) exitWith {0};
(([_hh, _key, 0] call ALiVE_fnc_hashGet) max 0) min 100
