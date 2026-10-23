#include "script_component.hpp"
/*
 * Author: JMSB
 * Presses one of the six buttons printed on the walking view's frame - F1-F4,
 * LEFT, RIGHT - by its keybind: numpad 1-4, 0 and . by default
 * (docs/SPEC_TACNET.json D16).
 *
 * - WHILE THE RADIO APP IS OPEN on the phone or side device, they are its soft
 *   keys and its cursor (FUNC(radioKey)), whatever the settings say.
 * - OTHERWISE each does what the player set it to (jmfsb_devices_buttonF1 ..
 *   buttonRight; BUTTON_IDS). The defaults are the voice keys of
 *   docs/DESIGN_VOICE.md - F1 accept a call, F2 ear / quick add, F3 mute the
 *   active net, F4 decline / hang up, the arrows the active net left / right
 *   (FUNC(voiceAction)) - and every one can be set to another action.
 *
 * BY KEYBIND ONLY. The walking view is a title layer, which takes no mouse,
 * so the buttons cannot be clicked. A press does something only while the
 * walking view is up, and a voice action with nothing to act on (no call to
 * accept) is not consumed, so the key falls through to the game.
 *
 * Arguments:
 * 0: Button, 0-5 in printed order F1 F2 F3 F4 LEFT RIGHT <NUMBER>
 *
 * Return Value:
 * Handled - the key is consumed <BOOL>
 *
 * Example:
 * [0] call jmfsb_devices_fnc_overlayButton
 *
 * Public: No
 */

params [["_index", -1, [0]]];

if (isNull (uiNamespace getVariable [QGVAR(overlayDisplay), displayNull])) exitWith {false};

if (GVAR(radioOpen)) exitWith {
    [_index] call FUNC(radioKey)
};

private _action = [GVAR(buttonF1), GVAR(buttonF2), GVAR(buttonF3), GVAR(buttonF4), GVAR(buttonLeft), GVAR(buttonRight)] param [_index, BUTTON_NONE];
if (_action isEqualTo BUTTON_NONE) exitWith {false};

if (_action in BUTTON_VOICE) exitWith {
    private _done = [_action] call FUNC(voiceAction);
    if (_done) then {[] call FUNC(overlayTick)};
    _done
};

// The zoom is the player's CBA setting, stepped through the CBA API so it
// persists as Addon Options would keep it - and refused if the server forces
// it. No suite rebuild: the walking view reads the zoom every frame.
private _fnc_zoom = {
    params ["_delta"];
    [QGVAR(phoneZoom), _delta, ZOOM_MIN, ZOOM_MAX, ZOOM_DECIMALS, false] call EFUNC(tacpad_apps,settingStep);
};

switch (_action) do {
    case BUTTON_RADIO_APP: {[] call FUNC(radioApp)};
    case BUTTON_ZOOM_IN: {[-ZOOM_STEP] call _fnc_zoom};
    case BUTTON_ZOOM_OUT: {[ZOOM_STEP] call _fnc_zoom};
    case BUTTON_EDGE_LEFT: {["left"] call FUNC(overlaySetEdge)};
    case BUTTON_EDGE_RIGHT: {["right"] call FUNC(overlaySetEdge)};
    case BUTTON_HIDE: {
        [false] call FUNC(overlaySetShown);
        [] call FUNC(overlayTick);
    };
    case BUTTON_TABLET: {["large"] call FUNC(open)};
    default {
        // "app:<id>": the tablet, opened on that app. The shell builds its
        // panels a frame after the dialog opens (FUNC(onLoad)); queued after
        // that, the app opens over them rather than under.
        if ((_action find BUTTON_APP_PREFIX) isEqualTo 0 && {["large"] call FUNC(open)}) then {
            [{
                [_this, [], true] call EFUNC(tacpad,openApp);
            }, _action select [count BUTTON_APP_PREFIX]] call CBA_fnc_execNextFrame;
        };
    };
};

true
