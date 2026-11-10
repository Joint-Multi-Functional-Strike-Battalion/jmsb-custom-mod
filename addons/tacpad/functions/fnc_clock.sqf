#include "script_component.hpp"
/*
 * Author: YonV
 * A mission time as HHMM, for the right-hand column of a traffic entry.
 *
 * The design puts a time on every row and it is the second thing the eye uses
 * after the badge - "the FLASH one, and it came in four minutes ago" is the
 * whole question a reader answers.
 *
 * Arguments:
 * 0: CBA_missionTime the entry was last touched <NUMBER>
 *
 * Return Value:
 * "HHMM" <STRING>
 *
 * Example:
 * private _t = [_entry get "lastActivity"] call jmfsb_tacpad_fnc_clock
 *
 * Public: No
 */

params [["_stamp", 0, [0]]];

// Mission time now, wound back by how long ago the entry was touched. dayTime
// is hours as a float, so the arithmetic is in hours throughout and only
// becomes minutes at the end.
private _agoHours = ((CBA_missionTime - _stamp) max 0) / 3600;
private _when = (dayTime - _agoHours + 24) % 24;

private _h = floor _when;
private _m = floor ((_when - _h) * 60);

format ["%1%2", [_h, 2] call CBA_fnc_formatNumber, [_m, 2] call CBA_fnc_formatNumber]
