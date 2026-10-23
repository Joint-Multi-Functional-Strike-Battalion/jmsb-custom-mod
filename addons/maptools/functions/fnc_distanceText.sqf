#include "script_component.hpp"
/*
 * Author: JMSB
 * A distance in metres under a kilometre, in kilometres to two places above.
 *
 * Arguments:
 * 0: Distance, metres <NUMBER>
 *
 * Return Value:
 * The distance <STRING>
 *
 * Example:
 * [1234] call jmfsb_maptools_fnc_distanceText
 *
 * Public: No
 */

params [["_metres", 0, [0]]];

if (_metres < M_PER_KM) exitWith {format ["%1 M", round _metres]};

format ["%1 KM", [_metres / M_PER_KM, 1, KM_DECIMALS] call CBA_fnc_formatNumber]
