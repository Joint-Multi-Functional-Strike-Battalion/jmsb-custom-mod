#include "script_component.hpp"
/*
 * Author: JMSB
 * Draws one column of VEHICLE STATUS from its lines (FUNC(vehicleLines)):
 * section heads with their right label and the ink rule under them (the app
 * rule of docs/DESIGN_TABLET_APPS.md), bar rows for damage and fuel, and plain
 * label / value rows, each over a thin rule.
 *
 * A COLUMN THAT RUNS OUT OF ROOM SAYS SO. The page is sized to its longest
 * column, up to the whole map area; past that, the lines that do not fit are
 * counted on a last "+N MORE" row instead of running off the page. A tank
 * with eight magazine types on three turrets is the case it is for.
 *
 * Colours come in as theme token names and are resolved here, through
 * jmfsb_tacpad_fnc_theme, so the page repaints with the scheme.
 *
 * A VALUE'S TONE IS A FILL, NEVER ITS TEXT. The swatches (TONE_OK, TONE_WARN)
 * are too pale to read as text on the light grounds, so a swatch value is ink
 * with a small swatch square beside it, as SQUAD draws its A / C / E chips -
 * and a bar's value is plain ink, the bar being the swatch. TONE_ALERT is the
 * inverted block: the accent filled behind the value and the value in the
 * ground colour, the tile band's "alert", so red never rests on a hue that is
 * tan or lime on some schemes. Other tokens (ink, muted, dim) colour the text.
 *
 * Arguments:
 * 0: The app's body <CONTROL>
 * 1: Column [x, y, w, bottom], relative to the body <ARRAY>
 * 2: Lines <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, [0, _top, _w * 0.33, _h], _lines] call jmfsb_devices_fnc_vehicleColumn
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [], [[]], 4], ["_lines", [], [[]]]];
if (isNull _body) exitWith {};
_rect params ["_x0", "_y", "_w", "_bottom"];

private _tokens = createHashMap;
private _fnc_tone = {
    params ["_token"];
    if !(_token in _tokens) then {
        _tokens set [_token, [_token] call EFUNC(tacpad,theme)];
    };
    _tokens get _token
};

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _ruleThin = RULE_THIN * pixelH;
private _ruleThick = RULE_THICK * pixelH;
private _barH = _rowH * VEHICLE_BAR_ROW;
private _ink = ["ink"] call _fnc_tone;
private _line = ["line"] call _fnc_tone;
private _muted = ["muted"] call _fnc_tone;
private _accent = ["accent"] call _fnc_tone;
private _ground = ["ground"] call _fnc_tone;
private _swatchH = _rowH * VEHICLE_SWATCH_ROW;
private _swatchW = _swatchH * pixelW / pixelH;
private _blockH = _rowH * VEHICLE_BLOCK_ROW;

// A right-aligned value in its cell [x, y, w, h], in its tone. A swatch square
// goes left of the text only when asked (a bar row has its bar for that).
private _fnc_value = {
    params ["_cell", "_text", "_tone", "_withSwatch"];
    _cell params ["_cx", "_cy", "_cw", "_ch"];
    if (_text isEqualTo "") exitWith {};

    if (_tone isEqualTo TONE_ALERT) exitWith {
        [_body, [_cx, _cy + (_ch - _blockH) * 0.5, _cw, _blockH], _accent] call EFUNC(tacpad,drawFill);
        [_body, [_cx, _cy, _cw - _pad, _ch], _text, _ground, VEHICLE_TEXT_ROW, true, "right"] call EFUNC(tacpad,drawText);
    };

    if (_tone in [TONE_OK, TONE_WARN]) exitWith {
        private _ctrl = [_body, _cell, _text, _ink, VEHICLE_TEXT_ROW, true, "right"] call EFUNC(tacpad,drawText);
        if (_withSwatch) then {
            private _sx = (_cx + _cw - (ctrlTextWidth _ctrl) - _pad - _swatchW) max _cx;
            [_body, [_sx, _cy + (_ch - _swatchH) * 0.5, _swatchW, _swatchH], [_tone] call _fnc_tone] call EFUNC(tacpad,drawFill);
        };
    };

    [_body, _cell, _text, [_tone] call _fnc_tone, VEHICLE_TEXT_ROW, true, "right"] call EFUNC(tacpad,drawText);
};

{
    private _kind = _x select 0;
    private _need = _rowH * ([[1, VEHICLE_HEAD_ROWS] select (_kind isEqualTo "head"), VEHICLE_GAP_ROWS] select (_kind isEqualTo "gap"));

    // The last row that fits says how many did not: every line but the last
    // keeps a row free under it for that.
    private _reserve = [_rowH, 0] select (_forEachIndex isEqualTo (count _lines - 1));
    if (_y + _need + _reserve > _bottom) exitWith {
        private _rest = {(_x select 0) isNotEqualTo "gap"} count (_lines select [_forEachIndex]);
        [_body, [_x0 + _pad, _y, _w - 2 * _pad, _rowH], format ["+%1 MORE", _rest], _muted, VEHICLE_TEXT_ROW, true, "right", true] call EFUNC(tacpad,drawText);
    };

    switch (_kind) do {
        case "head": {
            _x params ["", "_title", "_meta"];
            [_body, [_x0 + _pad, _y, _w * VEHICLE_HEAD_SPLIT, _rowH], _title, _muted, VEHICLE_TEXT_HEAD, true, "left", true] call EFUNC(tacpad,drawText);
            [_body, [_x0 + _w * (1 - VEHICLE_HEAD_SPLIT), _y, _w * VEHICLE_HEAD_SPLIT - _pad, _rowH], _meta, _muted, VEHICLE_TEXT_HEAD, true, "right"] call EFUNC(tacpad,drawText);
            [_body, [_x0 + _pad, _y + _rowH, _w - 2 * _pad, _ruleThick], _ink] call EFUNC(tacpad,drawFill);
        };
        case "bar": {
            _x params ["", "_label", "_fill", "_tone", "_value"];
            private _colour = if (_tone isEqualTo TONE_ALERT) then {_accent} else {[_tone] call _fnc_tone};
            private _barX = _x0 + _w * VEHICLE_BAR_LABEL_END;
            private _barW = _w * (VEHICLE_BAR_END - VEHICLE_BAR_LABEL_END);
            private _barY = _y + (_rowH - _barH) * 0.5;
            [_body, [_x0 + _pad, _y, _w * VEHICLE_BAR_LABEL_END - _pad, _rowH], _label, _ink, VEHICLE_TEXT_ROW, true] call EFUNC(tacpad,drawText);
            [_body, [_barX, _barY, _barW, _barH], _line] call EFUNC(tacpad,drawFill);
            if (_fill > 0) then {
                [_body, [_barX, _barY, _barW * ((_fill max 0) min 1), _barH], _colour] call EFUNC(tacpad,drawFill);
            };
            [[_barX + _barW + _pad, _y, _w * (1 - VEHICLE_BAR_END) - 2 * _pad, _rowH], _value, [_tone, "ink"] select (_tone in [TONE_OK, TONE_WARN]), false] call _fnc_value;
            [_body, [_x0 + _pad, _y + _rowH - _ruleThin, _w - 2 * _pad, _ruleThin], _line] call EFUNC(tacpad,drawFill);
        };
        case "row": {
            _x params ["", "_left", "_right", "_leftTone", "_rightTone", "_bold", "_indent"];
            private _in = _indent * VEHICLE_INDENT_PADS * _pad;
            private _split = _w * VEHICLE_ROW_SPLIT;
            [_body, [_x0 + _pad + _in, _y, _split - _pad - _in, _rowH], _left, [_leftTone] call _fnc_tone, VEHICLE_TEXT_ROW, _bold] call EFUNC(tacpad,drawText);
            [[_x0 + _split, _y, _w - _split - _pad, _rowH], _right, _rightTone, true] call _fnc_value;
            [_body, [_x0 + _pad, _y + _rowH - _ruleThin, _w - 2 * _pad, _ruleThin], _line] call EFUNC(tacpad,drawFill);
        };
    };

    _y = _y + _need;
} forEach _lines;
