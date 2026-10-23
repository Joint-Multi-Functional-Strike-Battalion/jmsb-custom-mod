#include "script_component.hpp"
/*
 * Author: JMSB
 * A bearing as the player asked to read it (QGVAR(angleUnit)): degrees as
 * three digits, NATO mils as four, or both.
 *
 * Arguments:
 * 0: Bearing, degrees clockwise from grid north <NUMBER>
 *
 * Return Value:
 * The bearing <STRING>
 *
 * Example:
 * [45] call jmfsb_maptools_fnc_bearingText
 *
 * Public: No
 */

params [["_bearing", 0, [0]]];

private _deg = round ((_bearing mod DEG_PER_TURN + DEG_PER_TURN) mod DEG_PER_TURN);
private _mil = round (_deg * MILS_PER_TURN / DEG_PER_TURN);

private _degText = format ["%1°", [_deg mod DEG_PER_TURN, BEARING_DIGITS_DEG] call CBA_fnc_formatNumber];
private _milText = format ["%1 MIL", [_mil mod MILS_PER_TURN, BEARING_DIGITS_MIL] call CBA_fnc_formatNumber];

switch (GVAR(angleUnit)) do {
    case "deg": {_degText};
    case "mil": {_milText};
    default {format ["%1 / %2", _degText, _milText]};
}
