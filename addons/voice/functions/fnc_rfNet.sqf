#include "script_component.hpp"
/*
 * Author: JMSB
 * The RF net that carries a voice net: TEAM, C2 and A2G are RF nets of the
 * same id; a CALL rides DATA (a call needs reach on DATA). VEH and DIRECT are
 * not radio.
 *
 * Arguments:
 * 0: Voice net id <STRING>
 *
 * Return Value:
 * RF net id, "" when the net is not radio <STRING>
 *
 * Example:
 * ["CALL 2"] call jmfsb_voice_fnc_rfNet
 *
 * Public: No
 */

params [["_net", "", [""]]];

switch ([_net] call FUNC(netKind)) do {
    case KIND_TEAM;
    case KIND_C2;
    case KIND_A2G;
    case KIND_CUSTOM: {_net};
    case KIND_CALL: {NET_DATA};
    default {""};
}
