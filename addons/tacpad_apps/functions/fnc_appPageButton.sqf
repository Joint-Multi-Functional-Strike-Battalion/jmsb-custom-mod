#include "script_component.hpp"
/*
 * Author: JMSB
 * One button or one segment of a segmented control on a board. Filled = the
 * picked segment or a primary button; outlined otherwise; an accent fill for
 * the one destructive button (ABORT). A dead button is drawn dim with no hit,
 * so it can never look like a press that went nowhere.
 *
 * Arguments:
 * 0: Body to draw into <CONTROL>
 * 1: Rectangle [x, y, w, h], relative to the body <ARRAY>
 * 2: Label <STRING>
 * 3: Style - "fill", "line" or "alarm" <STRING>
 * 4: Pressed: called with [control] <CODE>, {} for a dead button
 * 5: Data hung on the button as QGVAR(pageData) <ANY> (optional, default nil)
 *
 * Return Value:
 * The hit, controlNull for a dead button <CONTROL>
 *
 * Example:
 * [_body, [_x, _y, _w, _h], "START", "fill", {...}] call jmfsb_tacpad_apps_fnc_appPageButton
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_label", "", [""]],
    ["_style", "line", [""]],
    ["_onPress", {}, [{}]],
    ["_data", nil]
];

if (isNull _body) exitWith {controlNull};

private _ground = ["ground"] call EFUNC(tacpad,theme);
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _dead = _onPress isEqualTo {};

switch (true) do {
    case (_dead): {
        [_body, _rect, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
        [_body, _rect, _label, _dim, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    };
    case (_style isEqualTo "fill"): {
        [_body, _rect, _ink] call EFUNC(tacpad,drawFill);
        [_body, _rect, _label, _ground, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    };
    case (_style isEqualTo "alarm"): {
        [_body, _rect, _accent] call EFUNC(tacpad,drawFill);
        [_body, _rect, _label, _ground, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    };
    default {
        [_body, _rect, _ink, RULE_THIN] call EFUNC(tacpad,drawFrame);
        [_body, _rect, _label, _ink, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    };
};

if (_dead) exitWith {controlNull};

private _hit = [_body, _rect, _onPress] call EFUNC(tacpad,drawHit);
if (!isNil "_data") then {
    _hit setVariable [QGVAR(pageData), _data];
};
_hit
