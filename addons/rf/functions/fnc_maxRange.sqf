#include "script_component.hpp"
/*
 * Author: JMSB
 * THE PREFILTER. The distance at which a link on this band reaches quality 0
 * over clear ground with nothing in the way - no pair further apart than this
 * can link, so the mesh never casts a ray for it. Inverse of the log-distance
 * path loss at snr = thr against the band's floor.
 *
 * Arguments:
 * 0: Band <STRING>
 * 1: TX power plus both antenna gains, dB(m) <NUMBER>
 *
 * Return Value:
 * Distance m <NUMBER>
 *
 * Example:
 * ["UHF", 41] call jmfsb_rf_fnc_maxRange
 *
 * Public: No
 */

params [["_band", "VHF", [""]], ["_eirp", 0, [0]]];

(GVAR(bands) getOrDefault [_band, [VHF_EXP, VHF_REF, VHF_FLOOR]]) params ["_exp", "_ref", "_floor"];
private _thr = missionNamespace getVariable [QGVAR(thr), DEFAULT_THR_DB];

10 ^ ((_eirp - _ref - (_floor + _thr)) / (10 * _exp))
