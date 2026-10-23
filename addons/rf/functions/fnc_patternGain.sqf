#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_patternGain: what an antenna's pattern does toward a point. Omni
 * (RF_PATTERN_OMNI) reaches every way and adds nothing; a sector
 * (RF_PATTERN_SECTOR) reaches only inside its lobe - so many degrees wide
 * about its azimuth - and adds its gain there. No raycasts.
 *
 * Arguments:
 * 0: Antenna position ASL <ARRAY>
 * 1: Point position ASL <ARRAY>
 * 2: Pattern "omni" | "sector" <STRING>
 * 3: Azimuth, degrees true (optional, default 0) <NUMBER>
 * 4: Lobe width, degrees (optional, default 0) <NUMBER>
 * 5: Gain in the lobe dB (optional, default 0) <NUMBER>
 *
 * Return Value:
 * [reaches the point, gain dB] <ARRAY>
 *
 * Example:
 * [getPosASL _host, eyePos player, "sector", 45, 120, 3] call jmfsb_rf_fnc_patternGain
 *
 * Public: Yes
 */

params [
    ["_from", [0, 0, 0], [[]], 3],
    ["_to", [0, 0, 0], [[]], 3],
    ["_pattern", RF_PATTERN_OMNI, [""]],
    ["_azimuth", 0, [0]],
    ["_width", 0, [0]],
    ["_gain", 0, [0]]
];

if (_pattern isNotEqualTo RF_PATTERN_SECTOR) exitWith {[true, 0]};

// How far off the azimuth the point lies, 0 to 180 either way.
private _off = abs (((((_from getDir _to) - _azimuth) mod DEGREES_FULL) + DEGREES_FULL + DEGREES_HALF) mod DEGREES_FULL - DEGREES_HALF);
[_off <= _width / 2, _gain]
