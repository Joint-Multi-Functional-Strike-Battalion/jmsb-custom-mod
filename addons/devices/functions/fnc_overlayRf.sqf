#include "script_component.hpp"
/*
 * Author: JMSB
 * What RF says about the player's own sets, boiled down for the walking
 * view: which nets have a path, which are receive only, the hops to the
 * nearest relay on the data net, and every node he can reach.
 *
 * READ FROM THE CLIENT SLICE, NEVER COMPUTED. The player's nodes are the
 * ones in jmfsb_rf_slice (the server sends each client the nodes he holds);
 * each is asked jmfsb_rf_fnc_quality, jmfsb_rf_fnc_reach and jmfsb_rf_fnc_link
 * per net, which on a client read that slice. A net has a path when any of
 * his nodes has a quality above zero on it. Rebuilt by FUNC(overlayTick) after RF raises
 * jmfsb_rf_linkChanged - not inside the event, because RF raises it before
 * it has finished indexing the new slice.
 *
 * A RELAY IS A LAST HOP. A path through the mesh names the node before its
 * end; only a relay forwards, so every last hop seen is a relay in reach, and
 * the hops to it are its own link's hops. No relay seen but peers in reach
 * reads "direct only".
 *
 * RECEIVE ONLY: PLACEHOLDER, always false. It is EMCON SILENT on the node
 * (DESIGN_EW), and RF's public API does not yet tell a client a node's EMCON.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <HASHMAP>: ready <BOOL> (RF loaded), nodes <ARRAY of STRINGs>, nets
 * (net id -> [path <BOOL>, receive only <BOOL>, always false]) <HASHMAP>, peers (every
 * reachable node id) <ARRAY of STRINGs>, relayHops (-1 none seen) <NUMBER>,
 * meshReach (peers on the data net) <NUMBER>
 *
 * Example:
 * jmfsb_devices_overlayRf = [] call jmfsb_devices_fnc_overlayRf
 *
 * Public: No
 */

private _nets = createHashMap;
private _nodes = [];
private _peers = [];
private _relayHops = -1;
private _meshReach = 0;
private _ready = !isNil QEFUNC(rf,reach) && {!isNil QEFUNC(rf,link)} && {!isNil QEFUNC(rf,quality)};

if (_ready) then {
    private _slice = missionNamespace getVariable [QEGVAR(rf,slice), []];
    if !(_slice isEqualType []) then {_slice = []};

    {
        if !(_x isEqualType []) then {continue};
        _x params [["_node", "", [""]], ["_held", [], [[]]]];
        if (_node isEqualTo "") then {continue};
        _nodes pushBack _node;

        {
            if !(_x isEqualType []) then {continue};
            _x params [["_net", "", [""]]];
            if (_net isEqualTo "") then {continue};

            private _reach = [_node, _net] call EFUNC(rf,reach);
            private _quality = [_node, _net] call EFUNC(rf,quality);
            private _path = (_nets getOrDefault [_net, [false, false]]) select 0;
            _nets set [_net, [_path || _quality > 0, false]];
            _peers append _reach;

            if (_net isEqualTo MESH_NET) then {
                _meshReach = _meshReach max (count _reach);
                private _links = createHashMap;
                {
                    _links set [_x, [_node, _x, _net] call EFUNC(rf,link)];
                } forEach _reach;
                {
                    private _lastHop = _y param [2, ""];
                    if (_lastHop isEqualTo "" || {!(_lastHop in _links)}) then {continue};
                    private _hops = (_links get _lastHop) param [1, 0];
                    if (_hops > 0 && {_relayHops < 0 || _hops < _relayHops}) then {
                        _relayHops = _hops;
                    };
                } forEach _links;
            };
        } forEach _held;
    } forEach _slice;
};

createHashMapFromArray [
    ["ready", _ready],
    ["nodes", _nodes],
    ["nets", _nets],
    ["peers", _peers arrayIntersect _peers],
    ["relayHops", _relayHops],
    ["meshReach", _meshReach]
]
