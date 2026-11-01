#include "script_component.hpp"
/*
 * Author: JMSB
 * A fresh battery in a set: full, and switched back on if it was flat. The
 * item that was spent is the caller's business (jmfsb_voice_fnc_batterySwap
 * takes it out of the player's kit before asking). On a client this
 * forwards to the server.
 *
 * Arguments:
 * 0: Node id <STRING>
 *
 * Return Value:
 * Whether the node exists (true from a client, which cannot know) <BOOL>
 *
 * Example:
 * ["voice_76561198000000000_sr"] call jmfsb_rf_fnc_batterySwap
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

// A client's call goes to the server by remoteExec, which takes it only for a
// node the client holds (FUNC(srvRequest), review R1).
if (!isServer) exitWith {
    ["batterySwap", [_id]] remoteExecCall [QFUNC(srvRequest), SERVER_OWNER];
    true
};

private _node = GVAR(nodes) getOrDefault [_id, createHashMap];
if (count _node == 0) exitWith {false};

_node set ["battery", 1];
_node set ["flat", false];
(_node get "state") set ["on", true];
TRACE_1("battery swapped",_id);

true
