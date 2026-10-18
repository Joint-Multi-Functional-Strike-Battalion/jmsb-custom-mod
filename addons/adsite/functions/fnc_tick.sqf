#include "..\script_component.hpp"
/*
 * Author: JMSB
 * The one engagement pass, every ADS_TICK seconds while threats are in the
 * air. Server only.
 *
 *   1. an engaged threat whose intercept time has come is rolled
 *      (FUNC(resolve)); a threat past its impact time landed - a leak
 *   2. free units are given open threats (FUNC(assign)), under ADS_EVAL_CAP
 *      feasibility tests and ADS_ASSIGN_CAP engagements per pass
 *   3. no threat left: the PFH removes itself
 *
 * The pass is timed (diag_tickTime); one over ADS_WARN_MS logs a WARNING at
 * most once per ADS_WARN_GAP seconds. `#jmfsb adsite` shows the last and the
 * worst.
 *
 * Arguments:
 * 0: Unused <ANY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * (CBA per-frame handler)
 *
 * Public: No
 */

params ["", "_handle"];

private _t0 = diag_tickTime;
private _now = CBA_missionTime;
GVAR(pass) = GVAR(pass) + 1;

private _keep = [];
{
    private _threat = _x;
    private _unitKey = _threat select T_UNIT;
    if (_unitKey isNotEqualTo "" && {_now >= (_threat select T_RESOLVE)}) then {
        if ([_threat] call FUNC(resolve)) then { continue };
    };
    if (_now >= (_threat select T_TIMPACT)) then {
        GVAR(stats) set ["leaks", (GVAR(stats) get "leaks") + 1];
        continue;
    };
    _keep pushBack _threat;
} forEach GVAR(threats);
GVAR(threats) = _keep;

if (_keep isEqualTo []) then {
    [_handle] call CBA_fnc_removePerFrameHandler;
    GVAR(pfh) = -1;
} else {
    [_now] call FUNC(assign);
};

private _ms = (diag_tickTime - _t0) * 1000;
GVAR(lastMs) = _ms;
GVAR(maxMs) = GVAR(maxMs) max _ms;
if (_ms > ADS_WARN_MS && {_now - GVAR(lastWarn) > ADS_WARN_GAP}) then {
    GVAR(lastWarn) = _now;
    WARNING_3("engagement pass took %1 ms (%2 threats, %3 units) - over budget",_ms toFixed 2,count _keep,count GVAR(units));
};
