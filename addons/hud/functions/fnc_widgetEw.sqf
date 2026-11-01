#include "script_component.hpp"
/*
 * Author: JMSB
 * SCANNER: the sweep, on the HUD.
 *
 * THREE READINGS, AND THAT IS THE SCANNER. The handset's screen carries more
 * than this - the net block, the armed alarm, the stopwatch, the STAND BY footer
 * - and an earlier version of this tile reproduced all twelve rows of it. That
 * is the DEVICE, not the scanner: the scanner is the sweep, and the sweep is UAV,
 * JAM and MESH. The rest of the handset's screen belongs to the radio tile and
 * the timer tile, which already carry it, and putting it here as well would be
 * the same numbers in two places waiting to disagree.
 *
 * The heading is the tile's, drawn by FUNC(draw) above its rule like every other
 * tile's - so the box reads SCANNER / UAV / JAM / MESH without the word being
 * printed twice.
 *
 * IT IS STILL THE DEVICE'S OWN LOOK. Same words (CLEAR, ALONE), same green
 * terminal, same rule about what turns amber and what turns red - UAV amber
 * inside 2 km and red inside 1, JAM amber partial and red smothered, MESH red
 * when you are on your own. A man who has carried the handset reads this without
 * being told it is the same thing.
 *
 * NOTHING IS MEASURED HERE. Every value is FUNC(sweep)'s, which is
 * EFUNC(hacking,scannerRead)'s cache - the same sweep the handset and the map
 * screens read, so no two surfaces can disagree about what is in the air.
 *
 * Arguments:
 * 0: Draw ops, appended to - see FUNC(paint) <ARRAY>
 * 1: Y to start at <NUMBER>
 * 2: Slot width <NUMBER>
 * 3: Slot height <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ops, _y, _w, _h] call jmfsb_hud_fnc_widgetEw
 *
 * Public: No
 */

params [["_ops", [], [[]]], ["_y", 0, [0]], ["_w", 0, [0]], ["_h", 0, [0]]];

// THE HANDSET'S OWN PALETTE, not the tacpad's. This is a terminal readout and it
// is green because the device is green; taking the scheme's ink here would make
// it a different instrument that happens to show the same numbers.
private _green = [0, 0.67, 0.22, 1];
private _amber = [0.914, 0.651, 0.235, 1];
private _red   = [0.816, 0.271, 0.227, 1];
private _dim   = [0, 0.34, 0.12, 1];

private _pad = PAD * safeZoneW;

// THE SUITE'S ROW HEIGHT, the same one every other tile and every map screen
// uses - so three lines here are the same three lines high as three lines
// anywhere else. It only shrinks, and only if the slot is too short to hold
// them; it never stretches, because three rows spread down a tall
// slot is three lines with holes between them rather than a screen.
private _rows = 3;
private _base = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * safeZoneH;
// SHRINK ONLY, EXACTLY AS THE RULE ABOVE SAYS. This divided the whole box for
// a while, which is how three lines came to be spread down a default-sized
// slot at twice the type size of everything else in the suite.
private _rowH = _base min ((_h - _y - (PAD * safeZoneW)) / _rows);

// THE HANDSET'S OWN GLYPHS, in the handset's own gutter - signal, jam (broken
// when smothered), mesh. The tile claimed to be the device's look and carried
// none of its iconography; a man reads the glyph before the word.
// CLAMPED BY BOTH AXES. Height alone sized these, and a row that grew with a
// tall box made the glyphs wider than the box itself: the screenshot's
// scanner icons spilling out of their frame. An icon is a gutter ornament; it
// never gets more than a fifth of the width, whatever the rows do.
private _icoH = (_rowH * 0.62) min ((_w * 0.2) * pixelH / pixelW);
private _gutter = _icoH * pixelW / pixelH + _pad * 2;

