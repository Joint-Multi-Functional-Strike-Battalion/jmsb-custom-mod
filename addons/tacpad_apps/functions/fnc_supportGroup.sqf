#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT group label - the handoff's .glab. A surface-token band with a
 * 2px divider above and a 1px divider below, the micro-label flush left and
 * the group's guidance sentence flush right.
 *
 * THE GUIDANCE IS THE ONLY EXPLANATORY COPY ON THE SCREEN. It is bound to the
 * current selection in that group by the caller and rewritten on every draw;
 * list rows never carry it, and it never centres.
 *
 * Arguments:
 * 0: Parent controls group <CONTROL>
 * 1: Top edge, in the parent's space <NUMBER>
 * 2: Width <NUMBER>
 * 3: Label <STRING>
 * 4: Guidance sentence <STRING>
 *
 * Return Value:
 * Bottom edge of the label <NUMBER>
 *
 * Example:
 * _y = [_body, _y, _fw, "UNIT", "Select one"] call jmfsb_tacpad_apps_fnc_supportGroup
 *
 * Public: No
 */

// The band is a little shorter than a row - 7px/12px padding on 9.5px type in
// the handoff against 9px/14px on 13px for a row.
#define GROUP_H_K 0.85
#define GROUP_LABEL_W 0.3

params [
    ["_parent", controlNull, [controlNull]],
    ["_y", 0, [0]],
    ["_w", 0, [0]],
    ["_label", "", [""]],
    ["_guide", "", [""]]
];

if (isNull _parent) exitWith {_y};

private _h = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * SUP_UNIT_H * GROUP_H_K;
private _pad = PAD * SUP_UNIT_W;

private _surface = ["surface"] call EFUNC(tacpad,theme);
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);

[_parent, [0, _y, _w, _h], _surface] call EFUNC(tacpad,drawFill);
[_parent, [0, _y, _w, RULE_THICK * pixelH], _line] call EFUNC(tacpad,drawFill);
[_parent, [0, _y + _h - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

[_parent, [_pad, _y, _w * GROUP_LABEL_W, _h], _label, _ink, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_parent, [_w * GROUP_LABEL_W, _y, _w * (1 - GROUP_LABEL_W) - _pad, _h], _guide, _muted, TEXT_LABEL, false, "right"] call EFUNC(tacpad,drawText);

_y + _h
