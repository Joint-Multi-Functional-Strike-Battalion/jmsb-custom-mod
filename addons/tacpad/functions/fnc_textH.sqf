#include "script_component.hpp"
/*
 * Author: JMSB
 * How tall one line of text is at a given size, in safe-zone Y units.
 *
 * A control that holds a label has to be sized off the label, not off a row
 * height that happens to look right on one machine. Text scales with the
 * player's UI scale and with the suite's own text setting; a cell that is a
 * fixed fraction of ROW_H does neither, and at a large UI scale its own border
 * is drawn through the middle of its word.
 *
 * Arguments:
 * 0: Size, as a multiple of the body size <NUMBER> (optional, default 1)
 *
 * Return Value:
 * Line height <NUMBER>
 *
 * Example:
 * private _cellH = ([0.9] call jmfsb_tacpad_fnc_textH) + 2 * _padY
 *
 * Public: Yes
 */

params [["_size", 1, [0]]];
_size = [_size] call FUNC(textSize);

// The 1.25 is the leading FUNC(drawText) lays a single line out with. Both read
// it from here so a box sized against this cannot disagree with the text put in
// it.
TEXT_BASE * pixelH * pixelGrid * HOST_K * GVAR(textScale) * GVAR(uiScale) * _size * 1.25
