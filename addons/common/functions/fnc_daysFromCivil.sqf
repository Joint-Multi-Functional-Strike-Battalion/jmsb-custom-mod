#include "script_component.hpp"
/*
 * Author: YonV
 * Days from a civil date: Howard Hinnant's days_from_civil, epoch 0000-03-01
 * (a Wednesday). Arma has no date arithmetic - dateToNumber is a fraction of
 * one year and breaks across New Year - so dates become day counts and are
 * subtracted. (days + 3) mod 7 is the weekday, 0 Sunday .. 6 Saturday.
 *
 * Arguments:
 * 0: Year <NUMBER>
 * 1: Month, 1..12 <NUMBER>
 * 2: Day, 1..31 <NUMBER>
 *
 * Return Value:
 * Days since the epoch <NUMBER>
 *
 * Example:
 * [2026, 12, 25] call jmfsb_common_fnc_daysFromCivil
 *
 * Public: No
 */

params [["_year", 0, [0]], ["_month", 1, [0]], ["_day", 1, [0]]];

// https://howardhinnant.github.io/date_algorithms.html#days_from_civil
if (_month <= 2) then {_year = _year - 1};
private _era = floor (_year / 400);
private _yoe = _year - _era * 400;
private _doy = floor ((153 * (_month + ([-3, 9] select (_month <= 2))) + 2) / 5) + _day - 1;
private _doe = _yoe * 365 + floor (_yoe / 4) - floor (_yoe / 100) + _doy;

_era * 146097 + _doe
