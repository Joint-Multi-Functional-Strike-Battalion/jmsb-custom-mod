#include "script_component.hpp"
/*
 * Author: JMSB
 * What the TIMER app's live lines say now, and the shape that decides which
 * lines there are (code review R8). FUNC(appTimer) builds the page from these
 * values; its tick puts the next ones into the same lines in place
 * (EFUNC(tacpad,liveApply)), and builds the page again only when the shape
 * has changed - an alarm armed or deleted, the ring starting or stopping, a
 * delay stepped, the scheme or the type size changed.
 *
 * The values come in the order the page draws its live lines: per armed
 * alarm, soonest first, its countdown (red inside TIMER_RED_SECS, amber inside
 * TIMER_AMBER_SECS) and its number, wall time and owner; the custom delay and
 * its ARM key; the ALARM AT time and its ARM key, with what it costs in
 * mission time; the stopwatch's state, readout and START / STOP.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [shape <ARRAY>, values [[text, RGBA], ...] <ARRAY>]
 *
 * Example:
 * ([] call jmfsb_tacpad_apps_fnc_timerLive) params ["_shape", "_values"]
 *
 * Public: No
 */

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent"];
private _mute = [_ink # 0, _ink # 1, _ink # 2, LIVE_MUTE_ALPHA];

private _alarms = missionNamespace getVariable [QEGVAR(hacking,alarms), []];
private _ringing = !isNil QEGVAR(hacking,alarmRingUntil) && {time < (missionNamespace getVariable [QEGVAR(hacking,alarmRingUntil), -1])};

// Soonest first - the one about to go is the one you care about.
private _sorted = +_alarms;
_sorted sort true;

private _values = [];
{
    _x params ["", "_at", "_who"];
    private _left = _at - CBA_missionTime;
    private _colour = switch (true) do {
        case (_left < TIMER_RED_SECS): {_accent};
        case (_left < TIMER_AMBER_SECS): {TILE_AMBER};
        default {_ink};
    };
    _values pushBack [[_left] call FUNC(timerClock), _colour];

    // WHEN, as well as how long. A section coordinating on the radio says "at
    // twenty past", not "in eleven minutes forty" - and this roster is the
    // thing they are reading off.
    private _atClock = dayTime + (_left * timeMultiplier / 3600);
    _atClock = _atClock mod 24;
    _values pushBack [
        format ["#%1  %2:%3  %4",
            _forEachIndex + 1,
            [floor _atClock, 2] call CBA_fnc_formatNumber,
            [floor ((_atClock - floor _atClock) * 60), 2] call CBA_fnc_formatNumber,
            toUpper _who
        ],
        _mute
    ];
} forEach _sorted;

// The custom delay and its key.
private _custom = GVAR(alarmCustom);
_values pushBack [[_custom] call FUNC(timerClock), _ink];
_values pushBack [format ["ARM %1", [_custom] call FUNC(timerClock)], _ink];

// Against game time: the time, and what it costs in mission time - which
// moves on while the page is open.
private _at = GVAR(alarmAt);
private _atText = format ["%1:%2",
    [floor (_at / 3600), 2] call CBA_fnc_formatNumber,
    [floor ((_at % 3600) / 60), 2] call CBA_fnc_formatNumber
];
_values pushBack [_atText, _ink];
_values pushBack [format ["ARM AT %1  -  IN %2", _atText, [[_at] call FUNC(alarmAtDelay)] call FUNC(timerClock)], _ink];

// The stopwatch.
([] call FUNC(timerState)) params ["_secs", "_running", "", "_expired"];
_values pushBack [
    switch (true) do {
        case (_expired): {"TIME"};
        case (_running): {"RUNNING"};
        case (_secs > 0): {"HELD"};
        default {"READY"};
    },
    [_mute, _accent] select (_expired || _running)
];
_values pushBack [[_secs] call FUNC(timerClock), [_ink, _accent] select _expired];
_values pushBack [["START", "STOP"] select _running, _ground];

private _shape = [
    _sorted apply {_x select 0}, _ringing, isNil QEGVAR(hacking,alarms), _custom, _at,
    [] call EFUNC(tacpad,theme), EGVAR(tacpad,textScale), EGVAR(tacpad,uiScale), HOST_RECT, EGVAR(tacpad,displayMode)
];

[_shape, _values]
