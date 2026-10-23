#include "script_component.hpp"
/*
 * Author: JMSB
 * The walking view's screen cut into its rows, from the design's numbers
 * (docs/DESIGN_PHONE_WALKING.md and DESIGN_SIDE_DEVICES.md, "Layout"). Pure:
 * the same screen rectangle always answers the same rows, so the placement
 * and the per-tick draw can both ask without passing anything between them.
 *
 * TWO SHAPES. A landscape screen is the phone: one row of eight status cells,
 * the map with the squad list over its top left and the talking chip over its
 * top right, one row of nets. A portrait screen is the side devices' shared
 * screen: status in two rows of four, the map with the chip top left, the
 * squad list in two columns under the map, the nets in two columns under
 * that. Both carry the call strip along the map's bottom.
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
 * AN INNER BORDER, THE TABLET'S WAY (user, 2026-10-21: "corners do the same
 * as the tablet and on all devices"). The rows sit inside the screen hole by
 * OVERLAY_INSET of its shorter side - equal pixels on all four sides - clear
 * of the frame's corner bumpers; the ground shows between them and the frame.
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
 * gapX / gapY <NUMBER>, textScale <NUMBER>, content (the rim's inside) <ARRAY>,
 * status (cell rects), map, talk, call, nets (rects) <ARRAY>, squad (one or two rects)
 * <ARRAY>, squadRows <NUMBER>, netCellH, netCellW (widest a net cell may be)
 * <NUMBER>
 *
 * Example:
 * private _rows = [ctrlPosition _ground] call jmfsb_devices_fnc_overlayRows
 *
 * Public: No
 */

params [["_screen", [0, 0, 0, 0], [[]], 4]];

_screen params ["_sx", "_sy", "_sw", "_sh"];
private _portrait = (_sw / pixelW) < (_sh / pixelH);

private _unitW = _sw / ([PHONE_DESIGN_W, SIDE_DESIGN_W] select _portrait);
private _unitH = _sh / ([PHONE_DESIGN_H, SIDE_DESIGN_H] select _portrait);
private _gapX = DESIGN_GAP * _unitW;
private _gapY = DESIGN_GAP * _unitH;

// The content rectangle, the border's width in from the hole: the same
// pixels on all four sides, a share of the hole's shorter side.
private _insetPx = OVERLAY_INSET * ((_sw / pixelW) min (_sh / pixelH));
private _insetX = _insetPx * pixelW;
// The phone's top and bottom bars stand only a few pixels off the hole's
// edge (user, 2026-10-21: "top bar was too tall", "bottom bar was too
// tall") - enough to clear the frame's corner guards, which lie over the
// screen's corners.
private _insetY = [OVERLAY_INSET_Y * ((_sw / pixelW) min (_sh / pixelH)) * pixelH, _insetPx * pixelH] select _portrait;
_sx = _sx + _insetX;
_sy = _sy + _insetY;
_sw = _sw - 2 * _insetX;
_sh = _sh - 2 * _insetY;

private _statusU = [PHONE_ROW_STATUS, SIDE_ROW_STATUS] select _portrait;
private _squadU = [0, SIDE_ROW_SQUAD] select _portrait;
private _netsU = [PHONE_ROW_NETS, SIDE_ROW_NETS] select _portrait;

// How much the text, and the rows that carry it, grow over the design.
private _designText = DESIGN_TEXT * _unitH;
private _rowsH = (_statusU + _squadU + _netsU) * _unitH;
private _scale = (OVERLAY_TEXT_MIN * safeZoneH / (_designText max pixelH)) max 1;
_scale = _scale min OVERLAY_TEXT_SCALE_MAX min (((1 - OVERLAY_MAP_MIN) * _sh / (_rowsH max pixelH)) max 1);
private _rowUnit = _unitH * _scale;

private _statusH = _statusU * _rowUnit;
private _squadH = _squadU * _rowUnit;
private _netsH = _netsU * _rowUnit;
private _netCellH = ([PHONE_NET_CELL_H, SIDE_NET_CELL_H] select _portrait) * _rowUnit;

// The phone's bars are one line of text tall, with a gutter above and below.
if (!_portrait) then {
    private _line = _designText * _scale / OVERLAY_CELL_TEXT_FIT;
    _statusH = _line + 2 * _gapY;
    _netCellH = _line;
    _netsH = _line + 2 * _gapY;
};

// Status cells, left to right and then down.
private _cols = [STATUS_COLS_LANDSCAPE, STATUS_COLS_PORTRAIT] select _portrait;
private _statusRows = ceil (OVERLAY_STATUS_CELLS / _cols);
private _cellW = (_sw - (_cols - 1) * _gapX) / _cols;
private _cellH = (_statusH - (_statusRows + 1) * _gapY) / _statusRows;
private _status = [];
for "_i" from 0 to (OVERLAY_STATUS_CELLS - 1) do {
    _status pushBack [
        _sx + (_i mod _cols) * (_cellW + _gapX),
        _sy + _gapY + (floor (_i / _cols)) * (_cellH + _gapY),
        _cellW,
        _cellH
    ];
};

private _mapY = _sy + _statusH;
private _mapH = _sh - _statusH - _squadH - _netsH;
private _map = [_sx, _mapY, _sw, _mapH];

private _lineH = DESIGN_LINE * _rowUnit;
private _talkW = (DESIGN_TALK_W * _unitW * _scale) min (_sw - 2 * _gapX);
private _talk = if (_portrait) then {
    [_sx + _gapX, _mapY + _gapY, _talkW, _lineH]
} else {
    [_sx + _sw - _gapX - _talkW, _mapY + _gapY, _talkW, _lineH]
};

// The call strip along the map's bottom.
private _call = [_sx + _gapX, _mapY + _mapH - _gapY - _lineH, _sw - 2 * _gapX, _lineH];

private _squad = if (_portrait) then {
    private _colW = (_sw - (SQUAD_COLS_PORTRAIT - 1) * _gapX) / SQUAD_COLS_PORTRAIT;
    [
        [_sx, _mapY + _mapH, _colW, _squadH],
        [_sx + _gapX + _colW, _mapY + _mapH, _colW, _squadH]
    ]
} else {
    [[_sx + _gapX, _mapY + _gapY, (PHONE_LIST_W * _unitW * _scale) min (_sw / 2), _mapH - 3 * _gapY - _lineH]]
};

createHashMapFromArray [
    ["portrait", _portrait],
    ["unitW", _unitW],
    ["unitH", _unitH],
    ["gapX", _gapX],
    ["gapY", _gapY],
    ["textScale", _scale],
    ["textH", _designText * _scale],
    ["lineH", _lineH],
    ["content", [_sx, _sy, _sw, _sh]],
    ["map", _map],
    ["talk", _talk],
    ["status", _status],
    ["call", _call],
    ["squad", _squad],
    ["squadRows", [SQUAD_ROWS_LANDSCAPE, SQUAD_ROWS_PORTRAIT] select _portrait],
    // The nets row spans the content's width; FUNC(overlayDraw) adds its own
    // gutters, so the row is widened by one gutter each side to land the
    // cells on the content's edges.
    ["nets", [_sx - _gapX, _sy + _sh - _netsH, _sw + 2 * _gapX, _netsH]],
    ["netCellH", _netCellH],
    ["netCellW", NET_CELL_MAX_W * _unitW * _scale]
]
