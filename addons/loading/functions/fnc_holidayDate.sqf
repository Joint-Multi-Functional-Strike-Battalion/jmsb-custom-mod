#include "script_component.hpp"
/*
 * Author: YonV
 * The day a holiday falls on in a year, as a day count
 * (EFUNC(common,daysFromCivil)) so its window can be measured across New
 * Year. The class says how the date is found: `easter = 1` (the computus,
 * EFUNC(common,easterDate)); `month` with `weekday` and `nth` (the nth such
 * weekday of the month, NTH_LAST for the last - Memorial Day, Thanksgiving);
 * or `month` and `day`.
 *
 * Arguments:
 * 0: Holiday class under CFG_LOADING_SCREEN >> "Holidays" <CONFIG>
 * 1: Year <NUMBER> (default: this year)
 *
 * Return Value:
 * Day count of the holiday <NUMBER>
 *
 * Example:
 * [configFile >> "jmfsb_loading_CfgLoadingScreen" >> "Holidays" >> "thanksgiving", 2026] call jmfsb_loading_fnc_holidayDate
 *
 * Public: No
 */

params [["_cfg", configNull, [configNull]], ["_year", systemTime select 0, [0]]];

if (getNumber (_cfg >> "easter") > 0) exitWith {
    ([_year] call EFUNC(common,easterDate)) call EFUNC(common,daysFromCivil)
};

private _month = getNumber (_cfg >> "month");
private _nth = getNumber (_cfg >> "nth");
if (_nth isEqualTo 0) exitWith {
    [_year, _month, getNumber (_cfg >> "day")] call EFUNC(common,daysFromCivil)
};

// the nth weekday counted on from the month's first day, or the last counted
// back from its final day - the day before the next month's first
private _weekday = getNumber (_cfg >> "weekday");
if (_nth isEqualTo NTH_LAST) exitWith {
    private _nextFirst = [[_year, _month + 1, 1], [_year + 1, 1, 1]] select (_month isEqualTo 12);
    private _last = (_nextFirst call EFUNC(common,daysFromCivil)) - 1;
    _last - ((WEEKDAY(_last) - _weekday + DAYS_PER_WEEK) mod DAYS_PER_WEEK)
};

private _first = [_year, _month, 1] call EFUNC(common,daysFromCivil);
_first + ((_weekday - WEEKDAY(_first) + DAYS_PER_WEEK) mod DAYS_PER_WEEK) + DAYS_PER_WEEK * (_nth - 1)
