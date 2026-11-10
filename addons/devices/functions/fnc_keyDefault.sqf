#include "script_component.hpp"
/*
 * Author: YonV
 * A device key's default for the key layout the player picked (user,
 * 2026-11-08: the F row by default, the numpad standard as the setting's
 * other choice; GVAR(keyLayout), KEY_LAYOUT_TABLE). Every addon registering
 * one of these keys asks here, so Configure Addons' DEFAULT button resets to
 * the layout in use.
 *
 * Arguments:
 * 0: Keybind action id, as CBA_fnc_addKeybind takes it <STRING>
 * 1: Fallback, for an action the layout does not name <ARRAY>
 *
 * Return Value:
 * [key, [shift, ctrl, alt]] <ARRAY>
 *
 * Example:
 * [QGVAR(answerKey), [KEY_ANSWER, [false, false, false]]] call jmfsb_devices_fnc_keyDefault
 *
 * Public: Yes
 */

params [["_action", "", [""]], ["_fallback", [KEY_NONE, KEYBIND_NO_MODS], [[]]]];

GVAR(keyDefaults) getOrDefault [toLower _action, _fallback]
