#include "script_component.hpp"
/*
 * Author: JMSB
 * THE SATELLITE LINK BUDGET, one direction (docs/DESIGN_RF.md "The satellite
 * link"). No distance, no terrain, no clutter: the signal through the bird
 * arrives at a constant level, placed so that clear sky reads
 * SAT_LINK_QUALITY at the current threshold and span, less the rain fade of
 * this tick (jmfsb_rf_satFade, from the "SAT rain fade" setting and the
 * weather). The noise at the receiver is jmfsb_rf_fnc_noise on the SAT band,
 * so a jammer on SAT (EW's SAT domain, the jamming addon's GPS zones) raises
 * it and the link degrades exactly as a ground link would. No open sky at
 * either end: no signal.
 *
 * Arguments:
 * 0: Noise at the receiver on SAT, dBm <NUMBER>
 * 1: RX sensitivity dBm <NUMBER>
 * 2: Both ends have open sky (optional, default true) <BOOL>
 *
 * Return Value:
 * [rx dBm, snr dB, quality 0..1] <ARRAY>
 *
 * Example:
 * [[_pos, "SAT", "C2", 25] call jmfsb_rf_fnc_noise, -118] call jmfsb_rf_fnc_satBudget
 *
 * Public: No
 */

params [["_noise", SAT_FLOOR, [0]], ["_sens", SAT_FLOOR, [0]], ["_open", true, [true]]];

private _floor = (GVAR(bands) getOrDefault [SAT_BAND, [SAT_EXP, SAT_REF, SAT_FLOOR]]) select 2;
private _thr = missionNamespace getVariable [QGVAR(thr), DEFAULT_THR_DB];
private _span = missionNamespace getVariable [QGVAR(span), DEFAULT_SPAN_DB];

private _rx = if (_open) then {
    _floor + _thr + SAT_LINK_QUALITY * _span - GVAR(satFade)
} else {
    NO_SIGNAL_DBM
};

[_rx, 0, 0, 0, _noise, _sens, _thr, _span] call FUNC(linkBudget)
