#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: an AI group's radio - the man carrying its best set and that set's
 * RF profile (jmfsb_rf_fnc_carriedSets: his radio-slot item, his radio bag).
 * A set that can DF beats one that cannot, and the tighter DF class wins
 * (DF_PROFILES); the leader is looked at first, so he keeps it on a tie.
 * Cached per group for AI_SET_REFRESH_S: a DF tick asks for every enemy
 * group, and gear seldom changes.
 *
 * Arguments:
 * 0: Group <GROUP>
 *
 * Return Value:
 * [man, profile], [objNull, ""] when nobody in it carries a set <ARRAY>
 *
 * Example:
 * ([_group] call jmfsb_ew_fnc_aiSet) params ["_man", "_profile"]
 *
 * Public: No
 */

params [["_group", grpNull, [grpNull]]];

if (isNull _group) exitWith {[objNull, ""]};

private _now = CBA_missionTime;
private _key = hashValue _group;
private _hit = GVAR(aiSets) getOrDefault [_key, []];
if (_hit isNotEqualTo [] && {(_now - (_hit select 0)) < AI_SET_REFRESH_S} && {alive (_hit select 1) || (_hit select 2) isEqualTo ""}) exitWith {
    _hit select [1, 2]
};

private _best = [objNull, "", AI_SET_NO_DF + 1];
private _men = [leader _group] + ((units _group) - [leader _group]);
{
    private _man = _x;
    if (!alive _man) then {continue};
    {
        private _profile = _x select 2;
        private _i = DF_PROFILES findIf {(_x select 0) isEqualTo _profile};
        private _rank = [AI_SET_NO_DF, (DF_PROFILES select _i) select 1] select (_i >= 0);
        if (_rank < (_best select 2)) then {_best = [_man, _profile, _rank]};
    } forEach ([_man] call EFUNC(rf,carriedSets));
} forEach _men;

GVAR(aiSets) set [_key, [_now, _best select 0, _best select 1]];
[_best select 0, _best select 1]
