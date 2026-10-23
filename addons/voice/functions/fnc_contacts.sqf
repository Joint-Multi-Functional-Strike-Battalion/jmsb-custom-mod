#include "script_component.hpp"
/*
 * Author: JMSB
 * Everyone on the local player's side he could call: reachable = he reaches
 * them on DATA now (a call needs it); inCall = in a call or ringing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[unit, name, callsign, role tags ("SL"|"RTO"|"MEDIC"|"HQ"), reachable, inCall], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_contacts
 *
 * Public: Yes
 */

if (!GVAR(active)) exitWith {[]};
if (isNull player) exitWith {[]};

private _side = side group player;
(allPlayers select {_x isKindOf "CAManBase" && _x isNotEqualTo player && side group _x isEqualTo _side}) apply {
    [
        _x,
        name _x,
        groupId group _x,
        [_x] call FUNC(roles),
        ([_x, NET_DATA] call FUNC(linkQuality)) > 0,
        ([_x] call FUNC(inCall)) isNotEqualTo ""
    ]
}
