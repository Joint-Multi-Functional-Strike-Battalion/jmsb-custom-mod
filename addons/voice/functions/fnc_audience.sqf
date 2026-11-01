#include "script_component.hpp"
/*
 * Author: JMSB
 * The default "audience" hook: who a speaker's key event on a net goes to
 * (FUNC(transmit)) - every other player the SERVER has on that net
 * (FUNC(rosterNets)), not the speaker's own view of everyone's nets
 * (PLAN_VOICE_EW_PLAY V6: under the voice server a listener who is not told
 * never hears him). VEH: the crew of his vehicle. DIRECT: nobody (local voice
 * keys no net).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Players <ARRAY>
 *
 * Example:
 * [player, "C2"] call jmfsb_voice_fnc_audience
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]]];

if (isNull _unit || {_net in ["", NET_DIRECT]}) exitWith {[]};
if (_net isEqualTo NET_VEH) exitWith {([NET_VEH, _unit] call FUNC(members)) - [_unit]};

allPlayers select {
    _x isKindOf "CAManBase" && _x isNotEqualTo _unit && {_net in ([_x] call FUNC(rosterNets))}
}
