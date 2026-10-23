#include "script_component.hpp"
/*
 * Author: JMSB
 * One of the six keys printed on the tablet frame was pressed - clicked with
 * the mouse (FUNC(keyButtons)) or pressed on the numpad (FUNC(keyDown)):
 *
 * - F1-F4 (numpad 1-4) open the app the player set for that key, or close it
 *   when it is already on screen. Which app is his setting
 *   (jmfsb_devices_keyF1 .. keyF4); the keyboard's own F1-F4 keep selecting
 *   units.
 * - LEFT / RIGHT (numpad 0 / .) are the device arrows: they step the active
 *   voice net left / right (docs/DESIGN_VOICE.md, "Numpad"). Without the voice addon they step through
 *   the apps instead, as they always did.
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

if (!isNil QEFUNC(voice,stepActive)) exitWith {
    [_step] call EFUNC(voice,stepActive);
    true
};

// No voice addon: round the apps. With no app open, RIGHT opens the first and
// LEFT the last.
private _apps = keys EGVAR(tacpad,appHandlers);
if (_apps isEqualTo []) exitWith {true};
private _at = _apps find _current;
private _next = if (_at < 0) then {
    [count _apps - 1, 0] select (_step > 0)
} else {
    (_at + _step + count _apps) mod count _apps
};
[_apps select _next, [], true] call EFUNC(tacpad,openApp);
true
