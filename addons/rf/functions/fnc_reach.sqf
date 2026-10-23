#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_reach: every node a node can reach on a net, directly or through the
 * mesh. On the server any node; on a client only the client's own nodes.
 *
 * Arguments:
 * 0: Node id <STRING>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Node ids <ARRAY of STRINGs>
 *
 * Example:
 * ["node_a", "DATA"] call jmfsb_rf_fnc_reach
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_net", "", [""]]];

if (isServer) exitWith {
    private _peers = (GVAR(links) getOrDefault [_net, createHashMap]) getOrDefault [_id, createHashMap];
    (keys _peers) select {((_peers get _x) select 0) > 0}
};

+((GVAR(sliceIndex) getOrDefault [_id + "|" + _net, [createHashMap, []]]) select 1)
