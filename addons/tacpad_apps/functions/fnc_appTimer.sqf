#include "script_component.hpp"
/*
 * Author: YonV
 * TIMER: the alarm roster the cTab device had, the ways to arm into it, and
 * the stopwatch under it - three sections, each under its heading.
 *
 * THE OLD TIMER, CLEANER (user, 2026-11-01: "the stop watch app is weird what
 * is this in and at stuff" - "old timer but better visual design"). The IN /
 * AT rework of DESIGN_TABLET_REVIEW 3.7 is reverted to the timer before it:
 * quick keys that arm that many minutes from now, a CUSTOM delay with its own
 * ARM, an ALARM AT time with its own ARM. What changed is the drawing: one
 * label column and one control column down the whole page, every key the
 * same height, values at the tile detail size or larger (R1) and never
 * letter-tracked, and FILLED ARMS, OUTLINED ADJUSTS - every press that arms
 * is the ink block, every press that only moves a value is an outline.
 *
 *   ARMED ALARMS                         [RINGING - SILENCE]
 *        12:40   #1  04:30  SMITH                   [DEL #1]
 *   ----------------------------------------------------------
 *   SET AN ALARM
 *       ARM IN   [1 MIN] [2 MIN] [3 MIN] [5 MIN] [10 MIN]
 *       CUSTOM   15:00
 *                (-10) (-1) (+1) (+10) (+60)
 *                [ARM IN 15:00]
 *     ALARM AT   04:30
 *                (-1H) (-10) (-1) (+1) (+10) (+1H)
 *                [ARM AT 04:30 - IN 16:28]
 *   ----------------------------------------------------------
 *   STOPWATCH
 *        READY   00:00
 *                [START] (RESET)
 *
 * THE ROSTER IS THE POINT, and it is the archived device's page rebuilt rather
 * than reinvented - armed alarms, soonest first, each a RUNNING clock and not a
 * rounded minute, numbered and named by whoever set them, and coloured by how
 * close they are: red inside thirty seconds, amber inside two minutes. All of
 * them: the frame grows by a row per alarm.
 *
 * THE ALARMS ARE NOT THIS ADDON'S. jmfsb_hacking owns them - they ring through
 * its own handler, they are public so a section shares them, and the hand-held
 * scanner arms them too. This reads that roster and arms into it; two alarm
 * systems would be two sets of alarms nobody could reconcile.
 *
 * BUILT ONCE, TICKED IN PLACE (code review R8). Every line that moves - the
 * countdowns, the ALARM AT key, the stopwatch - is a value of FUNC(timerLive),
 * drawn here in the order it comes; the page's tick writes the next values
 * into the same lines (EFUNC(tacpad,liveApply)) and builds the page again only
 * when its shape has changed.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_tacpad_apps_fnc_appTimer
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

// MEASURED, THEN OPENED: three headings, the roster's rows, the two values,
// six rows of keys, the stopwatch's readout, the section rules and their air,
// and the frame's own chrome.
private _alarms = missionNamespace getVariable [QEGVAR(hacking,alarms), []];
private _padY = PAD * HOST_H;
private _ruleH = RULE_THICK * pixelH;
private _btnH = ([TIMER_VALUE_TEXT] call EFUNC(tacpad,textH)) + 2 * _padY;
private _lineH = (([TIMER_VALUE_TEXT] call EFUNC(tacpad,textH)) + KV_AIR_PX * pixelH) max KV_ROW_H;
private _clockH = ([TEXT_DISPLAY] call EFUNC(tacpad,textH)) + 2 * _padY;
private _keyStep = _btnH + _padY;
private _air = TIMER_SECTION_AIR * _padY;
private _sectionGap = _air + _ruleH + _air;
private _chrome = ((HEADER_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H) max ([TEXT_TITLE] call EFUNC(tacpad,textH))) + _ruleH * 3;
private _needed = _padY + _lineH * 5 + ((count _alarms) max 1) * _keyStep + _keyStep * 6
    + _sectionGap * 2 + _air * 2 + _clockH + _padY + _chrome;

([_display, "TIMER", TIMER_APP_W, _needed / HOST_H] call EFUNC(tacpad,appFrame)) params ["_group", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent"];

private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _mute = [_ink # 0, _ink # 1, _ink # 2, LIVE_MUTE_ALPHA];
private _dim = [_ink # 0, _ink # 1, _ink # 2, LIVE_DIM_ALPHA];

// THE TWO COLUMNS every row of the page is laid on: labels right-aligned in
// the first, so each ends a gap from what it names (as FUNC(kvRow) sets
// them); values and keys from the second.
private _labelW = _w * TIMER_LABEL_W;
private _ctrlX = _labelW + KV_GAP_PX * pixelW;
private _ctrlW = _w - _ctrlX - _pad;

// THE LIVE LINES. The nth live line drawn takes the nth value, and is kept
// with its type role for the tick to write the next one into.
([] call FUNC(timerLive)) params ["_shape", "_values"];
private _entries = [];
private _fnc_live = {
    params ["_rect", "_size", ["_bold", false], ["_align", "left"], ["_font", ""]];
    (_values select (count _entries)) params ["_text", "_colour"];
    private _ctrl = [_body, _rect, _text, _colour, _size, _bold, _align, false, _font] call EFUNC(tacpad,drawText);
    _entries pushBack [[_ctrl], [_size, _bold, _align, false, _font]];
    _ctrl
};

// A label in the first column.
private _fnc_label = {
    params ["_text", "_rowY", "_h"];
    [_body, [_pad, _rowY, _labelW - _pad, _h], _text, _mute, KV_TEXT, false, "right"] call EFUNC(tacpad,drawText);
};

// A section heading across the page - short, so it may be tracked (2.3).
private _fnc_heading = {
    params ["_text", "_rowY"];
    [_body, [_pad, _rowY, _w - 2 * _pad, _lineH], _text, _mute, KV_TEXT, true, "left", true] call EFUNC(tacpad,drawText);
};

// A rule between sections, with its air above and below.
private _fnc_rule = {
    params ["_rowY"];
    [_body, [_pad, _rowY + _air, _w - 2 * _pad, _ruleH], _ink] call EFUNC(tacpad,drawFill);
};

// A KEY. FILLED ARMS, OUTLINED ADJUSTS (user, 2026-11-01: it must be obvious
// which press arms an alarm). Its number - seconds, minutes or an alarm's id -
// rides on its hit (QGVAR(timerData)).
private _fnc_key = {
    params ["_rect", "_label", "_arms", "_onPress", ["_data", 0]];
    if (_arms) then {
        [_body, _rect, _ink] call EFUNC(tacpad,drawFill);
    } else {
        [_body, _rect, _ink, RULE_THIN] call EFUNC(tacpad,drawFrame);
    };
    [_body, _rect, _label, [_ink, _ground] select _arms, TIMER_VALUE_TEXT, true, "center", false, FONT_MONO] call EFUNC(tacpad,drawText);
    private _hit = [_body, _rect, _onPress] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(timerData), _data];
};

// A row of keys across the control column, [label, number] each, all one
// height and the row's width shared out evenly.
private _fnc_keys = {
    params ["_keys", "_rowY", "_arms", "_onPress"];
    private _keyW = (_ctrlW - ((count _keys) - 1) * _pad) / (count _keys);
    {
        _x params ["_label", "_data"];
        [[_ctrlX + _forEachIndex * (_keyW + _pad), _rowY, _keyW, _btnH], _label, _arms, _onPress, _data] call _fnc_key;
    } forEach _keys;
};

// ARMS that many seconds from now. By remoteExec to hacking's server function,
// the path the hand-held uses: the server holds the roster and names the setter
// from the sender (review S7).
private _fnc_arm = {
    params ["_ctrl"];
    if (isNil QEFUNC(hacking,srvAlarmAdd)) exitWith {};
    [_ctrl getVariable [QGVAR(timerData), TIMER_DELAY_MIN]] remoteExecCall [QEFUNC(hacking,srvAlarmAdd), SERVER_OWNER];
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};

private _y = _padY;

// ------------------------------------------------------------ the roster ----
private _ringing = !isNil QEGVAR(hacking,alarmRingUntil) && {time < (missionNamespace getVariable [QEGVAR(hacking,alarmRingUntil), -1])};

["ARMED ALARMS", _y] call _fnc_heading;

// RINGING is also the button that stops it. The keybind is the fast way and
// this is the discoverable one - a player who has never bound the key is
// looking at this screen anyway, because it is where the noise is coming from.
if (_ringing) then {
    private _silRect = [_ctrlX + _ctrlW / 2, _y, _ctrlW / 2, _lineH];
    [_body, _silRect, _accent] call EFUNC(tacpad,drawFill);
    [_body, _silRect, "RINGING - SILENCE", _ground, KV_TEXT, true, "center"] call EFUNC(tacpad,drawText);
    [_body, _silRect, {
        if (isNil QEFUNC(hacking,alarmSilence)) exitWith {};
        [] call EFUNC(hacking,alarmSilence);
        {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
};
_y = _y + _lineH;

switch (true) do {
    case (isNil QEGVAR(hacking,alarms)): {
        [_body, [_ctrlX, _y, _ctrlW, _btnH], "SCANNER NETWORK OFFLINE", _accent, KV_TEXT, true] call EFUNC(tacpad,drawText);
        _y = _y + _keyStep;
    };
    case (_alarms isEqualTo []): {
        [_body, [_ctrlX, _y, _ctrlW, _btnH], "NONE", _dim, KV_TEXT, true] call EFUNC(tacpad,drawText);
        _y = _y + _keyStep;
    };
    default {
        // Soonest first - the one about to go is the one you care about.
        private _sorted = +_alarms;
        _sorted sort true;
        private _delW = _w * TIMER_DEL_W;
        private _top = _y;
        {
            _x params ["_id"];
            private _rowY = _top + _forEachIndex * _keyStep;

            // The countdown in the label column, and WHEN as well as how long
            // beside it (FUNC(timerLive)).
            [[_pad, _rowY, _labelW - _pad, _btnH], TIMER_VALUE_TEXT, true, "right", FONT_MONO] call _fnc_live;
            [[_ctrlX, _rowY, _ctrlW - _delW - _pad, _btnH], KV_TEXT] call _fnc_live;

            // DEL names its row, so "#2" on the key is "#2" on the roster.
            [[_w - _pad - _delW, _rowY, _delW, _btnH], format ["DEL #%1", _forEachIndex + 1], false, {
                params ["_ctrl"];
                if (isNil QEFUNC(hacking,srvAlarmDelete)) exitWith {};
                private _kill = _ctrl getVariable [QGVAR(timerData), -1];
                // The roster is the server's (review S7): asked by remoteExec,
                // which a host runs on his own machine too - a publicVariable
                // never reached the server's list from the host. The server
                // publishes the new copy; this row goes from the screen now.
                [_kill] remoteExecCall [QEFUNC(hacking,srvAlarmDelete), SERVER_OWNER];
                private _list = missionNamespace getVariable [QEGVAR(hacking,alarms), []];
                private _i = _list findIf {(_x select 0) isEqualTo _kill};
                if (_i >= 0) then {_list deleteAt _i};
                {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }, _id] call _fnc_key;
        } forEach _sorted;
        _y = _y + count _sorted * _keyStep;
    };
};

[_y] call _fnc_rule;
_y = _y + _sectionGap;

// ---------------------------------------------------------- set an alarm ----
["SET AN ALARM", _y] call _fnc_heading;
_y = _y + _lineH;

// ONE PRESS FOR THE FIVE A SECTION ACTUALLY SETS. These are not steppers: each
// arms an alarm that many minutes from now and is done, because the whole point
// of a quick key is that it is set with one hand.
["ARM IN", _y, _btnH] call _fnc_label;
[TIMER_QUICK apply {[format ["%1 MIN", _x], _x * SECONDS_PER_MINUTE]}, _y, true, _fnc_arm] call _fnc_keys;
_y = _y + _keyStep + _air;

// A CUSTOM DELAY - anything the quick keys do not cover. The value is kept
// between openings (GVAR(alarmCustom)), never under a minute: an alarm you
// cannot see coming is a notification.
private _custom = GVAR(alarmCustom);
["CUSTOM", _y, _lineH] call _fnc_label;
[_body, [_ctrlX, _y, _ctrlW, _lineH], [_custom] call FUNC(timerClock), _ink, TIMER_VALUE_TEXT, true, "left", false, FONT_MONO] call EFUNC(tacpad,drawText);
_y = _y + _lineH;

[TIMER_CUSTOM_STEPS, _y, false, {
    params ["_ctrl"];
    private _by = (_ctrl getVariable [QGVAR(timerData), 0]) * SECONDS_PER_MINUTE;
    GVAR(alarmCustom) = ((GVAR(alarmCustom) + _by) max TIMER_DELAY_MIN) min TIMER_DELAY_MAX;
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_keys;
_y = _y + _keyStep;

[[[format ["ARM IN %1", [_custom] call FUNC(timerClock)], _custom]], _y, true, _fnc_arm] call _fnc_keys;
_y = _y + _keyStep + _air;

// AGAINST GAME TIME - a different kind of alarm entirely. Everything above is
// "in twenty minutes"; this is "at 0430", which is how orders are written, and
// on an accelerated mission the two are nothing like each other. Wraps round
// midnight rather than clamping - 2350 plus twenty minutes is ten past.
["ALARM AT", _y, _lineH] call _fnc_label;
[_body, [_ctrlX, _y, _ctrlW, _lineH], format ["%1:%2",
    [floor (GVAR(alarmAt) / 3600), 2] call CBA_fnc_formatNumber,
    [floor ((GVAR(alarmAt) % 3600) / 60), 2] call CBA_fnc_formatNumber
], _ink, TIMER_VALUE_TEXT, true, "left", false, FONT_MONO] call EFUNC(tacpad,drawText);
_y = _y + _lineH;

[TIMER_AT_STEPS, _y, false, {
    params ["_ctrl"];
    private _v = (GVAR(alarmAt) + (_ctrl getVariable [QGVAR(timerData), 0]) * SECONDS_PER_MINUTE) % TIMER_DAY_SECS;
    if (_v < 0) then {_v = _v + TIMER_DAY_SECS};
    GVAR(alarmAt) = _v;
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_keys;
_y = _y + _keyStep;

// WHAT IT COSTS IN MISSION TIME, SAID ON THE KEY (FUNC(timerLive)). Worked out
// at PRESS time, not at draw time: the screen may have been open for a minute
// and the world clock has moved under it.
private _armAtRect = [_ctrlX, _y, _ctrlW, _btnH];
[_body, _armAtRect, _ink] call EFUNC(tacpad,drawFill);
[_armAtRect, TIMER_VALUE_TEXT, true, "center", FONT_MONO] call _fnc_live;
[_body, _armAtRect, {
    if (isNil QEFUNC(hacking,srvAlarmAdd)) exitWith {};
    [[GVAR(alarmAt)] call FUNC(alarmAtDelay)] remoteExecCall [QEFUNC(hacking,srvAlarmAdd), SERVER_OWNER];
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);
_y = _y + _keyStep;

[_y] call _fnc_rule;
_y = _y + _sectionGap;

// ---------------------------------------------------------- the stopwatch ---
// This addon's own - an alarm is a mark you set for later, a stopwatch is a
// thing you time. Its state in the label column, the readout beside it.
["STOPWATCH", _y] call _fnc_heading;
_y = _y + _lineH;

[[_pad, _y, _labelW - _pad, _clockH], KV_TEXT, true, "right"] call _fnc_live;
[[_ctrlX, _y, _ctrlW, _clockH], TEXT_DISPLAY, true, "left", FONT_MONO] call _fnc_live;
_y = _y + _clockH;

private _halfW = (_ctrlW - _pad) / 2;
private _startRect = [_ctrlX, _y, _halfW, _btnH];
[_body, _startRect, _ink] call EFUNC(tacpad,drawFill);
[_startRect, TIMER_VALUE_TEXT, true, "center", FONT_MONO] call _fnc_live;
[_body, _startRect, {
    ["toggle"] call FUNC(timerSet);
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

[[_ctrlX + _halfW + _pad, _y, _halfW, _btnH], "RESET", false, {
    ["reset"] call FUNC(timerSet);
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_key;

[_group, _shape, _entries] call EFUNC(tacpad,liveStore);

// A screen showing clocks has to keep up with them or it is a photograph of
// them - in place, every second.
private _existing = uiNamespace getVariable [QGVAR(timerPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(timerPFH), [{
    params ["", "_handle"];

    // TWO QUESTIONS, NOT ONE. "Is this app still open" decides whether the loop
    // lives; "is the pointer off it" decides whether it may REBUILD. A rebuild
    // deletes and recreates every control on the screen, and a control deleted
    // between the press and the release never raises a click - see
    // EFUNC(tacpad,appIdle). Writing the next values into the same lines
    // deletes nothing, so that goes ahead wherever the pointer is.
    if !(["timer"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(timerPFH), -1];
    };

    private _group = uiNamespace getVariable [QEGVAR(tacpad,appGroup), controlNull];
    if (([_group] + ([] call FUNC(timerLive))) call EFUNC(tacpad,liveApply)) exitWith {};

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    ["timer"] call EFUNC(tacpad,openApp);
}, 1, []] call CBA_fnc_addPerFrameHandler];
