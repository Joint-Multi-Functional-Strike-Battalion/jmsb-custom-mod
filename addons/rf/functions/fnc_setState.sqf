#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_setState: changes a node's state. Keys (all optional): on, tx, relay,
 * activeNet, monitorNet, emcon (0..3), keys - [[net id, key], ...] to
 * replace the key the node holds for nets already in its fill - and data -
 * [[key, value], ...] merged into the node's extra-data field (see
 * jmfsb_rf_fnc_register; RF stores it, the listener hooks read it).
 *
 * EMCON is stored and raises jmfsb_rf_emconChanged; in milestone 1 its only
 * effect is that a node at EMCON_NO_RELAY or above stops relaying. Power caps
 * and receive-only come with EW.
 *
 * On a client this forwards to the server.
 *
 * Arguments:
 * 0: Node id <STRING>
 * 1: Changes <HASHMAP or ARRAY of [key, value]>
 *
 * Return Value:
 * Whether the node exists <BOOL>
 *
 * Example:
 * ["node_a", [["on", false]]] call jmfsb_rf_fnc_setState
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_changes", createHashMap, [createHashMap, []]]];

if (!isServer) exitWith {
    [QGVAR(setState), [_id, _changes]] call CBA_fnc_serverEvent;
    true
};
if (_changes isEqualType []) then {_changes = createHashMapFromArray _changes};

private _node = GVAR(nodes) getOrDefault [_id, createHashMap];
if (count _node == 0) exitWith {false};
private _state = _node get "state";

{
    switch (_x) do {
        case "on";
        case "tx";
        case "relay": {
            if (_y isEqualType true) then {_state set [_x, _y]};
        };
        case "activeNet";
        case "monitorNet": {
            if (_y isEqualType "") then {_state set [_x, _y]};
        };
        case "emcon": {
            private _level = ((round _y) max 0) min EMCON_MAX;
            if ((_state get "emcon") isNotEqualTo _level) then {
                _state set ["emcon", _level];
                [QGVAR(emconChanged), [_id, _level]] call CBA_fnc_localEvent;
            };
        };
        case "data": {
            if (_y isEqualType []) then {_y = createHashMapFromArray _y};
            if (_y isEqualType createHashMap) then {(_node get "data") merge [_y, true]};
        };
        case "keys": {
            private _fill = _node get "nets";
            {
                _x params [["_net", "", [""]], ["_key", "", [""]]];
                private _i = _fill findIf {(_x select 0) isEqualTo _net};
                if (_i >= 0) then {_fill set [_i, [_net, _key]]};
            } forEach _y;
        };
    };
} forEach _changes;

true
