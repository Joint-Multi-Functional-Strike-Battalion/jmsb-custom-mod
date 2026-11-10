#include "script_component.hpp"
/*
 * Author: YonV
 * How many seconds from now a given time of day is - the bridge between "wake
 * me at 0430" and the only thing the alarm roster understands, which is a delay.
 *
 * TWO CLOCKS, AND THEY DO NOT RUN AT THE SAME SPEED. `daytime` is the world's
 * clock and it moves at `timeMultiplier`; CBA_missionTime is the mission's and
 * it does not. On a mission at 6x, "in one hour of daylight" is ten minutes of
 * sitting there - so a delay worked out in game-clock seconds and handed to a
 * mission-clock waiter would fire six times too late, which on a first-light
 * assault is the whole plan.
 *
 * The conversion is the whole reason this is a function rather than two lines at
 * the call site: it is the sort of arithmetic that looks right until somebody
 * plays with acceleration on.
 *
 * ALWAYS FORWARD. A time that has already passed today is tomorrow's - which is
 * what a man setting 0430 at 2100 means, and the only reading that cannot
 * produce a delay in the past.
 *
 * Arguments:
 * 0: Target time of day, in seconds past midnight <NUMBER>
 *
 * Return Value:
 * Mission seconds until it comes round <NUMBER>
 *
 * Example:
 * private _delay = [4 * 3600 + 30 * 60] call jmfsb_tacpad_apps_fnc_alarmAtDelay
 *
 * Public: No
 */

params [["_target", 0, [0]]];

private _now = dayTime * 3600;
private _delta = _target - _now;

// Gone for today, so it means tomorrow.
if (_delta <= 0) then {_delta = _delta + 86400};

// A mission with time stopped has a world clock that never reaches the mark.
// Treating that as "immediately" would be worse than treating it as "at the
// same wall-clock offset", which is what falling back to 1x does.
private _mult = timeMultiplier;
if (!(_mult isEqualType 0)) then {_mult = 0};
if (_mult <= 0) then {_mult = 1};

_delta / _mult
