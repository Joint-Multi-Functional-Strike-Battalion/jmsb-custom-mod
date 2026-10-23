#include "script_component.hpp"
/*
 * Author: JMSB
 * After the mesh: announce what changed and push the slices.
 *
 * ANNOUNCE. For every node and net whose links differ from the last tick,
 * jmfsb_rf_linkChanged is raised on the server: [node id, net id, links],
 * links being [[peer id, quality, hops, lastHop], ...] sorted by peer.
 *
 * SLICES. A client's slice is the links of the nodes whose holder is his
 * player:
 *
 *   [[node id, [[net id, links, reach ids], ...]], ...]
 *
 * It goes to him with publicVariableClient only when it differs from the last
 * one he was sent - never every tick (SPEC rf.tick.slice_push). Qualities are
 * quantised in the mesh, so jitter does not count as a change. A client whose
 * nodes are all gone is sent one empty slice. The server's own player (hosted,
 * single player) takes his directly.
 *
 * DEBUG. With the overlay setting on, every direct link (best quality over the
 * nets) is published to all clients as jmfsb_rf_debugEdges when it changes.
 *
 * Arguments:
 * 0: Tick context (jmfsb_rf_fnc_tick) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ctx] call jmfsb_rf_fnc_slices
 *
 * Public: No
 */

params ["_ctx"];

// ANNOUNCE
private _now = createHashMap;
{
    private _netId = _x;
    {
        private _src = _x;
        private _list = [];
        {
            _list pushBack ([_x] + _y);
        } forEach _y;
        _list sort true;
        _now set [_src + "|" + _netId, [_src, _netId, _list]];
    } forEach _y;
} forEach GVAR(links);
{
    if ((GVAR(prevLinks) getOrDefault [_x, []]) isNotEqualTo _y) then {
        [QGVAR(linkChanged), _y] call CBA_fnc_localEvent;
    };
} forEach _now;
{
    if !(_x in _now) then {
        _y params ["_src", "_netId"];
        [QGVAR(linkChanged), [_src, _netId, []]] call CBA_fnc_localEvent;
    };
} forEach GVAR(prevLinks);
GVAR(prevLinks) = _now;

// SLICES
private _slices = createHashMap;
{
    private _holder = _y get "holder";
    if (isNull _holder || {!isPlayer _holder}) then {continue};
    private _client = owner _holder;
    private _nodeId = _x;
    private _nets = [];
    {
        private _netId = _x select 0;
        private _links = (_now getOrDefault [_nodeId + "|" + _netId, ["", "", []]]) select 2;
        private _reach = (_links select {(_x select 1) > 0}) apply {_x select 0};
        _nets pushBack [_netId, _links, _reach];
    } forEach (_y get "nets");
    _nets sort true;
    private _entries = _slices getOrDefault [_client, []];
    _entries pushBack [_nodeId, _nets];
    _slices set [_client, _entries];
} forEach GVAR(nodes);
{
    if !(_x in _slices) then {_slices set [_x, []]};
} forEach GVAR(sent);

private _gone = [];
{
    private _client = _x;
    private _slice = _y;
    _slice sort true;
    if ((GVAR(sent) getOrDefault [_client, "none"]) isEqualTo _slice) then {continue};
    if (_slice isEqualTo []) then {_gone pushBack _client} else {GVAR(sent) set [_client, _slice]};
    if (!isMultiplayer || {_client == clientOwner}) then {
        [QGVAR(slice), _slice] call FUNC(receiveSlice);
    } else {
        GVAR(slice) = _slice;
        _client publicVariableClient QGVAR(slice);
    };
} forEach _slices;
{
    GVAR(sent) deleteAt _x;
} forEach _gone;

// DEBUG OVERLAY
private _edges = [];
if (GVAR(debugOverlay)) then {
    private _debug = _ctx get "edges";
    private _keys = keys _debug;
    _keys sort true;
    _edges = _keys apply {_debug get _x};
};
if (_edges isNotEqualTo GVAR(debugEdges)) then {
    GVAR(debugEdges) = _edges;
    publicVariable QGVAR(debugEdges);
};
