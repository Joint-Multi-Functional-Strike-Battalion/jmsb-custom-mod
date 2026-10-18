#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Where a threat is at a given time, from its predicted path - never from the
 * round itself, which on a dedicated server may be another machine's.
 *
 * Arguments:
 * 0: Threat (T_* in script_component.hpp) <ARRAY>
 * 1: Mission time <NUMBER>
 *
 * Return Value:
 * Position ASL <ARRAY>
 *
 * Example:
 * [_threat, CBA_missionTime + 2] call jmfsb_adsite_fnc_posAt
 *
 * Public: No
 */

params ["_threat", "_t"];

private _p0 = _threat select T_P0;
private _t0 = _threat select T_T0;
private _dt = _t - _t0;

if ((_threat select T_MODEL) == MODEL_LINEAR) exitWith {
    private _span = ((_threat select T_TIMPACT) - _t0) max 0.1;
    private _f = ((_dt / _span) max 0) min 1;
    _p0 vectorAdd (((_threat select T_IMPACT) vectorDiff _p0) vectorMultiply _f)
};

(_p0 vectorAdd ((_threat select T_V0) vectorMultiply _dt)) vectorAdd [0, 0, -0.5 * ADS_GRAVITY * _dt * _dt]
