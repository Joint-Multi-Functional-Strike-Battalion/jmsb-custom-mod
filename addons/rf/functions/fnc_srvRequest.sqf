#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a client's request to the registry - FUNC(register),
 * FUNC(unregister), FUNC(setState), FUNC(batterySwap) or FUNC(netSet) called
 * on a client lands here by remoteExec.
 *
 * Review R1: these were CBA server events, so any client could unregister or
 * retune anyone's node. A client may act only on nodes it holds (the holder is
 * its own unit, FUNC(mayTouch)) and register only nodes it holds itself; an
 * admin may act on any. Nets are shared, so a client's netSet is an admin's
 * only.
 *
 * Arguments:
 * 0: Operation - "register", "unregister", "setState", "batterySwap" or
 *    "netSet" <STRING>
 * 1: The operation's own arguments <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["setState", ["node_a", [["tx", true]]]] remoteExecCall ["jmfsb_rf_fnc_srvRequest", 2]
 *
 * Public: No
 */

params [["_op", "", [""]], ["_args", [], [[]]]];

if (!isServer) exitWith {};

// The admin test is jmfsb_common's, which this core addon does not require.
private _fnc_admin = {!isNil QEFUNC(common,senderIsAdmin) && {[] call EFUNC(common,senderIsAdmin)}};

private _ok = switch (_op) do {
    case "register": {
        _args params [["_object", objNull, [objNull]], "", "", ["_id", "", [""]], "", ["_holder", objNull, [objNull]]];
        if (isNull _holder && {_object isKindOf "CAManBase"}) then {_holder = _object};
        private _node = GVAR(nodes) getOrDefault [_id, createHashMap];
        // A node of his own: the holder is a unit of the sending machine.
        private _mine = !isNull _holder
            && {(owner _holder) isEqualTo remoteExecutedOwner || {remoteExecutedOwner isEqualTo SERVER_OWNER}}
            && {count _node == 0 || {[_node] call FUNC(mayTouch)}};
        if (_mine || _fnc_admin) then {
            _args call FUNC(register);
            true
        } else {false};
    };
    case "unregister";
    case "setState";
    case "batterySwap": {
        private _node = GVAR(nodes) getOrDefault [_args param [0, "", [""]], createHashMap];
        // A node that is gone already: nothing to do, nothing to refuse.
        if (count _node == 0) exitWith {true};
        if !([_node] call FUNC(mayTouch)) exitWith {false};
        switch (_op) do {
            case "unregister": {_args call FUNC(unregister)};
            case "setState": {_args call FUNC(setState)};
            default {_args call FUNC(batterySwap)};
        };
        true
    };
    case "netSet": {
        if !(call _fnc_admin) exitWith {false};
        _args call FUNC(netSet);
        true
    };
    default {false};
};

if (!_ok) then {
    WARNING_2("%1 refused: machine %2 does not hold that node",_op,remoteExecutedOwner);
};
