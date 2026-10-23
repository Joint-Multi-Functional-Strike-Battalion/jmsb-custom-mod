#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: how many of the engine's ten custom channels are in use - ours (C2,
 * A2G, the CALL slots) and any the mission made itself - published to everyone
 * as jmfsb_adapter_von_channelUse [used, CUSTOM_MAX] for the devices' gauge
 * (user, 2026-10-21: "a net use % of the 10 custom channels"). Run whenever we
 * make a channel and once after the fixed ones.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Channels in use <NUMBER>
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_countChannels
 *
 * Public: No
 */

if (!isServer) exitWith {0};

private _used = 0;
for "_i" from 1 to CUSTOM_MAX do {
    if ((radioChannelInfo _i) param [CHANNEL_INFO_EXISTS, false]) then {_used = _used + 1};
};
// Ours count even if the engine's answer lags a frame behind the create.
_used = _used max count GVAR(customs);

private _use = [_used, CUSTOM_MAX];
if (_use isNotEqualTo (missionNamespace getVariable [QGVAR(channelUse), []])) then {
    GVAR(channelUse) = _use;
    publicVariable QGVAR(channelUse);
};
_used
