#include "script_component.hpp"
/*
 * Author: JMSB
 * Redraws the walking view - the status cells, the squad list and the talking
 * chip, the call strip, the nets - and puts the map back on the player.
 *
 * THE CONTROLS ARE THE LAYER'S OWN, MADE ONCE (overlay.hpp); a tick only sets
 * their text, colour, position and visibility. Each section - the status
 * row, the call strip, the squad list, the talking chip, the nets - works out
 * what it would show and sets it only when that differs from what it set
 * last (EFUNC(tacpad,changed), code review R8), so a still screen costs the
 * reading and nothing more. A new placement (FUNC(overlayPlace), whose key is
 * part of every section's) sets every section again.
 *
 * THE STATUS ROW IS THE TOP BAR, NO NOTIFICATION LINE (user, 2026-10-21).
 * Notifications pop up top right on the game screen only. The cells are
 * FUNC(overlayProviders)': NET is the custom channels in use, GPS the grid.
 *
 * NET CELLS ARE SQUARE (user, 2026-10-19), ONE PER VOICE NET THE PLAYER IS
 * ON (FUNC(overlayNets), docs/DESIGN_VOICE.md "Nets on the devices"), each
 * "<N> <NAME>" with N its SELECT NET key. The outline is a block in the net's
 * state colour (FUNC(netOutline): green good, amber weak or jammed, red no
 * route, dim muted) with the label inset over it by NET_EDGE_PX - never
 * hidden. The active net is filled light with dark text; a muted net's name
 * is dim; the small tag at the right is the net's ear (L / B / R). A ringing
 * call with no call net yet is a RING cell in the alert colour.
 *
 * CALLS GET THE CALL STRIP (FUNC(voiceLine)) along the map's bottom while
 * there is call business - a ring, a call, a pending callback, the F2
 * quick-add list - and nothing otherwise. The RADIO app (FUNC(radioDraw))
 * takes the map, the squad list and the net row while it is open.
 *
 * Arguments:
 * 0: The layer's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_devices_fnc_overlayDraw
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink"];
private _dim = [_ink # 0, _ink # 1, _ink # 2, OVERLAY_DIM_ALPHA];
// The squad list and the talking box on a wash of the ground (notes,
// 2026-10-30), so they read over any map.
private _wash = [_ground # 0, _ground # 1, _ground # 2, OVERLAY_WASH_ALPHA];
private _rows = [ctrlPosition (_display displayCtrl IDC_OVERLAY_GROUND)] call FUNC(overlayRows);
private _rf = missionNamespace getVariable [QGVAR(overlayRf), createHashMap];
private _gapX = _rows get "gapX";
private _gapY = _rows get "gapY";
private _portrait = _rows get "portrait";
// Every section's key starts here: the placement, the rows and the scheme.
private _base = [GVAR(overlayKey), _rows, _ground, _ink];

// ------------------------------------------------------------ status ----
// THE OLD TOP BAR (user, 2026-10-21): icon word and value; dim when the source
// is absent, amber on a warning, the whole cell red on an alert.
private _status = [] call FUNC(overlayStatus);
private _statusRects = _rows get "status";
private _statusTextH = _rows get "statusTextH";
// ONE LINE, ONE SIZE (user, 2026-10-31: "one line ... the same font in a
// single line"; then "font too small"): every cell is measured at the row's
// size first, and the one size they all get is the row's shrunk only as far
// as the WHOLE line needs - on the phone's one row each cell is as wide as
// its own text (GPS wide, MSG narrow), so the shrink is the line's overflow,
// not the widest cell's share; a portrait screen keeps its grid of equal
// cells and shrinks by the worst cell. A gutter in from each edge either
// way, so neighbours never touch.
if ([_display, "status", [_base, _status]] call EFUNC(tacpad,changed)) then {
    private _shown = (count _status) min OVERLAY_STATUS_CELLS;
    private _widths = [];
    private _fit = 1;
    for "_i" from 0 to _shown - 1 do {
        private _cell = _display displayCtrl IDC_OVERLAY_CELL(_i);
        (_status select _i) params ["_icon", "_value"];
        _cell ctrlSetFontHeight _statusTextH;
        _cell ctrlSetText format ["%1 %2", _icon, _value];
        private _textW = ctrlTextWidth _cell;
        _widths pushBack _textW;
        if (_portrait) then {
            private _inner = ((_statusRects param [_i, [0, 0, 0, 0]]) select 2) - 2 * _gapX;
            if (_inner > 0 && _textW > _inner) then {_fit = _fit min (_inner / _textW)};
        };
    };
    private _lineRects = _statusRects;
    if (!_portrait && _shown > 0) then {
        (_rows get "content") params ["_cx", "", "_cw"];
        (_statusRects param [0, [0, 0, 0, 0]]) params ["", "_cy", "", "_ch"];
        private _room = _cw - 2 * _shown * _gapX;
        private _sum = 0;
        {_sum = _sum + _x} forEach _widths;
        if (_sum > 0 && _room > 0 && _sum > _room) then {_fit = _room / _sum};
        // each cell its text's width (at the one size) plus a gutter each side,
        // and the line's spare room shared out between them
        private _spare = ((_room - _sum * _fit) max 0) / _shown;
        _lineRects = [];
        private _runX = _cx;
        {
            private _w = _x * _fit + 2 * _gapX + _spare;
            _lineRects pushBack [_runX, _cy, _w, _ch];
            _runX = _runX + _w;
        } forEach _widths;
    };
    for "_i" from 0 to (OVERLAY_STATUS_CELLS - 1) do {
        private _cell = _display displayCtrl IDC_OVERLAY_CELL(_i);
        if (_i >= count _status) then {
            _cell ctrlShow false;
            continue;
        };
        (_status select _i) params ["", "", "_state"];
        _cell ctrlSetPosition (_lineRects param [_i, [0, 0, 0, 0]]);
        _cell ctrlCommit 0;
        _cell ctrlSetFontHeight (_statusTextH * _fit);
        _cell ctrlSetTextColor ([_dim, _ink, COLOUR_WARN, COLOUR_TEXT] select (_state max STATE_OFF min STATE_ALERT));
        _cell ctrlSetBackgroundColor ([[0, 0, 0, 0], COLOUR_ALERT] select (_state isEqualTo STATE_ALERT));
        _cell ctrlShow true;
    };
};

// -------------------------------------------------------------- call ----
private _app = GVAR(radioOpen);
private _voiceLine = [] call FUNC(voiceLine);
if ([_display, "call", [_base, _voiceLine, _app]] call EFUNC(tacpad,changed)) then {
    private _callCtrl = _display displayCtrl IDC_OVERLAY_CALL;
    _callCtrl ctrlSetStructuredText parseText _voiceLine;
    _callCtrl ctrlShow (_voiceLine isNotEqualTo "" && !_app);
};

// ------------------------------------------------------ squad and chip ----
// The phone's list hugs its lines over the map; the side devices' fills two
// columns of three under it.
private _perColumn = _rows get "squadRows";
private _members = [_rf] call FUNC(overlaySquad);
private _lineH = _rows get "lineH";
if ([_display, "squad", [_base, _members, _app]] call EFUNC(tacpad,changed)) then {
    {
        private _ctrl = _display displayCtrl _x;
        private _rect = (_rows get "squad") param [_forEachIndex, []];
        if (_rect isEqualTo []) then {continue};
        private _chunk = _members select [_forEachIndex * _perColumn, _perColumn];
        if (_app || {_chunk isEqualTo []}) then {
            _ctrl ctrlShow false;
            continue;
        };
        _ctrl ctrlSetStructuredText parseText (_chunk joinString "<br/>");
        _ctrl ctrlSetBackgroundColor _wash;
        if (!_portrait) then {
            _ctrl ctrlSetPosition [_rect # 0, _rect # 1, _rect # 2, (count _chunk) * _lineH + _gapY];
        };
        _ctrl ctrlCommit 0;
        _ctrl ctrlShow true;
    } forEach [IDC_OVERLAY_SQUAD, IDC_OVERLAY_SQUAD2];
};

private _chip = [] call FUNC(overlayTalker);
if ([_display, "talk", [_base, _chip, _app]] call EFUNC(tacpad,changed)) then {
    private _talk = _display displayCtrl IDC_OVERLAY_TALK;
    _talk ctrlSetBackgroundColor _wash;
    _talk ctrlSetStructuredText parseText _chip;
    _talk ctrlShow (_chip isNotEqualTo "" && !_app);
};
(_display displayCtrl IDC_OVERLAY_MAP) ctrlShow !_app;

// ---------------------------------------------------------------- nets ----
// One row of equal cells on the phone, two columns on a portrait screen.
private _nets = [[] call FUNC(overlayNets), []] select _app;
(_rows get "nets") params ["_nx", "_ny", "_nw", "_nh"];
// EQUAL CELLS ACROSS THE FULL WIDTH whatever the count (notes, 2026-10-30):
// four on the phone's one row (user, 2026-10-31), six in two columns on a
// portrait screen; an empty one is a dim outline. The RADIO app takes the
// row (no nets) and every cell hides.
private _cells = [NET_ROW_CELLS_PHONE, NET_ROW_CELLS] select _portrait;
private _cols = [_cells, NET_COLS_PORTRAIT] select _portrait;
private _slots = [_cells, 0] select _app;
private _netRows = (ceil (_slots / _cols)) max 1;
private _cellW = (_nw - (_cols + 1) * _gapX) / _cols;
private _cellH = (_rows get "netCellH") min ((_nh - (_netRows + 1) * _gapY) / _netRows);
private _top = _ny + (_nh - _netRows * _cellH - (_netRows - 1) * _gapY) / 2;
private _edgeW = NET_EDGE_PX * pixelW;
private _edgeH = NET_EDGE_PX * pixelH;
private _textH = _rows get "textH";

// A cell is set only when the row would read differently.
private _netsFresh = [_display, "nets", [_base, _nets, _app]] call EFUNC(tacpad,changed);
for "_i" from 0 to ([-1, OVERLAY_NET_CELLS - 1] select _netsFresh) do {
    private _edge = _display displayCtrl IDC_OVERLAY_NETEDGE(_i);
    private _cell = _display displayCtrl IDC_OVERLAY_NET(_i);
    private _rx = _display displayCtrl IDC_OVERLAY_NETRX(_i);
    if (_i >= _slots) then {
        {_x ctrlShow false} forEach [_edge, _cell, _rx];
        continue;
    };
    private _x0 = _nx + _gapX + (_i mod _cols) * (_cellW + _gapX);
    private _y0 = _top + (floor (_i / _cols)) * (_cellH + _gapY);

    // AN EMPTY CELL IS A DIM OUTLINE on the ground, nothing in it.
    if (_i >= count _nets) then {
        _edge ctrlSetPosition [_x0, _y0, _cellW, _cellH];
        _edge ctrlSetBackgroundColor _dim;
        _cell ctrlSetPosition [_x0 + _edgeW, _y0 + _edgeH, _cellW - 2 * _edgeW, _cellH - 2 * _edgeH];
        _cell ctrlSetText "";
        _cell ctrlSetBackgroundColor [_ground # 0, _ground # 1, _ground # 2, 1];
        {_x ctrlCommit 0} forEach [_edge, _cell];
        _edge ctrlShow true;
        _cell ctrlShow true;
        _rx ctrlShow false;
        continue;
    };

    (_nets select _i) params ["", "_label", "_active", "", "", ["_ear", "", [""]], ["_muted", false, [false]], ["_kind", "", [""]]];
    private _ring = _kind isEqualTo NET_KIND_RING;
    // TALKING ON IT: the chip goes red with TX in front, whatever else it is.
    private _tx = (_nets select _i) param [9, false];
    if (_tx) then {_label = format ["%1 %2", NET_TX_TAG, _label]};
    private _outline = [[_nets select _i] call FUNC(netOutline), COLOUR_TX] select _tx;
    private _fill = switch (true) do {
        case (_tx): {COLOUR_TX};
        case (_ring): {COLOUR_ALERT};
        case (_active): {_ink};
        default {[_ground # 0, _ground # 1, _ground # 2, 1]};
    };
    private _text = switch (true) do {
        case (_tx): {COLOUR_TEXT};
        case (_ring || _active): {[_ground, COLOUR_TEXT] select _ring};
        case (_muted): {_dim};
        default {_ink};
    };

    _edge ctrlSetPosition [_x0, _y0, _cellW, _cellH];
    _edge ctrlSetBackgroundColor _outline;
    // THE LABEL STOPS SHORT OF THE EAR TAG (user, 2026-10-31: "overlapping
    // text" - "1 GHOST" ran under its B): the text control ends where the
    // tag begins, the tag's own box carries the fill on to the cell's edge,
    // and a name still wider than its room is set smaller by measure.
    private _tagW = [0, _textH + _edgeW] select (_ear isNotEqualTo "");
    private _nameW = _cellW - 2 * _edgeW - _tagW;
    _cell ctrlSetPosition [_x0 + _edgeW, _y0 + _edgeH, _nameW, _cellH - 2 * _edgeH];
    _cell ctrlSetFontHeight _textH;
    _cell ctrlSetText _label;
    private _labelW = ctrlTextWidth _cell;
    private _room = _nameW - 2 * _gapX;
    if (_room > 0 && _labelW > _room) then {_cell ctrlSetFontHeight (_textH * _room / _labelW)};
    _cell ctrlSetBackgroundColor _fill;
    _cell ctrlSetTextColor _text;
    _rx ctrlSetPosition [_x0 + _edgeW + _nameW, _y0 + _edgeH, _tagW, _cellH - 2 * _edgeH];
    _rx ctrlSetBackgroundColor _fill;
    _rx ctrlSetFontHeight _textH;
    _rx ctrlSetText _ear;
    _rx ctrlSetTextColor ([COLOUR_DIM, _ground] select _active);
    {
        _x ctrlCommit 0;
    } forEach [_edge, _cell, _rx];
    _edge ctrlShow true;
    _cell ctrlShow true;
    _rx ctrlShow (_ear isNotEqualTo "");
};

// ------------------------------------------------------- the RADIO app ----
[_display, _rows] call FUNC(radioDraw);

// ------------------------------------------------- the call's picture ----
// Over everything, top right of the map, while a call is live (FUNC(callWindow)).
[
    _display, _rows get "map", CALL_CORNER_SMALL, CALL_WINDOW_SHARE_SMALL, "", 1 - (GVAR(overlayOpacity) max 0 min 1),
    {!isNull (uiNamespace getVariable [QGVAR(overlayDisplay), displayNull])}
] call FUNC(callWindow);

// ----------------------------------------------------------------- map ----
// Centring is FUNC(overlayFollow)'s, every frame on the map's Draw event;
// called here as well so the map is never left off-centre if a frame's Draw
// is skipped.
[_display displayCtrl IDC_OVERLAY_MAP] call FUNC(overlayFollow);
