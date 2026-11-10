#include "script_component.hpp"
/*
 * Author: YonV
 * Hook "ptt": the local player's own push-to-talk, asked every frame by the
 * voice core (jmfsb_voice_fnc_frame), which sends the key edge to the net and
 * plays the cues. A PTT key held: down on that key's net (the last pressed
 * wins); TALK LOCAL held: down on no net - local voice keys nothing, every
 * listener hears it by distance (FUNC(gainOf)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [down, net id] <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_ptt
 *
 * Public: No
 */

if (isNull player) exitWith {[false, LOCAL_NET]};
if (GVAR(heldPtt) isNotEqualTo []) exitWith {
    [true, [GVAR(heldPtt) select -1] call EFUNC(voice,pttNet)]
};
[GVAR(holdLocal), LOCAL_NET]
