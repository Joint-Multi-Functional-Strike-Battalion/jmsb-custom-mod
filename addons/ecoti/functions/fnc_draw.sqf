#include "script_component.hpp"
/*
 * Author: YonV
 * The Draw3D handler. Draws from the caches only - who is in range, how
 * visible and what colour they are were worked out by the per-frame handlers -
 * so a frame costs the projection of what is already known and nothing more.
 * The boxes themselves are UI controls (FUNC(drawBoxes)); when ECOTI is off
 * they are hidden. The compass (FUNC(drawCompass)) and the side's LZs and DZs
 * (FUNC(drawZones), 2026-11-02) are shown and hidden here too, on the same test.
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

// NOT THROUGH A DIALOG. The boxes are controls on the mission display and a
// dialog - the tablet - sits over it; they drew straight through the screen
// (user, 2026-10-18). Hidden while any dialog is up, back when it closes.
GVAR(drawFrame) = diag_frameNo;

private _active = !dialog && {[] call FUNC(isActive)};

// The compass shows exactly when the boxes could - whether or not anyone is in
// range - and only if the player wants it.
[_active && GVAR(compass)] call FUNC(drawCompass);

// A full-screen goggle has no tube to look through, so the window is the screen.
private _window = [GVAR(windowSize), FULL_SCREEN_WINDOW] select ([] call FUNC(isFullScreen));

// The side's open LZs and DZs (user, 2026-11-02) - on the same test, at any
// range, whether or not anyone is in range (FUNC(drawZones)).
[_active, _window] call FUNC(drawZones);

if (!_active || {GVAR(men) isEqualTo [] && {GVAR(vehicles) isEqualTo [] && {GVAR(buildings) isEqualTo []}}}) exitWith {
    if (GVAR(shown) > 0) then {[[]] call FUNC(drawBoxes)};
};

// The camera's axes, in metres, for boxes square to the screen.
private _camPos = positionCameraToWorld ORIGIN;
private _camFwd = vectorNormalized ((positionCameraToWorld [0, 0, 1]) vectorDiff _camPos);
private _camRight = vectorNormalized ((positionCameraToWorld [1, 0, 0]) vectorDiff _camPos);
private _camUp = vectorNormalized ((positionCameraToWorld [0, 1, 0]) vectorDiff _camPos);

private _view = [_camPos, _camFwd, _camRight, _camUp, _window];

// The marked buildings (2026-11-06) go first: a mark is what the player was
// told to look for, and is never cut by MAX_BOXES.
private _boxes = ((GVAR(buildings) apply {[_x, _view] call FUNC(buildingBox)}) + (GVAR(men) apply {[_x, _view] call FUNC(manBox)}) + (GVAR(vehicles) apply {[_x, _view] call FUNC(vehicleBox)})) select {_x isNotEqualTo []};
_boxes resize ((count _boxes) min MAX_BOXES);

[_boxes] call FUNC(drawBoxes);
