#include "script_component.hpp"
/*
 * Author: YonV
 * A filed card's rows as one key/value column (user, 2026-11-02: "the 2 column
 * view in the message history is hard to read"): each line's label in the
 * quiet ink, its value right after it at the body size, top to bottom - never
 * a second column beside the first.
 *
 * jmfsb_tacpad_apps_fnc_kvRow'S LAYOUT (review 2026-11-01, DESIGN_TABLET_REVIEW
 * 2.4, decisions R1 and R2), drawn here because this addon cannot call it -
 * tacpad_apps requires tacpad, not the other way round. The label column is
 * the longest label, MEASURED, plus READER_KV_GAP_PX, held under
 * READER_KV_LABEL_MAX of the width (a longer label wraps in it); each label is
 * set against its right edge and the value starts a gap past it, at the tile
 * detail size, never smaller (R1), untracked (2.3).
 *
 * A LONG VALUE TAKES THE WHOLE WIDTH. A value that wraps beside its label - a
 * REMARKS sentence, a MIST paragraph - is drawn again under it, across the full
 * width, with its label as the heading at the left edge, rather than squeezed
 * into what is left of the row. A row is as tall as what it holds, with
 * READER_KV_AIR_PX of air under it.
 *
 * Arguments:
 * 0: Parent <CONTROL>
 * 1: Area [x, y, width], relative to the parent <ARRAY>
 * 2: Rows [[label, value, critical], ...] (FUNC(readerKvRows)) - a critical value is bold, in the accent <ARRAY>
 * 3: Floor - a row whose first line would end below it is not drawn; -1 for none <NUMBER> (optional, default -1)
 *
 * Return Value:
 * Y under the last row drawn; the given y when none was <NUMBER>
 *
 * Example:
 * _y = [_root, [_x, _y, _w], [_msg, true] call jmfsb_tacpad_fnc_readerKvRows] call jmfsb_tacpad_fnc_readerKv
 *
 * Public: No
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_area", [0, 0, 0], [[]], 3],
    ["_rows", [], [[]]],
    ["_floor", -1, [0]]
];

_area params ["_x0", "_y0", "_w"];

if (isNull _parent || _rows isEqualTo []) exitWith {_y0};

private _ink = ["ink"] call FUNC(theme);
private _muted = ["muted"] call FUNC(theme);
private _accentText = ["accentText"] call FUNC(theme);

private _valueSize = READER_KV_VALUE_SIZE;
private _lineH = [_valueSize] call FUNC(textH);
private _gap = READER_KV_GAP_PX * pixelW;
private _air = READER_KV_AIR_PX * pixelH;
private _under = READER_KV_UNDER_PX * pixelH;
private _capW = _w * READER_KV_LABEL_MAX;

// The labels first, each in the widest box it may have, and measured as drawn.
private _labels = _rows apply {
    [_parent, [_x0, _y0, _capW, _lineH], _x param [0, ""], _muted, READER_K_SIZE] call FUNC(drawText)
};
private _longest = 0;
{_longest = _longest max (ctrlTextWidth _x)} forEach _labels;

private _labelW = (_longest + _gap) min _capW;
private _valueX = _x0 + _labelW + _gap;
private _valueW = (_x0 + _w - _valueX) max 0;

private _rowY = _y0;
private _bottom = _y0;
private _drawn = 0;
{
    _x params [["_label", "", [""]], ["_value", "", [""]], ["_critical", false, [false]]];
    if (_floor >= 0 && (_rowY + _lineH) > _floor) exitWith {};

    private _labelCtrl = _labels select _forEachIndex;
    private _labelH = ctrlTextHeight _labelCtrl;
    private _colour = [_ink, _accentText] select _critical;

    // Beside the label first; a value that wraps there goes under it instead.
    private _valueCtrl = [_parent, [_valueX, _rowY, _valueW, _lineH], _value, _colour, _valueSize, _critical] call FUNC(drawText);
    private _valueH = ctrlTextHeight _valueCtrl;
    private _rowH = 0;

    if (_valueH > _lineH * READER_KV_WRAP_K) then {
        ctrlDelete _valueCtrl;
        _labelCtrl ctrlSetPosition [_x0, _rowY, _labelW, _labelH];
        _labelCtrl ctrlCommit 0;
        [_labelCtrl, _label, _muted, READER_K_SIZE, false, "left"] call FUNC(retext);

        private _valueY = _rowY + _labelH + _under;
        _valueCtrl = [_parent, [_x0, _valueY, _w, _lineH], _value, _colour, _valueSize, _critical] call FUNC(drawText);
        _valueH = (ctrlTextHeight _valueCtrl) max _lineH;
        _valueCtrl ctrlSetPosition [_x0, _valueY, _w, _valueH];
        _valueCtrl ctrlCommit 0;
        _rowH = _labelH + _under + _valueH;
    } else {
        _valueH = _valueH max _lineH;
        _valueCtrl ctrlSetPosition [_valueX, _rowY, _valueW, _valueH];
        _valueCtrl ctrlCommit 0;

        // The label on the value's first line; a label that wrapped in its
        // column hangs from the row's top.
        private _labelY = _rowY + ((_lineH - _labelH) max 0) * 0.5;
        _labelCtrl ctrlSetPosition [_x0, _labelY, _labelW, _labelH];
        _labelCtrl ctrlCommit 0;
        [_labelCtrl, _label, _muted, READER_K_SIZE, false, "right"] call FUNC(retext);
        _rowH = _valueH max (_labelY - _rowY + _labelH);
    };

    _bottom = _rowY + _rowH;
    _rowY = _bottom + _air;
    _drawn = _drawn + 1;
} forEach _rows;

// The labels of the rows the floor stopped.
{ctrlDelete _x} forEach (_labels select [_drawn]);

_bottom
