#include "script_component.hpp"
/*
 * Author: YonV
 * SELECT NET N - makes the Nth chip of the page the net row shows the active
 * net. The chip's number is the key (user, 2026-10-21: "a number that
 * corresponds to a numpad key"): numpad 1-4 for the page's four chips by
 * default; 5-9 are unbound (numpad 5-8 are the device keys, 9 the action
 * key) and, bound, name net buttons 5-9 across the pages - the rows then
 * turn to that button's page (FUNC(netChip)). Every one is a CBA keybind.
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

private _entry = [_number] call FUNC(netChip);
_entry params ["", "", ["_active", false, [false]], ["_netId", "", [""]], "", "", "", ["_kind", "", [""]]];
if (_netId isEqualTo "" || _kind isEqualTo NET_KIND_RING) exitWith {false};

// a button off the page shown turns the rows to its page
if (_number > NET_PAGE_SIZE || {[] call FUNC(keyOwned)}) then {GVAR(netPage) = floor ((_number - 1) / NET_PAGE_SIZE)};
if (!_active) then {[_netId] call EFUNC(voice,setActive)};
[] call FUNC(overlayTick);
true
