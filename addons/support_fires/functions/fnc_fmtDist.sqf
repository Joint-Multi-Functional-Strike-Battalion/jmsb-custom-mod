#include "script_component.hpp"
/*
 * Author: JMSB
 * A distance as the board reads it: metres under a kilometre, kilometres to
 * one decimal above ("400 m", "12 km", "14.2 km").
 *
 * Arguments:
 * 0: Distance (m) <NUMBER>
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * [14230] call jmfsb_support_fires_fnc_fmtDist
 *
 * Public: No
 */

params [["_m", 0, [0]]];

if (_m < 1000) exitWith {format ["%1 m", round _m]};

private _km = (round (_m / 100)) / 10;
if (_km isEqualTo round _km) exitWith {format ["%1 km", round _km]};
format ["%1 km", _km toFixed 1]
