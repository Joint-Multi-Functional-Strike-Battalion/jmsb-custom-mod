#include "script_component.hpp"
/*
 * Author: YonV
 * The net a SELECT NET / MUTE NET key names - the number on the chip. In the
 * F-row layout (FUNC(keyOwned); Shift + F1-F8) key N is net button N, the
 * chips numbered 1-8 across both pages. In the numpad layout keys 1-4 (numpad
 * 1-4) are the chips of the page the rows show (FUNC(overlayNets)); keys 5-8
 * have no default and, bound by the player, are net buttons 5-8 whichever
 * page is shown (FUNC(netButtons)).
 *
 * Arguments:
 * 0: Key number, 1-based <NUMBER>
 *
 * Return Value:
 * The FUNC(overlayNets) entry, [] for none <ARRAY>
 *
 * Example:
 * private _entry = [2] call jmfsb_devices_fnc_netChip
 *
 * Public: No
 */

params [["_number", 0, [0]]];

if (_number < 1) exitWith {[]};
private _state = [] call FUNC(netButtons);
if (_number > NET_PAGE_SIZE || {[] call FUNC(keyOwned)}) exitWith {(_state select 0) param [_number - 1, []]};
([_state] call FUNC(overlayNets)) param [_number - 1, []]
