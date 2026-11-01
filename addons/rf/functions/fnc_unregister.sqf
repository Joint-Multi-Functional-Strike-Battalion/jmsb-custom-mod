#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_unregister: takes a node out of the registry. Its links vanish on the
 * next tick, and every slice that named it changes then.
 *
 * Arguments:
 * 0: Node id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["node_a"] call jmfsb_rf_fnc_unregister
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

// A client's call goes to the server by remoteExec, which takes it only for a
// node the client holds (FUNC(srvRequest), review R1).
if (!isServer) exitWith {
    ["unregister", [_id]] remoteExecCall [QFUNC(srvRequest), SERVER_OWNER];
};

GVAR(nodes) deleteAt _id;
GVAR(sky) deleteAt _id;
