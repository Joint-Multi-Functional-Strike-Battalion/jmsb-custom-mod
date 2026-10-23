#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_link: the best path from node A to node B on a net. On the server any
 * pair; on a client only from a node in that client's own slice (anything else
 * reads as no link) - clients read, never compute.
 *
 * Arguments:
 * 0: Node id A <STRING>
 * 1: Node id B <STRING>
 * 2: Net id <STRING>
 *
 * Return Value:
 * [quality 0..1, hops (1 = direct, 0 = none), lastHop ("" = direct)] <ARRAY>
 *
 * Example:
 * ["node_a", "node_b", "DATA"] call jmfsb_rf_fnc_link
 *
 * Public: Yes
 */

params [["_a", "", [""]], ["_b", "", [""]], ["_net", "", [""]]];

if (isServer) exitWith {
    +(((GVAR(links) getOrDefault [_net, createHashMap]) getOrDefault [_a, createHashMap]) getOrDefault [_b, [0, 0, ""]])
};

+(((GVAR(sliceIndex) getOrDefault [_a + "|" + _net, [createHashMap]]) select 0) getOrDefault [_b, [0, 0, ""]])
