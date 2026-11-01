#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "setActive", client: makes a net's channel the current VON
 * channel (setCurrentChannel). The game's push-to-talk key sends on the
 * current channel, so this is what makes the PTT talk on the active net.
 * VON refuses a custom channel the player is not (yet) a member of.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Set <BOOL>
 *
 * Example:
 * ["C2"] call jmfsb_adapter_von_fnc_setActive
 *
 * Public: No
 */

params [["_net", "", [""]]];

private _ch = [_net] call FUNC(channel);
if (_ch < 0) exitWith {false};
// Remembered, then placed by FUNC(applyOpen): under push to talk the mic goes
// to the net now, as it always did; under voice activation it goes there only
// when the open channel is NET or TALK NET is held (user, 2026-10-24).
private _was = GVAR(activeCh);
GVAR(activeCh) = _ch;
[] call FUNC(applyOpen);
// Under push to talk the mic must have moved: a call channel the server has
// not let him on yet does not take, so the net is not active and the caller
// tries again (jmfsb_voice wantActive) - activeCh is not left on it.
if (!GVAR(vad) && {!GVAR(holdLocal)} && {currentChannel isNotEqualTo _ch}) exitWith {
    GVAR(activeCh) = _was;
    false
};
true
