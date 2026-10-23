#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet's net row (docs/images/voice_tablet_nets.png): one square cell
 * per voice net the player is on - the same nets the walking view shows, from
 * the same function (FUNC(overlayNets)), never a frequency. The frame's LEFT /
 * RIGHT keys step the active net.
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

// [label, active, outline, ear, muted, ring, transmitting].
private _cells = ([] call FUNC(overlayNets)) apply {
    _x params ["", "_label", "_active", "", "", "_ear", "_muted", "_kind", "", ["_tx", false, [false]]];
    [[_label, format ["%1 %2", NET_TX_TAG, _label]] select _tx, _active, [[_x] call FUNC(netOutline), COLOUR_TX] select _tx, _ear, _muted, _kind isEqualTo NET_KIND_RING, _tx]
};

private _global = !isNil QEFUNC(voice,global)
    && {missionNamespace getVariable [QEGVAR(voice,active), false]}
    && {[player] call EFUNC(voice,canGlobal)};
private _globalOn = _global && {missionNamespace getVariable [QEGVAR(voice,globalOn), false]};

private _key = str [_cells, _global, _globalOn];
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

if (_cells isEqualTo []) exitWith {
    [_body, [_gapX, 0, _w - 2 * _gapX, _h], (switch (true) do {case (isNil QEFUNC(voice,netState)): {"NO VOICE ADDON"}; case !(missionNamespace getVariable [QEGVAR(voice,active), true]): {format ["%1: NO NET", toUpper (missionNamespace getVariable [QEGVAR(voice,system), ""])]}; default {"NO VOICE NET"}}), _dimOnInk, TABLET_TEXT_NET, true] call EFUNC(tacpad,drawText);
    true
};

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

private _count = count _cells;
private _inner = _w - ([0, _globalW + _gapX] select _global);
private _cellW = ((_inner - (_count + 1) * _gapX) / _count) min (TABLET_NET_CELL_MAX_W * _unitW);
private _cellH = _h - 2 * _gapY;
// The ear tag sits in a square at the cell's right end.
private _tagW = _cellH * pixelW / pixelH;

{
    _x params ["_label", "_active", "_outline", "_ear", "_muted", "_ring", "_tx"];
    private _rect = [_gapX + _forEachIndex * (_cellW + _gapX), _gapY, _cellW, _cellH];
    private _fill = switch (true) do {
        case (_tx): {COLOUR_TX};
        case (_ring): {COLOUR_ALERT};
        default {[_ink, _solid] select _active};
    };
    private _text = switch (true) do {
        case (_ring || _tx): {COLOUR_TEXT};
        case (_active): {_ink};
        case (_muted): {_dimOnInk};
        default {_solid};
    };

    [_body, _rect, _fill] call EFUNC(tacpad,drawFill);
    [_body, _rect, _outline, NET_EDGE_PX] call EFUNC(tacpad,drawFrame);
    [_body, _rect, _label, _text, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText);
    if (_ear isNotEqualTo "") then {
        _rect params ["_cx", "_cy", "_cw", "_ch"];
        [_body, [_cx + _cw - _tagW, _cy, _tagW, _ch], _ear, COLOUR_DIM, TABLET_TEXT_NET, true, "center"] call EFUNC(tacpad,drawText);
    };
} forEach _cells;

true
