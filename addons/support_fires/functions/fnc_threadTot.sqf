#include "script_component.hpp"
/*
 * Author: YonV
 * TIME ON TARGET for a call for fire by message (2026-11-01, DESIGN_SUPPORT_
 * MESSAGING step 6): the card's TOT line as a time of game time, and the wait
 * before the shot that puts the first round - or missile - on the target
 * then. One reading for a battery (FUNC(srvThread)) and a cruise missile
 * launcher (FUNC(threadStrike)).
 *
 * THE LINE (to the second and relative since 2026-11-02, user):
 *   HHMM, HH:MM          that minute of the day
 *   HHMMSS, HH:MM:SS     that second
 *   +M, +M MIN           M game minutes from now
 * WILCO's when is the time it fires for, "TOT 1430" - to the second
 * ("TOT 143015") for a time given to the second or from now.
 *
 * Refused: no time on the line, or not one of these - "NO TOT"; a wait under
 * the asset's least response time, or more than TOT_MAX s of mission time
 * ahead - "CANNOT MAKE TOT". The game clock runs timeMultiplier times mission
 * time.
 *
 * Arguments:
 * 0: The TOT line's text <STRING>
 * 1: Time of flight (s) <NUMBER>
 * 2: The asset's least response time (s) <NUMBER>
 *
 * Return Value:
 * 0: The wait before the shot (s) <NUMBER>
 * 1: WILCO's when, "TOT hhmm" or "TOT hhmmss" <STRING>
 * 2: Why not, "" when it can <STRING>
 *
 * Example:
 * ["1430", 32, 10] call jmfsb_support_fires_fnc_threadTot
 *
 * Public: No
 */

params [["_text", "", [""]], ["_tof", 0, [0]], ["_respMin", 0, [0]]];

private _line = toUpper (trim _text);
private _now = round (dayTime * SECONDS_PER_HOUR);
private _at = -1;
private _bySecond = false;

private _relative = _line regexFind [TOT_REL_PATTERN];
if (_relative isNotEqualTo []) then {
    ((_relative select 0) param [1, ["0"]]) params [["_minutes", "0"]];
    _at = _now + (parseNumber _minutes) * SECONDS_PER_MINUTE;
    _bySecond = true;
} else {
    private _found = _line regexFind [TOT_PATTERN];
    if (_found isEqualTo []) exitWith {};
    (_found select 0) params ["", ["_hours", ["0"]], ["_mins", ["0"]], "", ["_secs", [""]]];
    private _hh = parseNumber (_hours select 0);
    private _mm = parseNumber (_mins select 0);
    private _ss = parseNumber (_secs param [0, ""]);
    if (_hh >= HOURS_PER_DAY || _mm >= SECONDS_PER_MINUTE || _ss >= SECONDS_PER_MINUTE) exitWith {};
    _bySecond = (_secs param [0, ""]) isNotEqualTo "";
    _at = _hh * SECONDS_PER_HOUR + _mm * SECONDS_PER_MINUTE + _ss;
    if (_at < _now) then {_at = _at + SECONDS_PER_DAY};
};
if (_at < 0) exitWith {[0, "", WHY_NO_TOT]};

private _ahead = (_at - _now) / (timeMultiplier max TIME_MULTIPLIER_MIN);
private _wait = _ahead - _tof;
if (_wait < _respMin || _ahead > TOT_MAX) exitWith {[0, "", WHY_TOT]};

// The time of day it fires for, as the line wrote it - to the second when
// that is how it was given.
private _clock = _at mod SECONDS_PER_DAY;
private _figures = [floor (_clock / SECONDS_PER_HOUR), floor ((_clock mod SECONDS_PER_HOUR) / SECONDS_PER_MINUTE)];
if (_bySecond) then {_figures pushBack (_clock mod SECONDS_PER_MINUTE)};
[_wait, format [TOT_WORDS, (_figures apply {[_x, TOT_PAD] call CBA_fnc_formatNumber}) joinString ""], ""]
