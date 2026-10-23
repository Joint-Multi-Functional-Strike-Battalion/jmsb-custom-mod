#include "script_component.hpp"
/*
 * Author: JMSB
 * One TAC//SUPPORT list row - the handoff's .row. Label flush left, optional
 * micro-label meta flush right, a 1px divider under it.
 *
 * THE STATES ARE THE HANDOFF'S, painted from the theme only:
 *   "rest" - ground fill, ink label, muted meta; hover lifts to surface
 *   "on"   - selected: full ink fill, ground label
 *   "acc"  - committed / active tasking: full accent fill, ground label. One
 *            per screen at most - the caller keeps that promise.
 *   "off"  - dim label, no hit, no pointer states
 * Pressed (accent-600 under a ground label) belongs to every pressable state
 * and is painted by FUNC(supportTint) from the hit's MouseButtonDown.
 *
 * No explanatory copy goes in a row. The meta is data - a count, a platform,
 * a seat number - and anything that explains belongs to the group label.
 *
 * Arguments:
 * 0: Parent controls group <CONTROL>
 * 1: Rect [x, y, w, h] <ARRAY>
 * 2: Label <STRING>
 * 3: Meta <STRING>
 * 4: State "rest", "on", "acc" or "off" <STRING>
 * 5: Press handler, given [hit]; {} for a row nobody presses <CODE>
 * 6: Data hung on the hit as QGVAR(pick) <ARRAY>
 * 7: Share of the width the label takes when there is a meta (optional,
 *    default 0.5) <NUMBER>
 *
 * Return Value:
 * The hit, or controlNull for a row with no handler <CONTROL>
 *
 * Example:
 * [_body, [0, _y, _fw, _rowH], "CAS", "1 AIRFRAME", "on", _fnc_pick, [0, "cas"]] call jmfsb_tacpad_apps_fnc_supportCell
 *
 * Public: No
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_label", "", [""]],
    ["_meta", "", [""]],
    ["_state", "rest", [""]],
    ["_handler", {}, [{}]],
    ["_data", [], [[]]],
    ["_split", 0.5, [0]]
];

if (isNull _parent) exitWith {controlNull};

_rect params ["_x0", "_y0", "_w", "_h"];
private _pad = PAD * SUP_UNIT_W;

private _ground = +(["ground"] call EFUNC(tacpad,theme));
_ground set [3, 1];
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _surface = ["surface"] call EFUNC(tacpad,theme);

private _fillColour = switch (_state) do {
    case "on": {_ink};
    case "acc": {_accent};
    default {_ground};
};
private _labelColour = switch (_state) do {
    case "on";
    case "acc": {_ground};
    case "off": {_dim};
    default {_ink};
};
private _metaColour = switch (_state) do {
    case "on";
    case "acc": {_ground};
    case "off": {_dim};
    default {_muted};
};

private _fill = [_parent, _rect, _fillColour] call EFUNC(tacpad,drawFill);

private _labelW = [_w * _split, _w] select (_meta isEqualTo "");
private _labels = [
    ["label", [_parent, [_x0 + _pad, _y0, _labelW - 2 * _pad, _h], _label, _labelColour, TEXT_TITLE, true]] call FUNC(supportHover)
];
if (_meta isNotEqualTo "") then {
    _labels pushBack (["label", [
        _parent, [_x0 + _labelW, _y0, _w - _labelW - _pad, _h],
        _meta, _metaColour, TEXT_LABEL, true, "right", true
    ]] call FUNC(supportHover));
};

[_parent, [_x0, _y0 + _h - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

if (_state isEqualTo "off" || {_handler isEqualTo {}}) exitWith {controlNull};

private _hit = [_parent, _rect, _handler] call EFUNC(tacpad,drawHit);
_hit setVariable [QGVAR(pick), _data];

// Hover lifts a resting row to the surface step; a selected or committed row
// already says what it is and keeps its fill.
private _hoverFill = [_fillColour, _surface] select (_state isEqualTo "rest");
["wire", [_hit, _fill, _labels, _fillColour, _hoverFill, []]] call FUNC(supportHover);

_hit
