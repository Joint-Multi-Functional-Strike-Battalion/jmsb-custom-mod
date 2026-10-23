#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_bandMhz: a band's frequency ranges in MHz (RF_BAND_MHZ), on every
 * machine - for a screen that draws where on the band a frequency sits.
 *
 * Arguments:
 * 0: Band "VHF" | "UHF" | "SAT" | "VIDEO" <STRING>
 *
 * Return Value:
 * [[low, high], ...] MHz, [] for an unknown band <ARRAY>
 *
 * Example:
 * ["VIDEO"] call jmfsb_rf_fnc_bandMhz
 *
 * Public: Yes
 */

params [["_band", "", [""]]];

+((GVAR(bandMhz) getOrDefault [_band, [[], 0]]) select 0)
