#include "script_component.hpp"
/*
 * Author: YonV
 * WEATHER, full size: the condition as a glyph and a word with DAY / NIGHT
 * beside it, the two verdicts a patrol plans against straight under it, and
 * the numbers behind them in two columns - conditions and light.
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
 * FORECAST is the engine's own and only that (DESIGN_TABLET_APPS.md WEATHER:
 * "next 8 h, with the effect on drones and CAS"): the overcast and fog it is
 * moving toward and when it gets there, with the NOW verdict rules applied to
 * them. Arma has no rain or wind forecast, so the page says NOT FORECAST
 * rather than drawing an hourly table it would have to invent.
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

// MEASURED, THEN OPENED. The hero, two verdict rows, six list rows and the
// forecast are a height that can be worked out - so it is, and the frame is
// made that size.
private _padY = PAD * HOST_H;
private _ruleH = RULE_THICK * pixelH;

// THE LIST ROWS ARE FUNC(kvRow)'s (review 2026-11-01, DESIGN_TABLET_REVIEW
// 2.4 / 3.6): at the tile detail size, never smaller (R1), so they do not
// shrink with the page - only the hero does.
private _kvH = KV_ROW_H;
private _verdicts = 2;
private _listRows = 6;

// HH:MM. Behind a polar circle the engine answers -1 for the sunrise that
// never comes; a map at that latitude is unlikely but the answer is a real
// one, so it is printed as no time rather than as 23:00 the day before.
private _fnc_hhmm = {
    params ["_hours"];
    if (_hours < 0) exitWith {"--:--"};

    private _h = floor _hours;
    private _m = round ((_hours - _h) * 60);
    if (_m >= 60) then {
        _h = (_h + 1) mod WX_HOURS_PER_DAY;
        _m = 0;
    };
    format ["%1:%2", [_h, 2] call CBA_fnc_formatNumber, [_m, 2] call CBA_fnc_formatNumber]
};

// The one set of verdict rules, for NOW and for FORECAST alike - the forecast
// has no wind or rain of its own (below), so those two come in as they are now.
private _fnc_airRisk = {
    params ["_cloud", "_mist", "_windMs"];
    _cloud > WX_AIR_OVERCAST || _mist > WX_AIR_FOG || _windMs > WX_AIR_WIND
};
private _fnc_thermal = {
    params ["_wet", "_mist"];
    _wet > WX_THERMAL_RAIN || _mist > WX_THERMAL_FOG
};
private _windSpeed = vectorMagnitude wind;

// ----------------------------------------------------------- the forecast ---
// WHAT THE ENGINE KNOWS, AND NO MORE. Arma forecasts one thing: the overcast
// and fog it is moving toward (overcastForecast, fogForecast) and how long
// until it gets there (nextWeatherChange, game seconds). There is no rain or
// wind forecast to read, so those rows say so and the verdicts take them as
// they are now. A change further out than WX_FORECAST_HOURS is named as past
// the window rather than turned into an hourly table.
private _change = nextWeatherChange;
private _cloudTo = overcastForecast;
private _fogTo = fogForecast;
private _scheduled = _change > 0;
private _byHours = (dayTime + _change / WX_SECS_PER_HOUR) mod WX_HOURS_PER_DAY;
private _by = [_byHours] call _fnc_hhmm;
private _past = _change > WX_FORECAST_HOURS * WX_SECS_PER_HOUR;

private _changeText = switch (true) do {
    case (!_scheduled): {"NONE SCHEDULED"};
    case (_past): {format ["BY %1 - PAST %2 H", _by, WX_FORECAST_HOURS]};
    default {format ["BY %1", _by]};
};
private _airTo = [_cloudTo, _fogTo, _windSpeed] call _fnc_airRisk;
private _thermalTo = [rain, _fogTo] call _fnc_thermal;
private _fnc_trend = {
    params ["_now", "_to"];
    format ["%1 > %2%3", round (_now * PERCENT), round (_to * PERCENT), "%"]
};
private _forecast = [
    ["NEXT CHANGE", _changeText, false],
    ["CLOUD COVER", [overcast, _cloudTo] call _fnc_trend, _cloudTo > WX_AIR_OVERCAST],
    ["FOG", [fog, _fogTo] call _fnc_trend, _fogTo > WX_THERMAL_FOG],
    ["ROTARY / CAS", ["ACCEPTABLE", "MARGINAL"] select _airTo, _airTo],
    ["THERMAL / DRONES", ["UNDEGRADED", "DEGRADED"] select _thermalTo, _thermalTo],
    ["RAIN, WIND", "NOT FORECAST", false]
];
private _forecastRows = ceil ((count _forecast) / WX_COLUMNS);

// The hero is three rows at the default and as tall as its word at a large
// text size: three rows clipped the word CLEAR at 2.4.
private _rowH = (ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H)
    max (([TEXT_TITLE] call EFUNC(tacpad,textH)) + _padY * 0.5);
private _heroH = (_rowH * WX_HERO_ROWS) max (([TEXT_DISPLAY] call EFUNC(tacpad,textH)) / WX_HERO_WORD);

private _fixed = _padY + _padY + _ruleH + _padY + _verdicts * _kvH + _padY + _ruleH + _padY + _listRows * _kvH + _padY * 2
    + _ruleH + _padY + _kvH + _forecastRows * _kvH + _padY;

// THE HEADER WAS THE MISSING INCH: the height asked of appFrame is the WHOLE
// window, and the body this page draws into loses the title bar and the
// borders. The chrome rides on top of the measurement.
private _chrome = HEADER_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H + _ruleH * 3;

// When taller runs out of screen, the hero gives way - the list cannot.
private _kFit = ((((WX_HOST_MAX * HOST_H) - _chrome - _fixed) / _heroH) min 1) max 0;
_heroH = _heroH * _kFit;
private _needed = _fixed + _heroH + _chrome;

([_display, "WEATHER", WX_APP_W, _needed / HOST_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;

// The tile already decides what the weather IS. Asking it rather than deciding
// again is what stops the tile saying RAIN while this says OVC. Its third
// field is the tile's qualifier, DAY or NIGHT - it was drawn here as the
// LOCAL TIME's value, which is how LOCAL TIME came to read "DAY".
private _tile = ([] call FUNC(tileData)) select {(_x # 0) == "weather"};
if (_tile isEqualTo []) exitWith {};
(_tile # 0) params ["", "", "_dayNight", "_cover", "_detail", "_state", "_icon"];

// ------------------------------------------------------------- the header ---
// One glyph, one word, at the size the design gives a tile's value and then
// some: this is the answer, everything under it is the working.
private _heroInk = [_ink, _accent] select (_state != "rest");
[_body, [_pad, _padY, _heroH], _icon, _heroInk] call EFUNC(tacpad,drawIcon);

private _heroX = _pad * 2 + _heroH * pixelW / pixelH;
private _word = [_body, [_heroX, _padY, _w - _heroX - _pad, _heroH * WX_HERO_WORD], _cover, _heroInk, (TEXT_DISPLAY * _kFit), true] call EFUNC(tacpad,drawText);

// DAY / NIGHT IS THE HEADER'S QUALIFIER, as it is the tile's (review
// 2026-11-01, DESIGN_TABLET_REVIEW 3.6): a chip beside the condition word.
private _chipH = ([KV_TEXT] call EFUNC(tacpad,textH)) + _padY;
[_body, [_heroX + ctrlTextWidth _word + _pad, _padY + (_heroH * WX_HERO_WORD - _chipH) * 0.5], _chipH, _dayNight, CHIP_OUTLINE, 0, KV_TEXT] call EFUNC(tacpad,drawChip);

// The detail line is figures - never letter-tracked (review 2026-11-01, 2.3).
[_body, [_heroX, _padY + _heroH * WX_HERO_WORD, _w - _heroX - _pad, _heroH * (1 - WX_HERO_WORD)], _detail, _muted, KV_TEXT] call EFUNC(tacpad,drawText);

private _y = _padY + _heroH + _padY;
[_body, [_pad, _y, _w - 2 * _pad, _ruleH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _ruleH + _padY;

// ----------------------------------------------------------- the verdicts ---
// What the numbers are FOR, under the condition (review 2026-11-01, 3.6: they
// were at the bottom, and they are the reason a player opens the page).
private _airRisk = [overcast, fog, _windSpeed] call _fnc_airRisk;
private _thermal = [rain, fog] call _fnc_thermal;

_y = _y + ([_body, [_pad, _y, _w - 2 * _pad], [
    ["ROTARY", ["CONDITIONS ACCEPTABLE", "MARGINAL - CEILING, VIS OR WIND"] select _airRisk, _airRisk],
    ["THERMAL", ["UNDEGRADED", "DEGRADED BY RAIN OR FOG"] select _thermal, _thermal]
], 1, _kvH] call FUNC(kvRow));

_y = _y + _padY;
[_body, [_pad, _y, _w - 2 * _pad, _ruleH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _ruleH + _padY;

// -------------------------------------------------------------- the rows ----
date params ["", "_month", "_day"];
private _sun = date call BIS_fnc_sunriseSunsetTime;
_sun params [["_rise", 0], ["_set", 0]];

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

// TWO COLUMNS (review 2026-11-01, DESIGN_TABLET_REVIEW 3.6) - FUNC(kvRow)
// fills down and then across, so the six conditions are the left column and
// the five lines of light the right one.
_y = _y + ([_body, [_pad, _y, _w - 2 * _pad], [
    ["CLOUD COVER", format ["%1%2", round (overcast * 100), "%"], overcast > 0.7],
    ["RAIN", format ["%1%2", round (rain * 100), "%"], rain > 0.05],
    ["FOG", format ["%1%2", round (fog * 100), "%"], fog > 0.35],
    ["WIND", format ["%1 - %2 M/S", round windDir, round _windSpeed], _windSpeed > 9],
    ["WIND STATE", _beaufort, _windSpeed > 9],
    ["VISIBILITY", format ["%1 KM", (round (viewDistance / 100)) / 10], viewDistance < 1000],
    ["LOCAL TIME", [dayTime] call _fnc_hhmm, false],
    ["FIRST LIGHT", [_rise] call _fnc_hhmm, false],
    ["LAST LIGHT", [_set] call _fnc_hhmm, false],
    ["MOON", format ["%1%2 LIT", round (moonIntensity * 100), "%"], false],
    ["DATE", format ["%1 %2", [_day, 2] call CBA_fnc_formatNumber, ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"] param [_month - 1, "---"]], false]
], WX_COLUMNS, _kvH] call FUNC(kvRow));

// ----------------------------------------------------------- FORECAST rows ---
// Under the light, a kicker that says what the forecast is - the engine's next
// change, not an hourly table - then the six pairs worked out at the top.
_y = _y + _padY;
[_body, [_pad, _y, _w - 2 * _pad, _ruleH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _ruleH + _padY;
[_body, [_pad, _y, _w - 2 * _pad, _kvH], "FORECAST - TO THE ENGINE'S NEXT CHANGE", _muted, KV_TEXT, true, "left", true] call EFUNC(tacpad,drawText);
_y = _y + _kvH;
[_body, [_pad, _y, _w - 2 * _pad], _forecast, WX_COLUMNS, _kvH] call FUNC(kvRow);
