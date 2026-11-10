#include "script_component.hpp"
/*
 * Author: YonV
 * What the timer currently reads, as numbers. The tile and the app both ask
 * here, so the band and the screen can never show different times.
 *
 * ONE CLOCK, TWO WAYS TO READ IT. A stopwatch counts up from when it was
 * started; a countdown counts down to a mark set before it. They are the same
 * accumulated seconds - the target is what turns one into the other - which is
 * why there is one timer here rather than two that can both be running.
 *
 * It survives the map closing, because the map is a screen and a timer is not:
 * the state is three numbers in missionNamespace and the clock is CBA's, so
 * nothing has to be ticking for the reading to be right.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: Seconds to show - elapsed, or remaining on a countdown <NUMBER>
 * 1: Running <BOOL>
 * 2: Counting down rather than up <BOOL>
 * 3: A countdown that has reached zero <BOOL>
 *
 * Example:
 * ([] call jmfsb_tacpad_apps_fnc_timerState) params ["_secs", "_running"]
 *
 * Public: No
 */

private _accum = missionNamespace getVariable [QGVAR(timerAccum), 0];
private _since = missionNamespace getVariable [QGVAR(timerSince), -1];
private _target = missionNamespace getVariable [QGVAR(timerTarget), 0];

private _running = _since >= 0;
private _elapsed = _accum + ([0, CBA_missionTime - _since] select _running);

if (_target <= 0) exitWith {[_elapsed max 0, _running, false, false]};

private _left = _target - _elapsed;
[_left max 0, _running, true, _left <= 0]
