#include "script_component.hpp"
/*
 * Author: YonV
 * The walking view's screen cut into its rows, from the design's numbers
 * (docs/DESIGN_PHONE_WALKING.md and DESIGN_SIDE_DEVICES.md, "Layout"). Pure:
 * the same screen rectangle always answers the same rows, so the placement
 * and the per-tick draw can both ask without passing anything between them.
 *
 * TWO SHAPES. A landscape screen is the phone: the status cells in ONE row
 * of seven at one size (STATUS_LAYOUT_LANDSCAPE; user, 2026-10-31: "one line
 * ... the same font" - FUNC(overlayDraw) fits the row by its widest cell), the map with the squad list over its
 * top left and the talking chip over its top right, one row of nets. A
 * portrait screen is the side devices' shared screen: status in three rows
 * of three, the map with the squad list over its top left and the chip over
 * its top right, the nets in two columns under it. Both carry the call strip
 * along the map's bottom.
 *
 * THE SIDE DEVICES' MAP RUNS FROM THE STATUS ROWS TO THE NETS (user,
 * 2026-11-09: "make better use of the screen ... the red box should be the
 * map"). The squad list left the space under the map for a place over it,
 * the phone's way.
 *
 * THE STATUS ROW IS THE TOP BAR (user, 2026-10-21: "more like your old top
 * bar ... just no net number it did not make sense, net % maybe") - see
 * FUNC(overlayProviders). The notification line under it stays gone.
 *
 * NO STATUS ROW AND NO NOTIFICATION LINE (user, 2026-10-21: the status row
 * "seems kind of meaningless just taking up space", the line "we removed this
 * from the phones and sides"). The map takes their room. Popups stay upper
 * right on the game screen; call business has its own strip over the map.
 *
 * THE BORDER IS OVERLAY_BORDER_PX, one pixel on all four sides, on every
 * walking-view device (user, 2026-10-30, the phone: "give the rest of the
 * space back to the screen"; 2026-11-09, the side devices: "there is too much
 * border"). The side devices' inset of a share of the hole's shorter side is
 * gone.
 *
 * TEXT HAS A FLOOR. At the design's own numbers a side device's text came out
 * at six or seven pixels (user, 2026-10-21: "hard to read"). Text is raised
 * to OVERLAY_TEXT_MIN of the screen's height, at most OVERLAY_TEXT_SCALE_MAX
 * times the design, and every text row grows with it - but never past the
 * point where the map would keep less than OVERLAY_MAP_MIN of the screen.
 *
 * Arguments:
 * 0: Screen rectangle [x, y, w, h] <ARRAY>
 *
 * Return Value:
 * Rows <HASHMAP>: portrait <BOOL>, unitW / unitH (one design unit) <NUMBER>,
 * gapX / gapY <NUMBER>, textScale <NUMBER>, textH <NUMBER>, statusTextH (a
 * status cell's type size before it is fitted to its text) <NUMBER>, content
 * (the rim's inside) <ARRAY>, status (cell rects), map, talk, call, nets
 * (rects) <ARRAY>, squad (one or two rects) <ARRAY>, squadRows <NUMBER>,
 * netCellH, netCellW (widest a net cell may be) <NUMBER>
 *
 * Example:
 * private _rows = [ctrlPosition _ground] call jmfsb_devices_fnc_overlayRows
 *
 * Public: No
 */

params [["_screen", [0, 0, 0, 0], [[]], 4]];

_screen params ["_sx", "_sy", "_sw", "_sh"];
// THE CLASS DECIDES THE SHAPE (notes, 2026-10-30): the shown device's
// (FUNC(overlayPlace)); the screen's own aspect only when none is set.
private _portrait = if (GVAR(overlayClass) isNotEqualTo "") then {
    GVAR(overlayClass) isEqualTo DEVICE_CLASS_PORTRAIT
} else {
    (_sw / pixelW) < (_sh / pixelH)
};

private _unitW = _sw / ([PHONE_DESIGN_W, SIDE_DESIGN_W] select _portrait);
private _unitH = _sh / ([PHONE_DESIGN_H, SIDE_DESIGN_H] select _portrait);
private _gapX = DESIGN_GAP * _unitW;
private _gapY = DESIGN_GAP * _unitH;

// The content rectangle, the border's width in from the hole: one pixel on
// all four sides, every device (user, 2026-10-30 and 2026-11-09).
private _insetX = OVERLAY_BORDER_PX * pixelW;
private _insetY = OVERLAY_BORDER_PX * pixelH;
_sx = _sx + _insetX;
_sy = _sy + _insetY;
_sw = _sw - 2 * _insetX;
_sh = _sh - 2 * _insetY;

// Status cells per row, left to right and then down.
private _layout = [STATUS_LAYOUT_LANDSCAPE, STATUS_LAYOUT_PORTRAIT] select _portrait;
private _statusRows = count _layout;

private _statusU = [PHONE_ROW_STATUS * _statusRows, SIDE_ROW_STATUS] select _portrait;
private _netsU = [PHONE_ROW_NETS, SIDE_ROW_NETS] select _portrait;

