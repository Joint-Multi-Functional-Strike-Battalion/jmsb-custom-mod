#include "script_component.hpp"
/*
 * Author: JMSB
 * A type size raised by a number of pixels - the same pixels at any
 * resolution, UI scale or device size. FUNC(drawText) sets a size s at
 * TEXT_BASE x pixelGrid x HOST_K x textScale x uiScale x s pixels, so one
 * pixel is the inverse of that.
 *
 * FUNC(textSize) uses it for the one pixel every app's text gets; an app that
 * wants more (the squad rail, the tiles' small lines - user, 2026-10-22: "2px
 * larger") asks here with APP_TEXT_UP_PX, and the answer is no longer a role,
 * so FUNC(textSize) passes it through as it is.
 *
 * Arguments:
 * 0: Size, as a multiple of the body size <NUMBER>
 * 1: Pixels to add <NUMBER>
 *
 * Return Value:
 * Size to draw at <NUMBER>
 *
 * Example:
 * [TEXT_BODY, APP_TEXT_UP_PX] call jmfsb_tacpad_fnc_textPx
 *
 * Public: Yes
 */

params [["_size", 1, [0]], ["_px", 0, [0]]];

_size + _px / (TEXT_BASE * pixelGrid * HOST_K * GVAR(textScale) * GVAR(uiScale))
