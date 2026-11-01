#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, by remoteExec from a client: "check my admin status" - after #login,
 * #logout, a change of unit, and once at start. The server sets the sender's
 * flag from its own records (FUNC(adminFlags)); the client never sets its own
 * (review S1). The unit is the sender's, never an argument.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] remoteExecCall ["jmfsb_common_fnc_adminClaim", 2]
 *
 * Public: No
 */

if (!isServer) exitWith {};

([] call FUNC(sender)) params ["", "_unit"];
if (isNull _unit) exitWith {};

[_unit] call FUNC(adminFlags);
