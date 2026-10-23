#include "script_component.hpp"
/*
 * Author: JMSB
 * The live tile band. Each tile is a kicker with a right-aligned qualifier, one
 * big live value and one detail line - and clicking it opens that app, which is
 * the only way into an app.
 *
 * THE THREE LINES ARE THREE CONTROLS. They were one structured text with <br/>
 * between them, which meant the value's size decided where the detail line sat
 * and the design's 9px/11px padding and 7px internal gap could not be expressed
 * at all. Separate controls put each line exactly where the module says it goes,
 * and a value that changes width cannot move anything.
 *
 * A tile never resizes on refresh. The value changes, the module does not: a
 * band that reflows every two seconds is a band nobody can click.
 *
 * ONE ROW ACROSS A DEVICE (docs/DESIGN_TABLET.md, "Live tiles"). The tablet
 * draws the band in a row of its own between the notification line and the
 * map, outside every panel - jmfsb_devices passes its own body and asks for the
 * row: every tile in one line, dividing the body's whole width and height, no
 * reader to stop short of and no panel to fit.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel id, "" when the body is not a registered panel <STRING>
 * 2: One row filling the body, for a device's tile row <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, "", true] call jmfsb_tacpad_apps_fnc_panelTiles
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_id", "", [""]], ["_fillRow", false, [false]]];

if (isNull _body) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _tiles = [] call FUNC(tileData);
private _tileW = TILE_W * HOST_W;
private _gap = TILE_GAP * HOST_W;
private _bodyW = (ctrlPosition _body) # 2;

// THE BAND ENDS WHERE THE READER BEGINS - at ANY ui scale. Placement scales
// the band's width by uiScale, so every constant that cleared the reader at
// scale 1 grew back under it at 1.1 - three overlap reports running. The
// reader's own placed left edge is computed the same way place() computes
// it, and no tile draws past it; the +N count says what was cut.
// A device's row has no reader beside it; only the panel band does.
if (!_fillRow) then {
    private _readerLeft = HOST_X + (((DEFAULT_READER # 0) min (1 - (DEFAULT_READER # 2) * EGVAR(tacpad,uiScale))) * HOST_W) - PAD * HOST_W;
    private _group = ctrlParentControlsGroup _body;
    private _gp = ctrlPosition _group;
    private _groupX = _gp # 0;

    // THE FRAME, NOT ONLY THE TILES. Clamping what is DRAWN left the band's own
    // panel - ground, outline and the LIVE TILES bar - at the width placement gave
    // it, so at a ui scale past about 1.19 the frame still ran under the reader's
    // left edge with the tiles stopping short of it. That is the sliver of overlap
    // left after the tile clamp: the last tile cleared the reader and the box
    // around it did not.
    //
    // Set before FUNC(fit), which re-lays the ground, the four outline edges and
    // the body from the group's own width at the end of this function.
    private _maxW = _readerLeft - _groupX;
    if ((_gp # 2) > _maxW) then {
        _group ctrlSetPosition [_groupX, _gp # 1, _maxW, _gp # 3];
        _group ctrlCommit 0;
    };

    _bodyW = _bodyW min (_maxW - 2 * RULE_THICK * pixelW);
};

// SHRINK TO FIT - AND BUDGET BOTH EDGES, WHICH IS THE WHOLE BUG.
//
// This used to size the tiles against _bodyW while the draw loop below cuts
// against _bodyW - _edge, and the first tile starts AT _edge. So the real
// requirement is 2 * _edge + n tiles + (n-1) gaps, the fit only paid for the
// tiles and gaps, and the last tile therefore missed by exactly one padding -
// every time, at every ui scale. The band showed "+1" and swallowed a tile
// nobody could reach, which with SUPPORT and HACK moved to the right meant HACK
// was always the one lost. A team lead with hack access could not see the tile.
if ((count _tiles) > 0) then {
    private _rows = [1, 2] select (GVAR(tileRows) isEqualTo "2" && !_fillRow);
    private _tilesPerRow = ceil ((count _tiles) / _rows);
    if (_tilesPerRow > 0) then {
        // The same two edges the draw loop and the cut check use.
        private _avail = _bodyW - 2 * (PAD * HOST_W);
        private _totalWidthNeeded = (_tileW * _tilesPerRow) + (_gap * (_tilesPerRow - 1));

        if (_totalWidthNeeded > _avail || _fillRow) then {
            _gap = 0.004 * HOST_W;
            // DIVIDE THE BAND EXACTLY. Not "shrink a bit and hope" - the row is
            // the available width minus its gaps, split evenly, so the last tile
            // ends ON the right edge rather than a hair past it.
            _tileW = (_avail - (_gap * (_tilesPerRow - 1))) / _tilesPerRow;
        };
    };
};

// FROM THE CONSTANT, NOT FROM THE BODY. The body is still whatever size the
// panel was built at when this runs - FUNC(fit) resizes it to TILE_H at the end
// of this function - so reading the height off it laid every tile out against a
// box that was about to change, and the detail line ended up hanging below the
// tile's own border.
private _tileH = TILE_H * HOST_H;
private _edge = PAD * HOST_W;
private _edgeY = PAD * HOST_H;
// A device's row is drawn into a body that is already its final size.
if (_fillRow) then {
    _tileH = ((ctrlPosition _body) # 3) - 2 * _edgeY;
};

// The module's own padding and internal gaps, off the design: 11px in from the
// sides, 9px down from the top, 7px between lines.
private _padX = _tileW * 0.0625;
private _kickOff = _tileH * 0.07;
private _kickH = _tileH * 0.20;
private _valueOff = _tileH * 0.30;
private _valueH = _tileH * 0.44;
private _detailOff = _tileH * 0.76;
private _detailH = _tileH * 0.20;

// ONE ROW OR TWO, and one is the default. A band the width of the screen is the
// design's, and it is right when the map is wide - but a player who wants the
// tiles out of the way of the map, or who runs a squad rail and a reader wide
// enough to squeeze it, gets them stacked instead. The tiles do not change; only
// how many of them stand beside each other.
private _rows = [1, 2] select (GVAR(tileRows) isEqualTo "2" && !_fillRow);
private _perRow = ceil (count _tiles / _rows);

private _i = 0;
{
    _x params ["_app", "_kicker", "_qualifier", "_value", "_detail", ["_state", "rest"], ["_icon", ""]];

    // Inset by the panel's own padding, so a tile's 2px outline is not sitting
    // on the panel's 2px outline - two edges touching read as one thick one.
    private _col = _i % _perRow;
    private _row = floor (_i / _perRow);
    private _x0 = _edge + _col * (_tileW + _gap);
    private _rowY = _edgeY + _row * (_tileH + _edgeY);
    // A GUARD, NOT A POLICY. The width above divides the band so every tile
    // fits by construction; this only catches a tile that genuinely cannot be
    // drawn. The epsilon is why HACK used to vanish - exact division leaves the
    // last tile's right edge equal to the limit, and a floating-point hair over
    // was read as "does not fit" and silently dropped it.
    if (_x0 + _tileW > _bodyW - _edge + 0.0005 * HOST_W) exitWith {};

    private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.45];
    private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

    // [fill, outline, kicker, qualifier, value, detail]. Every state is the same
    // six decisions, so they are declared together rather than as branches
    // scattered through the drawing - and the qualifier is its own colour
    // because WARN puts it in the accent while the kicker beside it stays ink.
    (switch (_state) do {
        // The one loud state. Inverted accent block, everything on it in ground.
        case "alert": {[_accent, _accent, _ground, _ground, _ground, _ground]};
        // Degraded but working: the outline and the numbers carry it, not a fill.
        case "warn": {[_ground, _accent, _ink, _accent, _accent, _mute]};
        // No feed. The frame stays so the band never reflows, but nothing on it
        // is claimed to be true.
        case "stale": {[_ground, _line, _dim, _dim, _dim, _dim]};
        default {[_ground, _ink, _ink, _mute, _ink, _mute]};
    }) params ["_fill", "_edgeInk", "_kickInk", "_qualInk", "_valueInk", "_detailInk"];

    // The tile's small text - kicker, qualifier, detail - is TEXT_BODY two
    // pixels over the rest of the app text (user, 2026-10-22: "the secondary
    // text in the tiles 2px larger"; jmfsb_tacpad_fnc_textPx).
    private _tileText = [TEXT_BODY, APP_TEXT_UP_PX] call EFUNC(tacpad,textPx);
    [_body, [_x0, _rowY, _tileW, _tileH], _fill] call EFUNC(tacpad,drawFill);
    [_body, [_x0, _rowY, _tileW, _tileH], _edgeInk, RULE_THICK] call EFUNC(tacpad,drawFrame);

    // Kicker left, qualifier hard right on the same line. Two controls, because
    // one structured text with an align='right' span in it puts the right span
    // on its own line the moment the left one runs long.
    [_body, [_x0 + _padX, _rowY + _kickOff, _tileW * 0.55, _kickH], _kicker, _kickInk, _tileText, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_x0 + _tileW * 0.45 - _padX, _rowY + _kickOff, _tileW * 0.55 - _padX, _kickH], _qualifier, _qualInk, _tileText, true, "right"] call EFUNC(tacpad,drawText);

    // A glyph sits opposite the value, not instead of it. The tile's whole job
    // is one number worth a glance; the icon says what kind of number it is
    // without the eye having to read the kicker first.
    if (_icon != "") then {
        private _glyphH = _valueH * 0.95;
        [
            _body,
            [_x0 + _tileW - _padX - _glyphH * pixelW / pixelH, _rowY + _valueOff + (_valueH - _glyphH) * 0.5, _glyphH],
            _icon,
            _valueInk
        ] call EFUNC(tacpad,drawIcon);
    };

    [_body, [_x0 + _padX, _rowY + _valueOff, _tileW - 2 * _padX, _valueH], _value, _valueInk, TEXT_DISPLAY, true] call EFUNC(tacpad,drawText);
    [_body, [_x0 + _padX, _rowY + _detailOff, _tileW - 2 * _padX, _detailH], _detail, _detailInk, _tileText, true] call EFUNC(tacpad,drawText);

    private _hit = [_body, [_x0, _rowY, _tileW, _tileH], {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(tileApp), ""], [], true] call EFUNC(tacpad,openApp);    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(tileApp), _app];

    _i = _i + 1;
} forEach _tiles;

// SAID, NOT SWALLOWED. A band too narrow for its tiles simply stopped drawing
// them, so nobody could tell a tile existed at all - the count is the only
// clue that the band is short of room.
private _dropped = (count _tiles) - _i;
if (_dropped > 0) then {
    private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
    [
        _body, [_bodyW - _edge - _tileW * 0.5, _edgeY + (_rows - 1) * (_tileH + _edgeY), _tileW * 0.5, _tileH],
        format ["+%1", _dropped], _mute, TEXT_BODY, true, "right", true
    ] call EFUNC(tacpad,drawText);
};

// The band is exactly one tile tall - it used to be a fixed default with empty
// air above and below the tiles.
if (!_fillRow) then {
    [_id, 0, _rows * TILE_H + (_rows + 1) * PAD] call EFUNC(tacpad,fit);
};
