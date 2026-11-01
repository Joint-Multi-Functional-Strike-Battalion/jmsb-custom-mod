#include "script_component.hpp"
/*
 * Author: JMSB
 * Mutes or unmutes the net whose chip carries this number (user, 2026-10-25:
 * "Ctrl and press 1-6 make a toggle mute"). The same numbering as
 * FUNC(netSelect); the active net does not change.
 *
 * Arguments:
 * 0: Chip number, 1 based <NUMBER>
 *
 * Return Value:
 * Toggled <BOOL>
 *
 * Example:
 * [2] call jmfsb_devices_fnc_netMute
 *
 * Public: No
 */

params [["_number", 0, [0]]];

if (isNil QEFUNC(voice,setMute) || {isNil QEFUNC(voice,netState)}) exitWith {false};

private _entry = ([] call FUNC(overlayNets)) param [_number - 1, []];
_entry params ["", "", "", ["_netId", "", [""]], "", "", "", ["_kind", "", [""]]];
if (_netId isEqualTo "" || _kind isEqualTo NET_KIND_RING) exitWith {false};

private _state = ([] call EFUNC(voice,netState)) select {(_x param [0, ""]) isEqualTo _netId};
if (_state isEqualTo []) exitWith {false};

private _muted = !((_state select 0) param [4, false]);
[_netId, _muted] call EFUNC(voice,setMute);
["RADIO", format ["%1 %2.", (_state select 0) param [1, _netId], ["unmuted", "muted"] select _muted]] call EFUNC(notify,notify);
[] call FUNC(overlayTick);
true
