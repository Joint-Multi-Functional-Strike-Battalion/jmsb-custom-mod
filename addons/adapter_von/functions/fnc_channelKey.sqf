#include "script_component.hpp"
/*
 * Author: JMSB
 * The custom channel a voice net rides: "C2" for every C2-kind net, "A2G"
 * for every A2G-kind net (the plan's air-to-ground nets too), or the CALL
 * net's own id. TEAM, VEH and DIRECT are on built-in channels.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Custom channel key, "" for none <STRING>
 *
 * Example:
 * ["CALL 3"] call jmfsb_adapter_von_fnc_channelKey
 *
 * Public: No
 */

params [["_net", "", [""]]];

switch ([_net] call EFUNC(voice,netKind)) do {
    case KIND_C2: {KEY_C2};
    case KIND_A2G: {KEY_A2G};
    case KIND_CALL;
    case KIND_CUSTOM: {_net};
    default {""};
}
