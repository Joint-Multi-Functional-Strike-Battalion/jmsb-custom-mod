#include "script_component.hpp"
/*
 * Author: YonV
 * THE MONITOR TRACES (user, 2026-11-08: "make this fancier with maybe a ekg",
 * then "is this even a real ekg looks the same on every one"): a heart
 * monitor's two lines for the world panel (FUNC(hudDraw)), TRACE_SECONDS of
 * signal scrolling left in TRACE_POINTS columns.
 *
 * THE EKG follows the patient's own rhythm and rate (TRACE_RHYTHMS):
 *
 *     sinus  P, QRS, T - the complex is a fixed length in SECONDS
 *            (TRACE_P/QRS/T timings) and the beats come every 60 / rate,
 *            so a fast heart packs them close and a slow one leaves a long
 *            flat between them - green
 *     pea    the same complexes, no pulse behind them - red
 *     vt     wide fast waves, never slower than TRACE_VT_RATE - red
 *     vf     a coarse irregular scrawl - red
 *     flat   asystole, a dead man: a line with a little drift - red
 *
 * Each patient has his own phase and R height (the seed), so two men at the
 * same rate do not beat in step.
 *
 * THE PLETH under it, the pulse oximeter's wave: one pulse a beat, a little
 * after the R wave, its height the pulse strength (0 to 1 - the profile gives
 * it from the pulse pressure); no pulse, no wave.
 *
 * Arguments:
 * 0: [beats per minute, rhythm (TRACE_RHYTHMS), seed 0-1, pulse 0-1] <ARRAY>
 *
 * Return Value:
 * [EKG columns, oldest first, each [low, high] - 1 a full R wave, 0 the
 * baseline <ARRAY>, EKG colour RGBA <ARRAY>, pleth columns, each [low, high]
 * 0-1 <ARRAY>], or [] for no trace <ARRAY>
 *
 * Example:
 * [[72, "sinus", 0.3, 0.8]] call jmfsb_watch_fnc_trace
 *
 * Public: No
 */

params [["_reading", [], [[]]]];

_reading params [["_bpm", 0, [0]], ["_rhythm", "flat", [""]], ["_seed", 0, [0]], ["_pulse", 0, [0]]];
if !(_rhythm in TRACE_RHYTHMS) exitWith {[]};

private _colour = [COLOUR_RED, TRACE_GREEN] select (_rhythm isEqualTo "sinus");
private _rate = [_bpm max 1, _bpm max TRACE_VT_RATE] select (_rhythm isEqualTo "vt");
private _period = 60 / _rate;
// the complex shrinks only when the beats come faster than it is long
private _fit = (_period / TRACE_COMPLEX_S) min 1;
private _offset = _seed * TRACE_SEED_S;
private _rHeight = TRACE_R_MIN + (1 - TRACE_R_MIN) * _seed;
if (!(_rhythm in ["sinus", "pea"])) then {_pulse = 0};
_pulse = 0 max _pulse min 1;

// One PQRST complex, _t seconds into the beat: P bump, Q dip, R spike, S
// dip, T bump, flat between.
private _fnc_complex = {
    params ["_t"];
    private _u = _t / _fit;
    switch (true) do {
        case (_u >= TRACE_P_AT && _u < TRACE_P_AT + TRACE_P_S): {0.15 * sin (((_u - TRACE_P_AT) / TRACE_P_S) * 180)};
        case (_u >= TRACE_Q_AT && _u < TRACE_Q_AT + TRACE_QRS_STEP): {-0.12 * ((_u - TRACE_Q_AT) / TRACE_QRS_STEP)};
        case (_u >= TRACE_Q_AT + TRACE_QRS_STEP && _u < TRACE_Q_AT + 2 * TRACE_QRS_STEP): {
            -0.12 + (_rHeight + 0.12) * ((_u - TRACE_Q_AT - TRACE_QRS_STEP) / TRACE_QRS_STEP)
        };
        case (_u >= TRACE_Q_AT + 2 * TRACE_QRS_STEP && _u < TRACE_Q_AT + 3 * TRACE_QRS_STEP): {
            _rHeight - (_rHeight + 0.3) * ((_u - TRACE_Q_AT - 2 * TRACE_QRS_STEP) / TRACE_QRS_STEP)
        };
        case (_u >= TRACE_Q_AT + 3 * TRACE_QRS_STEP && _u < TRACE_Q_AT + 4 * TRACE_QRS_STEP): {
            -0.3 + 0.3 * ((_u - TRACE_Q_AT - 3 * TRACE_QRS_STEP) / TRACE_QRS_STEP)
        };
        case (_u >= TRACE_T_AT && _u < TRACE_T_AT + TRACE_T_S): {0.3 * sin (((_u - TRACE_T_AT) / TRACE_T_S) * 180)};
        default {0};
    };
};

private _fnc_ekg = {
    params ["_s"];
    private _in = (_s + _offset) mod _period;
    switch (_rhythm) do {
        case "sinus";
        case "pea": {[_in] call _fnc_complex};
        case "vt": {0.8 * sin ((_in / _period) * 360)};
        case "vf": {0.4 * sin (_s * TRACE_VF_A) + 0.25 * sin (_s * TRACE_VF_B + 40)};
        default {TRACE_FLAT_AMP * sin (_s * TRACE_FLAT_DRIFT)};
    }
};

// The pleth: a fast upstroke TRACE_PLETH_DELAY after the R wave, a slow
// fall with the dicrotic notch on it.
private _fnc_pleth = {
    params ["_s"];
    if (_pulse <= 0) exitWith {0};
    private _p = (((_s + _offset - TRACE_PLETH_DELAY * _fit) mod _period) + _period) mod _period / _period;
    private _v = if (_p < TRACE_PLETH_RISE) then {
        sin ((_p / TRACE_PLETH_RISE) * 90)
    } else {
        private _q = (_p - TRACE_PLETH_RISE) / (1 - TRACE_PLETH_RISE);
        private _notch = if (_q >= 0.2 && _q < 0.4) then {0.12 * sin (((_q - 0.2) / 0.2) * 180)} else {0};
        (1 - _q) ^ 2 + _notch
    };
    _pulse * _v
};

// A column per TRACE_POINTS, its low and high over TRACE_SUBSAMPLES samples
// and the column before's last - so a QRS narrower than a column still shows
// whole, and each column joins the one before it.
private _step = TRACE_SECONDS / (TRACE_POINTS * TRACE_SUBSAMPLES);
private _start = time - TRACE_SECONDS;
private _lastE = [_start] call _fnc_ekg;
private _lastP = [_start] call _fnc_pleth;
private _ekg = [];
private _pleth = [];
for "_i" from 0 to TRACE_POINTS - 1 do {
    private _eLo = _lastE;
    private _eHi = _lastE;
    private _pLo = _lastP;
    private _pHi = _lastP;
    for "_j" from 1 to TRACE_SUBSAMPLES do {
        private _s = _start + (_i * TRACE_SUBSAMPLES + _j) * _step;
        _lastE = [_s] call _fnc_ekg;
        _lastP = [_s] call _fnc_pleth;
        _eLo = _eLo min _lastE;
        _eHi = _eHi max _lastE;
        _pLo = _pLo min _lastP;
        _pHi = _pHi max _lastP;
    };
    _ekg pushBack [_eLo, _eHi];
    _pleth pushBack [_pLo, _pHi];
};
[_ekg, _colour, _pleth]
