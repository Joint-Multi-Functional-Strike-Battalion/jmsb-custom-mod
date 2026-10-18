#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Gives open threats to free AD units - one unit per threat; a miss reopens it
 * for another (FUNC(resolve)). Server only, from FUNC(tick).
 *
 * Unit-centric: each free unit (alive, not busy, its targeting mode not Off)
 * looks at the open threats it is a candidate for, tests each it can
 * (FUNC(plan)), and picks one by its mode - Random, Closest (nearest intercept
 * point) or Highest threat (soonest impact). The engagement is fired
 * (FUNC(fire)) on the gunner's machine and the unit is busy until its
 * intercept time.
 *
 * BOUNDED: at most ADS_EVAL_CAP plan tests and ADS_ASSIGN_CAP engagements per
 * pass; the unit order rotates each pass so a capped pass does not starve the
 * same units.
 *
 * Arguments:
 * 0: Mission time now <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * [CBA_missionTime] call jmfsb_adsite_fnc_assign
 *
 * Public: No
 */

params ["_now"];

private _open = GVAR(threats) select {(_x select T_UNIT) isEqualTo ""};
if (_open isEqualTo []) exitWith {};

// the free units among the open threats' candidates
private _free = [];
{
    {
        if (_x in _free) then { continue };
        private _rec = GVAR(units) get _x;
        if (isNil "_rec") then { continue };
        private _veh = _rec select U_VEH;
        if (!alive _veh || {(_rec select U_BUSY) > _now}) then { continue };
        if ((_veh getVariable [QGVAR(mode), ADS_MODE_DEFAULT]) isEqualTo ADS_MODE_OFF) then { continue };
        _free pushBack _x;
    } forEach (_x select T_CANDS);
} forEach _open;
if (_free isEqualTo []) exitWith {};

private _n = count _free;
private _start = GVAR(pass) mod _n;
_free = (_free select [_start, _n]) + (_free select [0, _start]);

private _evals = 0;
private _assigned = 0;
{
    private _key = _x;
    private _rec = GVAR(units) get _key;
    private _veh = _rec select U_VEH;

    private _options = [];
    {
        if !(_key in (_x select T_CANDS)) then { continue };
        if (_evals >= ADS_EVAL_CAP) exitWith {};
        _evals = _evals + 1;
        private _plan = [_rec, _x, _now] call FUNC(plan);
        if (_plan isNotEqualTo []) then { _options pushBack [_x, _plan] };
    } forEach _open;
    if (_options isEqualTo []) then { continue };

    private _pick = switch (_veh getVariable [QGVAR(mode), ADS_MODE_DEFAULT]) do {
        case ADS_MODE_RANDOM: { selectRandom _options };
        case ADS_MODE_HIGHEST: {
            private _best = _options select 0;
            { if (((_x select 0) select T_TIMPACT) < ((_best select 0) select T_TIMPACT)) then { _best = _x } } forEach _options;
            _best
        };
        default {
            private _best = _options select 0;
            { if (((_x select 1) select 3) < ((_best select 1) select 3)) then { _best = _x } } forEach _options;
            _best
        };
    };
    _pick params ["_threat", "_plan"];
    _plan params ["_tI", "_aim", "_entry", "", "_gunner"];
    _entry params ["", "_weapon", "_fireMode", "", "", "", "_isMissile"];

    _threat set [T_UNIT, _key];
    _threat set [T_RESOLVE, _tI];
    _rec set [U_BUSY, _tI];
    _open deleteAt (_open find _threat);

    private _args = [_veh, _gunner, _weapon, _fireMode, _aim, _isMissile];
    if (local _gunner) then {
        _args call FUNC(fire);
    } else {
        [QGVAR(fire), _args, _gunner] call CBA_fnc_targetEvent;
    };

    _assigned = _assigned + 1;
    if (_assigned >= ADS_ASSIGN_CAP || _evals >= ADS_EVAL_CAP || {_open isEqualTo []}) exitWith {};
} forEach _free;
