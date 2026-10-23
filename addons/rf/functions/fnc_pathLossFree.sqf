#include "script_component.hpp"
/*
 * Author: JMSB
 * Log-distance path loss for a band over clear ground: ref + 10 n log10(d).
 * Pure arithmetic; the band table is the only thing it reads. Public so a
 * noise source (jmfsb_rf_fnc_addNoiseSource) can price its own emission with
 * the same band table the link budget uses - no raycasts, so it is cheap
 * enough for the per-receiver hook.
 *
 * Arguments:
 * 0: Distance m <NUMBER>
 * 1: Band "VHF" | "UHF" | "SAT" | "VIDEO" <STRING>
 *
 * Return Value:
 * Loss dB <NUMBER>
 *
 * Example:
 * [1500, "UHF"] call jmfsb_rf_fnc_pathLossFree
 *
 * Public: Yes
 */

params [["_dist", 1, [0]], ["_band", "VHF", [""]]];

(GVAR(bands) getOrDefault [_band, [VHF_EXP, VHF_REF, VHF_FLOOR]]) params ["_exp", "_ref"];

_ref + 10 * _exp * log (_dist max 1)
