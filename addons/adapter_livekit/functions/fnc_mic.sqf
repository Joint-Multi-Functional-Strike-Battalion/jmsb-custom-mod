#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens or closes the mic on the voice server from what is held
 * (FUNC(hold)): a PTT key opens it when the key's net (jmfsb_voice_fnc_pttNet)
 * is one the player is on and the voice core's cut-off level allows the net
 * (radio silence closes radio nets, unconscious the intercom too); TALK LOCAL
 * opens it unless he is dead or out of air. Only while the room is live. Sent
 * to the extension on a change only. The voice core's own key edge, cues and
 * refusals come through its "ptt" hook (FUNC(ptt)) in the same frame.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Mic open <BOOL>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_mic
 *
 * Public: No
 */

private _open = false;
if (GVAR(state) isEqualTo ROOM_LIVE && {!isNull player}) then {
    if (GVAR(heldPtt) isNotEqualTo []) then {
        private _net = [GVAR(heldPtt) select -1] call EFUNC(voice,pttNet);
        _open = _net isNotEqualTo LOCAL_NET
            && {GVAR(level) < ([_net] call EFUNC(voice,blockNeed))}
            && {_net in (([player] call EFUNC(voice,nets)) apply {_x select 0})};
    } else {
        _open = GVAR(holdLocal) && GVAR(level) < BLOCK_ALL;
    };
};

if (_open isEqualTo GVAR(mic)) exitWith {_open};
GVAR(mic) = _open;
["talk", [_open]] call FUNC(ext);
TRACE_1("mic",_open);
_open
