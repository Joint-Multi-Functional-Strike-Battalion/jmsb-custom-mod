#include "script_component.hpp"
/*
 * Author: JMSB
 * The EachFrame guard that takes the boxes and the compass down when something
 * covers the world view - the map, the tablet or any other dialog.
 *
 * WHY NOT IN FUNC(draw). FUNC(draw) is the Draw3D handler, and Arma does not
 * call Draw3D while the full-screen map is up: the scene is not rendered, so the
 * hide in FUNC(draw) never ran and the last frame's boxes stayed on the mission
 * display, over the map and the tablet (user, 2026-10-20: "the box around
 * vehicles still bleeds through to the tablet and map"). EachFrame runs every
 * frame whatever is on screen, so the guard lives here.
 *
 * Two tests: something covers the view (map or dialog), or Draw3D has not run
 * for more than a frame - which catches every other case where the scene is not
 * drawn without having to name it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_hideCovered
 *
 * Public: No
 */

if (GVAR(shown) isEqualTo 0 && {!GVAR(compassShown)}) exitWith {};

private _covered = visibleMap || {dialog} || {diag_frameNo - GVAR(drawFrame) > DRAW_FRAME_GAP};
if (!_covered) exitWith {};

[[]] call FUNC(drawBoxes);
[false] call FUNC(drawCompass);
