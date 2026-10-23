#include "script_component.hpp"
/*
 * Author: JMSB
 * The key a node holds for a net: the one it was registered with, or, when
 * that is "", its side's key for the net (jmfsb_rf_fnc_netSet makes one per
 * side when the net is created). Resolved at mesh time, so a node can be
 * registered before the signal plan has created the net.
 *
 * Arguments:
 * 0: Node <HASHMAP>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Key, "" when the node is not on the net or the net does not exist <STRING>
 *
 * Example:
 * [_node, "DATA"] call jmfsb_rf_fnc_nodeKey
 *
 * Public: No
 */

params [["_node", createHashMap, [createHashMap]], ["_netId", "", [""]]];

private _net = GVAR(nets) getOrDefault [_netId, createHashMap];
if (count _net == 0) exitWith {""};

private _entry = (_node getOrDefault ["nets", []]) select {(_x select 0) isEqualTo _netId};
if (_entry isEqualTo []) exitWith {""};

private _key = (_entry select 0) select 1;
if (_key isNotEqualTo "") exitWith {_key};
(_net getOrDefault ["keys", createHashMap]) getOrDefault [_node getOrDefault ["side", ""], ""]
