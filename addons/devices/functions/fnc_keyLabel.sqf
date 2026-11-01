#include "script_component.hpp"
/*
 * Author: JMSB
 * One of the mod's CBA keybinds as the player has it bound, for a line that
 * tells him which key to press: modifiers, then the key's own name - "NUM 9",
 * "CTRL+NUM 4"; UNBOUND when he cleared it, -- when there is no such bind.
 *
 * Arguments:
 * 0: Keybind action id, in the JMSB category <STRING>
 *
 * Return Value:
 * Key label, upper case <STRING>
 *
 * Example:
 * [QEGVAR(tacpad_apps,ticKey)] call jmfsb_devices_fnc_keyLabel
 *
 * Public: No
 */

params [["_action", "", [""]]];

private _bind = [JMFSB_CATEGORY, _action] call CBA_fnc_getKeybind;
if (isNil "_bind") exitWith {KEY_LABEL_NONE};

(_bind param [5, [0, []]]) params [["_dik", 0, [0]], ["_mods", [], [[]]]];
if (_dik <= 1) exitWith {KEY_LABEL_UNBOUND};

private _words = [];
{
    if (_mods param [_forEachIndex, false]) then {_words pushBack _x};
} forEach ["SHIFT", "CTRL", "ALT"];
_words pushBack (((keyName _dik) splitString """") joinString "");

toUpper (_words joinString "+")
