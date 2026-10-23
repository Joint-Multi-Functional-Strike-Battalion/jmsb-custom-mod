#include "script_component.hpp"
/*
 * Author: JMSB
 * Draws a TAC//SUPPORT label and returns it with the spec FUNC(supportTint)
 * needs to repaint it - or, given a hit, wires hover and press on that hit and
 * on the labels it covers.
 *
 * TWO JOBS, ONE FILE, because they are the two halves of one contract: the
 * label spec this hands out in mode "label" is exactly what mode "wire" stores
 * and FUNC(supportTint) reads back.
 *
 * Hover and pressed are the handoff's row states: hover lifts the fill,
 * pressed is accent-600 under a ground label until the release redraws the
 * screen. A label lying over a hit takes the mouse itself, so it gets the same
 * enter / exit pair as the hit does; the press is the hit's alone.
 *
 * Arguments (mode "label"):
 * 0: "label" <STRING>
 * 1: [parent, rect, text, colour, size, bold, align, tracked] - the
 *    EFUNC(tacpad,drawText) arguments <ARRAY>
 *
 * Arguments (mode "wire"):
 * 0: "wire" <STRING>
 * 1: [hit, fill, labels, rest fill, hover fill, hover text colour or []] <ARRAY>
 *
 * Return Value:
 * Mode "label": label spec [control, text, size, bold, align, colour] <ARRAY>
 * Mode "wire": None
 *
 * Example:
 * private _spec = ["label", [_body, _rect, "CAS", _ink, TEXT_TITLE, true]] call jmfsb_tacpad_apps_fnc_supportHover
 *
 * Public: No
 */

params [["_mode", "", [""]], ["_args", [], [[]]]];

if (_mode isEqualTo "label") exitWith {
    _args params [
        ["_parent", controlNull, [controlNull]],
        ["_rect", [0, 0, 0, 0], [[]], 4],
        ["_text", "", [""]],
        ["_colour", [0, 0, 0, 1], [[]]],
        ["_size", TEXT_BODY, [0]],
        ["_bold", false, [false]],
        ["_align", "left", [""]],
        ["_tracked", false, [false]]
    ];
    private _ctrl = [_parent, _rect, _text, _colour, _size, _bold, _align, _tracked] call EFUNC(tacpad,drawText);

    // The text as drawText set it - tracked and escaped - so a repaint does
    // not track it twice.
    private _shown = _text;
    if (_tracked) then {_shown = (toUpper _shown) splitString "" joinString " "};
    _shown = [_shown] call EFUNC(tacpad,xmlSafe);

    [_ctrl, _shown, _size, _bold, _align, _colour]
};

_args params [
    ["_hit", controlNull, [controlNull]],
    ["_fill", controlNull, [controlNull]],
    ["_labels", [], [[]]],
    ["_restFill", [], [[]]],
    ["_hoverFill", [], [[]]],
    ["_hoverText", [], [[]]]
];

if (isNull _hit) exitWith {};

_hit setVariable [QGVAR(tint), [_fill, _labels, _restFill, _hoverFill, _hoverText]];

{
    _x setVariable [QGVAR(tintHit), _hit];
    _x ctrlAddEventHandler ["MouseEnter", {
        params ["_ctrl"];
        [_ctrl, "hover"] call FUNC(supportTint);
    }];
    _x ctrlAddEventHandler ["MouseExit", {
        params ["_ctrl"];
        [_ctrl, "rest"] call FUNC(supportTint);
    }];
} forEach ([_hit] + (_labels apply {_x select 0}));

// The press repaints and lets the button go on to its click - false, so the
// release still raises ButtonClick.
_hit ctrlAddEventHandler ["MouseButtonDown", {
    params ["_ctrl", "_button"];
    if (_button isEqualTo 0) then {[_ctrl, "press"] call FUNC(supportTint)};
    false
}];
