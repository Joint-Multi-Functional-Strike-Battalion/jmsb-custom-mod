#include "script_component.hpp"
/*
 * Author: YonV
 * One of the six keys printed on the tablet frame was pressed - clicked with
 * the mouse (FUNC(keyButtons)) or pressed on the numpad (FUNC(keyDown)):
 *
 * - F1-F4 (numpad 1-4) open the app the player set for that key, or close it
 *   when it is already on screen. Which app is his setting
 *   (jmfsb_devices_keyF1 .. keyF4); the keyboard's own F1-F4 keep selecting
 *   units.
 * - LEFT / RIGHT (numpad 0 / .) are the device arrows. While the call's window
 *   is over the tablet they step it round the corners (FUNC(callCorner)).
 *   Otherwise THEY TURN THE LIVE TILES' PAGE (user, 2026-10-31: "the arrows
 *   on the tablet should move the live tiles";
 *   jmfsb_tacpad_apps_fnc_tilePageStep) when the band has more than one, and
 *   with one page they scroll an open screen up / down (FUNC(scrollScreen)).
 *   They no longer step the active net: the net chips are buttons, numpad
 *   1-4 pick the chips of the page shown, and the net row's own < > buttons
 *   turn the net pages (FUNC(tabletNets), 2026-11-07).
 *
 * Arguments:
 * 0: Key index - 0..3 = F1..F4, 4 = LEFT, 5 = RIGHT <NUMBER>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [0] call jmfsb_devices_fnc_softKey
 *
 * Public: No
 */

params [["_index", -1, [0]]];

private _current = uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""];

if (_index >= 0 && _index < SOFT_KEY_COUNT) exitWith {
    private _app = [GVAR(keyF1), GVAR(keyF2), GVAR(keyF3), GVAR(keyF4)] select _index;
    if (_app isEqualTo "") exitWith {true};
    if (_app isEqualTo _current) then {
        [] call EFUNC(tacpad,appClose);
    } else {
        [_app, [], true] call EFUNC(tacpad,openApp);
    };
    true
};

if !(_index in [KEY_INDEX_LEFT, KEY_INDEX_RIGHT]) exitWith {false};
private _step = [-1, 1] select (_index isEqualTo KEY_INDEX_RIGHT);

// The call's window, while one is up, takes the arrows: its corner (user,
// 2026-10-28, FUNC(callCorner)).
if ([_step] call FUNC(callCorner)) exitWith {true};

// The live tiles' page, when there is more than one.
if ([_step] call EFUNC(tacpad_apps,tilePageStep)) exitWith {true};

// An open screen with more than it shows scrolls (FUNC(scrollScreen)).
[_step] call FUNC(scrollScreen);
true
