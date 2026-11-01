#include "script_component.hpp"
/*
 * Author: JMSB
 * Holds one game channel's voice off while a refused PTT 2-4 key is down
 * (FUNC(applyOpen)), so the engine's Push To Talk, which sends on the current
 * channel, sends nothing; CH_NONE gives back the one held. Its chat is left
 * alone; its voice comes back only if it was on, and FUNC(channels) puts every
 * channel right on its next tick after that.
 *
 * Arguments:
 * 0: Channel to hold off, CH_NONE to give back <NUMBER> (default: CH_NONE)
 *
 * Return Value:
 * None
 *
 * Example:
 * [currentChannel] call jmfsb_adapter_von_fnc_holdOff
 *
 * Public: No
 */

params [["_ch", CH_NONE, [0]]];

GVAR(holdOff) params [["_held", CH_NONE, [0]], ["_voiceWas", false, [false]]];
if (_held isEqualTo _ch) exitWith {};

if (_held > CH_NONE) then {
    (channelEnabled _held) params ["_chat", "_voice"];
    if (_voiceWas && !_voice) then {_held enableChannel [_chat, true]};
    GVAR(holdOff) = [];
};
if (_ch > CH_NONE) then {
    (channelEnabled _ch) params ["_chat", "_voice"];
    GVAR(holdOff) = [_ch, _voice];
    if (_voice) then {_ch enableChannel [_chat, false]};
};
TRACE_2("holdOff",_held,_ch);
