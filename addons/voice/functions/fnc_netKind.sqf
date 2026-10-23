#include "script_component.hpp"
/*
 * Author: JMSB
 * The kind of a voice net, from its id: PAC plan nets by the plan (short
 * range "team", long range "c2", air-to-ground "a2g"), the rest by their
 * ids.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * "team", "c2", "a2g", "veh", "call", "direct", or "" when not a voice net <STRING>
 *
 * Example:
 * ["C2"] call jmfsb_voice_fnc_netKind
 *
 * Public: No
 */

params [["_net", "", [""]]];

private _plan = GVAR(planKinds) get _net;
if (!isNil "_plan") exitWith {_plan};

switch (true) do {
    case (_net isEqualTo NET_C2): {KIND_C2};
    case (_net isEqualTo NET_A2G): {KIND_A2G};
    case (_net isEqualTo NET_VEH): {KIND_VEH};
    case (_net isEqualTo NET_DIRECT): {KIND_DIRECT};
    case ((_net find TEAM_PREFIX) == 0): {KIND_TEAM};
    case ((_net find CALL_PREFIX) == 0): {KIND_CALL};
    default {""};
}
