#include "script_component.hpp"
/*
 * Author: JMSB
 * Sets the words and colour of a line FUNC(drawText) made, in place: the same
 * type role, face, tracking and escaping, so a line updated on a tick reads
 * exactly as it did when it was drawn. FUNC(drawText) sets its text through
 * this, so there is one way a line is written.
 *
 * THE BOX DOES NOT MOVE. The control keeps the position and font height it was
 * drawn with - those come from the size, which a live screen keeps in its
 * change key - so only what it says and its colour change. A line already
 * saying this is left alone.
 *
 * Arguments:
 * 0: The line <CONTROL>
 * 1: Text <STRING>
 * 2: RGBA <ARRAY>
 * 3: Size, as a multiple of the body size <NUMBER> (optional, default 1)
 * 4: Bold <BOOL> (optional, default false)
 * 5: Alignment - "left", "right" or "center" <STRING> (optional, default "left")
 * 6: Track the letters, and uppercase them <BOOL> (optional, default false)
 * 7: Font - "" for the label face, FONT_MONO for numbers <STRING> (optional, default "")
 *
 * Return Value:
 * Changed <BOOL>
 *
 * Example:
 * [_ctrl, "12:04", _ink, TEXT_TITLE, true] call jmfsb_tacpad_fnc_retext
 *
 * Public: No
 */

params [
    ["_ctrl", controlNull, [controlNull]],
    ["_text", "", [""]],
    ["_color", [0, 0, 0, 1], [[]]],
    ["_size", 1, [0]],
    ["_bold", false, [false]],
    ["_align", "left", [""]],
    ["_tracked", false, [false]],
    ["_font", "", [""]]
];

if (isNull _ctrl) exitWith {false};

// THE TWO TYPE ROLES (notes, 2026-10-30): words in the sans, numbers in the
// monospace; bold picks the bold cut of either.
private _face = switch (true) do {
    case (_font isEqualTo FONT_MONO): {[FONT_MONO, FONT_MONO_BOLD] select _bold};
    case (_font isNotEqualTo ""): {_font};
    default {[FONT_LABEL, FONT_LABEL_BOLD] select _bold};
};

// The apps' label and body text, one pixel up (FUNC(textSize)).
_size = [_size] call FUNC(textSize);

if (_tracked) then {
    _text = (toUpper _text) splitString "" joinString " ";
};

// After the tracking, so the spacing is applied to the glyphs the caller wrote
// rather than to the innards of an escape sequence.
_text = [_text] call FUNC(xmlSafe);

private _markup = format [
    "<t font='%1' size='%2' align='%3' color='%4'>%5</t>",
    _face,
    _size,
    _align,
    _color call BIS_fnc_colorRGBAtoHTML,
    _text
];
if (_markup isEqualTo (_ctrl getVariable [QGVAR(markup), ""])) exitWith {false};

_ctrl setVariable [QGVAR(markup), _markup];
_ctrl ctrlSetStructuredText parseText _markup;
true
