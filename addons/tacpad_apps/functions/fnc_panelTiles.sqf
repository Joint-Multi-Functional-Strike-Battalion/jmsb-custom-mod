#include "script_component.hpp"
/*
 * Author: YonV
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
 * AND A REFRESH DELETES NOTHING (code review R8). While the band's shape is
 * the one it was built for, a refresh writes each tile's words and colours
 * (FUNC(tileLive)) into the controls already there (EFUNC(tacpad,liveApply));
 * the band is built again only when the shape changes - a tile added, gone,
 * turned live or stale, a qualifier of another length, the page, the place,
 * the scheme or the type size.
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

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink"];

private _tiles = [] call FUNC(tileData);

// THE BAND PAGES (user, 2026-10-30: "add a 11th through 16th slot that you
// get to using the left right arrows ... increase the slot count with every
// new app"): every tile has a slot, a page is TILE_SLOTS a row, and the
// arrows at the band's ends turn it. The page is kept across redraws.
private _pageRows = [1, 2] select (GVAR(tileRows) isEqualTo "2" && !_fillRow);
private _perPage = TILE_SLOTS * _pageRows;
private _pages = (ceil ((count _tiles) / _perPage)) max 1;
private _page = ((uiNamespace getVariable [QGVAR(tilePage), 0]) min (_pages - 1)) max 0;
uiNamespace setVariable [QGVAR(tilePage), _page];
// The page count and this draw's arguments, for the device arrows
// (FUNC(tilePageStep)) to turn the page and draw the band again.
uiNamespace setVariable [QGVAR(tilePages), _pages];
uiNamespace setVariable [QGVAR(tileArgs), [_body, _id, _fillRow]];
private _paged = _pages > 1;
_tiles = _tiles select [_page * _perPage, _perPage];

// THE SAME BAND IS TICKED IN PLACE (code review R8). Its shape - which tiles,
// which of them live or stale, how long each qualifier is, the page, the
// body's and its panel's place, the host, the scheme and the type size - is
// what decides every control and where it stands; while it holds, the
// refresh writes the tiles' words and colours (FUNC(tileLive)) into the
// controls already there, and nothing under the cursor is deleted.
private _shape = [
    _tiles apply {
        private _qualifier = _x param [2, ""];
        private _state = _x param [5, "rest"];
        private _length = if (_qualifier isEqualType "") then {count _qualifier} else {-1};
        [_x select 0, _state isEqualTo "stale", _state in ["alert", "warn", "ok"], _length, _x param [7, 1]]
    },
    _page, _pages, _id, _fillRow, ctrlPosition _body, ctrlPosition (ctrlParentControlsGroup _body),
    HOST_RECT, EGVAR(tacpad,displayMode), [] call EFUNC(tacpad,theme), EGVAR(tacpad,textScale), EGVAR(tacpad,uiScale),
    GVAR(tileRows), pixelW, pixelH
];
private _values = [];
{
    _values append ([_x] call FUNC(tileLive));
} forEach (_tiles select [0, _body getVariable [QGVAR(tilesDrawn), 0]]);
if ([_body, _shape, _values] call EFUNC(tacpad,liveApply)) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});
_values = [];
private _entries = [];

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

// The band's inset at each end: the panel's own padding, and the page
// arrow's column when there is a page to turn to.
private _arrowCol = TILE_ARROW_PX * pixelW;
private _edge = PAD * HOST_W + ([0, _arrowCol + _gap] select _paged);

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
        private _avail = _bodyW - 2 * _edge;
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

// The ink's quieter steps: dim for a dead arrow, mute for the cut count. A
// tile's own are FUNC(tileLive)'s.
private _dim = [_ink # 0, _ink # 1, _ink # 2, TILE_DIM_ALPHA];
private _mute = [_ink # 0, _ink # 1, _ink # 2, LIVE_MUTE_ALPHA];

// THE LIVE PARTS. The nth tint, outline or line drawn takes the nth value
// (FUNC(tileLive)), and is kept with its type role for the refresh to write
// the next one into.
private _fnc_fill = {
    params ["_rect"];
    private _ctrl = [_body, _rect, (_values select (count _entries)) select 1] call EFUNC(tacpad,drawFill);
    _entries pushBack [[_ctrl], []];
};
private _fnc_frame = {
    params ["_rect", "_dashed"];
    private _ctrls = [_body, _rect, (_values select (count _entries)) select 1, RULE_THICK, _dashed] call EFUNC(tacpad,drawFrame);
    _entries pushBack [_ctrls, []];
};
private _fnc_text = {
    params ["_rect", "_style"];
    (_values select (count _entries)) params ["_text", "_colour"];
    private _ctrl = ([_body, _rect, _text, _colour] + _style) call EFUNC(tacpad,drawText);
    _entries pushBack [[_ctrl], _style];
};

private _i = 0;
{
    _x params ["_app", "", "_qualifier", "", "", ["_state", "rest"], "", ["_textK", 1, [0]]];

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

    // THE STATE'S COLOUR ALL ROUND THE TILE - the tint, the outline, the
    // value and the badge - is FUNC(tileLive)'s; a live state gets the tint,
    // and stale the line, dashed.
    _values append ([_x] call FUNC(tileLive));
    private _stale = _state isEqualTo "stale";
    private _live = _state in ["alert", "warn", "ok"];

    // The tile's small text - kicker, qualifier, detail - is TEXT_BODY two
    // pixels over the rest of the app text (user, 2026-10-22: "the secondary
    // text in the tiles 2px larger"; jmfsb_tacpad_fnc_textPx).
    // A tile may ask for a larger detail line - the PAC tile does (user,
    // 2026-10-24). ONLY THE DETAIL: its kicker and badge are the band's size
    // like every other tile's (review 2026-11-01, item 2.7: "kicker larger
    // than other tiles").
    private _smallText = [TEXT_BODY, APP_TEXT_UP_PX] call EFUNC(tacpad,textPx);
    private _tileText = _smallText * _textK;
    [_body, [_x0, _rowY, _tileW, _tileH], _ground] call EFUNC(tacpad,drawFill);
    if (_live) then {
        [[_x0, _rowY, _tileW, _tileH]] call _fnc_fill;
    };
    // STALE IS A DASHED OUTLINE with dim text, never dim text alone (notes,
    // 2026-10-30); every other state keeps its solid outline.
    [[_x0, _rowY, _tileW, _tileH], _stale] call _fnc_frame;

    // Kicker left, the qualifier a badge hard right on the same line - filled
    // with the state's colour and the ground on it, the line and ink at rest.
    // Two controls, because one structured text with an align='right' span in
    // it puts the right span on its own line the moment the left one runs
    // long. The qualifier and the value are numbers: the monospace.
    //
    // THE BADGE IS SIZED TO ITS WORD AND THE KICKER TAKES THE REST (user,
    // 2026-10-30: "scrunched up text"): the word at CHIP_SIZE_K of the small
    // text, like every chip, its width estimated at the monospace's own
    // advance (TILE_BADGE_GLYPH) so it never wraps; it was measured at a
    // tighter estimate and drawn a size larger, and broke in two.
    //
    // AND THE KICKER KEEPS TILE_KICKER_MIN_GLYPHS (review 2026-11-01, item
    // 2.7: the DRONES tile read "DRON"). The badge gets what is left after
    // that; a badge narrower than its word sets the word smaller by the same
    // ratio, so the chip shrinks with it instead of breaking in two.
    private _badgeW = 0;
    private _badgeSize = _smallText * CHIP_SIZE_K;
    if (_qualifier isNotEqualTo "") then {
        private _badgeFontH = ([_badgeSize] call EFUNC(tacpad,textH)) / 1.25;
        private _chipPadW = 2 * CHIP_PAD_PX * pixelW;
        private _badgeNatW = (count _qualifier) * TILE_BADGE_GLYPH * _badgeFontH * pixelW / pixelH + _chipPadW;
        private _kickFontH = ([_smallText] call EFUNC(tacpad,textH)) / 1.25;
        private _kickMinW = TILE_KICKER_MIN_GLYPHS * TILE_KICKER_GLYPH * _kickFontH * pixelW / pixelH;
        _badgeW = ((_badgeNatW min (_tileW * TILE_BADGE_MAX_K)) min (_tileW - 2 * _padX - _padX * 0.5 - _kickMinW)) max _chipPadW;
        if (_badgeW < _badgeNatW) then {
            _badgeSize = _badgeSize * (_badgeW - _chipPadW) / (_badgeNatW - _chipPadW);
        };
    };
    private _kickW = _tileW - 2 * _padX - ([0, _badgeW + _padX * 0.5] select (_badgeW > 0));
    [[_x0 + _padX, _rowY + _kickOff, _kickW, _kickH], [_smallText, true, "left", true, ""]] call _fnc_text;
    if (_badgeW > 0) then {
        private _badge = [_x0 + _tileW - _padX - _badgeW, _rowY + _kickOff, _badgeW, _kickH];
        [_badge] call _fnc_fill;
        [_badge, [_badgeSize, true, "center", false, FONT_MONO]] call _fnc_text;
    };

    // NO ICON ON THE BAND (notes, 2026-10-30; the user: keep them on the HUD
    // widgets only): the kicker and the value carry the tile. The entry keeps
    // its icon slot for the HUD.
    [[_x0 + _padX, _rowY + _valueOff, _tileW - 2 * _padX, _valueH], [TEXT_DISPLAY, true, "left", false, FONT_MONO]] call _fnc_text;
    [[_x0 + _padX, _rowY + _detailOff, _tileW - 2 * _padX, _detailH], [_tileText, true, "left", false, ""]] call _fnc_text;

    private _hit = [_body, [_x0, _rowY, _tileW, _tileH], {
        params ["_ctrl"];
        private _app = _ctrl getVariable [QGVAR(tileApp), ""];
        // The MSG tile is the reader, not an app (user, 2026-10-24).
        if (_app isEqualTo "msg") exitWith {[] call EFUNC(tacpad,openReader)};
        // The LOG tile is the reader's LOG view (2026-11-09).
        if (_app isEqualTo LOG_APP) exitWith {[] call FUNC(openLog)};
        [_app, [], true] call EFUNC(tacpad,openApp);
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(tileApp), _app];

    _i = _i + 1;
} forEach _tiles;

// SAID, NOT SWALLOWED. A band too narrow for its tiles simply stopped drawing
// them, so nobody could tell a tile existed at all - the count is the only
// clue that the band is short of room.
private _dropped = (count _tiles) - _i;
if (_dropped > 0) then {
    [
        _body, [_bodyW - _edge - _tileW * 0.5, _edgeY + (_rows - 1) * (_tileH + _edgeY), _tileW * 0.5, _tileH],
        format ["+%1", _dropped], _mute, TEXT_BODY, true, "right", true
    ] call EFUNC(tacpad,drawText);
};

// THE PAGE ARROWS at the band's ends, when there is a page to turn to (user,
// 2026-10-30): a column each, the glyph in the ink - dim where there is no
// page that way - and a press turns the page and draws the band again into
// the same body, next frame, with the same arguments.
if (_paged) then {
    private _bandH = _rows * _tileH + (_rows - 1) * _edgeY;
    {
        _x params ["_ax", "_glyph", "_step", "_can"];
        private _rect = [_ax, _edgeY, _arrowCol, _bandH];
        [_body, _rect, _glyph, [_dim, _ink] select _can, TEXT_BODY, true, "center", false, FONT_MONO] call EFUNC(tacpad,drawText);
        if (_can) then {
            private _turn = [_body, _rect, {
                params ["_ctrl"];
                (_ctrl getVariable [QGVAR(tilePageTurn), [0, []]]) params ["_step", "_args"];
                uiNamespace setVariable [QGVAR(tilePage), (uiNamespace getVariable [QGVAR(tilePage), 0]) + _step];
                [FUNC(panelTiles), _args] call CBA_fnc_execNextFrame;
            }] call EFUNC(tacpad,drawHit);
            _turn setVariable [QGVAR(tilePageTurn), [_step, [_body, _id, _fillRow]]];
        };
    } forEach [
        [PAD * HOST_W, TILE_ARROW_LEFT, -1, _page > 0],
        [_bodyW - PAD * HOST_W - _arrowCol, TILE_ARROW_RIGHT, 1, _page < _pages - 1]
    ];
};

// The band is exactly one tile tall - it used to be a fixed default with empty
// air above and below the tiles.
if (!_fillRow) then {
    [_id, 0, _rows * TILE_H + (_rows + 1) * PAD] call EFUNC(tacpad,fit);
};

// What the refresh writes into from now on: the tiles drawn, and their live
// parts under the shape they were built for.
_body setVariable [QGVAR(tilesDrawn), _i];
[_body, _shape, _entries] call EFUNC(tacpad,liveStore);
