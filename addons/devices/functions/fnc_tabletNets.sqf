#include "script_component.hpp"
/*
 * Author: YonV
 * The tablet's net row (docs/images/voice_tablet_nets.png): one square cell
 * per voice net the player is on - the same nets the walking view shows, from
 * the same function (FUNC(overlayNets)), never a frequency. A CELL IS A
 * BUTTON (user, 2026-10-31: "the von chips should be clickable"): a press
 * makes that net the active one (FUNC(netSelect)), as its SELECT NET key
 * does; the frame's LEFT / RIGHT keys page the live tiles, not the nets.
 *
 * ONE PAGE OF FOUR (user, 2026-11-07): the twelve net buttons are three pages
 * of four (FUNC(netButtons)); the row shows the page the walking view shows,
 * numbered 1-4, with a < 2/3 > pager left of GLOBAL while more than one page
 * has nets (FUNC(netPageStep)).
 *
 * THE OUTLINE IS THE NET'S STATE, the walking view's answer (FUNC(netOutline)):
 * green good, amber weak or jammed, red no route (never hidden), dim muted.
 * Each label carries its SELECT NET number. The tag at a cell's right is its ear (L / B / R); a muted
 * net's name is dim; a ringing call with no call net yet is a RING cell in the
 * alert colour.
 *
 * THE GLOBAL BUTTON (user, 2026-10-21: "give leaders a tablet button to use
 * the global net"; "not is leader but atl tl's and all of hhc"): a man the
 * comm plan puts on C2 - TLs, ATLs, all of HHC - or an admin, under game
 * voice, gets a GLOBAL cell at the row's right end (jmfsb_voice_fnc_canGlobal). A press puts him on Global
 * - the cell goes red, push-to-talk reaches everyone - and a second press
 * takes him back to his active net (jmfsb_voice_fnc_global).
 *
 * DARK ROW, LIGHT ACTIVE CELL (art/images/tablet_screen.png): the row and the
 * idle cells are ink with labels in the ground colour; only the active net is
 * filled with the ground, its label in ink.
 *
 * Arguments:
 * 0: The row's body <CONTROL>
 * 1: The rows' last drawn keys <HASHMAP>
 *
 * Return Value:
 * Redrawn <BOOL>
 *
 * Example:
 * [_body, _keys] call jmfsb_devices_fnc_tabletNets
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_keys", createHashMap, [createHashMap]]];
if (isNull _body) exitWith {false};

// ONE PAGE OF THE TWELVE NET BUTTONS (user, 2026-11-07; FUNC(netButtons)):
// [label, active, outline, ear, muted, ring, transmitting, receive only] per
// cell of the page shown, [] for an empty one.
private _buttons = [] call FUNC(netButtons);
_buttons params ["", "_page", "_pages"];
private _cells = ([_buttons] call FUNC(overlayNets)) apply {
    if (_x isEqualTo []) then {[]} else {
        _x params ["", "_label", "_active", "", "", "_ear", "_muted", "_kind", "", ["_tx", false, [false]], ["_receiveOnly", false, [false]]];
        [[_label, format ["%1 %2", NET_TX_TAG, _label]] select _tx, _active, [[_x] call FUNC(netOutline), COLOUR_TX] select _tx, _ear, _muted, _kind isEqualTo NET_KIND_RING, _tx, _receiveOnly]
    };
};
private _paged = count _pages > 1;
private _mark = format [NET_PAGE_MARK, (_pages find _page) + 1, count _pages];

private _global = !isNil QEFUNC(voice,global)
    && {(missionNamespace getVariable [QEGVAR(voice,system), ""]) isEqualTo VOICE_SYSTEM_VON}
    && {[player] call EFUNC(voice,canGlobal)};
private _globalOn = _global && {missionNamespace getVariable [QEGVAR(voice,globalOn), false]};

private _key = str [_cells, _global, _globalOn, _paged, _mark];
if (_key isEqualTo (_keys getOrDefault ["nets", ""])) exitWith {false};
_keys set ["nets", _key];

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _unitW = _w / TABLET_DESIGN_W;
private _gapX = TABLET_GAP * _unitW;
private _gapY = _h * TABLET_GAP / TABLET_ROW_NETS;

// The row is ink, so what is dim on it is the ground moved towards the ink by
// the shell's own dim mix - the "dim" token turned over.
private _dimOnInk = [0, 1, 2] apply {(_solid select _x) + ((_ink select _x) - (_solid select _x)) * MIX_DIM};
_dimOnInk pushBack 1;
// And on the active cell, which is the ground, the theme's own dim.
private _dimOnGround = ["dim"] call EFUNC(tacpad,theme);

// NO VOICE HERE AT ALL is a line across the row: no voice addon, or the
// server's voice cannot run on this machine (VOICE UNAVAILABLE).
private _noVoice = switch (true) do {
    case (isNil QEFUNC(voice,netState)): {"NO VOICE ADDON"};
    case !(missionNamespace getVariable [QEGVAR(voice,active), true]): {TEXT_VOICE_UNAVAILABLE};
    default {""};
};
if (_cells isEqualTo [] && _noVoice isNotEqualTo "") exitWith {
    [_body, [_gapX, 0, _w - 2 * _gapX, _h], _noVoice, _dimOnInk, TABLET_TEXT_NET, true] call EFUNC(tacpad,drawText);
    true
};
// ON NO NET THE ROW KEEPS ITS SHAPE (review 2026-11-01, item 2.6): it was one
// "NO VOICE NET" line in a strip, and the row changed shape the moment a net
// appeared. Now the cells are drawn as usual and the first one is a dim cell
// reading NO NET - same height, same place.
private _noNet = _cells isEqualTo [];

// NO "0 <" / "> ." ENDS (user, 2026-10-21, the corners: the font has no
// arrow glyphs, so a bare "0" and "." sat in the screen's corners). The
// frame's own LEFT / RIGHT keys step the nets.

// The GLOBAL button, at the right end.
private _globalW = [0, TABLET_NET_GLOBAL_W * _unitW] select _global;
if (_global) then {
    private _rect = [_w - _gapX - _globalW, _gapY, _globalW, _h - 2 * _gapY];
    [_body, _rect, [_ink, COLOUR_TX] select _globalOn] call EFUNC(tacpad,drawFill);
    [_body, _rect, [_dimOnInk, COLOUR_TX] select _globalOn, NET_EDGE_PX] call EFUNC(tacpad,drawFrame);
    [_body, _rect, [GLOBAL_LABEL_OFF, GLOBAL_LABEL_ON] select _globalOn, [_solid, COLOUR_TEXT] select _globalOn, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText);
    [_body, _rect, {[] call EFUNC(voice,global)}] call EFUNC(tacpad,drawHit);
};

// A PAGE'S FOUR EQUAL CELLS ACROSS THE WIDTH whatever the count (notes,
// 2026-10-30; four since the net pages, 2026-11-07), NET_CELL_PX_TABLET tall,
// an empty one a dim outline. The legend - the keys - is a tooltip over the
// row: text only on hover.
// THE PAGER (< 2/3 >) between the cells and GLOBAL: its room is kept whether
// or not there is more than one page, so the cells never jump; its buttons
// and marker are drawn only while there is. The frame's LEFT / RIGHT keys
// stay on the live tiles (user, 2026-10-31), so these buttons are how the
// tablet turns the net pages.
private _count = NET_PAGE_SIZE;
private _pagerW = TABLET_NET_PAGER_W * _unitW;
private _inner = _w - ([0, _globalW + _gapX] select _global) - _pagerW - _gapX;
private _cellW = (_inner - (_count + 1) * _gapX) / _count;
private _cellH = (_h - 2 * _gapY) min (NET_CELL_PX_TABLET * pixelH);
private _cellY = (_h - _cellH) / 2;
// The ear tag sits in a square at the cell's right end.
private _tagW = _cellH * pixelW / pixelH;

if (_paged) then {
    private _px = _gapX + _count * (_cellW + _gapX);
    private _arrowW = _pagerW * TABLET_NET_PAGER_ARROW_K;
    [_body, [_px + _arrowW, _cellY, _pagerW - 2 * _arrowW, _cellH], _mark, _solid, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText);
    {
        _x params ["_ax", "_glyph", "_step"];
        private _rect = [_ax, _cellY, _arrowW, _cellH];
        [_body, _rect, _dimOnInk, RULE_THIN] call EFUNC(tacpad,drawFrame);
        [_body, _rect, _glyph, _solid, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText);
        private _hit = [_body, _rect, {
            params ["_ctrl"];
            if !([_ctrl getVariable [QGVAR(pageStep), 0]] call FUNC(netPageStep)) exitWith {};
            // Redrawn the next frame rather than inside the press, which
            // would delete the button under it.
            [{_this call FUNC(tabletTick)}, [ctrlParent _ctrl, -1]] call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(pageStep), _step];
        _hit ctrlSetTooltip TABLET_NET_LEGEND;
    } forEach [[_px, NET_PAGE_PREV_TEXT, -1], [_px + _pagerW - _arrowW, NET_PAGE_NEXT_TEXT, 1]];
};

for "_i" from 0 to (_count - 1) do {
    private _rect = [_gapX + _i * (_cellW + _gapX), _cellY, _cellW, _cellH];
    if ((_cells param [_i, []]) isEqualTo []) then {
        ([_body, _rect, _dimOnInk, RULE_THIN] call EFUNC(tacpad,drawFrame)) apply {_x ctrlSetTooltip TABLET_NET_LEGEND};
        if (_noNet && _i isEqualTo 0) then {
            ([_body, _rect, TEXT_NO_NET, _dimOnInk, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText)) ctrlSetTooltip TABLET_NET_LEGEND;
        };
        continue;
    };
    (_cells select _i) params ["_label", "_active", "_outline", "_ear", "_muted", "_ring", "_tx", "_receiveOnly"];
    private _fill = switch (true) do {
        case (_tx): {COLOUR_TX};
        case (_ring): {COLOUR_ALERT};
        default {[_ink, _solid] select _active};
    };
    // A muted net's name is dim on the active cell too (user, 2026-11-01).
    private _text = switch (true) do {
        case (_ring || _tx): {COLOUR_TEXT};
        case (_active): {[_ink, _dimOnGround] select _muted};
        case (_muted): {_dimOnInk};
        default {_solid};
    };

    ([_body, _rect, _fill] call EFUNC(tacpad,drawFill)) ctrlSetTooltip TABLET_NET_LEGEND;
    [_body, _rect, _outline, NET_EDGE_PX] call EFUNC(tacpad,drawFrame);
    // The label's box stops where the ear tag's begins (user, 2026-10-31:
    // "overlapping text"), so a long name never runs under the tag.
    // RECEIVE ONLY (EMCON 3, FUNC(overlayNets)): a grey R in a tag's square
    // at the LEFT end, the ear keeping the right.
    _rect params ["_cx", "_cy", "_cw", "_ch"];
    private _roW = [0, _tagW] select _receiveOnly;
    private _labelW = _cw - _roW - ([0, _tagW] select (_ear isNotEqualTo ""));
    ([_body, [_cx + _roW, _cy, _labelW, _ch], _label, _text, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText)) ctrlSetTooltip TABLET_NET_LEGEND;
    if (_ear isNotEqualTo "") then {
        [_body, [_cx + _cw - _tagW, _cy, _tagW, _ch], _ear, COLOUR_DIM, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText);
    };
    if (_receiveOnly) then {
        [_body, [_cx, _cy, _tagW, _ch], NET_RX_TAG, COLOUR_DIM, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText);
    };
    // A MUTED NET IS STRUCK THROUGH (user, 2026-11-01: "when a channel is
    // muted put a red line through it"): one straight bar in the alert red,
    // the outline's thickness, across the cell's middle over the dimmed name -
    // the same strike as the phone's (FUNC(overlayDraw)). It was a stepped
    // diagonal ("what an ugly line"). Not on a TX cell, which is already red.
    if (_muted && !_tx) then {
        private _lineH = NET_EDGE_PX * pixelH;
        [_body, [_cx, _cy + (_ch - _lineH) / 2, _cw, _lineH], COLOUR_ALERT] call EFUNC(tacpad,drawFill);
    };
    // The press: the cell's number is its SELECT NET number.
    private _hit = [_body, _rect, {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(netIndex), 0]] call FUNC(netSelect);
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(netIndex), _i + 1];
    _hit ctrlSetTooltip TABLET_NET_LEGEND;
};

true
