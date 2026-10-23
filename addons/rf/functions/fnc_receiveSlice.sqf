#include "script_component.hpp"
/*
 * Author: JMSB
 * A client takes the slice the server pushed (public variable handler on
 * jmfsb_rf_slice) and indexes it for jmfsb_rf_fnc_link and jmfsb_rf_fnc_reach.
 * For every node and net whose links differ from the slice before,
 * jmfsb_rf_linkChanged is raised locally: [node id, net id, links]. No
 * computation beyond that - clients read, never compute.
 *
 * Arguments:
 * 0: Variable name <STRING>
 * 1: Slice <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [QGVAR(slice), _slice] call jmfsb_rf_fnc_receiveSlice
 *
 * Public: No
 */

params ["", ["_slice", [], [[]]]];

GVAR(slice) = _slice;
private _index = createHashMap;
{
    _x params ["_nodeId", "_nets"];
    {
        _x params ["_netId", "_links", "_reach"];
        private _byPeer = createHashMap;
        {
            _byPeer set [_x select 0, _x select [1, 3]];
        } forEach _links;
        private _key = _nodeId + "|" + _netId;
        _index set [_key, [_byPeer, _reach, _links, _nodeId, _netId]];
        if (((GVAR(sliceIndex) getOrDefault [_key, [createHashMap, [], []]]) select 2) isNotEqualTo _links) then {
            [QGVAR(linkChanged), [_nodeId, _netId, _links]] call CBA_fnc_localEvent;
        };
    } forEach _nets;
} forEach _slice;

{
    if !(_x in _index) then {
        [QGVAR(linkChanged), [_y select 3, _y select 4, []]] call CBA_fnc_localEvent;
    };
} forEach GVAR(sliceIndex);

GVAR(sliceIndex) = _index;
