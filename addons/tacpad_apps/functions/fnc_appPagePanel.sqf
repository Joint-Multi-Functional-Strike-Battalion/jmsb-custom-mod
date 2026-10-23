#include "script_component.hpp"
/*
 * Author: JMSB
 * One panel of a board (RADIO, DRONES, HACK): a hairline box, the title on
 * the left, a right label, and the heavy ink rule under the header - the
 * design's "Panels: title + right label, rule under the header".
 *
 * Arguments:
 * 0: Body to draw into <CONTROL>
 * 1: The panel's rectangle [x, y, w, h], relative to the body <ARRAY>
 * 2: Title <STRING>
 * 3: Right label <STRING> (optional, default "")
 *
 * Return Value:
 * The content rectangle under the rule [x, y, w, h] <ARRAY>
 *
 * Example:
 * private _in = [_body, [0, 0, _w, _h], "CHANNELS", "7 NETS"] call jmfsb_tacpad_apps_fnc_appPagePanel
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_title", "", [""]],
    ["_right", "", [""]]
];

if (isNull _body) exitWith {[0, 0, 0, 0]};

_rect params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _surface = ["surface"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
private _headH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H * 1.2;
private _ruleH = RULE_THICK * pixelH;

[_body, _rect, _surface] call EFUNC(tacpad,drawFill);
[_body, _rect, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);

[_body, [_left + _pad, _top, _w * 0.6 - _pad, _headH], _title, _ink, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
if (_right isNotEqualTo "") then {
    [_body, [_left + _w * 0.4, _top, _w * 0.6 - _pad, _headH], _right, _muted, TEXT_BODY, false, "right"] call EFUNC(tacpad,drawText);
};

[_body, [_left, _top + _headH, _w, _ruleH], _ink] call EFUNC(tacpad,drawFill);

[_left, _top + _headH + _ruleH, _w, _h - _headH - _ruleH]
