#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_quality: how well a node is connected on a net - the best path quality
 * from it to any peer on that net, through the mesh. On the server any node;
 * on a client only the client's own nodes (his slice).
 *
 * -1 means RF does not know: the node is not in the registry (server) or not
 * in the slice (client), or it does not hold the net. 0 means it knows and
 * nobody is reachable - out of range, cut by terrain, or drowned in noise.
 *
 * Arguments:
 * 0: Node id <STRING>
 * 1: Net id <STRING>
 *
 * Return Value:
 * Quality 0..1, -1 when unknown <NUMBER>
 *
 * Example:
 * ["von_123_sr", "ALPHA"] call jmfsb_rf_fnc_quality
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_net", "", [""]]];

private _peers = if (isServer) then {
    private _fill = (GVAR(nodes) getOrDefault [_id, createHashMap]) getOrDefault ["nets", []];
    if ((_fill findIf {(_x select 0) isEqualTo _net}) < 0) then {nil} else {
        (GVAR(links) getOrDefault [_net, createHashMap]) getOrDefault [_id, createHashMap]
    }
} else {
    private _entry = GVAR(sliceIndex) getOrDefault [_id + "|" + _net, []];
    if (_entry isEqualTo []) then {nil} else {_entry select 0}
};

if (isNil "_peers") exitWith {QUALITY_UNKNOWN};

private _best = 0;
{
    _best = _best max (_x select 0);
} forEach (values _peers);
_best
