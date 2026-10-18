#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Can this unit intercept this threat, and where? One feasibility test - the
 * unit of work FUNC(assign) caps per pass.
 *
 * The layer decides the weapon: while the threat is more than
 * ADS_INNER_WINDOW seconds from impact only a missile may take it (the outer
 * layer); inside the window the gun or CIWS is tried first (the inner layer),
 * then a missile. A weapon is usable with a live AI gunner (a player's weapon
 * is never fired for him) and a round in it. The intercept point is led by
 * the interceptor's flight time from after the crew's reaction, refined
 * ADS_PLAN_PASSES times along the threat's predicted path, and must be inside
 * the weapon's reach and at least ADS_INTERCEPT_MARGIN before impact.
 *
 * Arguments:
 * 0: Unit record (U_* in script_component.hpp) <ARRAY>
 * 1: Threat (T_* in script_component.hpp) <ARRAY>
 * 2: Mission time now <NUMBER>
 *
 * Return Value:
 * [intercept time, aim point ASL, weapon entry, distance m, gunner], or [] <ARRAY>
 *
 * Example:
 * [_rec, _threat, CBA_missionTime] call jmfsb_adsite_fnc_plan
 *
 * Public: No
 */

params ["_rec", "_threat", "_now"];

_rec params ["_veh", "_gun", "_missile"];
private _impactAt = _threat select T_TIMPACT;
private _order = [[_missile], [_gun, _missile]] select ((_impactAt - _now) <= ADS_INNER_WINDOW);
private _from = getPosASL _veh;

private _out = [];
{
    if (_x isEqualTo []) then { continue };
    _x params ["_path", "", "", "_mag", "_speed", "_range"];

    private _gunner = [_veh turretUnit _path, driver _veh] select (_path isEqualTo [-1]);
    if (!alive _gunner || {isPlayer _gunner}) then { continue };
    if ((_veh magazineTurretAmmo [_mag, _path]) <= 0) then { continue };

    private _tI = _now + ADS_REACTION;
    private _at = [_threat, _tI] call FUNC(posAt);
    for "_i" from 1 to ADS_PLAN_PASSES do {
        _tI = _now + ADS_REACTION + (_from vectorDistance _at) / _speed;
        _at = [_threat, _tI] call FUNC(posAt);
    };
    private _d = _from vectorDistance _at;
    if (_d <= _range && {_tI <= _impactAt - ADS_INTERCEPT_MARGIN}) exitWith {
        _out = [_tI, _at, _x, _d, _gunner];
    };
} forEach _order;
_out
