#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the custom channel for a key, made with radioChannelCreate the
 * first time it is needed and published to everyone (jmfsb_adapter_von_
 * channelMap). Custom channels the mission made itself are left alone; when
 * all ten are taken there is none.
 *
 * Arguments:
 * 0: Channel key <STRING>
 *
 * Return Value:
 * Custom channel id 1..10, 0 when none <NUMBER>
 *
 * Example:
 * ["C2"] call jmfsb_adapter_von_fnc_ensureChannel
 *
 * Public: No
 */

params [["_key", "", [""]]];

if (!isServer || _key isEqualTo "") exitWith {CUSTOM_NONE};
private _id = GVAR(customs) getOrDefault [_key, CUSTOM_NONE];
if (_id > CUSTOM_NONE) exitWith {_id};

// A CALL's key and an RTO net's key are both the net id; the kind tells them apart.
private _color = switch (_key) do {
    case KEY_C2: {COLOR_C2};
    case KEY_A2G: {COLOR_A2G};
    default {[COLOR_CALL, COLOR_CUSTOM] select (([_key] call EFUNC(voice,netKind)) isEqualTo KIND_CUSTOM)};
};
_id = radioChannelCreate [_color, _key, CHANNEL_CALLSIGN, []];
if (_id <= CUSTOM_NONE) exitWith {
    WARNING_1("no free custom channel for %1",_key);
    CUSTOM_NONE
};

GVAR(customs) set [_key, _id];
GVAR(channelMap) = (keys GVAR(customs)) apply {[_x, GVAR(customs) get _x]};
publicVariable QGVAR(channelMap);
[] call FUNC(countChannels);
INFO_2("custom channel %1 = %2",_id,_key);
_id
