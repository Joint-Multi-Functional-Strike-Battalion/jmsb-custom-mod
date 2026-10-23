#include "script_component.hpp"
/*
 * Author: JMSB
 * A band's row of the band table, read-only: [path-loss exponent, loss at
 * 1 m dB, noise floor dBm], as the settings have it now. The floor is what
 * jmfsb_rf_fnc_noise returns with no noise source registered, so a consumer
 * can show the rise a jammer causes above it.
 *
 * Arguments:
 * 0: Band "VHF" | "UHF" | "SAT" | "VIDEO" <STRING>
 *
 * Return Value:
 * [exponent, ref dB, floor dBm], [] for an unknown band <ARRAY>
 *
 * Example:
 * (["UHF"] call jmfsb_rf_fnc_bandInfo) select 2
 *
 * Public: Yes
 */

params [["_band", "", [""]]];

+(GVAR(bands) getOrDefault [_band, []])
