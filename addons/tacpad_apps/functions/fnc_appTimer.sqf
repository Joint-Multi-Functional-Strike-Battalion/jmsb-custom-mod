#include "script_component.hpp"
/*
 * Author: JMSB
 * TIMER: the alarm roster the cTab device had, and the stopwatch under it.
 *
 * THE ROSTER IS THE POINT, and it is the archived device's page rebuilt rather
 * than reinvented - armed alarms, soonest first, each a RUNNING clock and not a
 * rounded minute, numbered and named by whoever set them, and coloured by how
 * close they are: red inside thirty seconds, amber inside two minutes.
 *
 * ALL OF THEM. It showed the first five and silently dropped the rest, which on
 * a section that arms alarms for every phase line is a roster that lies. The
 * frame grows by a row per alarm instead.
 *
 * THE ALARMS ARE NOT THIS ADDON'S. jmfsb_hacking owns them - they ring through
 * its own handler, they are public so a section shares them, and the hand-held
 * scanner arms them too. This reads that roster and arms into it; two alarm
 * systems would be two sets of alarms nobody could reconcile.
 *
 * The stopwatch below it is this addon's own and is a different tool: an alarm
 * is a mark you set for later, a stopwatch is a thing you time.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

([_display, "TIMER", 0.44, (0.68 + (count (missionNamespace getVariable [QEGVAR(hacking,alarms), []]) * ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale)))] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
private _amber = [0.85, 0.65, 0.15, 1];

// A running clock, not a rounded minute: a row that reads "1 MIN" for sixty
// seconds is a label, not a timer. The archived device's own formatter.
private _fnc_clock = {
    params ["_secs"];
    private _s = (round _secs) max 0;
    private _h = floor (_s / 3600);
    private _m = floor ((_s - _h * 3600) / 60);
    private _r = _s - _h * 3600 - _m * 60;
    if (_h > 0) then {
        format ["%1:%2:%3", _h, [_m, 2] call CBA_fnc_formatNumber, [_r, 2] call CBA_fnc_formatNumber]
    } else {
        format ["%1:%2", [_m, 2] call CBA_fnc_formatNumber, [_r, 2] call CBA_fnc_formatNumber]
    };
};

private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;
private _y = _padY;

// ------------------------------------------------------------ the roster ----
private _alarms = missionNamespace getVariable [QEGVAR(hacking,alarms), []];
private _ringing = !isNil QEGVAR(hacking,alarmRingUntil) && {time < (missionNamespace getVariable [QEGVAR(hacking,alarmRingUntil), -1])};

[_body, [_pad, _y, _w * 0.5, _rowH], "ARMED ALARMS", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);

// RINGING is also the button that stops it. The keybind is the fast way and
// this is the discoverable one - a player who has never bound the key is
// looking at this screen anyway, because it is where the noise is coming from.
if (_ringing) then {
    private _silW = _w * 0.5 - _pad;
    [_body, [_w * 0.5, _y, _silW, _rowH], _accent, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_body, [_w * 0.5, _y, _silW, _rowH], "RINGING - SILENCE", _accent, TEXT_BODY, true, "center", true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.5, _y, _silW, _rowH], {
        if (isNil QEFUNC(hacking,alarmSilence)) exitWith {};
        [] call EFUNC(hacking,alarmSilence);
        {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
};
_y = _y + _rowH;

if (isNil QEGVAR(hacking,alarms)) then {
    [_body, [_pad, _y, _w - 2 * _pad, _rowH], "SCANNER NETWORK OFFLINE", _accent, TEXT_TITLE] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;
} else {
    if (_alarms isEqualTo []) then {
        [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NONE", _dim, TEXT_TITLE] call EFUNC(tacpad,drawText);
        _y = _y + _rowH;
    } else {
        // Soonest first - the one about to go is the one you care about.
        private _sorted = +_alarms;
        _sorted sort true;

        // each row steps down onto itself before it draws; the step past the last one follows the loop
        _y = _y - _rowH;
        {
            _y = _y + _rowH;
            _x params ["_id", "_at", "_who"];
            private _left = _at - CBA_missionTime;
            private _colour = switch (true) do {
                case (_left < 30): {_accent};
                case (_left < 120): {_amber};
                default {_ink};
            };

            [_body, [_pad, _y, _w * 0.3, _rowH], [_left] call _fnc_clock, _colour, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
            // WHEN, as well as how long. A section coordinating on the radio
            // says "at twenty past", not "in eleven minutes forty" - and this
            // roster is the thing they are reading off.
            private _atClock = dayTime + (_left * timeMultiplier / 3600);
            _atClock = _atClock mod 24;

            [
                _body, [_w * 0.32, _y, _w * 0.44, _rowH],
                format ["#%1  %2:%3  %4",
                    _forEachIndex + 1,
                    [floor _atClock, 2] call CBA_fnc_formatNumber,
                    [floor ((_atClock - floor _atClock) * 60), 2] call CBA_fnc_formatNumber,
                    toUpper _who
                ],
                _mute, TEXT_BODY, false
            ] call EFUNC(tacpad,drawText);

            // DEL names its row, so "#2" on the key is "#2" on the roster.
            private _delW = _w * 0.2;
            [_body, [_w - _delW - _pad, _y, _delW, _rowH * 0.9], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
            [_body, [_w - _delW - _pad, _y, _delW, _rowH * 0.9], format ["DEL #%1", _forEachIndex + 1], _mute, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);

            private _hit = [_body, [_w - _delW - _pad, _y, _delW, _rowH * 0.9], {
                params ["_ctrl"];
                private _kill = _ctrl getVariable [QGVAR(alarmId), -1];
                private _list = missionNamespace getVariable [QEGVAR(hacking,alarms), []];
                private _i = _list findIf {(_x select 0) isEqualTo _kill};
                if (_i >= 0) then {
                    _list deleteAt _i;
                    // Public, because the roster is the section's and the waiter
                    // that would have rung it checks this same list.
                    publicVariable QEGVAR(hacking,alarms);
                };
                {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }] call EFUNC(tacpad,drawHit);
            _hit setVariable [QGVAR(alarmId), _id];
        } forEach _sorted;
        _y = _y + _rowH;
    };
};

_y = _y + _padY;

// ONE PRESS FOR THE FIVE A SECTION ACTUALLY SETS. These are not steppers: each
// arms an alarm that many minutes from now and is done, because the whole point
// of a quick key is that it is set with one hand.
private _fnc_arm = {
    params ["_ctrl"];
    if (isNil QEFUNC(hacking,alarmAdd)) exitWith {};

    // Through hacking's own event, so the server holds the roster and every
    // machine gets the same list - the same path the hand-held uses.
    [QEGVAR(hacking,alarmAdd), [_ctrl getVariable [QGVAR(alarmStep), 300], name player]] call CBA_fnc_serverEvent;
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};

private _quick = [1, 2, 3, 5, 10];
private _stepW = (_w - (count _quick + 1) * _pad) / (count _quick);
{
    private _sx = _pad + _forEachIndex * (_stepW + _pad);

    [_body, [_sx, _y, _stepW, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
    [_body, [_sx, _y, _stepW, _btnH], str _x, _ink, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);

    private _hit = [_body, [_sx, _y, _stepW, _btnH], _fnc_arm] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(alarmStep), _x * 60];
} forEach _quick;

[_body, [_pad, _y + _btnH, _w - 2 * _pad, _rowH * 0.8], "MINUTES FROM NOW", _mute, TEXT_LABEL, false, "center", true] call EFUNC(tacpad,drawText);
_y = _y + _btnH + _rowH * 0.8;

// --------------------------------------------------------- a custom delay ---
// Anything the five keys do not cover. The value is kept between openings,
// because setting forty-seven minutes and losing it to a map close is how a
// player decides a screen is not worth using.
private _custom = GVAR(alarmCustom);

[_body, [_pad, _y, _w * 0.44, _rowH], "CUSTOM", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_w * 0.44, _y, _w * 0.56 - _pad, _rowH], [_custom] call _fnc_clock, _ink, TEXT_TITLE, true, "right"] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

private _fnc_bump = {
    params ["_ctrl"];
    // Never below a minute: an alarm you cannot see coming is a notification.
    GVAR(alarmCustom) = ((GVAR(alarmCustom) + (_ctrl getVariable [QGVAR(bumpBy), 0])) max 60) min 86400;
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};

private _bumps = [["-10", -600], ["-1", -60], ["+1", 60], ["+10", 600], ["+60", 3600]];
private _bumpW = (_w - (count _bumps + 1) * _pad) / (count _bumps);
{
    _x params ["_label", "_by"];
    private _bx = _pad + _forEachIndex * (_bumpW + _pad);

    [_body, [_bx, _y, _bumpW, _btnH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_body, [_bx, _y, _bumpW, _btnH], _label, _mute, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);

    private _hit = [_body, [_bx, _y, _bumpW, _btnH], _fnc_bump] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(bumpBy), _by];
} forEach _bumps;
_y = _y + _btnH + _padY;

[_body, [_pad, _y, _w - 2 * _pad, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
[_body, [_pad, _y, _w - 2 * _pad, _btnH], format ["ARM %1", [_custom] call _fnc_clock], _ink, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);
private _armCustom = [_body, [_pad, _y, _w - 2 * _pad, _btnH], _fnc_arm] call EFUNC(tacpad,drawHit);
_armCustom setVariable [QGVAR(alarmStep), _custom];
_y = _y + _btnH + _padY;

// ------------------------------------------------------ against game time ---
// A DIFFERENT KIND OF ALARM ENTIRELY. Everything above is "in twenty minutes";
// this is "at 0430", which is how orders are written - and on an accelerated
// mission the two are nothing like each other. See FUNC(alarmAtDelay).
private _at = GVAR(alarmAt);
private _atText = format ["%1:%2",
    [floor (_at / 3600), 2] call CBA_fnc_formatNumber,
    [floor ((_at % 3600) / 60), 2] call CBA_fnc_formatNumber
];

[_body, [_pad, _y, _w * 0.44, _rowH], "ALARM AT", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_w * 0.44, _y, _w * 0.56 - _pad, _rowH], _atText, _ink, TEXT_TITLE, true, "right"] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

private _fnc_bumpAt = {
    params ["_ctrl"];
    // Wraps round midnight rather than clamping - 2350 plus twenty minutes is
    // ten past, not ten to.
    private _v = (GVAR(alarmAt) + (_ctrl getVariable [QGVAR(bumpBy), 0])) % 86400;
    if (_v < 0) then {_v = _v + 86400};
    GVAR(alarmAt) = _v;
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};

private _atBumps = [["-1H", -3600], ["-10", -600], ["-1", -60], ["+1", 60], ["+10", 600], ["+1H", 3600]];
private _atW = (_w - (count _atBumps + 1) * _pad) / (count _atBumps);
{
    _x params ["_label", "_by"];
    private _bx = _pad + _forEachIndex * (_atW + _pad);

    [_body, [_bx, _y, _atW, _btnH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_body, [_bx, _y, _atW, _btnH], _label, _mute, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);

    private _hit = [_body, [_bx, _y, _atW, _btnH], _fnc_bumpAt] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(bumpBy), _by];
} forEach _atBumps;
_y = _y + _btnH + _padY;

// WHAT IT COSTS IN MISSION TIME, SAID OUT LOUD. On a 6x mission "at 0430" can be
// four minutes away, and a man who does not know that sets it and walks off.
private _atDelay = [_at] call FUNC(alarmAtDelay);

[_body, [_pad, _y, _w - 2 * _pad, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
[
    _body, [_pad, _y, _w - 2 * _pad, _btnH],
    format ["ARM AT %1  -  IN %2", _atText, [_atDelay] call _fnc_clock],
    _ink, TEXT_TITLE, true, "center"
] call EFUNC(tacpad,drawText);

[_body, [_pad, _y, _w - 2 * _pad, _btnH], {
    if (isNil QEFUNC(hacking,alarmAdd)) exitWith {};
    // Worked out at PRESS time, not at draw time: the screen may have been open
    // for a minute and the world clock has moved under it.
    [QEGVAR(hacking,alarmAdd), [[GVAR(alarmAt)] call FUNC(alarmAtDelay), name player]] call CBA_fnc_serverEvent;
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

_y = _y + _btnH + _padY;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

// ---------------------------------------------------------- the stopwatch ---
([] call FUNC(timerState)) params ["_secs", "_running", "_down", "_expired"];

[_body, [_pad, _y, _w * 0.5, _rowH], "STOPWATCH", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
[
    _body, [_w * 0.5, _y, _w * 0.5 - _pad, _rowH],
    switch (true) do {
        case (_expired): {"TIME"};
        case (_running): {"RUNNING"};
        case (_secs > 0): {"HELD"};
        default {"READY"};
    },
    ([_mute, _accent] select (_expired || _running)), TEXT_LABEL, true, "right", true
] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

// The readout's box is its own text height plus air, not a multiple of the row:
// at 2.4 times the body size it outgrew a row-based box and START / RESET sat
// over the digits (user screenshot, 2026-10-21: "lower the buttons a little").
private _clockH = ([TEXT_DISPLAY] call EFUNC(tacpad,textH)) + 2 * _padY;
[_body, [_pad, _y, _w - 2 * _pad, _clockH], [_secs] call _fnc_clock, ([_ink, _accent] select _expired), TEXT_DISPLAY, true, "center"] call EFUNC(tacpad,drawText);
_y = _y + _clockH + _padY;

private _halfW = (_w - 3 * _pad) / 2;

[_body, [_pad, _y, _halfW, _btnH], _accent] call EFUNC(tacpad,drawFill);
[_body, [_pad, _y, _halfW, _btnH], ["START", "STOP"] select _running, _ground, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);
[_body, [_pad, _y, _halfW, _btnH], {
    ["toggle"] call FUNC(timerSet);
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

private _resetX = _pad * 2 + _halfW;
[_body, [_resetX, _y, _halfW, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
[_body, [_resetX, _y, _halfW, _btnH], "RESET", _ink, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);
[_body, [_resetX, _y, _halfW, _btnH], {
    ["reset"] call FUNC(timerSet);
    {["timer"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

// A screen showing clocks has to redraw itself or it is a photograph of them.
private _existing = uiNamespace getVariable [QGVAR(timerPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(timerPFH), [{
    params ["", "_handle"];

    // TWO QUESTIONS, NOT ONE. "Is this app still open" decides whether the loop
    // lives; "is the pointer off it" decides whether it may REDRAW. They were
    // the same test, and redrawing means deleting and rebuilding every control
    // on the screen - so this loop was destroying the buttons under the
    // player's cursor once a second and a press had to survive a coin toss.
    // See EFUNC(tacpad,appIdle).
    if !(["timer"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(timerPFH), -1];
    };

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    ["timer"] call EFUNC(tacpad,openApp);
}, 1, []] call CBA_fnc_addPerFrameHandler];
