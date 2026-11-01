#include "script_component.hpp"
/*
 * Author: JMSB
 * The PTT keys while other modifiers are held. A CBA keybind fires only on its
 * exact modifiers, so a PTT on CapsLock would not key while sprinting (Shift)
 * - TFAR hooks the mission display's keys for its own PTT for the same reason
 * (core/functions/events/keys/fnc_onTangentPressedHack.sqf). This is that
 * hook for our four PTT keybinds: a press matches a binding when the key is
 * its key and every modifier it asks for is held (extra ones are fine); the
 * binding asking for the most modifiers wins, so Ctrl+CapsLock (long range)
 * beats CapsLock (short range). A release of the key releases it.
 *
 * fnc_ptt presses and releases once, so the keybind and this hook seeing the
 * same press is harmless.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Key <NUMBER>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
 * 5: Down (KeyDown) or up (KeyUp) <BOOL>
 *
 * Return Value:
 * false - never consumes the key <BOOL>
 *
 * Example:
 * (_this + [true]) call jmfsb_adapter_tfar_fnc_pttKey
 *
 * Public: No
 */

params ["", ["_key", 0, [0]], ["_shift", false, [false]], ["_ctrl", false, [false]], ["_alt", false, [false]], ["_down", true, [false]]];

if (_key <= 0) exitWith {false};

private _held = [_shift, _ctrl, _alt];
private _best = "";
private _bestMods = -1;
{
    private _action = _x select 0;
    private _keybind = [JMFSB_CATEGORY, format ["%1_%2", QGVAR(ptt), _action]] call CBA_fnc_getKeybind;
    if (isNil "_keybind") then {continue};
    {
        _x params [["_code", 0, [0]], ["_mods", [false, false, false], [[]]]];
        if (_code != _key) then {continue};
        if (!_down) then {
            [_action, false] call FUNC(ptt);
            continue;
        };
        private _asked = {_x isEqualTo true} count _mods;
        private _met = true;
        {
            if (_x isEqualTo true && {!(_held param [_forEachIndex, false])}) exitWith {_met = false};
        } forEach _mods;
        if (_met && _asked > _bestMods) then {
            _best = _action;
            _bestMods = _asked;
        };
    } forEach (_keybind param [8, [], [[]]]);
} forEach PTT_KEYS;

if (_best isNotEqualTo "") then {[_best, true] call FUNC(ptt)};
false
