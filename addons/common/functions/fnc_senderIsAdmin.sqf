#include "script_component.hpp"
/*
 * Author: YonV
 * Whether the remote-executed call now running may do an admin's work
 * (review S1-S5, R2). This machine's own calls and calls from the server
 * pass. On the server, a client's call passes when the server itself counts
 * that machine an admin (FUNC(adminCheck): logged in with #login, or its
 * Steam id on the server's own list). On a client, only the server passes:
 * a client cannot know who is an admin.
 *
 * Only for code reached by remoteExec. A CBA event handler is not remote
 * executed, so this passes there: never use it behind a CBA event.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The sender may act as an admin <BOOL>
 *
 * Example:
 * if !([] call jmfsb_common_fnc_senderIsAdmin) exitWith {}
 *
 * Public: Yes
 */

if (!isRemoteExecuted) exitWith {true};
if (remoteExecutedOwner isEqualTo SERVER_OWNER) exitWith {true};
if (!isServer) exitWith {false};

([] call FUNC(sender)) params ["_owner", "", "_uid"];
[_owner, _uid] call FUNC(adminCheck)
