#include "script_component.hpp"
/*
 * Author: JMSB
 * The Draw3D handler. Draws from the caches only - who is in range, how
 * visible and what colour they are were worked out by the per-frame handlers -
 * so a frame costs the projection of what is already known and nothing more.
 * The boxes themselves are UI controls (FUNC(drawBoxes)); when ECOTI is off
 * they are hidden.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_draw
 *
 * Public: No
 */

if ((GVAR(men) isEqualTo [] && {GVAR(vehicles) isEqualTo []}) || {!([] call FUNC(isActive))}) exitWith {
    if (GVAR(shown) > 0) then {[[]] call FUNC(drawBoxes)};
};

// The camera's axes, in metres, for boxes square to the screen.
private _camPos = positionCameraToWorld ORIGIN;
private _camFwd = vectorNormalized ((positionCameraToWorld [0, 0, 1]) vectorDiff _camPos);
private _camRight = vectorNormalized ((positionCameraToWorld [1, 0, 0]) vectorDiff _camPos);
private _camUp = vectorNormalized ((positionCameraToWorld [0, 1, 0]) vectorDiff _camPos);

// A full-screen goggle has no tube to look through, so the window is the screen.
private _window = [GVAR(windowSize), FULL_SCREEN_WINDOW] select ([] call FUNC(isFullScreen));

private _view = [_camPos, _camFwd, _camRight, _camUp, _window];

private _boxes = ((GVAR(men) apply {[_x, _view] call FUNC(manBox)}) + (GVAR(vehicles) apply {[_x, _view] call FUNC(vehicleBox)})) select {_x isNotEqualTo []};
_boxes resize ((count _boxes) min MAX_BOXES);

[_boxes] call FUNC(drawBoxes);
