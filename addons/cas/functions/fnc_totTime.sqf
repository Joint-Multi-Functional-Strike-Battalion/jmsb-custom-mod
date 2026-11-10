#include "script_component.hpp"
/*
 * Author: YonV
 * A CAS REQUEST's TIME ON TARGET as a mission time (2026-11-09, the 9-line's
 * TOT line - the call for fire's forms): "+5" five minutes from now; "1430"
 * or "143015" the next time the game's clock reads it, through the time
 * multiplier. Both CAS providers hold the pass until it (less the dive's
 * TOT_DIVE_LEAD s) - this addon's drones and support_air's aircraft.
 *
 * Arguments:
 * 0: The TOT line as typed <STRING>
 *
 * Return Value:
 * CBA_missionTime it is due, -1 none or not read <NUMBER>
 *
 * Example:
 * ["+5"] call jmfsb_cas_fnc_totTime
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

_text = trim _text;
if (_text isEqualTo "") exitWith {-1};

if ((_text select [0, 1]) isEqualTo TOT_PLUS) exitWith {
    private _minutes = _text select [1];
    if !(_minutes regexMatch "^\d+(\.\d+)?$") exitWith {-1};
    CBA_missionTime + (parseNumber _minutes) * TOT_MINUTE_S
};

private _digits = _text regexReplace ["[^0-9]", ""];
if !((count _digits) in [TOT_HHMM, TOT_HHMMSS]) exitWith {-1};
private _hh = parseNumber (_digits select [0, 2]);
private _mm = parseNumber (_digits select [2, 2]);
private _ss = [0, parseNumber (_digits select [4, 2])] select (count _digits isEqualTo TOT_HHMMSS);
private _due = _hh + _mm / TOT_MINUTE_S + _ss / TOT_HOUR_S;
private _hours = _due - dayTime;
if (_hours < 0) then {_hours = _hours + TOT_DAY_HOURS};
CBA_missionTime + _hours * TOT_HOUR_S / (timeMultiplier max 1)
