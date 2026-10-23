#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet's screen cut into its rows, from the design's numbers
 * (docs/DESIGN_TABLET.md, "Layout"): the device bar, the notification line, the
 * live tiles with the rule under them, the map area and the net row, top to
 * bottom. Pure: the same screen always answers the same rows, so the layout at
 * open and the tick that redraws them can both ask.
 *
 * THE MAP AREA IS THE HOST. It is what is handed to the shell as the rectangle
 * the suite draws in, so every panel and every app lands on the map and never
 * over a bar - an app opens "as a page over the map area (tiles and net row
 * stay)" because the shell centres it in its host.
 *
 * THE MAP AREA HAS A BORDER. TABLET_BORDER design px of ink stand between it
 * and the hole's sides, and between it and the net row, so the map and its
 * markers stop short of the bezel instead of running under it.
 *
 * THE SCREEN SITS IN A RECESS. Every row is inset TABLET_RECESS design px from
 * the hole on all four sides; the band round them is the recess, dark, no
 * light rim (user, 2026-10-21: "there is a light line around the screen that
 * needs to go away"). Nothing reaches the bezel.
 *
 * THE RECESS HAS ROUND CORNERS (user, 2026-10-23: "on all devices on the
 * outside dark border add a slight roundness to the corners"): the hole's
 * corners are cut round in the frame texture, and the band, drawn above the
 * frame, would square them off again - so its four straight bands stop a
 * corner's width short of each corner, and a quarter-round piece fills each
 * corner (FUNC(tabletChrome)), clear outside its arc where the frame shows.
 *
 * Arguments:
 * 0: Screen rectangle [x, y, w, h] <ARRAY>
 * 1: The hole's corner radius [w, h] (optional, default none) <ARRAY>
 *
 * Return Value:
 * Rows <HASHMAP>: bar, notify, tiles, rule, map, nets, the border's
 * borderL / borderR / borderB, the recess bands recessT / recessB / recessL /
 * recessR and its corners cornerTL / cornerTR / cornerBL / cornerBR (rects
 * [x, y, w, h])
 * <ARRAY>, gapX / gapY (the design's air, in screen units) <NUMBER>
 *
 * Example:
 * private _rows = [_screenPos] call jmfsb_devices_fnc_tabletRows
 *
 * Public: No
 */

params [["_screen", [0, 0, 0, 0], [[]], 4], ["_corner", [0, 0], [[]], 2]];

_screen params ["_sx", "_sy", "_sw", "_sh"];
_corner params ["_cw", "_ch"];

private _unitW = _sw / TABLET_DESIGN_W;

// The recess: the hole's outer band, and the rows inside it.
private _recessW = TABLET_RECESS * _unitW;
private _recessH = TABLET_RECESS * (_sh / TABLET_DESIGN_H);
private _recess = [
    ["recessT", [_sx + _cw, _sy, _sw - 2 * _cw, _recessH]],
    ["recessB", [_sx + _cw, _sy + _sh - _recessH, _sw - 2 * _cw, _recessH]],
    ["recessL", [_sx, _sy + _ch, _recessW, _sh - 2 * _ch]],
    ["recessR", [_sx + _sw - _recessW, _sy + _ch, _recessW, _sh - 2 * _ch]],
    ["cornerTL", [_sx, _sy, _cw, _ch]],
    ["cornerTR", [_sx + _sw - _cw, _sy, _cw, _ch]],
    ["cornerBL", [_sx, _sy + _sh - _ch, _cw, _ch]],
    ["cornerBR", [_sx + _sw - _cw, _sy + _sh - _ch, _cw, _ch]]
];
_sx = _sx + _recessW;
_sy = _sy + _recessH;
_sw = _sw - 2 * _recessW;
_sh = _sh - 2 * _recessH;
_unitW = _sw / TABLET_DESIGN_W;
private _unitH = _sh / TABLET_DESIGN_H;

private _barH = TABLET_ROW_BAR * _unitH;
private _notifyH = TABLET_ROW_NOTIFY * _unitH;
private _tilesH = TABLET_ROW_TILES * _unitH;
private _ruleH = TABLET_RULE_TILES * _unitH;
private _netsH = TABLET_ROW_NETS * _unitH;

private _notifyY = _sy + _barH;
private _tilesY = _notifyY + _notifyH;
private _ruleY = _tilesY + _tilesH;
private _mapY = _ruleY + _ruleH;
private _netsY = _sy + _sh - _netsH;
private _borderW = TABLET_BORDER * _unitW;
private _borderH = TABLET_BORDER * _unitH;
private _mapH = _netsY - _mapY - _borderH;

createHashMapFromArray (_recess + [
    ["bar", [_sx, _sy, _sw, _barH]],
    ["notify", [_sx, _notifyY, _sw, _notifyH]],
    ["tiles", [_sx, _tilesY, _sw, _tilesH]],
    ["rule", [_sx, _ruleY, _sw, _ruleH]],
    ["map", [_sx + _borderW, _mapY, _sw - 2 * _borderW, _mapH]],
    ["borderL", [_sx, _mapY, _borderW, _mapH + _borderH]],
    ["borderR", [_sx + _sw - _borderW, _mapY, _borderW, _mapH + _borderH]],
    ["borderB", [_sx + _borderW, _mapY + _mapH, _sw - 2 * _borderW, _borderH]],
    ["nets", [_sx, _netsY, _sw, _netsH]],
    ["gapX", TABLET_GAP * _unitW],
    ["gapY", TABLET_GAP * _unitH]
])
