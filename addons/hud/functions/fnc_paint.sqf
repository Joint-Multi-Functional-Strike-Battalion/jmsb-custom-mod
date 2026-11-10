#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a list of draw ops on a slot: builds the controls once, and after that
 * only changes their text, colour and size.
 *
 * BUILT ONCE, UPDATED IN PLACE (review P5 / R8). The slot used to be emptied
 * and refilled every second - every control in both slots deleted and made
 * again, found by walking every control on the mission display. Now the
 * controls a slot holds are kept on the slot itself, in op order, and a tick
 * that draws the same shape as the last one only touches what changed.
 *
 * WHEN IT REBUILDS. The slot's key changed (which readout, the box, the scheme,
 * the opacity, the text and UI scale, the host, the resolution), or the op
 * list's SHAPE changed: a different count, a different kind at some place in
 * the list, or a text, frame or icon laid out differently. A rebuild is the
 * tacpad helper called with exactly the args the op carries, which is what the
 * readouts always did - so a rebuilt slot is the old slot, pixel for pixel.
 *
 * WHAT IT UPDATES IN PLACE, and why each is the same pixels:
 * - fill: position and background colour, the only two things drawFill sets.
 * - frame: the edge colour. Its box is part of the shape.
 * - text: the structured text, built with drawText's own markup. Position,
 *   size, weight, alignment, tracking and font are part of the shape, so the
 *   control's box and font height are the ones drawText set.
 * - icon: position, texture and tint, the three things drawIcon sets. Whether
 *   it has a tint at all is part of the shape (a tint cannot be unset).
 *
 * Arguments:
 * 0: The slot control <CONTROL>
 * 1: The slot's key - anything whose change must rebuild it <ARRAY>
 * 2: Draw ops, [kind, args] each - kind is one of the HUD_OP_* defines <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_slotCtrl, [_id, _pos], [[HUD_OP_FILL, [[0, 0, _w, _h], _ground]]]] call jmfsb_hud_fnc_paint
 *
 * Public: No
 */

params [["_group", controlNull, [controlNull]], ["_key", [], [[]]], ["_ops", [], [[]]]];

if (isNull _group) exitWith {};

// THE SHAPE: everything about an op that fixes where and how its controls sit,
// and nothing that merely changes what they say or what colour they are.
private _shape = _ops apply {
    _x params ["_kind", "_args"];
    switch (_kind) do {
        case HUD_OP_TEXT: {
            _args params ["_pos", "", "", ["_size", 1], ["_bold", false], ["_align", "left"], ["_tracked", false], ["_font", ""]];
            [_kind, _pos, _size, _bold, _align, _tracked, _font]
        };
        case HUD_OP_FRAME: {
            _args params ["_pos", "", ["_weight", 1], ["_dashed", false]];
            [_kind, _pos, _weight, _dashed]
        };
        case HUD_OP_ICON: {
            _args params ["", "", ["_tint", []]];
            [_kind, _tint isEqualTo []]
        };
        default {[_kind]};
    }
};

// A copy, so a colour array shared with the tacpad's theme cache can never be
// changed under the comparison below.
private _now = +(_ops apply {_x select 1});

// [key, shape, controls per op, args per op] - what this slot holds now.
private _built = _group getVariable [QGVAR(built), []];
_built params [
    ["_wasKey", [], [[]]],
    ["_wasShape", [], [[]]],
    ["_children", [], [[]]],
    ["_was", [], [[]]]
];

private _rebuild = _built isEqualTo []
    || _wasKey isNotEqualTo _key
    || _wasShape isNotEqualTo _shape;

if (_rebuild) exitWith {
    {
        {ctrlDelete _x} forEach _x;
    } forEach _children;

    // In op order, which is creation order, which is the stacking order the
    // readouts were written for.
    private _made = _ops apply {
        _x params ["_kind", "_args"];
        private _full = [_group] + _args;
        switch (_kind) do {
            case HUD_OP_FRAME: {_full call EFUNC(tacpad,drawFrame)};
            case HUD_OP_TEXT: {[_full call EFUNC(tacpad,drawText)]};
            case HUD_OP_ICON: {[_full call EFUNC(tacpad,drawIcon)]};
            default {[_full call EFUNC(tacpad,drawFill)]};
        }
    };

    _group setVariable [QGVAR(built), [+_key, _shape, _made, _now]];
};

// SAME SHAPE: change only what changed, op by op, on the control made for it.
{
    private _args = _x;
    if (_args isEqualTo (_was select _forEachIndex)) then {continue};

    private _kind = (_ops select _forEachIndex) select 0;
    private _ctrls = _children select _forEachIndex;

    if (_kind isEqualTo HUD_OP_FILL) then {
        _args params ["_pos", "_colour"];
        private _ctrl = _ctrls select 0;
        _ctrl ctrlSetPosition _pos;
        _ctrl ctrlSetBackgroundColor _colour;
        _ctrl ctrlCommit 0;
    };

    if (_kind isEqualTo HUD_OP_FRAME) then {
        private _colour = _args select 1;
        {_x ctrlSetBackgroundColor _colour} forEach _ctrls;
    };

    if (_kind isEqualTo HUD_OP_ICON) then {
        _args params ["_pos", "_texture", ["_tint", []]];
        _pos params ["_ix", "_iy", "_ih"];
        private _ctrl = _ctrls select 0;
        _ctrl ctrlSetPosition [_ix, _iy, _ih * pixelW / pixelH, _ih];
        _ctrl ctrlSetText _texture;
        if (_tint isNotEqualTo []) then {
            _ctrl ctrlSetTextColor _tint;
        };
        _ctrl ctrlCommit 0;
    };

    if (_kind isEqualTo HUD_OP_TEXT) then {
        _args params ["", "_text", "_colour", ["_size", 1], ["_bold", false], ["_align", "left"], ["_tracked", false], ["_font", ""]];

        // drawText's own markup, step for step: the face for the role, the
        // size through textSize, tracking before escaping.
        private _face = switch (true) do {
            case (_font isEqualTo FONT_MONO): {[FONT_MONO, FONT_MONO_BOLD] select _bold};
            case (_font isNotEqualTo ""): {_font};
            default {[FONT_LABEL, FONT_LABEL_BOLD] select _bold};
        };
        if (_tracked) then {
            _text = (toUpper _text) splitString "" joinString " ";
        };
        _text = [_text] call EFUNC(tacpad,xmlSafe);

        (_ctrls select 0) ctrlSetStructuredText parseText format [
            "<t font='%1' size='%2' align='%3' color='%4'>%5</t>",
            _face,
            [_size] call EFUNC(tacpad,textSize),
            _align,
            _colour call BIS_fnc_colorRGBAtoHTML,
            _text
        ];
    };
} forEach _now;

_group setVariable [QGVAR(built), [_wasKey, _wasShape, _children, _now]];
