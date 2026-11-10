#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a call for fire's METHOD OF FIRE (user, 2026-11-02) - FUNC(srvThread)'s.
 * The card's Method line, as the support core reads it
 * (EFUNC(support,readOrder): interval, volleys, continuous), within the
 * module's own limits - the board's steppers' tops:
 *
 *   INTERVAL n S          seconds added between one gun's rounds, up to Max
 *                         Interval (the board's INTERVAL, slot 33)
 *   n VOLLEYS             the order fired n times - n - 1 repeats, up to Max
 *                         Repeats (the board's REPEAT, slot 34), following on
 *                         the guns' own rhythm with no pause between them
 *                         (2026-11-05, Simplex's loops; FUNC(fireVirtual))
 *   CONTINUOUS FOR n MIN  one long volley: each gun a round every reload plus
 *                         the interval for n minutes - up to Max Continuous
 *                         Fire (none offered: WHY_NO_CONTINUOUS). Illumination
 *                         kept over a target is this. It sets the rounds per
 *                         gun itself, past Max Rounds Per Gun; the stock still
 *                         ends it
 *
 * Nothing on the line: one volley, no interval - as before.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The order, EFUNC(support,readOrder)'s <HASHMAP>
 *
 * Return Value:
 * 0: Why not, "" when it can <STRING>
 * 1: Interval (s) <NUMBER>
 * 2: Repeats <NUMBER>
 * 3: Rounds per gun of a continuous fire, -1 for the card's <NUMBER>
 * 4: WILCO's words <ARRAY of STRINGs>
 *
 * Example:
 * [_logic, _order] call jmfsb_support_fires_fnc_threadMethod
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_order", createHashMap, [createHashMap]]];

private _interval = (round (_order getOrDefault ["interval", -1])) max 0 min (_logic getVariable [QGVAR(maxInterval), 0]);
private _repeat = ((round (_order getOrDefault ["volleys", -1])) - 1) max 0 min (_logic getVariable [QGVAR(maxRepeat), 0]);
private _minutes = _order getOrDefault ["continuous", -1];
private _most = _logic getVariable [QGVAR(maxContinuous), 0];

private _words = [];
if (_interval > 0) then {_words pushBack format [WORDS_INTERVAL, _interval]};

if (_minutes > 0 && _most <= 0) exitWith {[WHY_NO_CONTINUOUS, 0, 0, -1, []]};
if (_minutes > 0) exitWith {
    private _span = _minutes min _most;
    private _gap = (_logic getVariable [QGVAR(reload), 1]) + _interval;
    _words pushBack format [WORDS_CONTINUOUS, _span];
    ["", _interval, 0, 1 + floor (_span * SECONDS_PER_MINUTE / _gap), _words]
};

if (_repeat > 0) then {_words pushBack format [WORDS_VOLLEYS, _repeat + 1]};
["", _interval, _repeat, -1, _words]
