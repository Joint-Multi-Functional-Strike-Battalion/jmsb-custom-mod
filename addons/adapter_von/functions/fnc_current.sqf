#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "current", client: the net the game's push-to-talk sends on now
 * (the current VON channel), so a channel picked with the game's own keys
 * becomes the active net.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Net id, "" when the current channel is none of ours <STRING>
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_current
 *
 * Public: No
 */

if (isNull player) exitWith {""};
[player, currentChannel] call FUNC(netOf)
