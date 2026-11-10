#include "script_component.hpp"
/*
 * Author: YonV
 * One tick of the escorts' attack on a target area (user, 2026-11-02: ALL
 * ATTACK; FUNC(escortAttack)), from their watch (FUNC(escortTick)).
 *
 * THE TARGETS: every hostile vehicle, static and man alive inside the area -
 * vehicles and statics first, then men, each nearest the centre first. Not
 * one with a man of the players' own side within the friendly range, unless
 * danger close was acknowledged (the lead's own release rule).
 *
 * SHARED OUT: each escort keeps its target while it is alive and still a
 * target; else it takes the first one no other escort has, or - fewer targets
 * than escorts - the first one. It is revealed it, let loose (RED, COMBAT)
 * and sent over it (a rotary escort to its standoff) with its own weapons.
 * An escort with nothing left but flares is Winchester and rejoins.
 *
 * A target an escort was put on that is now destroyed is counted on the lead
 * (QGVAR(escortHits)). The attack ends (FUNC(escortAttackEnd)) when no target
 * is left, every escort is Winchester, or its time is up.
 *
 * Arguments:
 * 0: The lead aircraft <OBJECT>
 * 1: Its escorts still alive <ARRAY>
 * 2: The attack <HASHMAP>
 *
 * Return Value:
 * The escorts attacking this tick - the rest fly their slots <ARRAY>
 *
 * Example:
 * [_lead, _alive, _attack] call jmfsb_support_fnc_escortStrike
 *
 * Public: No
 */

params [["_lead", objNull, [objNull]], ["_escorts", [], [[]]], ["_attack", createHashMap, [createHashMap]]];

private _pos = _attack get "pos";
private _side = _attack get "side";
private _friendly = _attack get "friendly";
private _danger = _attack get "danger";
private _engaged = _attack get "engaged";
private _hit = _attack get "hit";

// THE COUNT: what an escort was put on and is now destroyed.
{
    if (!alive _x && !(_x in _hit)) then {_hit pushBack _x};
} forEach _engaged;
_lead setVariable [QGVAR(escortHits), count _hit];

if (CBA_missionTime > (_attack get "until")) exitWith {
    [_lead] call FUNC(escortAttackEnd);
    []
};

// Armed: a magazine with rounds in it that is not a countermeasure.
private _armed = _escorts select {
    ((magazinesAllTurrets _x) findIf {
        (_x select 2) > 0 && getText (configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> (_x select 0) >> "ammo") >> "simulation") isNotEqualTo ESCORT_CM_AMMO_SIM
    }) > -1
};

private _hostile = (_pos nearEntities [["AllVehicles"], _attack get "radius"]) select {
    alive _x
        && !(_x isKindOf "Air")
        && (side group _x) isNotEqualTo civilian
        && (_side getFriend (side group _x)) < ESCORT_FRIEND_LIMIT
};
if (!_danger && _friendly > 0) then {
    _hostile = _hostile select {
        ((_x nearEntities [["CAManBase"], _friendly]) findIf {alive _x && (side group _x) isEqualTo _side}) < 0
    };
};
private _vehicles = (_hostile select {!(_x isKindOf "CAManBase")}) apply {[_x distance2D _pos, _x]};
private _men = (_hostile select {_x isKindOf "CAManBase"}) apply {[_x distance2D _pos, _x]};
_vehicles sort true;
_men sort true;
private _targets = (_vehicles apply {_x select 1}) + (_men apply {_x select 1});

if (_targets isEqualTo [] || _armed isEqualTo []) exitWith {
    [_lead] call FUNC(escortAttackEnd);
    []
};

private _taken = [];
{
    private _esc = _x;
    private _target = _esc getVariable [QGVAR(attackTarget), objNull];
    if !(_target in _targets) then {
        private _free = _targets select {!(_x in _taken)};
        _target = (_free + _targets) select 0;
        _esc setVariable [QGVAR(attackTarget), _target];
        _engaged pushBackUnique _target;
    };
    _taken pushBack _target;

    private _grp = group effectiveCommander _esc;
    _grp reveal [_target, ESCORT_REVEAL];
    _grp setCombatMode "RED";
    _grp setBehaviour "COMBAT";
    _grp setSpeedMode "FULL";
    {
        _x doTarget _target;
        _x doFire _target;
    } forEach ((crew _esc) select {alive _x});
    _esc doMove ([getPosATL _target, _target getPos [ESCORT_STANDOFF_HELI, _target getDir _esc]] select (_esc isKindOf "Helicopter"));
} forEach _armed;

_armed
