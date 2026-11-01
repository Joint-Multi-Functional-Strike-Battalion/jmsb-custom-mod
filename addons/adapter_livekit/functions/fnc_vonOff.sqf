#include "script_component.hpp"
/*
 * Author: JMSB
 * GAME VON OFF (user, 2026-10-31: "no in-game VON"): under the voice server
 * every game channel's voice is off on this machine - Global, Side, Command,
 * Group, Vehicle, Direct and the custom channels - so Caps Lock reaching
 * Arma's own Push To Talk sends nothing, and a mission that leaves a channel
 * open does not send the voice twice. Chat is left as the mission set it.
 * Run at start, on his respawn, and every VON_OFF_TICK_S (a mission script
 * may turn a channel back on). Also under "none" while the server runs the
 * voice server: that machine has no voice at all.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Channels turned off now <NUMBER>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_vonOff
 *
 * Public: No
 */

if (!hasInterface) exitWith {0};

private _off = 0;
for "_ch" from 0 to VON_CHANNELS_MAX do {
    (channelEnabled _ch) params ["_chat", "_voice"];
    if (_voice) then {
        _ch enableChannel [_chat, false];
        _off = _off + 1;
    };
};
if (_off > 0) then {TRACE_1("game VON voice turned off",_off)};
_off
