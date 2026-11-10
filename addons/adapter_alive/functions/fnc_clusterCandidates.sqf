#include "script_component.hpp"
/*
 * Author: YonV
 * ALiVE's map knowledge as plain positions: where the water is, where the
 * towns are.
 *
 * The globals are per-map static indexes built by ALiVE's analysis
 * (ALIVE_clustersCivMarine, ALIVE_clustersCivSettlement - note the CIV in
 * both names). On a map ALiVE has not indexed they do not exist and this
 * returns empty, which callers must treat as "cannot place here" out loud.
 *
 * A cluster's centre is stored 2D (verified: clusters.<map>_civ.sqf, e.g.
 * ["center",[14523,6229.63]]), so it is lifted to 3D here rather than in
 * every consumer.
 *
 * Arguments:
 * 0: Kind - "marine" or "settlement" <STRING>
 *
 * Return Value:
 * [[centre <ARRAY>, size <NUMBER>], ...] <ARRAY>
 *
 * Example:
 * ["marine"] call jmfsb_adapter_alive_fnc_clusterCandidates
 */

params [["_kind", "marine", [""]]];

private _hash = switch (toLower _kind) do {
    case "marine": {missionNamespace getVariable "ALIVE_clustersCivMarine"};
    case "settlement": {missionNamespace getVariable "ALIVE_clustersCivSettlement"};
    default {nil};
};

if (isNil "_hash") exitWith {[]};

private _out = [];
{
    private _c = _x;
    if !(_c isEqualType []) then {continue};

    private _pos = [_c, "center", []] call ALiVE_fnc_hashGet;
    if (_pos isEqualTo []) then {continue};
    if (count _pos < 3) then { _pos = [_pos select 0, _pos select 1, 0] };

    _out pushBack [_pos, [_c, "size", 150] call ALiVE_fnc_hashGet];
} forEach (_hash select HASH_VALUES);

_out
