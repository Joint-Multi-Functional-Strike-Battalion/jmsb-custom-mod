#include "script_component.hpp"
/*
 * Author: JMSB
 * The RF nodes the local player holds, with the nets each is on - read, never
 * computed. On a client that is his slice (jmfsb_rf_slice, which the server
 * sends him for exactly the nodes he holds); on the server - a hosted or
 * single-player game, where nothing is sent to itself - the registry's answer
 * through jmfsb_rf_fnc_nodesFor. Either way the pair feeds
 * jmfsb_rf_fnc_quality / reach / link, which read the same source.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[node id, [net id, ...]], ...]; [] without RF or with no set <ARRAY>
 *
 * Example:
 * private _mine = [] call jmfsb_tacpad_apps_fnc_radioRfNodes
 *
 * Public: No
 */

if (isNil QEFUNC(rf,quality) || {isNull player}) exitWith {[]};

if (isServer) exitWith {
    ([player] call EFUNC(rf,nodesFor)) apply {
        _x params ["_id", "", "", ["_fill", [], [[]]]];
        [_id, _fill apply {_x param [0, ""]}]
    }
};

private _slice = missionNamespace getVariable [QEGVAR(rf,slice), []];
if !(_slice isEqualType []) exitWith {[]};

private _out = [];
{
    if !(_x isEqualType []) then {continue};
    _x params [["_node", "", [""]], ["_held", [], [[]]]];
    if (_node isEqualTo "") then {continue};
    _out pushBack [_node, _held apply {_x param [0, ""]}];
} forEach _slice;

_out
