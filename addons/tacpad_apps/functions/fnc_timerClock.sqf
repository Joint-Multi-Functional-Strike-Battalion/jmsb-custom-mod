#include "script_component.hpp"
/*
 * Author: YonV
 * A running clock, not a rounded minute: a row that reads "1 MIN" for sixty
 * seconds is a label, not a timer. The archived device's own formatter, for
 * the TIMER app's roster, stopwatch and delays (FUNC(appTimer),
 * FUNC(timerLive)).
 *
 * Arguments:
 * 0: Seconds <NUMBER>
 *
 * Return Value:
 * "MM:SS", or "H:MM:SS" from an hour up <STRING>
 *
 * Example:
 * [125] call jmfsb_tacpad_apps_fnc_timerClock
 *
 * Public: No
 */

params [["_secs", 0, [0]]];

private _s = (round _secs) max 0;
private _h = floor (_s / 3600);
private _m = floor ((_s - _h * 3600) / 60);
private _r = _s - _h * 3600 - _m * 60;
if (_h > 0) then {
    format ["%1:%2:%3", _h, [_m, 2] call CBA_fnc_formatNumber, [_r, 2] call CBA_fnc_formatNumber]
} else {
    format ["%1:%2", [_m, 2] call CBA_fnc_formatNumber, [_r, 2] call CBA_fnc_formatNumber]
}
