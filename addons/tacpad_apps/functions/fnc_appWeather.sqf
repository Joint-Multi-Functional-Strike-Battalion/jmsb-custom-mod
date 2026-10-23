#include "script_component.hpp"
/*
 * Author: JMSB
 * WEATHER, full size: the condition as a glyph and a word, the numbers behind
 * it, and the three lines a patrol actually plans against - light, visibility
 * and wind.
 *
 * IT READS THE ENGINE AND NOTHING ELSE. Every figure here is a scripting command
 * on the local machine, so there is no source that can disagree with the tile
 * and nothing to keep in sync - the tile and this are two renderings of one
 * read, which is why they share FUNC(tileData)'s condition rules.
 *
 * FIRST AND LAST LIGHT are the honest names. Arma gives sunrise and sunset, and
 * a patrol leaving before dawn cares about the moment there is enough light to
 * move, not the moment the disc clears the horizon - but the engine does not
 * model civil twilight, so these are labelled for what they are.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

// MEASURED, THEN OPENED. Eleven rows, a hero block and a two-line footer is a
// height that can be worked out - so it is, and the frame is made that size.
// Guessing 0.52 and letting a scrollbar take up the difference is the app
// declining to do arithmetic it is perfectly able to do.
private _padY = PAD * HOST_H;

// A ROW IS AS TALL AS THE LINE STANDING IN IT. ROW_H is a DENSITY - a target
// spacing - and it is not a promise that the type fits: past about 1.4 on the
// text-size setting the line is taller than the row, eleven of them walk the
// footer off the bottom of a frame that was measured in rows, and the last thing
// on the page is cut in half. Measured off the type instead, so the page is
// whatever height it actually needs at whatever size the player reads at.
private _rowH = (ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H)
    max (([TEXT_TITLE] call EFUNC(tacpad,textH)) + _padY * 0.5);

// The hero is the same problem at 2.4: three rows was ample at the default and
// clipped the word CLEAR at a large one.
private _heroH = (_rowH * 3) max (([TEXT_DISPLAY] call EFUNC(tacpad,textH)) / 0.62);

// ONE TALL COLUMN - asked for by the user for the twentieth time, in those
// words, so the two-column compromise is dead. Eleven rows stack down a
// narrower frame; if a huge text size outgrows the safe zone, appFrame's
// clamp shows it as clipping at the bottom edge rather than sliding the page
// off both ends.
private _lines = 11;
private _perCol = _lines;

private _needed = _padY + _heroH + _padY + RULE_THICK * pixelH + _padY
    + (_perCol * _rowH) + _padY * 2 + RULE_THICK * pixelH + (_rowH * 2) + _padY * 2;

// THE HEADER WAS THE MISSING INCH - the reason "taller" fell short build
// after build: the height asked of appFrame is the WHOLE window, but the
// body this page draws into loses the title bar and the borders. A page
// measured exactly to its content therefore clipped its last line by
// exactly one header. The chrome rides on top of the measurement now.
private _chrome = HEADER_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H + (RULE_THICK * pixelH) * 3;

// And when taller genuinely runs out of screen, the PAGE fits the screen:
// rows, hero and type scale down by one factor so the last line is always on
// the page.
private _kFit = (((0.92 * HOST_H) - _chrome) / _needed) min 1;
_rowH = _rowH * _kFit;
_heroH = _heroH * _kFit;
_needed = _needed * _kFit + _chrome;

([_display, "WEATHER", 0.42, _needed / HOST_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _pad = PAD * HOST_W;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

// The tile already decides what the weather IS. Asking it rather than deciding
// again is what stops the tile saying RAIN while this says OVC.
private _tile = ([] call FUNC(tileData)) select {(_x # 0) == "weather"};
if (_tile isEqualTo []) exitWith {};
(_tile # 0) params ["", "", "_clock", "_cover", "_detail", "_state", "_icon"];

// ------------------------------------------------------------- the header ---
// One glyph, one word, at the size the design gives a tile's value and then
// some: this is the answer, everything under it is the working.
[_body, [_pad, _padY, _heroH], _icon, ([_ink, _accent] select (_state != "rest"))] call EFUNC(tacpad,drawIcon);

private _heroX = _pad * 2 + _heroH * pixelW / pixelH;
[_body, [_heroX, _padY, _w - _heroX - _pad, _heroH * 0.62], _cover, ([_ink, _accent] select (_state != "rest")), (TEXT_DISPLAY * _kFit), true] call EFUNC(tacpad,drawText);
[_body, [_heroX, _padY + _heroH * 0.6, _w - _heroX - _pad, _heroH * 0.4], _detail, _mute, (TEXT_BODY * _kFit), true, "left", true] call EFUNC(tacpad,drawText);

private _y = _padY + _heroH + _padY;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

// -------------------------------------------------------------- the rows ----
date params ["", "_month", "_day"];
private _sun = date call BIS_fnc_sunriseSunsetTime;
_sun params [["_rise", 0], ["_set", 0]];

// Behind a polar circle the engine answers -1 for the sunrise that never comes.
// A map at that latitude is unlikely but the answer is a real one, so it is
// printed as no time rather than as 23:00 the day before.
private _fnc_hhmm = {
    params ["_hours"];
    if (_hours < 0) exitWith {"----"};

    private _h = floor _hours;
    format ["%1%2", [_h, 2] call CBA_fnc_formatNumber, [round ((_hours - _h) * 60), 2] call CBA_fnc_formatNumber]
};

private _windSpeed = vectorMagnitude wind;

// Beaufort, because "8 m/s" means nothing to most people and "fresh breeze -
// dust and loose paper lift" means something to anyone who has to walk in it.
private _beaufort = switch (true) do {
    case (_windSpeed < 0.3): {"CALM"};
    case (_windSpeed < 1.6): {"LIGHT AIR"};
    case (_windSpeed < 3.4): {"LIGHT BREEZE"};
    case (_windSpeed < 5.5): {"GENTLE BREEZE"};
    case (_windSpeed < 8): {"MODERATE BREEZE"};
    case (_windSpeed < 10.8): {"FRESH BREEZE"};
    case (_windSpeed < 13.9): {"STRONG BREEZE"};
    case (_windSpeed < 17.2): {"NEAR GALE"};
    default {"GALE"};
};

private _colW = _w - 2 * _pad;

{
    _x params ["_label", "_value", "_hot"];

    // Filled down the left column and then down the right, not alternating -
    // a reader goes down a column, and interleaving would put CLOUD COVER
    // opposite RAIN for no reason anybody could name.
    private _col = floor (_forEachIndex / _perCol);
    private _cx = _pad + _col * (_colW + _pad);
    private _ry = _y + (_forEachIndex - _col * _perCol) * _rowH;

    [_body, [_cx, _ry, _colW * 0.46, _rowH], _label, _mute, (TEXT_BODY * _kFit), true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_cx + _colW * 0.46, _ry, _colW * 0.54, _rowH], _value, ([_ink, _accent] select _hot), (TEXT_TITLE * _kFit), true, "right"] call EFUNC(tacpad,drawText);
    [_body, [_cx, _ry + _rowH - RULE_THIN * pixelH, _colW, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach [
    ["LOCAL TIME", _clock, false],
    ["CLOUD COVER", format ["%1%2", round (overcast * 100), "%"], overcast > 0.7],
    ["RAIN", format ["%1%2", round (rain * 100), "%"], rain > 0.05],
    ["FOG", format ["%1%2", round (fog * 100), "%"], fog > 0.35],
    ["WIND", format ["%1 - %2 M/S", round windDir, round _windSpeed], _windSpeed > 9],
    ["WIND STATE", _beaufort, _windSpeed > 9],
    ["VISIBILITY", format ["%1 KM", (round (viewDistance / 100)) / 10], viewDistance < 1000],
    ["FIRST LIGHT", [_rise] call _fnc_hhmm, false],
    ["LAST LIGHT", [_set] call _fnc_hhmm, false],
    ["MOON", format ["%1%2 LIT", round (moonIntensity * 100), "%"], false],
    ["DATE", format ["%1 %2", [_day, 2] call CBA_fnc_formatNumber, ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"] param [_month - 1, "---"]], false]
];

// ------------------------------------------------------------- the footer ---
// What the numbers are FOR. A weather screen that will not say whether you can
// fly or be seen is a screen nobody opens twice.
//
// IT FOLLOWS THE ROWS. Pinning it to the bottom of the frame meant it landed on
// top of the last two rows whenever the frame was a fraction shorter than the
// content - which is what drew a line through DATE.
private _footY = _y + _perCol * _rowH + _padY;
[_body, [_pad, _footY - _padY, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);

private _airRisk = overcast > 0.75 || {fog > 0.4} || _windSpeed > 12;
private _thermal = rain > 0.1 || {fog > 0.3};

[
    _body, [_pad, _footY, _w - 2 * _pad, _rowH],
    format ["ROTARY - %1", ["CONDITIONS ACCEPTABLE", "MARGINAL - CEILING, VIS OR WIND"] select _airRisk],
    ([_ink, _accent] select _airRisk), (TEXT_BODY * _kFit), true, "left", true
] call EFUNC(tacpad,drawText);

[
    _body, [_pad, _footY + _rowH, _w - 2 * _pad, _rowH],
    format ["THERMAL - %1", ["UNDEGRADED", "DEGRADED BY RAIN OR FOG"] select _thermal],
    ([_ink, _accent] select _thermal), (TEXT_BODY * _kFit), true, "left", true
] call EFUNC(tacpad,drawText);
