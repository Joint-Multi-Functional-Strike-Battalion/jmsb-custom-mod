#include "script_component.hpp"
/*
 * Author: YonV
 * The holiday whose crest the loading screen shows today, or configNull for
 * the unit crest. Every class under CFG_LOADING_SCREEN >> "Holidays" has a
 * window: from `daysBefore` days ahead of its day (FUNC(holidayDate)) to
 * `daysAfter` days past it. Where two windows overlap the holiday nearer
 * today wins (user, 2026-10-30: "Christmas takes priority over New Year's"),
 * and on a tie the first in the config. Last year's and next year's dates
 * are tried as well as this year's, so a window across New Year counts.
 *
 * Arguments:
 * 0: Date as [year, month, day] <ARRAY> (default: today, systemTime)
 *
 * Return Value:
 * Holiday class, or configNull <CONFIG>
 *
 * Example:
 * [[2026, 12, 26]] call jmfsb_loading_fnc_holiday   // newYearsDay
 *
 * Public: No
 */

private _now = systemTime;
params [["_today", [_now select 0, _now select 1, _now select 2], [[]], [3]]];

private _todayN = _today call EFUNC(common,daysFromCivil);
private _year = _today select 0;
private _holiday = configNull;
private _nearest = -1;
{
    private _cfg = _x;
    private _before = getNumber (_cfg >> "daysBefore");
    private _after = getNumber (_cfg >> "daysAfter");
    {
        private _delta = _todayN - ([_cfg, _year + _x] call FUNC(holidayDate));
        if (_delta >= -_before && _delta <= _after && {_nearest < 0 || {abs _delta < _nearest}}) then {
            _holiday = _cfg;
            _nearest = abs _delta;
        };
    } forEach NEIGHBOUR_YEARS;
} forEach ("true" configClasses (CFG_LOADING_SCREEN >> "Holidays"));
TRACE_3("Holiday",_today,configName _holiday,_nearest);

_holiday
