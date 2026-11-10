#include "script_component.hpp"
/*
 * Author: YonV
 * A key/value list, drawn whole in one call: each label in the quiet ink, its
 * value in the monospace right after it, a hairline under every row - split
 * into two or three columns on a wide area instead of stretched across it.
 *
 * THE VALUE STARTS WHERE THE LABELS END (review 2026-11-01, DESIGN_TABLET_REVIEW
 * 2.4: WEATHER and DRONES > ENEMY drew a label at the far left and its value
 * at the middle of a full-width row - about 600 px of travel per line). The
 * label column is as wide as its own longest label, MEASURED (ctrlTextWidth)
 * rather than guessed as a share of the row, plus KV_GAP_PX of slack; every
 * label is right-aligned in it and the value starts KV_GAP_PX past it, so even
 * the shortest label ends a gap or two from its value, not a column away.
 *
 * ONE HELPER, so every app's key/value list is the same list (decision R2:
 * a new function rather than a seventh argument on FUNC(row)). Values and
 * labels are drawn at the tile detail size, never smaller (decision R1) -
 * KV_TEXT, the same size the tile band's detail line is drawn at.
 *
 * Columns are filled down, then across: a reader goes down a column, so the
 * caller orders the pairs the way they should be read and a two-column list
 * of ten is its first five on the left and its last five on the right.
 *
 * Arguments:
 * 0: Parent to draw into <CONTROL>
 * 1: Area [x, y, w], relative to the parent <ARRAY>
 * 2: Pairs [[label, value, hot], ...] - hot is a BOOL (true draws the value in
 *    the accent) or an RGBA the caller took from the theme <ARRAY>
 * 3: Columns - 0 for as many as the width holds, up to KV_COLUMNS_MAX <NUMBER>
 *    (optional, default 0)
 * 4: Row height - 0, or anything smaller, for KV_ROW_H <NUMBER> (optional, default 0)
 *
 * Return Value:
 * Height drawn <NUMBER>
 *
 * Example:
 * private _h = [_body, [_pad, _y, _w - 2 * _pad], [["RANGE", "1200 M"], ["BEARING", "045 DEG", true]], 2] call jmfsb_tacpad_apps_fnc_kvRow
 *
 * Public: Yes
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_area", [0, 0, 0], [[]], 3],
    ["_pairs", [], [[]]],
    ["_columns", 0, [0]],
    ["_rowH", 0, [0]]
];

if (isNull _parent || {_pairs isEqualTo []}) exitWith {0};

_area params ["_x0", "_y0", "_w"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);

private _size = KV_TEXT;
_rowH = _rowH max KV_ROW_H;
private _gap = KV_GAP_PX * pixelW;
private _gutter = KV_GUTTER_PX * pixelW;

// AS MANY COLUMNS AS THE WIDTH HOLDS when the caller leaves it open: a column
// is wanted per KV_COLUMN_W of the host, never more than KV_COLUMNS_MAX and
// never more than there are pairs to put in them.
private _count = count _pairs;
if (_columns <= 0) then {
    _columns = floor (_w / (KV_COLUMN_W * HOST_W));
};
_columns = ((_columns max 1) min KV_COLUMNS_MAX) min _count;

private _perCol = ceil (_count / _columns);
private _colW = (_w - _gutter * (_columns - 1)) / _columns;

for "_c" from 0 to (_columns - 1) do {
    private _slice = _pairs select [_c * _perCol, _perCol];
    private _cx = _x0 + _c * (_colW + _gutter);

    // The labels first, each in the whole column, and measured as drawn.
    private _labels = [];
    private _longest = 0;
    {
        _x params [["_label", "", [""]]];
        private _ry = _y0 + _forEachIndex * _rowH;
        private _ctrl = [_parent, [_cx, _ry, _colW, _rowH], _label, _muted, _size] call EFUNC(tacpad,drawText);
        _longest = _longest max (ctrlTextWidth _ctrl);
        _labels pushBack [_ctrl, _label];
    } forEach _slice;

    // THE LABEL COLUMN: the longest label with the gap as slack - a box
    // exactly as wide as its measured text can wrap its last letter - held
    // under KV_LABEL_MAX of the column so a long label cannot push its value
    // off the end.
    private _labelW = (_longest + _gap) min (_colW * KV_LABEL_MAX);

    // Every label pulled into that column and set against its right edge, so
    // the shortest label ends as close to its value as the longest one does.
    {
        _x params ["_ctrl", "_label"];
        (ctrlPosition _ctrl) params ["", "_ly", "", "_lh"];
        _ctrl ctrlSetPosition [_cx, _ly, _labelW, _lh];
        _ctrl ctrlCommit 0;
        [_ctrl, _label, _muted, _size, false, "right"] call EFUNC(tacpad,retext);
    } forEach _labels;

    // The values, left-aligned one gap past the label column, then the row's
    // hairline.
    private _valueX = _cx + _labelW + _gap;
    {
        _x params ["", ["_value", "", [""]], ["_hot", false, [false, []]]];
        private _ry = _y0 + _forEachIndex * _rowH;
        private _colour = if (_hot isEqualType []) then {_hot} else {[_ink, _accent] select _hot};
        [_parent, [_valueX, _ry, (_cx + _colW - _valueX) max 0, _rowH], _value, _colour, _size, true, "left", false, FONT_MONO] call EFUNC(tacpad,drawText);
        [_parent, [_cx, _ry + _rowH - RULE_THIN * pixelH, _colW, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
    } forEach _slice;
};

_perCol * _rowH
