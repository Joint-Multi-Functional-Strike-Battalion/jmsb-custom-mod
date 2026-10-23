#include "script_component.hpp"
/*
 * Author: JMSB
 * THE LINK BUDGET, as a pure function (docs/DESIGN_RF.md "Link budget"):
 *
 *   rx      = tx + gainTx + gainRx - loss
 *   snr     = rx - noise
 *   quality = clamp((snr - thr) / span, 0, 1), and 0 below the receiver's
 *             sensitivity
 *
 * loss is everything the world takes - path loss, terrain, clutter and body -
 * already summed by the caller (jmfsb_rf_fnc_pathLoss, jmfsb_rf_fnc_bodyLoss).
 * noise is the floor plus whatever the noise-source hooks add
 * (jmfsb_rf_fnc_noise). No registry, no world query: the same numbers give the
 * same answer, which is what the range self-test leans on.
 *
 * Arguments:
 * 0: TX power dBm <NUMBER>
 * 1: TX antenna gain dB <NUMBER>
 * 2: RX antenna gain dB <NUMBER>
 * 3: Total loss dB <NUMBER>
 * 4: Noise at the receiver dBm <NUMBER>
 * 5: RX sensitivity dBm <NUMBER>
 * 6: Threshold dB (optional, default the setting) <NUMBER>
 * 7: Span dB (optional, default the setting) <NUMBER>
 *
 * Return Value:
 * [rx dBm, snr dB, quality 0..1] <ARRAY>
 *
 * Example:
 * [37, 2, 2, 120, -110, -112] call jmfsb_rf_fnc_linkBudget
 *
 * Public: Yes
 */

params [
    ["_tx", 0, [0]],
    ["_gTx", 0, [0]],
    ["_gRx", 0, [0]],
    ["_loss", 0, [0]],
    ["_noise", VHF_FLOOR, [0]],
    ["_sens", VHF_FLOOR, [0]],
    ["_thr", missionNamespace getVariable [QGVAR(thr), DEFAULT_THR_DB], [0]],
    ["_span", missionNamespace getVariable [QGVAR(span), DEFAULT_SPAN_DB], [0]]
];

private _rx = _tx + _gTx + _gRx - _loss;
private _snr = _rx - _noise;
private _quality = if (_rx < _sens) then {0} else {(((_snr - _thr) / (_span max 1)) max 0) min 1};

[_rx, _snr, _quality]
