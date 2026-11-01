#include "script_component.hpp"
/*
 * Author: JMSB
 * Asks the server for this player's index - one row per thread they can see,
 * with no message bodies. Called once when the player exists and again after a
 * reconnect, because the client cache is disposable by design and refetching is
 * cheaper than keeping it correct across a disconnect.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_messaging_fnc_request
 *
 * Public: Yes
 */

if (isNull player) exitWith {};

// By remoteExecCall, so the server can check the player named is the sender's
// own (review S7).
[player] remoteExecCall [QFUNC(srvRequestIndex), SERVER_OWNER];
