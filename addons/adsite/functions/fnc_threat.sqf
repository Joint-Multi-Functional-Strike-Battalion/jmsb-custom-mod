#include "..\script_component.hpp"
/*
 * Author: JMSB
 * A relevant round has been fired (FUNC(shot)): predict where it lands ONCE,
 * find the AD units it threatens, and queue it. Server only.
 *
 * A unit is threatened when the predicted impact is inside its protect radius
 * and the shooter's side is hostile to it (getFriend under ADS_FRIEND) - or,
 * with Ignore Sides on, whoever fired. A round no unit protects against costs
 * this one pass over the units and is forgotten. At most ADS_THREAT_CAP are
 * held; the rest are counted as dropped.
 *
 * Arguments:
 * 0: Shot id <STRING>
 * 1: Shooter, where the round is local <OBJECT>
 * 2: Launch position, ASL <ARRAY>
 * 3: Launch velocity <ARRAY>
 * 4: [family, speed] (FUNC(family)) <ARRAY>
 * 5: Target position ASL, or [] <ARRAY>
 * 6: Shooter's side <SIDE>
 *
 * Return Value: None
 *
 * Example:
 * [QGVAR(threat), [_id, _gunner, _pos, _vel, _info, [], west]] call CBA_fnc_serverEvent
 *
 * Public: No
 */

params ["_id", "_owner", "_p0", "_v", "_info", "_target", "_side"];

if (!GVAR(enabled) || {count GVAR(units) == 0}) exitWith {};

private _family = _info select 0;
// a shell fired flat is a tank's direct fire, not artillery
if (_family == FAM_ARTILLERY && {(_v select 2) < (vectorMagnitude _v) * sin ADS_ARTY_PITCH}) exitWith {};

private _hit = [_p0, _v, _info, _target] call FUNC(predict);
if (_hit isEqualTo []) exitWith {};
_hit params ["_impact", "_tti", "_model", "_vUsed"];
if (_tti < ADS_TTI_MIN || _tti > ADS_TTI_MAX) exitWith {};

private _cands = [];
{
    _y params ["_veh", "", "", "_radius"];
    if (alive _veh && {(_veh distance2D _impact) <= _radius} && {
        GVAR(ignoreSides) || {((side _veh) getFriend _side) < ADS_FRIEND}
    }) then {
        _cands pushBack _x;
    };
} forEach GVAR(units);
if (_cands isEqualTo []) exitWith {};

if (count GVAR(threats) >= ADS_THREAT_CAP) exitWith {
    GVAR(stats) set ["dropped", (GVAR(stats) get "dropped") + 1];
};

private _now = CBA_missionTime;
GVAR(threats) pushBack [_id, _owner, _impact, _now + _tti, _model, _p0, _vUsed, _now, _cands, "", -1, _family];
GVAR(stats) set ["threats", (GVAR(stats) get "threats") + 1];

[_cands] call FUNC(alarm);
[] call FUNC(start);