// THE FONT FOLLOWS THE NARROW AXIS TOO - measured on the LABEL COLUMN, not
// the box. The first cap used the box width and forgot the glyph gutter
// steals a slice of the label's half, so MESH - one letter longer than UAV -
// still wrapped. The reference is the same column at the shipped ten-cell
// width, and the floor is low enough to actually fit before it clips.
private _cellW = ((safeZoneW / safeZoneH) min 1.2) / 40;
// 0.85 is margin, not precision - the ratio cannot measure glyphs, so it
// stops guessing at the edge and undershoots instead. Floor low enough to
// always fit before it clips.
private _kw = (0.85 * (_w * 0.58 - _gutter - _pad * 2) / (5 * _cellW - _gutter - _pad * 2)) max 0.8;
private _k = ((_rowH / _base) min _kw) max 0.8;
private _size = 0.72 * _k;

private _fnc_line = {
    params ["_row", "_label", ["_value", ""], ["_colour", [0, 0.67, 0.22, 1]], ["_centre", false], ["_icon", ""]];
    private _ry = _y + _row * _rowH;

    if (_centre) exitWith {
        _ops pushBack [HUD_OP_TEXT, [[_pad, _ry, _w - 2 * _pad, _rowH], _label, _colour, _size, true, "center"]];
    };

    private _gx = _pad * 2;
    if (_icon isNotEqualTo "") then {
        _ops pushBack [HUD_OP_ICON, [[_gx, _ry + (_rowH - _icoH) * 0.5, _icoH], _icon, _colour]];
        _gx = _gx + _gutter;
    };

    // 58/42, not half and half - the values are short words and the labels
    // are what kept wrapping; the split follows the need.
    _ops pushBack [HUD_OP_TEXT, [[_gx, _ry, _w * 0.58 - _gx, _rowH], _label, _colour, _size, true]];
    _ops pushBack [HUD_OP_TEXT, [[_w * 0.58, _ry, _w * 0.42 - _pad * 2, _rowH], _value, _colour, _size, true, "right"]];
};

private _sweep = [] call FUNC(sweep);

// The tile's own heading already says SCANNER, above the rule FUNC(draw) puts
// there - printing it a second time inside the box would be the same word twice.
if (_sweep isEqualTo []) exitWith {
    [1, "NO SET", "", _dim, true] call _fnc_line;
};

_sweep params [
    ["_droneState", 0], ["_droneDist", 0], ["_droneDir", 0], ["_jam", 0],
    ["_chanText", ""], ["_freqText", ""], ["_mesh", 0]
];

// --- UAV -------------------------------------------------------------------
// Bearing before range and zero-padded to three digits, exactly as the handset
// does it: the column does not jump about as the drone circles, and a bearing
// tells you which way to look where a count tells you nothing.
private _droneText = "CLEAR";
if (_droneState > 0) then {
    private _brg = str round _droneDir;
    while {count _brg < 3} do {_brg = "0" + _brg};
    _droneText = format ["%1 %2m", _brg, round _droneDist];
};

[
    0, "UAV", _droneText,
    [_green, _amber, _red] select (0 max (_droneState min 2)),
    false, QPATHTOEF(hacking,data\icons\signal.paa)
] call _fnc_line;

// --- JAM -------------------------------------------------------------------
private _jamState = switch (true) do {
    case (_jam <= 0): {0};
    case (_jam >= 0.75): {2};
    default {1};
};

[
    1, "JAM",
    ["CLEAR", format ["%1%2", round (_jam * 100), "%"]] select (_jamState > 0),
    [_green, _amber, _red] select _jamState,
    false,
    // Smothered is a different picture from noisy - the handset's own swap.
    [QPATHTOEF(hacking,data\icons\jam.paa), QPATHTOEF(hacking,data\icons\broken.paa)] select (_jamState == 2)
] call _fnc_line;

// --- MESH ------------------------------------------------------------------
// ALONE is red on the handset, because being off the mesh is a state worth
// noticing rather than a neutral fact.
[
    2, "MESH",
    [format ["%1 NODE%2", _mesh, ["", "S"] select (_mesh > 1)], "ALONE"] select (_mesh <= 0),
    [_green, _red] select (_mesh <= 0),
    false, QPATHTOEF(hacking,data\icons\mesh.paa)
] call _fnc_line;
