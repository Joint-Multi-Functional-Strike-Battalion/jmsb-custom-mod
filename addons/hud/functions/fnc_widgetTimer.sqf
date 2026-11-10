#include "script_component.hpp"
/*
 * Author: YonV
 * TIMER: the clock, the stopwatch, and the next alarm due.
 *
 * IT MEASURES NOTHING. The stopwatch is EFUNC(tacpad_apps,timerState)'s and the
 * alarms are jmfsb_hacking's roster - the same two the map screen reads - so the
 * HUD and the timer app can never disagree about how long is left.
 *
 * Arguments:
 * 0: Draw ops, appended to - see FUNC(paint) <ARRAY>
 * 1: Y to start at <NUMBER>
 * 2: Slot width <NUMBER>
 * 3: Slot height <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ops, _y, _w, _h] call jmfsb_hud_fnc_widgetTimer
 *
 * Public: No
 */

params [["_ops", [], [[]]], ["_y", 0, [0]], ["_w", 0, [0]], ["_h", 0, [0]]];

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _base = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * safeZoneH;
// A ROW IS THE SUITE'S OWN ROW, AND IT ONLY EVER SHRINKS. Rows used to be the
// slot's whole box divided by however many of them there were, so a slot at its
// default size - the vanilla Custom Info panel's size - spread three lines down
// the whole panel with holes between them, at type twice the size the rest of
// the suite sets. The design's row height is the row height here too: a slot the
// player has made too SHORT for its rows squeezes them, and one made taller
// simply has air under the readout.
private _rowH = _base min ((_h - _y - (PAD * safeZoneW)) / 3);
// Width caps the scale too - see the note in FUNC(widgetEw).
private _kw = (_w / (10 * (((safeZoneW / safeZoneH) min 1.2) / 40))) max 0.8;
private _k = ((_rowH / _base) min _kw) max 0.8;
private _pad = PAD * safeZoneW;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

private _fnc_clock = {
    params ["_secs"];
    private _s = (round _secs) max 0;
    private _hh = floor (_s / 3600);
    private _mm = floor ((_s - _hh * 3600) / 60);
    private _ss = _s - _hh * 3600 - _mm * 60;
    if (_hh > 0) then {
        format ["%1:%2:%3", _hh, [_mm, 2] call CBA_fnc_formatNumber, [_ss, 2] call CBA_fnc_formatNumber]
    } else {
        format ["%1:%2", [_mm, 2] call CBA_fnc_formatNumber, [_ss, 2] call CBA_fnc_formatNumber]
    };
};

// The world's clock, which is the one an order is written against.
private _dt = dayTime;
_ops pushBack [HUD_OP_TEXT, [
    [_pad, _y, _w - 2 * _pad, _rowH * 1.4],
    format ["%1:%2",
        [floor _dt, 2] call CBA_fnc_formatNumber,
        [floor ((_dt - floor _dt) * 60), 2] call CBA_fnc_formatNumber
    ],
    _ink, (1.6 * _k), true
]];
private _row = _y + _rowH * 1.5;

// The stopwatch, only while it has something to say. A row reading 00:00 for the
// whole mission is a row spent on nothing.
if (!isNil QEFUNC(tacpad_apps,timerState)) then {
    ([] call EFUNC(tacpad_apps,timerState)) params ["_secs", "_running", "_down", "_expired"];
    if (_running || _secs > 0) then {
        _ops pushBack [HUD_OP_TEXT, [[_pad, _row, _w * 0.42, _rowH], ["STOPWATCH", "COUNTDOWN"] select _down, _mute, (0.62 * _k), true, "left", true]];
        _ops pushBack [HUD_OP_TEXT, [
            [_w * 0.42, _row, _w * 0.58 - _pad, _rowH],
            [_secs] call _fnc_clock,
            ([_ink, _accent] select _expired), (0.95 * _k), true, "right"
        ]];
        _row = _row + _rowH;
    };
};

// NEXT ALARM ONLY, not the roster. The roster is the timer app's page; what a
// man wants on his screen is how long until the next thing happens.
private _alarms = missionNamespace getVariable [QEGVAR(hacking,alarms), []];
if (_alarms isEqualTo []) exitWith {};

private _soonest = 1e9;
{
    private _left = (_x select 1) - CBA_missionTime;
    if (_left < _soonest) then {_soonest = _left};
} forEach _alarms;

private _hot = _soonest < 120;
_ops pushBack [HUD_OP_TEXT, [[_pad, _row, _w * 0.42, _rowH], "NEXT ALARM", _mute, (0.62 * _k), true, "left", true]];
_ops pushBack [HUD_OP_TEXT, [
    [_w * 0.42, _row, _w * 0.58 - _pad, _rowH],
    [_soonest] call _fnc_clock,
    ([_ink, _accent] select _hot), (0.95 * _k), true, "right"
]];

if (count _alarms > 1) then {
    _ops pushBack [HUD_OP_TEXT, [
        [_pad, _row + _rowH, _w - 2 * _pad, _rowH],
        format ["%1 ARMED", count _alarms],
        _mute, (0.62 * _k), false, "left", true
    ]];
};
