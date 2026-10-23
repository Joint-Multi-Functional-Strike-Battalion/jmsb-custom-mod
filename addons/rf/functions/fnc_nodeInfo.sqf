#include "script_component.hpp"
/*
 * Author: JMSB
 * One node of the registry, read-only (server): a copy, so a caller can never
 * write the registry through it. Keys: id, object, profile, side (string),
 * nets (net ids of the fill - keys are not handed out), holder, owner, state
 * (on, tx, relay, activeNet, monitorNet, emcon) and data.
 *
 * Arguments:
 * 0: Node id <STRING>
 *
 * Return Value:
 * Node copy, empty when unknown or not on the server <HASHMAP>
 *
 * Example:
 * ((["node_a"] call jmfsb_rf_fnc_nodeInfo) get "state") get "activeNet"
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

if (!isServer) exitWith {createHashMap};

private _node = GVAR(nodes) getOrDefault [_id, createHashMap];
if (count _node == 0) exitWith {createHashMap};

createHashMapFromArray [
    ["id", _id],
    ["object", _node get "object"],
    ["profile", _node get "profile"],
    ["side", _node get "side"],
    ["nets", (_node get "nets") apply {_x select 0}],
    ["holder", _node get "holder"],
    ["owner", _node get "owner"],
    ["state", +(_node get "state")],
    ["data", +(_node getOrDefault ["data", createHashMap])]
]
