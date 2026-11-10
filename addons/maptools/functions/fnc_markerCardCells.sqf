#include "script_component.hpp"
/*
 * Author: YonV
 * One pick row of the marker card - its tabs, icons, colours, sizes, steppers
 * or channels: an even grid of cells, the picked one filled in the ink as the
 * MAP TOOLS strip shows its running tool, the rest outlined in the theme's
 * line (user, 2026-11-02: the card "is ugly" - a light outline, not an ink cage
 * round every cell). A colour cell is its swatch, the picked one with the thick
 * ink outline instead, so the colour itself is never covered.
 *
 * A press puts the cell's value into the card's state under its key and the
 * card is drawn again next frame - the press's own button goes with it.
 *
 * Arguments:
 * 0: The card <CONTROL>
 * 1: [x, y, w, cell height] - the cells run across w, a row each cell height <ARRAY>
 * 2: The cells: [label, icon texture, swatch RGBA, value, tooltip, icon in its
 *    own colours] each - "" / [] for what a cell does not have; the last
 *    optional, default false (the icon in the ink) <ARRAY>
 * 3: The picked value - "" where no cell is ever the picked one (a stepper)
 *    <STRING or NUMBER>
 * 4: The state key the value goes under <STRING>
 * 5: Cells a row <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_card, [_pad, _y, _w, _h], _cells, "mil_dot", "type", 6] call jmfsb_maptools_fnc_markerCardCells
 *
 * Public: No
 */

params [
    ["_card", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_cells", [], [[]]],
    ["_picked", "", ["", 0]],
    ["_key", "", [""]],
    ["_cols", 1, [0]]
];

if (isNull _card || _cols < 1) exitWith {};

_rect params ["_rx", "_ry", "_rw", "_cellH"];

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "", "_line"];
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _cellW = _rw / _cols;

{
    _x params ["_label", "_icon", "_swatch", "_value", "_tip", ["_own", false]];

    private _on = _value isEqualTo _picked;
    private _cx = _rx + (_forEachIndex mod _cols) * _cellW;
    private _cy = _ry + floor (_forEachIndex / _cols) * _cellH;
    private _cw = _cellW - _pad;
    private _ch = _cellH - _padY;
    private _cell = [_cx, _cy, _cw, _ch];

    if (_swatch isNotEqualTo []) then {
        [_card, [_cx + _pad, _cy + _padY, _cw - 2 * _pad, _ch - 2 * _padY], _swatch] call EFUNC(tacpad,drawFill);
        if (_on) then {
            [_card, _cell, _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
        } else {
            [_card, _cell, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
        };
    } else {
        if (_on) then {
            [_card, _cell, _ink] call EFUNC(tacpad,drawFill);
        } else {
            [_card, _cell, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
        };
    };

    private _glyph = [_ink, _solid] select _on;
    if (_icon isNotEqualTo "") then {
        private _iconH = _ch * CARD_ICON_K;
        private _iconW = _iconH * pixelW / pixelH;
        [_card, [_cx + (_cw - _iconW) / 2, _cy + (_ch - _iconH) / 2, _iconH], _icon, [_glyph, []] select _own] call EFUNC(tacpad,drawIcon);
    };
    if (_label isNotEqualTo "") then {
        [_card, _cell, _label, _glyph, TEXT_LABEL, _on, "center"] call EFUNC(tacpad,drawText);
    };

    private _hit = [_card, _cell, {
        params ["_ctrl"];
        (uiNamespace getVariable [QGVAR(cardState), createHashMap]) set [_ctrl getVariable [QGVAR(cardKey), ""], _ctrl getVariable [QGVAR(cardValue), ""]];
        {[] call FUNC(markerCardDraw)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(cardKey), _key];
    _hit setVariable [QGVAR(cardValue), _value];
    if (_tip isNotEqualTo "") then {
        _hit ctrlSetTooltip _tip;
    };
} forEach _cells;
