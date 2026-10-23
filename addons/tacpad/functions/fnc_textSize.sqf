#include "script_component.hpp"
/*
 * Author: JMSB
 * The size a role is actually drawn at. The apps' text - TEXT_LABEL and
 * TEXT_BODY - is one pixel larger than the scale says (user, 2026-10-21: "make
 * the font on all the apps 1px larger, not the headers"); TEXT_TITLE (titles,
 * headers) and TEXT_DISPLAY are drawn as they are, and so is any size that is
 * not one of the roles (the device bars' own sizes).
 *
 * ONE PIXEL, WORKED OUT. FUNC(drawText) sets a size s at TEXT_BASE x pixelGrid x
 * HOST_K x textScale x uiScale x s pixels, so a pixel is the inverse of that -
 * the same one pixel at any resolution, UI scale or device size.
 *
 * FUNC(drawText) and FUNC(textH) both pass sizes through here, so a cell sized
 * for its text cannot disagree with the text drawn in it. A size already raised
 * is no longer a role and comes back as it is.
 *
 * Arguments:
 * 0: Size, as a multiple of the body size <NUMBER>
 *
 * Return Value:
 * Size to draw at <NUMBER>
 *
 * Example:
 * [TEXT_BODY] call jmfsb_tacpad_fnc_textSize
 *
 * Public: Yes
 */

params [["_size", 1, [0]]];

if !(_size in [TEXT_LABEL, TEXT_BODY]) exitWith {_size};
[_size, APP_TEXT_PX] call FUNC(textPx)
