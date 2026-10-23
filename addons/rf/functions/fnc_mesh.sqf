#include "script_component.hpp"
/*
 * Author: JMSB
 * The mesh of one net for the nodes holding one key: every node's best path
 * to every other, as [quality, hops, lastHop].
 *
 * EDGES: jmfsb_rf_fnc_edge for every pair, once - n(n-1)/2 calls, each
 * prefiltered and cached (see there for the cost).
 *
 * SEARCH: the widest path - the route whose weakest leg is strongest -
 * ported from radio_mesh's fnc_signal: a Dijkstra on max-min quality, settling
 * one relay at a time. Only relays are settled and extended from: a node that
 * cannot relay (profile, relay switched off, EMCON >= EMCON_NO_RELAY) is an
 * endpoint only. Cost per source is relays x nodes, not nodes squared.
 *
 * HOP LIMIT: the smallest profile hop limit among the relays on the path
 * bounds how many relays it may pass through. Tracked along the path as the
 * search extends it; like radio_mesh's weak-hop count it is greedy (a wider
 * path that later hits the limit is not swapped for a narrower one that would
 * not), which is the price of a single Dijkstra.
 *
 * A SATELLITE LEG (jmfsb_rf_fnc_edge, both ends SAT terminals under open sky)
 * is one edge like any other: however far apart, it is one hop, and each
 * relay at its ends counts once against the hop limit.
 *
 * hops is the number of legs (1 = direct); lastHop is the relay that hands the
 * traffic to the receiver, "" when direct. Quality is quantised to
 * QUALITY_STEP so a slice changes only when a link does.
 *
 * Arguments:
 * 0: Node ids <ARRAY of STRINGs>
 * 1: Band <STRING>
 * 2: Net id <STRING>
 * 3: Tick context (jmfsb_rf_fnc_tick) <HASHMAP>
 *
 * Return Value:
 * Source id -> peer id -> [quality, hops, lastHop] <HASHMAP>
 *
 * Example:
 * [_ids, "UHF", "DATA", _ctx] call jmfsb_rf_fnc_mesh
 *
 * Public: No
 */

params ["_ids", "_band", "_net", "_ctx"];

private _n = count _ids;
private _info = _ctx get "info";
private _debug = _ctx get "edges";

// EDGES
private _adj = [];
for "_i" from 0 to (_n - 1) do {
    _adj pushBack (_ids apply {0});
};
for "_i" from 0 to (_n - 2) do {
    for "_j" from (_i + 1) to (_n - 1) do {
        private _q = [_ids select _i, _ids select _j, _band, _net, _ctx] call FUNC(edge);
        (_adj select _i) set [_j, _q];
        (_adj select _j) set [_i, _q];
        if (_q > 0 && GVAR(debugOverlay)) then {
            private _pair = [_ids select _i, _ids select _j];
            _pair sort true;
            private _key = _pair joinString "|";
            private _qq = (round (_q / QUALITY_STEP)) * QUALITY_STEP;
            private _was = _debug getOrDefault [_key, [_key, objNull, objNull, 0]];
            if (_qq > (_was select 3)) then {
                _debug set [_key, [_key, (_info get (_pair select 0)) select 3, (_info get (_pair select 1)) select 3, _qq]];
            };
        };
    };
};

// RELAYS and their hop limits
private _relay = [];
private _limit = [];
{
    (_info get _x) params ["_node", "_prof"];
    private _state = _node get "state";
    private _lim = _prof get "hopLimit";
    _limit pushBack _lim;
    _relay pushBack ((_prof get "relayCapable") && {_state get "relay"} && {(_state get "emcon") < EMCON_NO_RELAY} && _lim > 0);
} forEach _ids;

// WIDEST PATH from every source
private _out = createHashMap;
for "_s" from 0 to (_n - 1) do {
    private _best = +(_adj select _s);
    private _hops = _ids apply {1};
    private _last = _ids apply {-1};
    private _relays = _ids apply {0};
    private _lims = _ids apply {HOP_LIMIT_NONE};
    private _done = _ids apply {false};
    _done set [_s, true];
    _best set [_s, 0];

    while {true} do {
        // the unsettled relay reached best so far
        private _u = -1;
        private _uQ = 0;
        for "_i" from 0 to (_n - 1) do {
            if (!(_done select _i) && {_relay select _i} && {(_best select _i) > _uQ}) then {
                _u = _i;
                _uQ = _best select _i;
            };
        };
        if (_u < 0) exitWith {};
        _done set [_u, true];

        // can this path take one more relay?
        private _newRelays = (_relays select _u) + 1;
        private _newLim = (_lims select _u) min (_limit select _u);
        if (_newRelays > _newLim) then {continue};

        private _row = _adj select _u;
        for "_v" from 0 to (_n - 1) do {
            if (_done select _v) then {continue};
            private _q = _uQ min (_row select _v);
            if (_q > (_best select _v)) then {
                _best set [_v, _q];
                _hops set [_v, (_hops select _u) + 1];
                _last set [_v, _u];
                _relays set [_v, _newRelays];
                _lims set [_v, _newLim];
            };
        };
    };

    private _peers = createHashMap;
    for "_v" from 0 to (_n - 1) do {
        private _q = (round ((_best select _v) / QUALITY_STEP)) * QUALITY_STEP;
        if (_v == _s || _q <= 0) then {continue};
        private _l = _last select _v;
        private _lastHop = if (_l >= 0) then {_ids select _l} else {""};
        _peers set [_ids select _v, [_q, _hops select _v, _lastHop]];
    };
    _out set [_ids select _s, _peers];
};

_out
