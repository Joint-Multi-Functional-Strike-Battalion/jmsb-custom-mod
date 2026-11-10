#include "script_component.hpp"
/*
 * Author: YonV
 * Draws one row inside a panel body: an optional swatch, a label, an optional
 * value - right-aligned at the far edge, or left-aligned in a value column
 * when the caller sets one - and a hairline under it.
 *
 * Every list in the suite is this row - the roster, the traffic list, the tool
 * strip - so they cannot drift apart in padding, type size or divider weight,
 * which is exactly what happens when three panels each draw their own.
 *
 * Arguments:
 * 0: Body control to draw into <CONTROL>
 * 1: Row index, 0 based <NUMBER>
 * 2: Label <STRING>
 * 3: Right-hand value <STRING> (optional, default "")
 * 4: Swatch RGBA, [] for none <ARRAY> (optional, default [])
 * 5: Draw the label in the accent colour <BOOL> (optional, default false)
 * 6: Called with [rowIndex, control] when clicked, {} for a dead row <CODE>
 *      (optional, default {}). The control is passed so a row can carry what it
 *      is about on itself - reading it back off a list by position breaks the
 *      moment that list changes between the draw and the click.
 * 7: Value column - where the value starts, as a fraction of the row's width,
 *      left-aligned there; ROW_VALUE_RIGHT (0) for the value right-aligned at
 *      the row's far edge <NUMBER> (optional, default ROW_VALUE_RIGHT)
 *
 * Return Value:
 * The row's text control - the label's; a value column draws its own <CONTROL>
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_index", 0, [0]],
    ["_label", "", [""]],
    ["_value", "", [""]],
    ["_swatch", [], [[]]],
    ["_accented", false, [false]],
    ["_onClick", {}, [{}]],
    ["_valueAt", ROW_VALUE_RIGHT, [0]]
];

if (isNull _body) exitWith {controlNull};

private _display = ctrlParent _body;
if (isNull _display) exitWith {controlNull};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _w = (ctrlPosition _body) # 2;
private _scale = EGVAR(tacpad,textScale);
// THE ROW RHYTHM (notes, 2026-10-30): the host class's pixels, grown by the
// text scale only when the type would overflow them; the type is held to the
// row either way.
private _rowH = ROW_H_SCREEN;
private _y = _index * _rowH;
private _pad = PAD * HOST_W;
private _size = [TEXT_BODY] call EFUNC(tacpad,textSize);
private _lineH = [TEXT_BODY] call EFUNC(tacpad,textH);
if (_lineH > _rowH) then {_size = _size * _rowH / _lineH};

private _swatchW = 0;
if (_swatch isNotEqualTo []) then {
    _swatchW = _rowH * 0.4;
    private _mark = _display ctrlCreate [QEGVAR(tacpad,fill), -1, _body];
    _mark ctrlSetPosition [_pad, _y + _rowH * 0.3, _swatchW, _rowH * 0.4];
    _mark ctrlSetBackgroundColor _swatch;
    _mark ctrlCommit 0;
};

private _text = _display ctrlCreate [QEGVAR(tacpad,cell), -1, _body];
private _textX = _pad + _swatchW + ([0, _pad] select (_swatch isNotEqualTo []));

// A VALUE COLUMN (user, 2026-10-30, of the WEATHER rows: "move this data to
// the left, hard to read across screen like this"). With a column set, the
// label stops a pad short of it and the value is left-aligned from it in a
// control of its own - structured text has no tab stop, so one control
// cannot hold a label at the left and a value at a fixed x. Without one the
// value rides right-aligned in the label's control, as every list always has.
private _column = _valueAt > ROW_VALUE_RIGHT && _value != "";
private _valueX = _w * _valueAt;
private _labelW = [_w - _textX - _pad, (_valueX - _textX - _pad) max 0] select _column;
_text ctrlSetPosition [_textX, _y, _labelW, _rowH];

private _fontH = TEXT_BASE * pixelH * pixelGrid * HOST_K * _scale;
private _colour = [_ink, _accent] select _accented;
// The label in the sans, the value in the monospace (the two type roles).
private _line1 = format [
    "<t font='%4' size='%3' color='%1'>%2</t>",
    _colour call BIS_fnc_colorRGBAtoHTML,
    [_label] call EFUNC(tacpad,xmlSafe),
    _size,
    FONT_LABEL
];
if (_value != "") then {
    private _valueText = format [
        "<t font='%4' size='%3' align='%5' color='%1'>%2</t>",
        _ink call BIS_fnc_colorRGBAtoHTML,
        [_value] call EFUNC(tacpad,xmlSafe),
        _size,
        FONT_MONO_BOLD,
        ["right", "left"] select _column
    ];
    if (_column) then {
        // The same class, y, height and font height as the label's control,
        // so the two sit on one baseline.
        private _cell = _display ctrlCreate [QEGVAR(tacpad,cell), -1, _body];
        _cell ctrlSetPosition [_valueX, _y, _w - _valueX - _pad, _rowH];
        _cell ctrlSetFontHeight _fontH;
        _cell ctrlSetStructuredText parseText _valueText;
        _cell ctrlCommit 0;
    } else {
        _line1 = _line1 + _valueText;
    };
};
_text ctrlSetFontHeight _fontH;
_text ctrlSetStructuredText parseText _line1;
_text ctrlCommit 0;

// 1px between rows, 2px between regions - the divider weights are the design's
// way of saying which boundaries matter, so they are not interchangeable. In
// real pixels, because that is the only thing that keeps them distinguishable:
// scaled by the UI grid they were both drawn at about 4px and converged.
[_body, [0, _y + _rowH - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

// A clickable row gets a transparent button laid over it. The structured text
// underneath raises no ButtonClick, so the handler has to live on a control that
// does - see the hit class in the shell's gui.hpp.
//
// THROUGH EFUNC(tacpad,drawHit), not by hand. Building the button here missed
// the half of that function that matters: a structured text control TAKES the
// press even though it cannot act on it, so a row whose label ran its full width
// answered only in the padding at the ends. drawHit hands the press on from the
// label to the button under it.
if (_onClick isNotEqualTo {}) then {
    private _hit = [_body, [0, _y, _w, _rowH], {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(rowIndex), 0], _ctrl] call (_ctrl getVariable [QGVAR(rowClick), {}]);
    }] call EFUNC(tacpad,drawHit);

    _hit setVariable [QGVAR(rowIndex), _index];
    _hit setVariable [QGVAR(rowClick), _onClick];

    // Callers hang what the row is about on the control they get back and the
    // handler reads it straight off the same control - so the button is what is
    // returned, not the text under it.
    _text = _hit;
};

_text