// How much the text, and the rows that carry it, grow over the design.
private _designText = DESIGN_TEXT * _unitH;
private _rowsH = (_statusU + _netsU) * _unitH;
private _scale = (OVERLAY_TEXT_MIN * safeZoneH / (_designText max pixelH)) max 1;
_scale = _scale min OVERLAY_TEXT_SCALE_MAX min (((1 - OVERLAY_MAP_MIN) * _sh / (_rowsH max pixelH)) max 1);
private _rowUnit = _unitH * _scale;

private _statusH = _statusU * _rowUnit;
// THE NET CELLS ARE FIXED PIXELS (notes, 2026-10-30): 38 on the phone's one
// row, 34 in two columns on a portrait screen - a page of four net buttons
// either way (user, 2026-11-07), the portrait screen's page marker in a row
// of its own under them.
private _netCellH = ([NET_CELL_PX_PHONE, NET_CELL_PX_PORTRAIT] select _portrait) * pixelH;
private _netsH = if (_portrait) then {
    ((ceil (NET_PAGE_SIZE / NET_COLS_PORTRAIT)) + NET_PAGE_MARK_ROWS) * (_netCellH + _gapY) + _gapY
} else {
    _netCellH + 2 * _gapY
};

// The phone's status block is a line of text per row, a gutter above each
// row and under the last.
if (!_portrait) then {
    private _line = _designText * _scale / OVERLAY_CELL_TEXT_FIT;
    _statusH = _statusRows * _line + (_statusRows + 1) * _gapY;
};

// The cells: each row's are equal shares of the content's width. A cell
// past the layout's slots lands on its last row.
private _cellH = (_statusH - (_statusRows + 1) * _gapY) / _statusRows;
private _status = [];
private _row = 0;
private _col = 0;
for "_i" from 0 to (OVERLAY_STATUS_CELLS - 1) do {
    private _cols = _layout select (_row min (_statusRows - 1));
    private _cellW = (_sw - (_cols - 1) * _gapX) / _cols;
    _status pushBack [
        _sx + _col * (_cellW + _gapX),
        _sy + _gapY + (_row min (_statusRows - 1)) * (_cellH + _gapY),
        _cellW,
        _cellH
    ];
    _col = _col + 1;
    if (_col >= _cols) then {
        _col = 0;
        _row = _row + 1;
    };
};
// A cell's type: the row's size, held to the cell's height. FUNC(overlayDraw)
// fits each cell's text under it by measure.
private _statusTextH = (_designText * _scale) min (_cellH * OVERLAY_CELL_TEXT_FIT);

// The map: everything between the status rows and the nets, every device.
private _mapY = _sy + _statusH;
private _mapH = _sh - _statusH - _netsH;
private _map = [_sx, _mapY, _sw, _mapH];

// A text row is never under the hand devices' row height (the row rhythm).
// On a portrait screen the squad list and the chip share the map's top, half
// each.
private _lineH = (DESIGN_LINE * _rowUnit) max (ROW_PX_DEVICE * pixelH);
private _halfW = (_sw - 3 * _gapX) / 2;
private _talkW = [(DESIGN_TALK_W * _unitW * _scale) min (_sw - 2 * _gapX), _halfW] select _portrait;
private _talk = [_sx + _sw - _gapX - _talkW, _mapY + _gapY, _talkW, _lineH];

// The call strip along the map's bottom.
private _call = [_sx + _gapX, _mapY + _mapH - _gapY - _lineH, _sw - 2 * _gapX, _lineH];
// The quick-answer strip right above it (2026-11-06), the full width.
private _askH = ASK_STRIP_LINES * _lineH;
private _ask = [_sx + _gapX, (_call select 1) - _gapY - _askH, _sw - 2 * _gapX, _askH];

// The squad list over the map's top left; FUNC(overlayDraw) sets its height
// to its lines.
private _squadW = [(PHONE_LIST_W * _unitW * _scale) min (_sw / 2), _halfW] select _portrait;
private _squad = [[_sx + _gapX, _mapY + _gapY, _squadW, _mapH - 3 * _gapY - _lineH]];

createHashMapFromArray [
    ["portrait", _portrait],
    ["unitW", _unitW],
    ["unitH", _unitH],
    ["gapX", _gapX],
    ["gapY", _gapY],
    ["textScale", _scale],
    ["textH", _designText * _scale],
    ["statusTextH", _statusTextH],
    ["lineH", _lineH],
    ["content", [_sx, _sy, _sw, _sh]],
    ["map", _map],
    ["talk", _talk],
    ["status", _status],
    ["call", _call],
    ["ask", _ask],
    ["squad", _squad],
    ["squadRows", SQUAD_ROWS_LANDSCAPE],
    // The nets row spans the content's width; FUNC(overlayDraw) adds its own
    // gutters, so the cells sit one gutter in from the content's edges - not
    // on them (user, 2026-10-31: the first chip "too close to the edge").
    ["nets", [_sx, _sy + _sh - _netsH, _sw, _netsH]],
    ["netCellH", _netCellH],
    ["netCellW", NET_CELL_MAX_W * _unitW * _scale]
]
