#include "script_component.hpp"
/*
 * Author: JMSB
 * The nets on which two nodes hold the same key (server) - the nets on which
 * B decodes A. EW asks it to decide whether an intercept is NAMED (the key is
 * held: the track shows the net) or only energy. The keys themselves never
 * leave the registry.
 *
 * Arguments:
 * 0: Node id A <STRING>
 * 1: Node id B <STRING>
 *
 * Return Value:
 * Net ids <ARRAY of STRINGs>
 *
 * Example:
 * ["node_a", "node_b"] call jmfsb_rf_fnc_sharedNets
 *
 * Public: Yes
 */

params [["_a", "", [""]], ["_b", "", [""]]];

if (!isServer) exitWith {[]};

private _nodeA = GVAR(nodes) getOrDefault [_a, createHashMap];
private _nodeB = GVAR(nodes) getOrDefault [_b, createHashMap];
if (count _nodeA == 0 || {count _nodeB == 0}) exitWith {[]};

private _out = [];
{
    private _net = _x select 0;
    private _keyA = [_nodeA, _net] call FUNC(nodeKey);
    if (_keyA isEqualTo "") then {continue};
    if (_keyA isEqualTo ([_nodeB, _net] call FUNC(nodeKey))) then {_out pushBackUnique _net};
} forEach (_nodeA get "nets");

_out
