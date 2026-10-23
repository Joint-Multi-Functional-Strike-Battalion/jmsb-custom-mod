#include "script_component.hpp"
/*
 * Author: JMSB
 * Makes one of the local player's nets his active net. THE GAME'S PUSH-TO-TALK
 * THEN SENDS ON IT: the adapter sets it as the current voice channel (VON:
 * setCurrentChannel - TEAM = Group, C2-kind = custom 1, A2G = custom 2, a
 * CALL = its custom channel, VEH = Vehicle, DIRECT = Direct). The other nets
 * are still heard. Plays the net switch click.
 * Under TFAR / ACRE: that radio's adapter puts the set carrying the net
 * first (hook "setActive"); no click, no RF state of ours.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * true when set <BOOL>
 *
 * Example:
 * ["C2"] call jmfsb_voice_fnc_setActive
 *
 * Public: Yes
 */

params [["_net", "", [""]]];

if (!GVAR(active)) exitWith {
    if !([_net] call HOOK("setActive")) exitWith {false};
    GVAR(activeNetId) = _net;
    [QGVAR(netsChanged), []] call CBA_fnc_localEvent;
    true
};
if !(_net in (GVAR(myNets) apply {_x select 0})) exitWith {false};
if (_net isEqualTo GVAR(activeNetId)) exitWith {true};
if !([_net] call HOOK("setActive")) exitWith {false};

GVAR(activeNetId) = _net;
private _rfNet = [_net] call FUNC(rfNet);
{
    [_x, [["activeNet", _rfNet]]] call EFUNC(rf,setState);
} forEach GVAR(myNodes);
["netSwitch", _net] call FUNC(playCue);
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
true
