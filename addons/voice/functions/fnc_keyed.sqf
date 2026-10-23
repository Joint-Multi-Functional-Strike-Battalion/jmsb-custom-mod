#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, event jmfsb_voice_keyed: a speaker who can be heard here keyed or
 * released his push-to-talk on a net (he sent it himself, fnc_transmit). The
 * adapter applies his volume for this listener at once (its "keyed" hook;
 * VON: setPlayerVoNVolume from the current quality) and counts him as
 * talking until his key-up; then the talking list is brought up to date in
 * the same call (fnc_talkSync), so jmfsb_voice_talk and the squelch come with
 * the event, not with the engine's report.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 * 2: Key down <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "C2", true] call jmfsb_voice_fnc_keyed
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]], ["_on", false, [false]]];

if (!hasInterface || isNull player || isNull _unit || _unit isEqualTo player) exitWith {};
[_unit, _net, _on] call HOOK("keyed");
[] call FUNC(talkSync);
