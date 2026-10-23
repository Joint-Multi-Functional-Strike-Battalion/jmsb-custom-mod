#include "script_component.hpp"
/*
 * Author: JMSB
 * One TAC//SUPPORT stepper - the handoff's .stepper, which replaces every
 * slider: a micro-label above, then a 2px ink box of three cells - a "-"
 * cell, the value bar, a "+" cell. The value sits flush left in the bar with
 * an ink fill beside it showing where the value lies in its range.
 *
 * Step cells go accent under a ground glyph on hover and accent-600 on press;
 * at a range end the cell dims and takes no press. The value is one slot of
 * the support parameter array, so the map overlay that reads the same slot
 * follows each step live.
 *
 * A VALUE LIST steps through the listed values in order instead of adding the
 * step - the ROE stepper walks the combat modes least to most permissive
 * while the slot keeps the adapter's index for each.
 *
 * Arguments:
 * 0: Parent controls group <CONTROL>
 * 1: [x, y, w] - where the label goes and how wide the box is <ARRAY>
 * 2: Label <STRING>
 * 3: Value text <STRING>
 * 4: Parameter slot <NUMBER>
 * 5: Step <NUMBER>
 * 6: Minimum <NUMBER>
 * 7: Maximum <NUMBER>
 * 8: Value list, [] for a plain range <ARRAY>
 * 9: Draw the range bar <BOOL>
 *
 * Return Value:
 * Bottom edge of the stepper <NUMBER>
 *
 * Example:
 * _y = [_body, [_pad, _y, _w], "CAS RADIUS", "500 M", 0, 100, 100, 1000, [], true] call jmfsb_tacpad_apps_fnc_supportStepper
 *
 * Public: No
 */

// 38px box on 34px rows, square-ish 34px step cells, an 8px range bar.
#define STEP_LABEL_K 0.75
#define STEP_BOX_K 1.2
#define STEP_CELL_K 1.1
#define STEP_BAR_PX 8
#define STEP_BAR_SPAN 0.45
#define STEP_BAR_MIN 0.03

params [
    ["_parent", controlNull, [controlNull]],
    ["_at", [0, 0, 0], [[]], 3],
    ["_label", "", [""]],
    ["_valueText", "", [""]],
    ["_slot", 0, [0]],
    ["_delta", 1, [0]],
    ["_min", 0, [0]],
    ["_max", 1, [0]],
    ["_list", [], [[]]],
    ["_bar", true, [false]]
];

if (isNull _parent) exitWith {_at select 1};

_at params ["_x0", "_y0", "_w"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * SUP_UNIT_H;
private _pad = PAD * SUP_UNIT_W;
private _labelH = _rowH * STEP_LABEL_K;
private _boxH = _rowH * STEP_BOX_K;
private _cellW = _boxH * STEP_CELL_K * (pixelW / pixelH);

private _ground = +(["ground"] call EFUNC(tacpad,theme));
_ground set [3, 1];
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

// Where the value lies, as a position in its range.
private _raw = (missionNamespace getVariable [QGVAR(supportParams), SUP_PARAMS_DEFAULT]) param [_slot, _min];
private _pos = if (_list isEqualTo []) then {(_raw max _min) min _max} else {(_list find _raw) max 0};
private _lo = [_min, 0] select (_list isNotEqualTo []);
private _hi = [_max, count _list - 1] select (_list isNotEqualTo []);
private _frac = if (_hi > _lo) then {(_pos - _lo) / (_hi - _lo)} else {1};

[_parent, [_x0, _y0, _w, _labelH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);

private _by = _y0 + _labelH;
[_parent, [_x0, _by, _w, _boxH], _ground] call EFUNC(tacpad,drawFill);
[_parent, [_x0, _by, _w, _boxH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
[_parent, [_x0 + _cellW, _by, RULE_THICK * pixelW, _boxH], _ink] call EFUNC(tacpad,drawFill);
[_parent, [_x0 + _w - _cellW, _by, RULE_THICK * pixelW, _boxH], _ink] call EFUNC(tacpad,drawFill);

// The value bar.
private _vx = _x0 + _cellW + _pad * 2;
private _vw = _w - 2 * _cellW - _pad * 4;
[_parent, [_vx, _by, _vw * (1 - STEP_BAR_SPAN), _boxH], _valueText, _ink, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
if (_bar) then {
    private _barH = STEP_BAR_PX * pixelH;
    private _barW = _vw * STEP_BAR_SPAN * (_frac max STEP_BAR_MIN);
    [_parent, [_vx + _vw * (1 - STEP_BAR_SPAN), _by + (_boxH - _barH) / 2, _barW, _barH], _ink] call EFUNC(tacpad,drawFill);
};

// The two step cells. Inset by the frame so the hover fill does not paint
// over the box's own border.
private _inX = RULE_THICK * pixelW;
private _inY = RULE_THICK * pixelH;
{
    _x params ["_glyph", "_dir", "_cx"];
    private _end = [_pos <= _lo, _pos >= _hi] select (_dir > 0);
    private _rect = [_cx + _inX, _by + _inY, _cellW - 2 * _inX, _boxH - 2 * _inY];
    private _fill = [_parent, _rect, _ground] call EFUNC(tacpad,drawFill);
    private _spec = ["label", [_parent, _rect, _glyph, [_ink, _dim] select _end, TEXT_TITLE, true, "center"]] call FUNC(supportHover);

    if (!_end) then {
        private _hit = [_parent, _rect, {
            params ["_ctrl"];
            (_ctrl getVariable [QGVAR(step), []]) params ["_slot", "_delta", "_min", "_max", ["_list", []]];
            private _prm = missionNamespace getVariable [QGVAR(supportParams), SUP_PARAMS_DEFAULT];
            if (_list isEqualTo []) then {
                _prm set [_slot, ((_prm param [_slot, _min]) + _delta) max _min min _max];
            } else {
                private _i = (_list find (_prm param [_slot, _list select 0])) max 0;
                _prm set [_slot, _list select (((_i + ([-1, 1] select (_delta > 0))) max 0) min (count _list - 1))];
            };
            missionNamespace setVariable [QGVAR(supportParams), _prm];
            {["support"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(step), [_slot, _delta * _dir, _min, _max, _list]];
        ["wire", [_hit, _fill, [_spec], _ground, _accent, _ground]] call FUNC(supportHover);
    };
} forEach [["-", -1, _x0], ["+", 1, _x0 + _w - _cellW]];

_by + _boxH
