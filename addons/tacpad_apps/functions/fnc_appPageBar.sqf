#include "script_component.hpp"
/*
 * Author: JMSB
 * A quality bar with its number beside it: RF's 0..1 link quality (or any
 * other 0..1 share). The fill is the swatch for the band it falls in - green
 * GOOD, yellow FAIR, the accent below - and -1 (RF's "does not know") is an
 * empty track with a dash, never a zero that reads as a dead link.
 *
 * Arguments:
 * 0: Body to draw into <CONTROL>
 * 1: Rectangle [x, y, w, h] of the bar and its number <ARRAY>
 * 2: Value 0..1, or QUALITY_UNKNOWN <NUMBER>
 * 3: Text beside the bar, "" for the value to two places <STRING> (optional, default "")
 * 4: Higher is worse - the colours run the other way (risk) <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, [_x, _y, _w, _h], 0.82] call jmfsb_tacpad_apps_fnc_appPageBar
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_value", QUALITY_UNKNOWN, [0]],
    ["_text", "", [""]],
    ["_inverse", false, [false]]
];

if (isNull _body) exitWith {};

_rect params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _known = _value >= 0;
private _v = (_value max 0) min 1;
private _score = [_v, 1 - _v] select _inverse;
private _colour = switch (true) do {
    case (_score >= QUALITY_GOOD): {["swatchGreen"] call EFUNC(tacpad,theme)};
    case (_score >= QUALITY_FAIR): {["swatchYellow"] call EFUNC(tacpad,theme)};
    default {["accent"] call EFUNC(tacpad,theme)};
};

private _trackW = _w * 0.55;
private _trackH = _h * 0.35;
private _trackY = _top + (_h - _trackH) * 0.5;

[_body, [_left, _trackY, _trackW, _trackH], _line] call EFUNC(tacpad,drawFill);
if (_known && _v > 0) then {
    [_body, [_left, _trackY, _trackW * _v, _trackH], _colour] call EFUNC(tacpad,drawFill);
};

if (_text isEqualTo "") then {
    _text = if (_known) then {_v toFixed 2} else {"--"};
};
[_body, [_left + _trackW + PAD * HOST_W, _top, _w - _trackW - PAD * HOST_W, _h], _text, ([_dim, _ink] select _known), TEXT_LABEL, false] call EFUNC(tacpad,drawText);
