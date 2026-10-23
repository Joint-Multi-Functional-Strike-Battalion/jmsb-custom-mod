#include "script_component.hpp"
/*
 * Author: JMSB
 * Redraws the walking view - the status cells, the squad list and the talking
 * chip, the call strip, the nets - and puts the map back on the player.
 *
 * EVERYTHING IS DRAWN FRESH EACH TICK. The rows are a few controls' worth of
 * text and eight net cells; a redraw costs less than working out what
 * changed, and a row that always draws what is true now cannot drift.
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
private _rows = [ctrlPosition (_display displayCtrl IDC_OVERLAY_GROUND)] call FUNC(overlayRows);
private _rf = missionNamespace getVariable [QGVAR(overlayRf), createHashMap];

// ------------------------------------------------------------ status ----
// THE OLD TOP BAR (user, 2026-10-21): icon word and value; dim when the source
// is absent, amber on a warning, the whole cell red on an alert.
private _status = [] call FUNC(overlayStatus);
for "_i" from 0 to (OVERLAY_STATUS_CELLS - 1) do {
    private _cell = _display displayCtrl IDC_OVERLAY_CELL(_i);
    if (_i >= count _status) then {
        _cell ctrlShow false;
        continue;
    };
    (_status select _i) params ["_icon", "_value", "_state"];
    _cell ctrlSetText format ["%1 %2", _icon, _value];
    _cell ctrlSetTextColor ([_dim, _ink, COLOUR_WARN, COLOUR_TEXT] select (_state max STATE_OFF min STATE_ALERT));
    _cell ctrlSetBackgroundColor ([[0, 0, 0, 0], COLOUR_ALERT] select (_state isEqualTo STATE_ALERT));
    _cell ctrlShow true;
};

// -------------------------------------------------------------- call ----
private _app = GVAR(radioOpen);
private _voiceLine = [] call FUNC(voiceLine);
private _callCtrl = _display displayCtrl IDC_OVERLAY_CALL;
_callCtrl ctrlSetStructuredText parseText _voiceLine;
_callCtrl ctrlShow (_voiceLine isNotEqualTo "" && !_app);

// ------------------------------------------------------ squad and chip ----
// The phone's list hugs its lines over the map; the side devices' fills two
// columns of three under it.
private _portrait = _rows get "portrait";
private _perColumn = _rows get "squadRows";
private _members = [_rf] call FUNC(overlaySquad);
private _lineH = _rows get "lineH";
private _gapX = _rows get "gapX";
private _gapY = _rows get "gapY";
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
    if (!_portrait) then {
        _ctrl ctrlSetPosition [_rect # 0, _rect # 1, _rect # 2, (count _chunk) * _lineH + _gapY];
        _ctrl ctrlSetBackgroundColor COLOUR_BAR_SCRIM;
        _ctrl ctrlCommit 0;
    };
    _ctrl ctrlShow true;
} forEach [IDC_OVERLAY_SQUAD, IDC_OVERLAY_SQUAD2];

private _chip = [] call FUNC(overlayTalker);
private _talk = _display displayCtrl IDC_OVERLAY_TALK;
_talk ctrlSetStructuredText parseText _chip;
_talk ctrlShow (_chip isNotEqualTo "" && !_app);
(_display displayCtrl IDC_OVERLAY_MAP) ctrlShow !_app;

// ---------------------------------------------------------------- nets ----
// One row of equal cells on the phone, two columns on a portrait screen.
private _nets = [[] call FUNC(overlayNets), []] select _app;
(_rows get "nets") params ["_nx", "_ny", "_nw", "_nh"];
private _cols = [(count _nets) max 1, NET_COLS_PORTRAIT] select _portrait;
private _netRows = ceil ((count _nets) / _cols) max 1;
private _cellW = (_nw - (_cols + 1) * _gapX) / _cols;
if (!_portrait) then {_cellW = _cellW min (_rows get "netCellW")};
private _cellH = (_rows get "netCellH") min ((_nh - (_netRows + 1) * _gapY) / _netRows);
private _top = _ny + (_nh - _netRows * _cellH - (_netRows - 1) * _gapY) / 2;
private _edgeW = NET_EDGE_PX * pixelW;
private _edgeH = NET_EDGE_PX * pixelH;
private _textH = _rows get "textH";

for "_i" from 0 to (OVERLAY_NET_CELLS - 1) do {
    private _edge = _display displayCtrl IDC_OVERLAY_NETEDGE(_i);
    private _cell = _display displayCtrl IDC_OVERLAY_NET(_i);
    private _rx = _display displayCtrl IDC_OVERLAY_NETRX(_i);
    if (_i >= count _nets) then {
        {_x ctrlShow false} forEach [_edge, _cell, _rx];
        continue;
    };

    (_nets select _i) params ["", "_label", "_active", "", "", ["_ear", "", [""]], ["_muted", false, [false]], ["_kind", "", [""]]];
    private _x0 = _nx + _gapX + (_i mod _cols) * (_cellW + _gapX);
    private _y0 = _top + (floor (_i / _cols)) * (_cellH + _gapY);
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
    _cell ctrlSetPosition [_x0 + _edgeW, _y0 + _edgeH, _cellW - 2 * _edgeW, _cellH - 2 * _edgeH];
    _cell ctrlSetFontHeight _textH;
    _cell ctrlSetText _label;
    _cell ctrlSetBackgroundColor _fill;
    _cell ctrlSetTextColor _text;
    _rx ctrlSetPosition [_x0 + _cellW - _textH - _edgeW, _y0 + _edgeH, _textH, _cellH - 2 * _edgeH];
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

// ----------------------------------------------------------------- map ----
// Centring is FUNC(overlayFollow)'s, every frame on the map's Draw event;
// called here as well so the map is never left off-centre if a frame's Draw
// is skipped.
[_display displayCtrl IDC_OVERLAY_MAP] call FUNC(overlayFollow);
