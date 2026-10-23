#include "script_component.hpp"
/*
 * Author: JMSB
 * Hook "reserve": the server gives a net its custom channel now, rather than
 * at the first join - so the voice core can refuse an RTO net while there is
 * still a chance to say so (jmfsb_voice_fnc_srvNetAdd). The channel is kept by
 * the net's key for the rest of the mission (VON cannot delete one); the same
 * name made again gets the same channel back.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Reserved - false when the ten custom channels are all taken <BOOL>
 *
 * Example:
 * ["RECON 2"] call jmfsb_adapter_von_fnc_reserve
 *
 * Public: No
 */

params [["_net", "", [""]]];

if (!isServer) exitWith {false};

([[_net] call FUNC(channelKey)] call FUNC(ensureChannel)) > CUSTOM_NONE
