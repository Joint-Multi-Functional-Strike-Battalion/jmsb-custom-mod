#include "script_component.hpp"
/*
 * Author: YonV
 * The ETA a WILCO says, "ETA m:ss" (DESIGN_SUPPORT_MESSAGING 5.1): minutes and
 * seconds, rounded up to the second. "" when nobody can give one. Another word
 * may stand for ETA - "ON STATION IN m:ss" (FUNC(stationWilco), 2026-11-02).
 *
 * Arguments:
 * 0: Seconds, -1 unknown <NUMBER>
 * 1: The word in front <STRING> (optional, default "ETA")
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * [160] call jmfsb_support_fnc_etaText
 *
 * Public: Yes
 */

params [["_seconds", ETA_UNKNOWN, [0]], ["_word", ETA_WORD, [""]]];

if (_seconds < 0) exitWith {""};

private _s = ceil _seconds;
private _min = floor (_s / ETA_MINUTE);
private _sec = _s mod ETA_MINUTE;

format ["%1 %2:%3%4", _word, _min, ["", "0"] select (_sec < ETA_SECONDS_PAD), _sec]
