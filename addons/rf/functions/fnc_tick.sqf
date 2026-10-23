#include "script_component.hpp"
/*
 * Author: JMSB
 * THE SERVER TICK (CBA per-frame handler at the player tick rate):
 *
 *   0. the satellite's rain fade for this tick (setting x rain / overcast)
 *   1. registry: drop nodes whose object (or holder) is gone; collect the
 *      live, switched-on nodes with their position, profile, body loss and,
 *      for a SAT terminal, open sky (jmfsb_rf_fnc_openSky, cached per node
 *      and re-cast on the static tick or when it moved)
 *   2. listeners: hand every emitting node to the listener hooks
 *   3. mesh: per net, per key, jmfsb_rf_fnc_mesh. A node is on a net's
 *      mesh when its profile has the net's band or SAT (a SAT terminal
 *      backhauls any net through the bird)
 *   4. slices: jmfsb_rf_fnc_slices announces changes and pushes each client
 *      its own slice when it changed
 *
 * The static tick is not a second handler: it is the age at which a cached
 * edge between two nodes that have not moved is re-cast (jmfsb_rf_fnc_edge).
 *
 * PERFORMANCE, built for 60 players: the mesh is n(n-1)/2 edge calls per net
 * and key, but the edge cache is per band, so a 60-man DATA net and the voice
 * nets on the same band share casts; only moving pairs within clear-ground
 * range cast every tick.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(tick), GVAR(tickPlayers)] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (!isServer) exitWith {};

// THE SATELLITE'S WEATHER, once per tick: rain fades it, overcast a share
GVAR(satFade) = GVAR(satFadeDb) * ((rain + SAT_OVERCAST_SHARE * overcast) min 1);

private _now = CBA_missionTime;
private _info = createHashMap;
private _emitters = [];
private _gone = [];
{
    private _node = _y;
    private _obj = _node get "object";
    private _holder = _node get "holder";
    if (isNull _obj || {(_node getOrDefault ["hasHolder", false]) && {isNull _holder}}) then {
        _gone pushBack _x;
        continue;
    };
    if (!alive _obj) then {continue};
    private _state = _node get "state";
    if !(_state get "on") then {continue};

    // AI NODES only when the setting or the node says so; vehicles and
    // placed nodes held by nobody always count
    if (!GVAR(aiNodes) && {!(_node get "ai")} && {
        (_obj isKindOf "CAManBase" && {!isPlayer _obj}) || {!isNull _holder && {!isPlayer _holder}}
    }) then {continue};

    private _prof = GVAR(profiles) get (_node get "profile");
    private _pos = [_obj] call FUNC(nodePos);

    // OPEN SKY for a SAT terminal: cached, re-cast on the static tick or
    // when the antenna moved - never per frame
    private _sky = false;
    if (SAT_BAND in (_prof get "bands")) then {
        (GVAR(sky) getOrDefault [_x, SKY_UNCAST]) params ["_skyPos", "_skyTime", "_skyOpen"];
        _sky = _skyOpen;
        if ((_now - _skyTime) >= GVAR(tickStatic) || (_skyPos vectorDistance _pos) > EDGE_REUSE_M) then {
            _sky = [_obj, _pos] call FUNC(openSky);
            GVAR(sky) set [_x, [_pos, _now, _sky]];
        };
    };
    _info set [_x, [_node, _prof, _pos, _obj, [_obj] call FUNC(bodyLoss), _sky]];
    _emitters pushBack [
        _x, _obj, _pos, _node get "profile", _prof get "bands", _prof get "txPowerDbm",
        _node get "side", _state get "tx", _state get "emcon", (_node get "nets") apply {_x select 0},
        _node getOrDefault ["data", createHashMap]
    ];
} forEach GVAR(nodes);
{
    GVAR(nodes) deleteAt _x;
    GVAR(sky) deleteAt _x;
    TRACE_1("node dropped, object gone",_x);
} forEach _gone;

{
    [_emitters] call _x;
} forEach GVAR(listeners);

private _ctx = createHashMapFromArray [
    ["info", _info],
    ["noise", createHashMap],
    ["edges", createHashMap]
];

// THE MESH per net, partitioned by key: only sets holding the same key
// decode each other
private _links = createHashMap;
{
    private _netId = _x;
    private _net = _y;
    if ((_net get "state") get "cut") then {continue};
    private _band = _net get "band";

    // a SAT terminal carries any net through the bird, whatever its band
    private _groups = createHashMap;
    {
        _y params ["_node", "_prof"];
        private _bands = _prof get "bands";
        if !(_band in _bands || SAT_BAND in _bands) then {continue};
        private _key = [_node, _netId] call FUNC(nodeKey);
        if (_key isEqualTo "") then {continue};
        private _members = _groups getOrDefault [_key, []];
        _members pushBack _x;
        _groups set [_key, _members];
    } forEach _info;

    private _netLinks = createHashMap;
    {
        if (count _y < 2) then {continue};
        _netLinks merge ([_y, _band, _netId, _ctx] call FUNC(mesh));
    } forEach _groups;
    _links set [_netId, _netLinks];
} forEach GVAR(nets);
GVAR(links) = _links;

// the edge cache forgets pairs nobody has asked about for two static ticks
private _stale = [];
{
    if ((_now - (_y select 2)) > EDGE_CACHE_KEEP * GVAR(tickStatic)) then {_stale pushBack _x};
} forEach GVAR(edgeCache);
{
    GVAR(edgeCache) deleteAt _x;
} forEach _stale;

[_ctx] call FUNC(slices);
