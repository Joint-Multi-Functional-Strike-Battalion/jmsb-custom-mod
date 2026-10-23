#include "script_component.hpp"
/*
 * Author: JMSB
 * SELECT NET N - makes the Nth chip of the net row the active net. The chip's
 * number is the key (user, 2026-10-21: "a number that corresponds to a numpad
 * key"): numpad 1-4 for nets 1-4 by default, 5-9 unbound because numpad 5-9
 * are the tablet, RADIO, its tabs and TIC. Every one is a CBA keybind.
 *
 * Not consumed when there is no such net or it is the ringing cell, so the
 * key falls through to the game.
 *
 * Arguments:
 * 0: Net number, 1-based <NUMBER>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [2] call jmfsb_devices_fnc_netSelect
 *
 * Public: No
 */

params [["_number", 0, [0]]];

if (isNil QEFUNC(voice,setActive)) exitWith {false};

private _entry = ([] call FUNC(overlayNets)) param [_number - 1, []];
_entry params ["", "", ["_active", false, [false]], ["_netId", "", [""]], "", "", "", ["_kind", "", [""]]];
if (_netId isEqualTo "" || _kind isEqualTo NET_KIND_RING) exitWith {false};
if (_active) exitWith {true};

[_netId] call EFUNC(voice,setActive);
[] call FUNC(overlayTick);
true
