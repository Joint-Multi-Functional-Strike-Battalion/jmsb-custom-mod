#include "script_component.hpp"
/*
 * Author: JMSB
 * One line of text, in one of the system's type roles.
 *
 * Every panel used to build its own <t> tag with format, which is how five
 * panels ended up with five different ideas of what a kicker looks like. The
 * roles are the design's: a micro-label, a value, a subject, a detail line.
 *
 * THE LINE IS CENTRED IN THE RECTANGLE IT IS GIVEN. Structured text renders at
 * the top of its control, so a label in a row-height box sits against the row
 * above it with all the air underneath - which is what made the roster read as
 * gappy and the tool cells look mispositioned. The caller hands over the box the
 * text belongs in and gets the text in the middle of it.
 *
 * TRACKING IS FAKED. The design sets its micro-labels at 0.16em letter-spacing
 * and Arma's structured text has no letter-spacing at all, so a tracked label is
 * drawn with a space between each character. It is only ever asked for on the
 * short uppercase kickers - WEATHER, FLASH, SQUAD - because on a sentence it
 * would be both unreadable and far too wide.
 *
 * Arguments:
 * 0: Parent <CONTROL>
 * 1: Position [x, y, w, h], relative to the parent <ARRAY>
 * 2: Text <STRING>
 * 3: RGBA <ARRAY>
 * 4: Size, as a multiple of the body size <NUMBER> (optional, default 1)
 * 5: Bold <BOOL> (optional, default false)
 * 6: Alignment - "left", "right" or "center" <STRING> (optional, default "left")
 * 7: Track the letters, and uppercase them <BOOL> (optional, default false)
 *
 * Return Value:
 * The control <CONTROL>
 *
 * Example:
 * [_body, [_pad, 0, _w, _rowH], "WEATHER", _ink, TEXT_TITLE, true, "left", true] call jmfsb_tacpad_fnc_drawText
 *
 * Public: Yes
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_pos", [0, 0, 0, 0], [[]], 4],
    ["_text", "", [""]],
    ["_color", [0, 0, 0, 1], [[]]],
    ["_size", 1, [0]],
    ["_bold", false, [false]],
    ["_align", "left", [""]],
    ["_tracked", false, [false]]
];

if (isNull _parent) exitWith {controlNull};

// The apps' label and body text, one pixel up (FUNC(textSize)).
_size = [_size] call FUNC(textSize);

if (_tracked) then {
    _text = (toUpper _text) splitString "" joinString " ";
};

// After the tracking, so the spacing is applied to the glyphs the caller wrote
// rather than to the innards of an escape sequence.
_text = [_text] call FUNC(xmlSafe);

_pos params ["_x", "_y", "_w", "_h"];

private _fontH = TEXT_BASE * pixelH * pixelGrid * HOST_K * GVAR(textScale) * GVAR(uiScale);

// One line occupies a little more than its font height. The box is shrunk to
// that and dropped to the middle of what the caller asked for, which is what
// puts the text in the centre rather than against the top edge. FUNC(textH)
// returns the same number, so a caller can size a cell to fit its own label.
private _lineH = [_size] call FUNC(textH);

// THE BOX IS THE LINE. It was `_lineH max _h` while the top was still dropped
// by half the difference - so whenever the line was SHORTER than the caller's
// box, which is the common case, the control hung below that box by the same
// half it had been dropped. A label not WHOLLY inside a hit is a label
// FUNC(drawHit) will not claim, and an unclaimed label eats every press that
// lands on it: the only clickable part of the cell was the sliver above the
// label. "The clickable area seems confined, it is hard to find" (user,
// 2026-09-05, of the PAC tab row) is exactly that sliver, and "nothing
// happens" was the same sliver while the header hit still covered it.
//
// Taller-than-the-box lines are unchanged - the top is not dropped at all
// then, and the box is the line either way, which is what FUNC(appFrame)
// sizes its CLOSE hit against.
private _ctrl = (ctrlParent _parent) ctrlCreate [QGVAR(cell), -1, _parent];
_ctrl ctrlSetPosition [_x, _y + ((_h - _lineH) max 0) * 0.5, _w, _lineH];

// The control's own font height is the body size; the tag scales off it. Set
// before the text, because structured text is laid out when it is assigned.
_ctrl ctrlSetFontHeight _fontH;
_ctrl ctrlSetStructuredText parseText format [
    "<t font='%1' size='%2' align='%3' color='%4'>%5</t>",
    ["RobotoCondensed", "RobotoCondensedBold"] select _bold,
    _size,
    _align,
    _color call BIS_fnc_colorRGBAtoHTML,
    _text
];
_ctrl ctrlCommit 0;

// REGISTERED FOR THE HIT THAT MAY COVER IT. A structured text control takes the
// mouse press and cannot act on it, so a label lying over a button is a hole in
// that button - see FUNC(drawHit), which hands the press on. The list is kept on
// the parent and stamped with the frame it was built in, so it is this draw's
// labels and not the last one's, and so drawHit does not have to walk every
// control on the display to find them.
if ((_parent getVariable [QGVAR(labelFrame), -1]) isNotEqualTo diag_frameNo) then {
    _parent setVariable [QGVAR(labelFrame), diag_frameNo];
    _parent setVariable [QGVAR(labels), []];
};

private _labels = _parent getVariable [QGVAR(labels), []];
_labels pushBack _ctrl;
_parent setVariable [QGVAR(labels), _labels];

_ctrl
