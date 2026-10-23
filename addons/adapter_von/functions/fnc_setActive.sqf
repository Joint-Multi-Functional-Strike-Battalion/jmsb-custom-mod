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
if (currentChannel isEqualTo _ch) exitWith {true};
setCurrentChannel _ch
