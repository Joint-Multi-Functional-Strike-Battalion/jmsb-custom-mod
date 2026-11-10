#include "script_component.hpp"
/*
 * Author: YonV
 * The size a role is actually drawn at. The apps' text - TEXT_LABEL and
 * TEXT_BODY - is one pixel larger than the scale says (user, 2026-10-21: "make
 * the font on all the apps 1px larger, not the headers"); TEXT_TITLE (titles,
 * headers) and TEXT_DISPLAY are drawn as they are, and so is any size that is
 * not one of the roles (the device bars' own sizes). TEXT_BODY is raised two
 * pixels more, to the tiles' detail size (tablet review 2026-11-01, R1).
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
// BODY TEXT AND VALUES NEVER SMALLER THAN A TILE'S DETAIL LINE (tablet review
// 2026-11-01, R1): TEXT_BODY is drawn at the tiles' small-text size, TEXT_BODY
// raised by APP_TEXT_UP_PX (FUNC(textPx), jmfsb_tacpad_apps_fnc_panelTiles);
// labels, kickers and hints stay APP_TEXT_PX up.
[_size, [APP_TEXT_PX, APP_TEXT_UP_PX] select (_size isEqualTo TEXT_BODY)] call FUNC(textPx)
