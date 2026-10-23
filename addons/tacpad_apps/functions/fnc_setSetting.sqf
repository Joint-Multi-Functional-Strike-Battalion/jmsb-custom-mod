#include "script_component.hpp"
/*
 * Author: JMSB
 * Changes one CBA setting from inside the game, then puts the change on screen.
 *
 * THROUGH CBA'S OWN SETTER (CBA_settings_fnc_set, the client source, stored),
 * so a change persists the way an Addon Options change does and CBA itself
 * puts the value into missionNamespace and runs the setting's change script.
 * A setting the server or mission forces is refused (FUNC(settingLocked)):
 * writing it here would only be put straight back. Only without CBA's settings
 * is the value written to missionNamespace by hand.
 *
 * Setting several at once is what `_apply` is for: writing a custom colour and
 * then switching the scheme to custom is one change from the player's side, and
 * rebuilding the whole suite twice for it would flicker the map and reopen this
 * screen underneath their cursor. Write the quiet ones first, apply on the last.
 *
 * Arguments:
 * 0: Setting name, the full jmfsb_..._name string <STRING>
 * 1: New value <ANY>
 * 2: Rebuild the suite and reopen the settings screen <BOOL> (optional, default true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [QGVAR(show_tiles), false] call jmfsb_tacpad_apps_fnc_setSetting
 *
 * Public: No
 */

params [["_name", "", [""]], ["_value", nil], ["_apply", true, [false]]];

if (_name == "" || {isNil "_value"}) exitWith {};

if ([_name] call FUNC(settingLocked)) exitWith {
    WARNING_1("setSetting: %1 is forced by the server or mission",_name);
};

// [setting, value, priority, source, store]. The store flag was being passed in
// the source slot, which wants a string - so every press logged a params type
// error and nothing was ever written back to the profile.
if (isNil "CBA_settings_fnc_set") then {
    missionNamespace setVariable [_name, _value];
} else {
    [_name, _value, false, "client", true] call CBA_settings_fnc_set;
};

// The settings that repaint rather than rebuild announce themselves, because a
// colour change has to reach panels that are already drawn.
[_name + "_changed", []] call CBA_fnc_localEvent;

if (!_apply) exitWith {};

// A knob that turned a panel on or off has changed which panels should exist,
// so the shell rebuilds the lot; everything else only needs a repaint and a
// redraw of the contents. Rebuilding both ways is cheap and always correct.
[] call EFUNC(tacpad,open);

// Reopen the settings screen so its own rows show what they now say. It was
// destroyed by the rebuild, and a settings list that still reads OFF after you
// turned something on is worse than no list.
[{
    ["settings"] call EFUNC(tacpad,openApp);
}] call CBA_fnc_execNextFrame;
