#include "script_component.hpp"
/*
 * Author: JMSB
 * Server end of an admin debug command (FUNC(debugCommand)): runs the
 * handler here and replies to the admin who typed it. Reached by remoteExec,
 * so the caller is the sender's own unit and an admin by the server's records
 * (review S7: the CBA event it replaced let any client run any server
 * command as anyone).
 *
 * Arguments:
 * 0: Command name <STRING>
 * 1: Its words <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["state", []] remoteExecCall ["jmfsb_common_fnc_debugRunServer", 2]
 *
 * Public: No
 */

params [["_name", "", [""]], ["_args", [], [[]]]];

if (!isServer || {!([] call FUNC(senderIsAdmin))}) exitWith {};
([] call FUNC(sender)) params ["", "_caller"];

private _entry = (localNamespace getVariable [QGVAR(debugCommands), createHashMap]) getOrDefault [_name, []];
if (_entry isEqualTo []) exitWith {};

private _reply = [_args, _caller] call (_entry select 2);
if (!isNil "_reply") then {[_reply, _caller] call FUNC(debugReply)};
