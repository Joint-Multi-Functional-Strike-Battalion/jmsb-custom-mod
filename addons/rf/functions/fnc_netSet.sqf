#include "script_component.hpp"
/*
 * Author: JMSB
 * Creates a net or changes one (server). A net that does not exist yet is
 * made with one key per side (west, east, independent, civilian), generated
 * here once - every set of a side holds its side's key unless it was
 * registered with another, so two sides on a net of the same name never
 * decode each other. A net that exists keeps its keys unless the change
 * names them.
 *
 * Changes (all optional): name, band, spreadGainDb, source, pace
 * [P, A, C, E], cut, held, patchedTo, key (one key for every side), keys
 * ([[side string, key], ...]). cut, held and patchedTo are the net's state;
 * only cut is acted on in milestone 1 (a cut net has no links).
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Changes <HASHMAP or ARRAY of [key, value]>
 *
 * Return Value:
 * Whether the net exists after the call <BOOL>
 *
 * Example:
 * ["C2", [["band", "VHF"], ["source", "signal plan"]]] call jmfsb_rf_fnc_netSet
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_changes", createHashMap, [createHashMap, []]]];

if (_id isEqualTo "") exitWith {false};
if (!isServer) exitWith {
    [QGVAR(netSet), [_id, _changes]] call CBA_fnc_serverEvent;
    false
};
if (_changes isEqualType []) then {_changes = createHashMapFromArray _changes};

private _net = GVAR(nets) getOrDefault [_id, createHashMap];
if (count _net == 0) then {
    private _keys = createHashMap;
    {
        _keys set [str _x, [] call FUNC(newKey)];
    } forEach SIDES_KEYED;
    _net = createHashMapFromArray [
        ["id", _id],
        ["name", _id],
        ["band", NET_DATA_BAND],
        ["keys", _keys],
        ["spreadGainDb", 0],
        ["pace", ["", "", "", ""]],
        ["state", createHashMapFromArray [["cut", false], ["held", false], ["patchedTo", ""]]],
        ["source", ""]
    ];
    GVAR(nets) set [_id, _net];
    INFO_1("net %1 created",_id);
};

{
    switch (_x) do {
        case "name";
        case "source": {_net set [_x, _y]};
        case "band": {
            if (_y in RF_BANDS) then {_net set ["band", _y]};
        };
        case "spreadGainDb": {_net set [_x, _y]};
        case "pace": {_net set [_x, _y]};
        case "key": {
            private _keys = _net get "keys";
            private _key = _y;
            {_keys set [_x, _key]} forEach (keys _keys);
        };
        case "keys": {
            private _keys = _net get "keys";
            {
                _x params ["_side", "_key"];
                _keys set [_side, _key];
            } forEach _y;
        };
        case "cut": {
            private _state = _net get "state";
            if ((_state get "cut") isNotEqualTo _y) then {
                _state set ["cut", _y];
                [QGVAR(netCut), [_id, _y]] call CBA_fnc_localEvent;
            };
        };
        case "held";
        case "patchedTo": {(_net get "state") set [_x, _y]};
    };
} forEach _changes;

true
